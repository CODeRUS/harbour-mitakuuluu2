import QtQuick 2.1
import Sailfish.Silica 1.0
import harbour.mitakuuluu2.client 1.0
import QtLocation 5.0
import QtPositioning 5.1
import "Utilities.js" as Utilities

Page {
    id: page
    objectName: "conversationPage"
    allowedOrientations: conversationOrientation

    property PositionSource positionSource
    property AudioRecorder audioRecorder
    property ConversationModel conversationModel: ConversationModel {}

    onStatusChanged: {
        if (page.status === PageStatus.Inactive && pageStack.depth === 1) {
            if (positionSource)
                positionSource.destroy()
            saveText()
            Mitakuuluu.setActiveJid("")
            Theme.clearBackgroundImage()
        }
        else if (page.status === PageStatus.Active) {
            if (pageStack._currentContainer.attachedContainer == null) {
                if (isGroup) {
                    pageStack.pushAttached(Qt.resolvedUrl("GroupProfile.qml"), {"conversationModel": conversationModel, "jid": jid, "conversationPage": page})
                }
                else if (isBroadcast) {
                    pageStack.pushAttached(Qt.resolvedUrl("BroadcastProfile.qml"), {"subject": initialModel.name, "initialParticipants": initialParticipants, "conversationModel": conversationModel, "jid": jid, "conversationPage": page})
                }
                else {
                    pageStack.pushAttached(Qt.resolvedUrl("UserProfile.qml"), {"conversationModel": conversationModel, "jid": jid})
                }
            }
            var wallpaper = wallpaperConfig.value
            if (wallpaper !== "unset") {
                Theme.setBackgroundImage(Qt.resolvedUrl(wallpaper), Screen.width, Screen.height)
            }

            var firstStartConversation = settings.firstStartConversation
            if (firstStartConversation) {
                horizontalHint.stop()
                horizontalHint.direction = TouchInteraction.Left
                horizontalHint.start()
                settings.firstStartConversation = false
            }
            horizontalHint.visible = firstStartConversation
            hintLabel.visible = firstStartConversation
            if (settings.showKeyboard) {
                sendBox.forceActiveFocus()
            }
        }
    }

    DConfValue {
        id: wallpaperConfig
        key: "/apps/harbour-mitakuuluu2/wallpaper/" + page.jid
        defaultValue: "unset"
    }

    property var initialModel
    onInitialModelChanged: {
        if (page.status == PageStatus.Inactive) {
            jid = initialModel.jid
            if (jid.indexOf("@broadcast") < 0) {
                name = initialModel.nickname
            }
            else {
                if (initialModel.name.length == 0) {
                    name = qsTr("Broadcast")
                }
                else {
                    name = Utilities.emojify(initialModel.name, emojiPath)
                }
                lastseen = getNickname(initialModel.jid, initialModel.jid.split("@")[0], initialModel.subowner)
            }

            available = initialModel.available
            blocked = initialModel.blocked
            avatar = settings.usePhonebookAvatars || (jid.indexOf("-") > 0)
                    ? (initialModel.avatar == "undefined" ? "" : (initialModel.avatar))
                    : (initialModel.owner == "undefined" ? "" : (initialModel.owner.length > 0 ? initialModel.owner : initialModel.avatar))
            typing = initialModel.typing
            lastseconds = parseInt(initialModel.timestamp)

            conversationModel.jid = jid

            Mitakuuluu.setActiveJid(jid)
            if (!available && jid.indexOf("@broadcast") < 0 && jid.indexOf("-") < 0) {
                Mitakuuluu.requestLastOnline(jid)
            }
        }
    }

    property var initialParticipants: isBroadcast ? initialModel.subowner.split(";") : []

    property bool isGroup: jid.indexOf("-") > 0
    property bool isBroadcast: jid.indexOf("@broadcast") >= 0
    property int muted: 0
    property bool blocked: false
    property bool available: false
    property string name: ""
    property string jid: ""
    property string avatar: ""
    property string lastseen: lastseconds == -2 ? qsTr("Contact blocked you")
                                                : (lastseconds == -1 ? qsTr("Last online: hidden")
                                                                     : qsTr("Last seen: %1", "Last seen converstation text")
                                                                            .arg(timestampToDateTime(lastseconds)))
    property int lastseconds: 0
    property bool typing: false

    function saveText() {
        typingConfig.value = sendBox.text.trim()
    }
    DConfValue {
        id: typingConfig
        key: "/apps/harbour-mitakuuluu2/typing/" + page.jid
        defaultValue: ""
        onValueChanged: {
            sendBox.text = typingConfig.value
        }
    }

    function getMediaPreview(model) {
        if (model.mediatype == 1) {
            if (model.localurl.length > 0) {
                return model.localurl
            }
            else {
                return "data:" + model.mediamime + ";base64," + model.mediathumb
            }
        }
        else {
            return "data:image/jpeg;base64," + model.mediathumb
        }
    }

    function addMention(mjid) {
        var mention = getNicknameByJid(mjid) + ": "
        sendBox.text += mention
        sendBox.cursorPosition += mention.length
        sendBox.forceActiveFocus()
    }

    Connections {
        target: ContactsBaseModel
        onConversationClean: {
            if (pjid == page.jid) {
                conversationModel.reloadConversation()
            }
        }
    }

    Connections {
        target: Mitakuuluu
        onPresenceAvailable: {
            if (mjid == page.jid) {
                lastseconds = new Date().getTime() / 1000
                available = true
            }
        }
        onPresenceUnavailable: {
            if (mjid == page.jid) {
                available = false
                Mitakuuluu.requestLastOnline(page.jid)
            }
        }
        onPresenceLastSeen: {
            if (mjid == page.jid && !page.available) {
                lastseconds = seconds
                page.available = seconds == 0
            }
        }
        onPictureUpdated: {
            if (pjid == page.jid) {
                avatar = ""
                avatar = path
            }
        }
        onContactTyping: {
            if (cjid == page.jid) {
                typing = true
            }
        }
        onContactPaused: {
            if (cjid == page.jid) {
                typing = false
            }
        }
        onMessageReceived: {
            typing = false
            if (applicationActive && !blocked && (data.jid === jid) && (data.author != Mitakuuluu.myJid)) {
                if (settings.notifyActive)
                    vibration.start()
                if (!conversationView.atYEnd)
                    newMessageItem.opacity = 1.0
            }
            else if (data.author == Mitakuuluu.myJid) {
                //scrollDown.start()
            }
        }
        onNewGroupSubject: {
            if (data.jid == page.jid) {
                name = data.message
            }
        }
        onContactsBlocked: {
            if (!page.isGroup) {
                if  (list.indexOf(page.jid) !== -1) {
                    blocked = true
                }
                else {
                    blocked = false
                }
            }
        }
        onGroupsMuted: {
            if (page.isGroup) {
                if  (jids.indexOf(page.jid) !== -1) {
                    blocked = true
                }
                else {
                    blocked = false
                }
            }
        }
    }

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        pressDelay: 0
        contentHeight: height

        PullDownMenu {
            busy: typing
            /*MenuItem {
                text: qsTr("Clear all messages", "Conversation menu item")
                onClicked: {
                    remorseAll.execute(qsTr("Clear all messages", "Conversation delete all messages remorse popup"),
                                       function() {
                                           conversationModel.removeConversation(page.jid)
                                           ContactsBaseModel.reloadContact(page.jid)
                                       },
                                       5000)
                }
            }*/

            MenuItem {
                text: qsTr("Muting", "Contacts context menu muting item")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("MutingSelector.qml"), {"jid": page.jid})
                }
            }

            MenuItem {
                text: qsTr("Search message")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("SearchConversation.qml"), {"jid": page.jid})
                }
            }

            MenuItem {
                text: qsTr("Load old conversation", "Conversation menu item")
                visible: conversationView.count < conversationModel.allCount
                onClicked: {
                    conversationModel.loadOldConversation(20)
                }
            }
        }

        PushUpMenu {
            id: pushMedia
            visible: Mitakuuluu.connectionStatus == Mitakuuluu.LoggedIn

            _activeHeight: mediaSendRow.height

            Item {
                width: parent.width
                height: Theme.itemSizeMedium

                Row {
                    id: mediaSendRow
                    x: width > parent.width ? 0 : ((parent.width - width) / 2)
                    height: parent.height
                    spacing: Theme.paddingSmall
                    visible: !audioRecorder

                    IconButton {
                        icon.source: "image://theme/icon-m-image"
                        onClicked: {
                            pushMedia.hide()
                            pageStack.push(Qt.resolvedUrl("MediaSelector.qml"), {"mode": "image", "datesort": true, "multiple": true})
                            pageStack.currentPage.accepted.connect(mediaReceiver.mediaAccepted)
                        }
                    }

                    IconButton {
                        icon.source: "image://theme/icon-camera-shutter-release"
                        onClicked: {
                            pushMedia.hide()
                            pageStack.push(Qt.resolvedUrl("Capture.qml"), {"broadcastMode": false, "jid": page.jid})
                            pageStack.currentPage.captured.connect(captureReceiver.captureAccepted)
                        }
                    }

                    IconButton {
                        icon.source: "image://theme/icon-m-gps"
                        onClicked: {
                            pushMedia.hide()
                            if (checkLocationEnabled())
                                positionSourceCreationTimer.start()
                            else
                                banner.notify(qsTr("Enable location in settings!", "Banner text if GPS disabled in settings"))
                        }
                    }

                    Item {
                        id: voicePlaceholder
                        width: Theme.itemSizeSmall
                        height: Theme.itemSizeSmall
                    }

                    IconButton {
                        icon.source: "image://theme/icon-m-people"
                        onClicked: {
                            pushMedia.hide()
                            pageStack.push(Qt.resolvedUrl("SendContactCard.qml"))
                            pageStack.currentPage.accepted.connect(vcardReceiver.contactAccepted)
                        }
                    }
                }

                IconButton {
                    id: voiceSend
                    icon.source: "image://theme/icon-m-mic"
                    icon.anchors.centerIn: undefined
                    icon.anchors.verticalCenter: voiceSend.verticalCenter

                    x: voicePlaceholder.x + mediaSendRow.x
                    width: audioRecorder ? (64 * 3 + mediaSendRow.spacing) : Theme.itemSizeSmall

                    onClicked: {
                        if (voiceRecordTimer.running) {
                            voiceRecordTimer.stop()
                            banner.notify(qsTr("Hold button for recording, release to send", "Conversation voice recorder description label"))
                        }
                    }
                    onPressed: {
                        Mitakuuluu.startRecording(page.jid)
                        voiceRecordTimer.start()
                        page.forwardNavigation = false
                        page.backNavigation = false
                        recordDuration.anchors.leftMargin = mouse.x - (Theme.itemSizeSmall * 2)
                        durationLabel.color = Theme.primaryColor
                    }
                    onReleased: {
                        Mitakuuluu.endTyping(page.jid)
                        if (audioRecorder) {
                            audioRecorder.stop()
                            if (containsMouse) {
                                var voiceMedia = Mitakuuluu.saveVoice(audioRecorder.path)
                                Mitakuuluu.sendMedia([page.jid], voiceMedia, "", initialParticipants, page.name)
                            }
                            Mitakuuluu.rejectMediaCapture(audioRecorder.path)
                            audioRecorder.destroy()
                            pushMedia.hide()
                        }
                        page.forwardNavigation = true
                        page.backNavigation = true
                    }
                    onPositionChanged: {
                        recordDuration.anchors.leftMargin = mouse.x - (Theme.itemSizeSmall * 2)
                        durationLabel.color = containsMouse ? Theme.primaryColor : "red"
                    }
                }

                Item {
                    id: recordDuration
                    height: 64
                    width: 64 * 2
                    anchors.left: voiceSend.left
                    anchors.leftMargin: - (Theme.itemSizeSmall * 2)
                    visible: audioRecorder

                    Label {
                        id: durationLabel
                        anchors {
                            left: parent.left
                            verticalCenter: parent.verticalCenter
                        }
                        text: audioRecorder ? (Format.formatDuration(audioRecorder.duration / 1000, Format.DurationShort)) : ""
                        font.pixelSize: Theme.fontSizeLarge
                    }

                    Label {
                        id: deleteVoiceLabel
                        anchors {
                            top: durationLabel.bottom
                            topMargin: - Theme.paddingMedium
                            horizontalCenter: durationLabel.horizontalCenter
                        }
                        text: !voiceSend.containsMouse ? qsTr("Release to delete", "Conversation voice recorder delete label")
                                                       : qsTr("Release to send", "Conversation voice recorder delete label")
                        color: Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeTiny
                    }
                }
            }
        }

        PageHeader {
            id: header
            clip: true
            Rectangle {
                smooth: true
                width: parent.width
                height: 20
                anchors.bottom: parent.bottom
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop {
                        position: 1.0
                        color: page.blocked ? Theme.rgba("red", 0.6)
                                            : (Mitakuuluu.connectionStatus == Mitakuuluu.LoggedIn ? (page.available ? Theme.rgba(Theme.highlightColor, 0.6)
                                                                                                                    : "transparent")
                                                                                                  : "transparent")
                    }
                }
            }
            AvatarHolder {
                id: pic
                height: parent.height - (Theme.paddingSmall * 2)
                width: height
                source: page.avatar
                emptySource: "../images/avatar-empty" + (page.jid.indexOf("-") > 0 ? "-group" : "") + ".png"
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingSmall
            }
            Column {
                id: hColumn
                anchors.left: parent.left
                anchors.leftMargin: pic.width
                anchors.right: pic.left
                spacing: Theme.paddingSmall
                anchors.verticalCenter: parent.verticalCenter
                Label {
                    id: nameText
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    color: Theme.highlightColor
                    font.pixelSize: Theme.fontSizeMedium
                    font.family: Theme.fontFamily
                    elide: Text.ElideRight
                    truncationMode: TruncationMode.Fade
                    text: Utilities.emojify(page.name, emojiPath)
                }
                Label {
                    id: lastSeenText
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    truncationMode: TruncationMode.Fade
                    color: Theme.primaryColor
                    font.pixelSize: Theme.fontSizeExtraSmall
                    font.family: Theme.fontFamily
                    text: typing
                            ? qsTr("Typing...", "Contact typing converstation text")
                            : lastseen
                    visible: typing || (!available && page.jid.indexOf("-") == -1 && text.length > 0)
                }
            }
        }

        SilicaListView {
            id: conversationView
            model: conversationModel
            anchors {
                top: header.bottom
                bottom: sendBox.top
            }
            width: parent.width
            clip: true
            cacheBuffer: height * 2
            pressDelay: 0
            spacing: Theme.paddingMedium
            interactive: contentHeight > height
            currentIndex: -1
            verticalLayoutDirection: ListView.BottomToTop
            delegate: Component {
                id: delegateComponent
                Loader {
                    width: parent.width
                    asynchronous: false
                    source: Qt.resolvedUrl(settings.conversationTheme)
                }
            }
            MouseArea {
                id: newMessageItem
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                height: visible ? (message.paintedHeight + (Theme.paddingLarge * 2)) : 0
                visible: opacity > 0
                opacity: 0.0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 500
                        easing.type: Easing.InOutQuad
                        properties: "opacity,height"
                    }
                }

                Rectangle {
                    id: bg
                    anchors.fill: parent
                    color: Theme.secondaryHighlightColor
                }

                Label {
                    id: message
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: Theme.fontSizeLarge
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.paddingLarge
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.paddingRight
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    wrapMode: Text.Wrap
                    text: qsTr("New message", "Conversation new message indicator")
                }

                onClicked: {
                    if (!conversationView.atYEnd)
                        scrollDownTimer.start()
                    opacity = 0.0
                }
            }

            function scrollToTop() {
                if (!conversationView.atYBeginning)
                    scrollUpTimer.start()
            }
            function scrollToBottom() {
                if (!conversationView.atYEnd)
                    scrollDownTimer.start()
            }

            onAtYEndChanged: {
                if (atYEnd && newMessageItem.visible) {
                    newMessageItem.opacity = 0.0
                }
            }

            onFlickStarted: {
                if (!conversationView.hasOwnProperty("quickScroll") || !conversationView.quickScroll) {
                    iconUp.opacity = 1.0;
                    iconDown.opacity = 1.0;
                }
            }
            onMovementEnded: {
                if (iconUp.visible || iconDown.visible)
                    hideIconsTimer.start()
            }

            VerticalScrollDecorator {
                id: vscroll
                opacity: (timer.moving && _inBounds) || timer.running || scrollUpTimer.running || scrollDownTimer.running ? 1.0 : 0.0

                Timer {
                    id: timer
                    property bool moving: conversationView.movingVertically
                    onMovingChanged: if (!moving && vscroll._inBounds) restart()
                    interval: 300
                }
            }
        }

        EmojiTextArea {
            id: sendBox
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.leftMargin: - Theme.paddingMedium
            anchors.right: parent.right
            anchors.rightMargin: - Theme.paddingMedium
            placeholderText: qsTr("Tap here to enter message", "Message composing tet area placeholder")
            focusOutBehavior: settings.hideKeyboard ? FocusBehavior.ClearItemFocus : FocusBehavior.KeepFocus
            textRightMargin: settings.sendByEnter ? 0 : 64
            property bool buttonVisible: settings.sendByEnter
            maxHeight: page.isPortrait ? 200 : 140
            background: Component {
                Item {
                    anchors.fill: parent

                    IconButton {
                        id: sendButton
                        icon.source: "image://theme/icon-m-message"
                        highlighted: enabled
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: - Theme.paddingSmall
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.paddingSmall
                        visible: !sendBox.buttonVisible
                        enabled: Mitakuuluu.connectionStatus == Mitakuuluu.LoggedIn && sendBox.text.trim().length > 0
                        onClicked: {
                            sendBox.send()
                        }
                    }
                }
            }
            EnterKey.enabled: settings.sendByEnter ? (Mitakuuluu.connectionStatus == 4 && text.trim().length > 0) : true
            EnterKey.highlighted: text.trim().length > 0
            EnterKey.iconSource: settings.sendByEnter ? "image://theme/icon-m-message" : "image://theme/icon-m-enter"
            EnterKey.onClicked: {
                if (settings.sendByEnter) {
                    send()
                }
            }
            onTextChanged: {
                if (!typingTimer.running) {
                    if (page.jid.indexOf("@broadcast") < 0) {
                        Mitakuuluu.startTyping(page.jid)
                        typingTimer.start()
                    }
                }
                else
                    typingTimer.restart()
            }
            function send() {
                deselect()
                console.log("send: " + sendBox.text.trim())
                Mitakuuluu.sendText(page.jid, sendBox.text.trim(), initialParticipants, page.name)
                sendBox.text = ""
                if (settings.hideKeyboard)
                    focus = false
                saveText()
            }
        }

        MouseArea {
            id: stopScroll
            visible: scrollUpTimer.running || scrollDownTimer.running
            anchors.fill: conversationView
            onPressed: {
                if (scrollUpTimer.running)
                    scrollUpTimer.stop()
                if (scrollDownTimer.running)
                    scrollDownTimer.stop()
            }
        }

        IconButton {
            id: iconUp
            y: parent.height / 2 - height
            anchors {
                right: parent.right
                rightMargin: Theme.paddingMedium
            }
            icon.source: "image://theme/icon-l-up"
            visible: opacity > 0.0
            opacity: 0.0
            onClicked: {
                conversationView.scrollToTop()
            }
            Behavior on opacity {
                FadeAnimation {}
            }
        }

        IconButton {
            id: iconDown
            y: parent.height / 2 + height
            anchors {
                right: parent.right
                rightMargin: Theme.paddingMedium
            }
            icon.source: "image://theme/icon-l-down"
            visible: opacity > 0.0
            opacity: 0.0
            onClicked: {
                conversationView.scrollToBottom()
            }
            Behavior on opacity {
                FadeAnimation {}
            }
        }
    }

    InteractionHintLabel {
        id: hintLabel
        anchors.bottom: page.bottom
        Behavior on opacity { FadeAnimation { duration: 1000 } }
        text: qsTr("Flick left to access Contact details")
        visible: false
    }

    TouchInteractionHint {
        id: horizontalHint
        loops: Animation.Infinite
        anchors.verticalCenter: page.verticalCenter
        visible: false
    }

    RemorsePopup {
        id: remorseAll
    }

    Timer {
        id: forceTimer
        interval: 300
        triggeredOnStart: false
        repeat: false
        onTriggered: sendBox.forceActiveFocus()
    }

    Timer {
        id: typingTimer
        interval: 3000
        triggeredOnStart: false
        repeat: false
        onTriggered: Mitakuuluu.endTyping(page.jid)
    }

    Timer {
        id: hideIconsTimer
        interval: 3000
        onTriggered: {
            iconUp.opacity = 0.0
            iconDown.opacity = 0.0
        }
    }

    Timer {
        id: scrollDownTimer
        interval: 1
        repeat: true
        onTriggered: {
            conversationView.contentY += 100
            if (conversationView.atYEnd) {
                scrollDownTimer.stop()
                iconDown.opacity = 0.0
                conversationView.returnToBounds()
            }
        }
    }

    Timer {
        id: scrollUpTimer
        interval: 1
        repeat: true
        onTriggered: {
            conversationView.contentY -= 100
            if (conversationView.atYBeginning) {
                scrollUpTimer.stop()
                iconUp.opacity = 0.0
                conversationView.returnToBounds()
            }
        }
    }

    Timer {
        id: voiceRecordTimer
        interval: 500
        onTriggered: {
            createVoiceRecorder()
        }
    }

    function createVoiceRecorder() {
        console.log("creating recorder component")
        audioRecorder = recorderComponent.createObject(null)
        audioRecorder.record()
        recordDuration.anchors.leftMargin = 0
        durationLabel.color = Theme.primaryColor
    }

    Component {
        id: recorderComponent
        AudioRecorder {}
    }

    Timer {
        id: positionSourceRecreationTimer
        interval: 1500
        onTriggered: {
            createPositionSource()
        }
    }

    Timer {
        id: positionSourceCreationTimer
        interval: 1
        onTriggered: {
            createPositionSource()
        }
    }

    function createPositionSource() {
        console.log("creating location component")
        positionSource = positionSourceComponent.createObject(null, {"initialTimestamp": new Date().getTime()})
    }

    Component {
        id: positionSourceComponent
        PositionSource {
            active: true
            updateInterval : 1000
            property int initialTimestamp: 0

            onPositionChanged: {
                if (positionSource
                        && positionSource.position
                        && positionSource.position.horizontalAccuracyValid
                        && positionSource.position.horizontalAccuracy > 0
                        && positionSource.position.timestamp.getTime() >= initialTimestamp
                        && positionSource.position.coordinate
                        && positionSource.position.coordinate.isValid) {
                    console.log("sending coordinates: " + positionSource.position.coordinate.latitude + "," + positionSource.position.coordinate.longitude)
                    Mitakuuluu.sendLocation(page.jid,
                                            positionSource.position.coordinate.latitude,
                                            positionSource.position.coordinate.longitude,
                                            16,
                                            settings.mapSource,
                                            initialParticipants,
                                            page.name)
                    positionSource.active = false
                    positionSource.destroy()
                }
            }

            Component.onCompleted: {
                banner.notify(qsTr("Waiting for coordinates...", "Conversation location sending banner text"))
                console.log("waiting for coordinates. initial: " + initialTimestamp)
            }

            onSourceErrorChanged: {
                if (sourceError === PositionSource.ClosedError) {
                    console.log("Position source backend closed, restarting...")
                    positionSourceRecreationTimer.restart()
                    positionSource.destroy()
                }
            }
        }
    }

    QtObject {
        id: captureReceiver
        property string imagePath: ""

        function captureAccepted() {
            pageStack.currentPage.captured.disconnect(captureReceiver.captureAccepted)
            imagePath = pageStack.currentPage.imagePath
            Mitakuuluu.sendMedia([page.jid], imagePath, "", initialParticipants, page.name)
        }
    }

    QtObject {
        id: mediaReceiver
        property var mediaFiles: []

        function mediaAccepted() {
            pageStack.currentPage.accepted.disconnect(mediaReceiver.mediaAccepted)
            mediaFiles = pageStack.currentPage.selectedFiles
            for (var i = 0; i < mediaFiles.length; i++) {
                Mitakuuluu.sendMedia([page.jid], mediaFiles[i], "", initialParticipants, page.name)
            }
        }
    }

    QtObject {
        id: vcardReceiver
        property var vcardData
        property string displayName

        function contactAccepted() {
            pageStack.currentPage.accepted.disconnect(vcardReceiver.contactAccepted)
            vcardData = pageStack.currentPage.vCardData
            displayName = pageStack.currentPage.displayLabel
            Mitakuuluu.sendVCard([page.jid], displayName, vcardData, initialParticipants, page.name)
        }
    }
}
