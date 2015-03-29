import QtQuick 2.1
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import QtMultimedia 5.0
import harbour.mitakuuluu2.client 1.0
import org.nemomobile.thumbnailer 1.0
import "Utilities.js" as Utilities

MouseArea {
    id: item

    property bool down: pressed && containsMouse && !DragFilter.canceled

    property bool haveSection: model.section ? ((index == conversationView.count - 1) || (conversationView.model.get(index + 1).section != conversationView.model.get(index).section)) : false

    width: parent.width
    height: mainBg.height + content.anchors.topMargin + (menuOpen ? _menuItem.height : 0) + (urlmenuOpen ? _urlmenuItem.height : 0)
    ListView.onRemove: animateRemoval(item)
    property bool __silica_item_removed: false
    Binding on opacity {
        when: __silica_item_removed
        value: 0.0
    }

    default property alias children: content.data

    property var menu: componentContextMenu
    property Item _menuItem: null
    property bool menuOpen: _menuItem != null && _menuItem._open

    property var urlmenu: componentUrlMenu
    property Item _urlmenuItem: null
    property bool urlmenuOpen: _urlmenuItem != null && _urlmenuItem._open

    property Item fakeClipboardObject: null

    property var messageColor: down ? highlightColor : contactColor
    property var contactColor: Theme.rgba(getContactColor(model.author, isGroup), Theme.highlightBackgroundOpacity)
    property var highlightColor: Theme.rgba(Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity)

    property int maxWidth: parent.width - Theme.itemSizeLarge
    onMaxWidthChanged: {
        if (textLoader.active && textLoader.item) {
            textLoader.item.relayout()
        }
    }

    DragFilter.screenMargin: Theme.paddingLarge
    onPressed: item.DragFilter.begin(mouse.x, mouse.y)
    onCanceled: item.DragFilter.end()
    onPreventStealingChanged: if (preventStealing) item.DragFilter.end()

    property string mediaTitle: model.name
    onMediaTitleChanged: {
        if ((model.watype == Mitakuuluu.Image || model.watype == Mitakuuluu.Video) && model.name && model.url.slice(model.url.length - model.name.length) !== model.name
                       && model.local.slice(model.local.length - model.name.length) !== model.name) {
            textLoader.active = true
        }
    }

    Component.onCompleted: {
        if (model.watype == Mitakuuluu.Text || model.watype == Mitakuuluu.System) {
            textLoader.active = true
        }
        if (model.watype == Mitakuuluu.Image) {
            imageLoader.active = true
        }
        else if (model.watype == Mitakuuluu.Audio) {
            playerLoader.active = true
        }
        else if (model.watype == Mitakuuluu.Video) {
            videoLoader.active = true
        }
        else if (model.watype == Mitakuuluu.Contact) {
            contactLoader.active = true
        }
        else if (model.watype == Mitakuuluu.Location) {
            locationLoader.active = true
        }
    }

    Component.onDestruction: {
        if (_menuItem != null) {
            _menuItem.hide()
            _menuItem._parentDestroyed()
        }
        if (_urlmenuItem != null) {
            _urlmenuItem.hide()
            _urlmenuItem._parentDestroyed()
        }

        // This item must not be removed if reused in an ItemPool
        __silica_item_removed = false
    }

    onClicked: {
        if (page.isGroup) {
            singleTimer.start()
        }
        else {
            singleAction()
        }
    }
    onPressAndHold: {
        showMenu()
    }
    onDoubleClicked: {
        if (singleTimer.running) {
            singleTimer.stop()
            doubleAction()
        }
    }

    function singleAction() {
        if (model.watype == Mitakuuluu.Text) {
            var links = textLoader.item.text.match(/<a.*?href=\"(.*?)\">(.*?)<\/a>/gi);
            if (links && links.length > 0) {
                var urlmodel = []
                links.forEach(function(link) {
                    var groups = link.match(/<a.*?href=\"(.*?)\">(.*?)<\/a>/i);
                    var urlink = [groups[2], groups[1]]
                    urlmodel[urlmodel.length] = urlink
                });
                showUrlMenu({"model" : urlmodel})
            }
        }
        else {
            openMedia()
        }
    }

    function doubleAction() {
        page.addMention(model.author)
    }

    Timer {
        id: singleTimer
        repeat: false
        interval: 300
        onTriggered: {
            singleAction()
        }
    }

    onMenuOpenChanged: {
        if (ListView.view && ('__silica_contextmenu_instance' in ListView.view)) {
            ListView.view.__silica_contextmenu_instance = menuOpen ? _menuItem : null
        }
    }

    onUrlmenuOpenChanged: {
        if (ListView.view && ('__silica_contextmenu_instance' in ListView.view)) {
            ListView.view.__silica_contextmenu_instance = urlmenuOpen ? _urlmenuItem : null
        }
    }

    function remove() {
        remorseAction(qsTr("Remove message", "Conversation message remorse text"),
                      function() {
                          conversationModel.deleteMessage(model.msgid, settings.deleteMediaFiles)
                      })
    }

    function remorseAction(text, action, timeout) {
        // null parent because a reference is held by RemorseItem until
        // it either triggers or is cancelled.
        var remorse = remorseComponent.createObject(null)
        remorse.execute(item, text, action, timeout)
    }

    function animateRemoval(delegate) {
        if (delegate === undefined) {
            delegate = item
        }
        removeComponent.createObject(delegate, { "target": delegate })
    }

    function showMenu(properties) {
        if (menu == null) {
            return null
        }
        if (_menuItem == null) {
            if (menu.createObject !== undefined) {
                _menuItem = menu.createObject(item, properties || {})
                _menuItem.closed.connect(function() { _menuItem.destroy() })
            } else {
                _menuItem = menu
            }
        }
        if (_menuItem) {
            if (menu.createObject === undefined) {
                for (var prop in properties) {
                    if (prop in _menuItem) {
                        _menuItem[prop] = properties[prop];
                    }
                }
            }
            _menuItem.show(item)

            //FIXME: why i'm not working properly? :(
            //conversationView.positionViewAtIndex(index, ListView.Contains)
        }
        return _menuItem
    }

    function hideMenu() {
        if (_menuItem != null) {
            _menuItem.hide()
        }
    }

    function showUrlMenu(properties) {
        if (urlmenu == null) {
            return null
        }
        if (_urlmenuItem == null) {
            if (urlmenu.createObject !== undefined) {
                _urlmenuItem = urlmenu.createObject(item, properties || {})
                _urlmenuItem.closed.connect(function() { _urlmenuItem.destroy() })
            } else {
                _urlmenuItem = urlmenu
            }
        }
        if (_urlmenuItem) {
            if (urlmenu.createObject === undefined) {
                for (var prop in properties) {
                    if (prop in _urlmenuItem) {
                        _urlmenuItem[prop] = properties[prop];
                    }
                }
            }
            _urlmenuItem.show(item)
        }
        return _urlmenuItem
    }

    function hideUrlMenu() {
        if (_urlmenuItem != null) {
            _urlmenuItem.hide()
        }
    }

    function downloadMedia() {
        banner.notify(qsTr("Media download started...", "Conversation message download started banner text"))
        Mitakuuluu.downloadMedia(model.msgid, page.jid)
    }

    function cancelMedia() {
        banner.notify(qsTr("Media download canceled.", "Conversation message download canceled banner text"))
        Mitakuuluu.cancelDownload(model.msgid, page.jid)
    }

    function openMedia() {
        if (model.watype == Mitakuuluu.Image || model.watype == Mitakuuluu.Video) {
            if (model.local.length > 0)
                Qt.openUrlExternally(model.local)
        }
        else if (model.watype == Mitakuuluu.Contact) {
            var vcardpath = Mitakuuluu.openVCardData(model.name, model.data)
            Qt.openUrlExternally(vcardpath)
        }
        else if (model.watype == Mitakuuluu.Location) {
            Qt.openUrlExternally("geo:" + model.latitude + "," + model.longitude)
        }
    }

    function copyToClipboard() {
        var text = ""
        if (model.watype == Mitakuuluu.Text) {
            text = model.data
        }
        else if (model.watype == Mitakuuluu.Location) {
            text = "https://maps.google.com/maps?q=loc:" + model.latitude + "," + model.longitude
        }
        else if (model.watype >= Mitakuuluu.Image && model.watype <= Mitakuuluu.Video) {
            text = model.url
        }
        if (text.length > 0) {
            fakeClipboardObject = fakeClipboardComponent.createObject(null, {"clipboard": text})
        }
    }

    Item {
        id: arrowBg
        clip: true
        y: mainBg.y + Theme.paddingMedium
        property int size: Math.sqrt(rectBg.width*rectBg.width + rectBg.height*rectBg.height)
        height: size
        width: size / 2
        Component.onCompleted: {
            if (model.author === Mitakuuluu.myJid) {
                if (settings.sentLeft)
                    anchors.right = mainBg.left
                else
                    anchors.left = mainBg.right
            }
            else {
                if (settings.sentLeft)
                    anchors.left = mainBg.right
                else
                    anchors.right = mainBg.left
            }
        }
        visible: model.watype !== Mitakuuluu.System

        Rectangle {
            id: rectBg
            color: messageColor
            width: Math.sqrt(Theme.paddingLarge*Theme.paddingLarge*2) / 2
            height: width
            rotation: 45
            y: (arrowBg.size - width) / 2
            Component.onCompleted: {
                if (model.author === Mitakuuluu.myJid) {
                    if (settings.sentLeft)
                        x = (arrowBg.size - width) / 2
                    else
                        x = 0 - (arrowBg.size - width) - 1
                }
                else {
                    if (settings.sentLeft)
                        x = 0 - (arrowBg.size - width) - 1
                    else
                        x = (arrowBg.size - width) / 2
                }
            }
        }
    }

    Rectangle {
        id: mainBg
        anchors {
            fill: content
            margins: - Theme.paddingSmall
        }
        color: messageColor
    }

    SectionHeader {
        id: sectionHeader
        anchors.top: parent.top
        text: haveSection ? model.section : ""
        visible: haveSection

    }

    Column {
        id: content
        anchors {
            top: parent.top
            topMargin: haveSection ? sectionHeader.height : 0
            margins: Theme.paddingLarge
        }
        property int mediaWidth: imageLoader.activeWidth
                                    || playerLoader.activeWidth
                                    || videoLoader.activeWidth
                                    || contactLoader.activeWidth
                                    || locationLoader.activeWidth
                                    || textLoader.activeWidth
        width: Math.max(info.minWidth, mediaWidth)
        Component.onCompleted: {
            if (model.watype == Mitakuuluu.System) {
                anchors.horizontalCenter = parent.horizontalCenter
            }
            else if (model.author === Mitakuuluu.myJid) {
                if (settings.sentLeft)
                    anchors.left = parent.left
                else
                    anchors.right = parent.right
            }
            else {
                if (settings.sentLeft)
                    anchors.right = parent.right
                else
                    anchors.left = parent.left
            }
        }
        Loader {
            id: imageLoader

            property int activeWidth: visible ? width : 0
            property int displayWidth: rotated ? model.height : model.width
            property int displayHeight: rotated ? model.width : model.height
            width: Math.min(displayWidth, maxWidth)
            height: displayHeight / (displayWidth / width)

            property string ext: model.local.toLowerCase().split(".").pop()
            property bool rotated: ext === "jpg" || ext === "jpeg" ? (Mitakuuluu.getExifRotation(model.local) == 90) : false

            active: false
            visible: active
            asynchronous: true
            sourceComponent: imageComponent
        }
        Loader {
            id: playerLoader
            property int activeWidth: visible ? width : 0
            active: false
            asynchronous: true
            sourceComponent: playerComponent
        }
        Loader {
            id: videoLoader

            property int activeWidth: visible ? width : 0
            width: Math.min(model.width, maxWidth)
            height: model.height / (model.width / width)

            active: false
            visible: active
            asynchronous: true
            sourceComponent: videoComponent
        }
        Loader {
            id: contactLoader
            property int activeWidth: visible ? width : 0
            active: false
            visible: active
            asynchronous: true
            sourceComponent: contactComponent
        }
        Loader {
            id: locationLoader

            property int activeWidth: visible ? width : 0
            width: maxWidth
            height: Theme.itemSizeExtraLarge

            active: false
            visible: active
            asynchronous: true
            sourceComponent: locationComponent
        }
        Loader {
            id: textLoader
            property int activeWidth: visible ? width : 0
            active: false
            visible: active
            asynchronous: true
            sourceComponent: textComponent
        }
        Item {
            id: info
            width: parent.width
            height: participantInfo.height || statusinfo.height
            property int minWidth: participantInfo.activeWidth + statusinfo.width + Theme.paddingMedium

            Label {
                id: participantInfo
                anchors.left: parent.left
                property int activeWidth: visible ? paintedWidth : 0
                property int maxWidth: item.maxWidth - statusinfo.width - Theme.paddingLarge
                text: getNicknameByJid(model.author)
                color: down ? Theme.secondaryHighlightColor : Theme.secondaryColor
                elide: Text.ElideRight
                truncationMode: TruncationMode.Fade
                font.pixelSize: settings.fontSize - 4
                visible: isGroup

                onWidthChanged: {
                    if (width > participantInfo.maxWidth) {
                        width = participantInfo.maxWidth
                    }
                }
            }

            Row {
                id: statusinfo
                height: time.paintedHeight
                width: time.width + deliveryStatus.width
                anchors.right: parent.right

                Label {
                    id: time
                    text: timestampToTime(model.timestamp)
                    font.pixelSize: settings.fontSize - 4
                    color: down ? Theme.secondaryHighlightColor : Theme.secondaryColor
                    width: visible ? paintedWidth : 0
                    visible: settings.showTimestamp
                }

                Loader {
                    id: deliveryStatus
                    anchors.verticalCenter: parent.verticalCenter
                    active: model.author === Mitakuuluu.myJid
                    asynchronous: true
                    sourceComponent: deliveryComponent
                }
            }
        }
    }

    Component {
        id: deliveryComponent
        Item {
            id: deliveryItem
            width: (model.status == Mitakuuluu.ReceivedByTarget || model.status == Mitakuuluu.Played)
                   ? (msgSentTick.width * 1.5)
                   : msgSentTick.width
            height: msgSentTick.height

            GlassItem {
                id: msgSentTick
                width: 16
                height: 16
                anchors.right: parent.right
                falloffRadius: 0.3
                radius: 0.4
                color: (model.status <= Mitakuuluu.SentByClient) ? "#80ff0000" : "#80ffff00"
            }

            GlassItem {
                id: msgDeliveredTick
                width: 16
                height: 16
                anchors.left: parent.left
                falloffRadius: 0.3
                radius: 0.4
                color: "#8000ff00"
                visible: model.status == Mitakuuluu.ReceivedByTarget || model.status == Mitakuuluu.Played
            }
        }
    }

    Component {
        id: textComponent

        Label {
            id: messageLabel
            text: Utilities.linkify(Utilities.emojify(model.watype == Mitakuuluu.Image || model.watype == Mitakuuluu.Video ? model.name : model.data, emojiPath), Theme.highlightColor)
            textFormat: Text.RichText
            wrapMode: Text.NoWrap
            font.pixelSize: settings.fontSize
            color: down ? Theme.highlightColor : Theme.primaryColor
            property int fullWidth: 0
            Component.onCompleted: {
                fullWidth = paintedWidth
                relayout()
            }
            function relayout() {
                wrapMode = Text.NoWrap
                if (fullWidth > maxWidth) {
                    width = maxWidth
                }
                else {
                    width = fullWidth + 1
                }
                wrapMode = Text.WrapAtWordBoundaryOrAnywhere
            }
        }
    }

    Component {
        id: imageComponent
        Item {
            id: imageItem
            Loader {
                id: picprev
                anchors.fill: parent
                asynchronous: true
                sourceComponent: model.local ? localMediaPreview : thumbMediaPreview
            }
            BusyIndicator {
                anchors.centerIn: parent
                size: BusyIndicatorSize.Medium
                running: visible
                visible: picprev.status == Image.Loading
            }

            ProgressCircle {
                width: Theme.itemSizeLarge
                height: Theme.itemSizeLarge
                anchors.centerIn: parent
                visible: model.mediaprogress > 0 && model.mediaprogress < 100
                value: model.mediaprogress / 100
            }

            IconButton {
                anchors.centerIn: parent
                icon.source: (model.mediaprogress > 0 && model.mediaprogress < 100) ? "image://theme/icon-l-clear" : "image://theme/icon-l-down"
                icon.width: Theme.itemSizeMedium
                icon.height: Theme.itemSizeMedium
                visible: model.local.length == 0
                onClicked: {
                    if (model.mediaprogress > 0 && model.mediaprogress < 100)
                        cancelMedia()
                    else
                        downloadMedia()
                }
            }
        }
    }

    Component {
        id: videoComponent
        Item {
            id: videoItem
            property bool ready: model.mediaprogress == 0 || model.mediaprogress == 100
            Loader {
                id: vidprev
                anchors.fill: parent
                asynchronous: true
                sourceComponent: model.local ? localVideoPreview : thumbMediaPreview
            }

            Image {
                source: "image://theme/icon-m-play"
                visible: model.local.length > 0 && ready
                anchors.centerIn: parent
                asynchronous: true
                cache: true
            }

            BusyIndicator {
                anchors.centerIn: parent
                size: BusyIndicatorSize.Medium
                running: visible
                visible: vidprev.status == Image.Loading
            }

            ProgressCircle {
                width: Theme.itemSizeLarge
                height: Theme.itemSizeLarge
                anchors.centerIn: parent
                visible: model.mediaprogress > 0 && model.mediaprogress < 100
                value: model.mediaprogress / 100
            }

            IconButton {
                anchors.centerIn: parent
                //icon.source: (model.mediaprogress > 0 && model.mediaprogress < 100) ? "image://theme/icon-l-clear" : "image://theme/icon-l-down"
                icon.source: ready ? "image://theme/icon-l-down" : "image://theme/icon-l-clear"

                visible: model.local.length == 0 || !ready
                onClicked: {
                    if (model.mediaprogress > 0 && model.mediaprogress < 100)
                        cancelMedia()
                    else
                        downloadMedia()
                }
            }
        }
    }

    Component {
        id: localVideoPreview
        Thumbnail {
            fillMode: Image.PreserveAspectFit
            source: model.local
            sourceSize.width: width
            sourceSize.height: height
            clip: true
            smooth: true
            mimeType: model.mime
        }
    }

    Component {
        id: localMediaPreview
        Image {
            fillMode: Image.PreserveAspectFit
            source: "image://nemoThumbnail/" + model.local
            smooth: true
            cache: false
            clip: false
            sourceSize.width: imageRotated ? height : width
            sourceSize.height: imageRotated ? width : height
            property bool imageRotated: Mitakuuluu.getExifRotation(model.local) == 90
        }
    }

    Component {
        id: thumbMediaPreview
        Image {
            fillMode: Image.PreserveAspectFit
            source: "data:" + (model.watype == Mitakuuluu.Video ? "image/jpeg" : model.mime) + ";base64," + model.data
            clip: true
            smooth: true
        }
    }

    Component {
        id: contactComponent
        Row {
            id: contactItem
            height: Theme.itemSizeMedium
            spacing: Theme.paddingLarge

            Image {
                id: contactImage
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.itemSizeMedium
                height: Theme.itemSizeMedium
                source: "image://theme/icon-m-service-generic"
                cache: true
            }

            Label {
                id: contactName
                anchors.verticalCenter: parent.verticalCenter
                width: paintedWidth + Theme.paddingLarge
                wrapMode: Text.NoWrap
                text: model.name
                font.pixelSize: settings.fontSize
            }
        }
    }

    Component {
        id: playerComponent
        Row {
            id: playerItem
            height: visible ? Theme.itemSizeMedium : 0
            anchors {
                left: parent.left
                leftMargin: Theme.paddingMedium
            }
            property string source: model.local

            Audio {
                id: player
                onDurationChanged: {
                    playerSeek.maximumValue = duration
                }
                onPositionChanged: {
                    playerSeek.value = position
                }
                onStatusChanged: {
                    if (status == Audio.EndOfMedia)
                        playerSeek.value = player.duration
                }
            }

            IconButton {
                id: playButton
                anchors.verticalCenter: parent.verticalCenter
                icon.source: playerItem.source.length > 0 ? (player.playbackState == Audio.PlayingState ? "image://theme/icon-m-pause"
                                                                                                    : "image://theme/icon-m-play")
                                                      : ((model.mediaprogress > 0 && model.mediaprogress < 100) ? "image://theme/icon-l-clear"
                                                                                                                : "image://theme/icon-l-down")
                icon.height: 64
                icon.width: 64
                onClicked: {
                    if (source.length > 0)
                    {
                        if (player.source !== source)
                            player.source = source
                        if (player.playbackState == Audio.PlayingState)
                            player.pause()
                        else
                            player.play()
                    }
                    else if (model.author !== Mitakuuluu.myJid) {
                        if (model.mediaprogress > 0 && model.mediaprogress < 100)
                            cancelMedia()
                        else
                            downloadMedia()
                    }
                }
            }

            Slider {
                id: playerSeek
                property bool ready: model.mediaprogress == 0 || model.mediaprogress == 100
                anchors.verticalCenter: parent.verticalCenter
                width: maxWidth - playButton.width
                minimumValue: 0
                maximumValue: 100
                stepSize: 1
                value: ready ? player.position : model.mediaprogress
                valueText: ready ? Format.formatDuration(value / 1000, Format.DurationShort) : (model.mediaprogress + "%")
                label: ready ? "" : qsTr("Uploading...", "Uploading voice record text")
                enabled: ready
                onReleased: player.seek(value)
            }
        }
    }

    Component {
        id: locationComponent
        Image {
            id: locprev
            anchors.verticalCenter: parent.verticalCenter
            source: locationPreview(width, height, model.latitude, model.longitude, 14, settings.mapSource)
            asynchronous: true
            cache: true
            smooth: true

            Image {
                source: "../images/location-marker.png"
                anchors {
                    centerIn: parent
                }
                visible: locprev.status == Image.Ready
            }

            BusyIndicator {
                anchors.centerIn: parent
                size: BusyIndicatorSize.Medium
                running: visible
                visible: locprev.status == Image.Loading
            }
        }
    }

    Component {
        id: componentUrlMenu
        ContextMenu {
            id: urlMenu
            property alias model: urlMenuRepeater.model
            Repeater {
                id: urlMenuRepeater
                property alias childs: urlMenuRepeater.model
                width: parent.width
                delegate: MenuItem {
                    parent: urlMenuRepeater
                    text: modelData[0]
                    elide: Text.ElideRight
                    truncationMode: TruncationMode.Fade
                    onClicked: {
                        Qt.openUrlExternally(modelData[1])
                    }
                }
            }
        }
    }

    Component {
        id: componentContextMenu
        ContextMenu {
            MenuItem {
                text: qsTr("Resend message", "Conversation message context menu item")
                visible: model.author === Mitakuuluu.myJid && model.status < Mitakuuluu.ReceivedByServer
                enabled: Mitakuuluu.connectionStatus === Mitakuuluu.LoggedIn
                onClicked: {
                    conversationModel.resendMessage(page.jid, model.msgid)
                }
            }

            MenuItem {
                text: qsTr("Copy", "Conversation message context menu item")
                visible: model.watype == Mitakuuluu.Text || model.watype == Mitakuuluu.Location
                onClicked: {
                    //conversationModel.copyToClipboard(model.msgid)
                    copyToClipboard()
                }
            }

            MenuItem {
                text: qsTr("Forward", "Conversation message context menu item")
                enabled: Mitakuuluu.connectionStatus === Mitakuuluu.LoggedIn
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("Forward.qml"), {"jid": page.jid, "messageModel": model, "conversationModel": page.conversationModel})
                }
            }

            MenuItem {
                visible: model.local.indexOf(".cache") > 0
                text: qsTr("Save to Gallery", "Conversation message context menu item")
                onClicked: {
                    var fname = Mitakuuluu.saveMedia(model.local, model.watype)
                    banner.notify(qsTr("Media saved as %1", "Banner text message").arg(fname))
                }
            }

            MenuItem {
                id: removeMsg
                text: qsTr("Delete", "Conversation message context menu item")
                onClicked: {
                    if (model.mediaprogress > 0 && model.mediaprogress < 100)
                        Mitakuuluu.cancelDownload(model.msgid, page.jid)
                    remove()
                }
            }
        }
    }

    Component {
        id: fakeClipboardComponent
        TextEdit {
            id: fakeClipboard
            visible: false
            property string clipboard
            Component.onCompleted: {
                text = clipboard
                selectAll()
                copy()
                banner.notify(qsTr("Message copied to clipboard", "Banner item text"))
                fakeClipboardObject.destroy()
            }
        }
    }

    Component {
        id: remorseComponent
        RemorseItem {}
    }

    Component {
        id: removeComponent
        RemoveAnimation {
            running: true
        }
    }
}
