import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.thumbnailer 1.0
import harbour.mitakuuluu2.client 1.0
import "Utilities.js" as Utilities

Page {
    id: page
    objectName: "groupProfile"
    allowedOrientations: globalOrientation

    property string jid: ""
    onJidChanged: {
        var model = ContactsBaseModel.getModel(jid)
        subject = model.nickname
        jid = model.jid
        participantsModel.clear()

        setGroupInfo(model)

        Mitakuuluu.getGroupInfo(jid)
        //Mitakuuluu.getParticipants(jid)
    }
    property Page conversationPage

    property string subject: ""

    property string ownerJid: ""
    property string owner: ""
    property int creation: 0
    property string sowner: ""
    property int screation: 0
    property string avatar: ""

    function timestampToFullDate(stamp) {
        var d = new Date(stamp*1000)
        return Qt.formatDateTime(d, "dd MMM yyyy")
    }

    function setGroupInfo(value) {
        page.subject = value.nickname
        subjectArea.text = page.subject
        page.ownerJid = value.owner
        page.owner = getNicknameByJid(value.owner)
        page.creation = value.timestamp
        page.sowner = getNicknameByJid(value.subowner)
        page.screation = value.subtimestamp
        if (typeof(value.avatar) != "undefined" && value.avatar != "undefined" && value.avatar.length > 0)
            page.avatar = value.avatar
        else
            page.avatar = ""
    }

    function getNicknameByJid(jid) {
        if (!jid || jid == undefined || typeof(jid) === "undefined")
            return ""
        if (jid == Mitakuuluu.myJid)
            return qsTr("You", "Display You instead of your own nickname")
        var model = ContactsBaseModel.getModel(jid)
        if (model && model.nickname)
            return model.nickname
        else
            return jid.split("@")[0]
    }

    onStatusChanged: {
        if (status == PageStatus.Inactive) {

        }
        else if (status == PageStatus.Active) {
            console.log("requesting media for jid: " + jid)
            Mitakuuluu.requestContactMedia(jid)
        }
    }

    Connections {
        target: Mitakuuluu
        onGroupParticipants: {
            if (gjid == page.jid) {
                for (var i = 0; i < pjids.length; i++) {
                    console.log("group " + gjid + " user " + pjids[i])
                    var model = ContactsBaseModel.getModel(pjids[i])
                    participantsModel.append({"jid": model.jid,
                                              "name": getNicknameByJid(model.jid),
                                              "avatar": model.avatar,
                                              "owner": model.owner})
                }
            }
        }
        /*onGroupInfo: {
            console.log("got group info: " + group.jid)
            if (group.jid == page.jid) {
                setGroupInfo(group)
            }
        }*/
        onContactChanged: {
            if (data.jid == page.jid) {
                setGroupInfo(data)
            }
        }
        /*onContactsChanged: {
            console.log("contacts changed")
            if (page.jid.length > 0) {
                var model = roster.getContactModel(page.jid)
                setGroupInfo(model)
            }
        }*/
        onNewGroupSubject: {
            if (data.jid == page.jid) {
                page.subject = data.message
                subjectArea.text = page.subject
                page.sowner = getNicknameByJid(data.subowner)
                page.screation = data.subtimestamp
            }
        }
        onParticipantAdded: {
            if (gjid == page.jid) {
                var model = ContactsBaseModel.getModel(pjid)
                var avatar = (typeof(model.avatar) != "undefined" && model.avatar != "undefined" && model.avatar.length > 0) ? model.avatar : ""
                participantsModel.append({"jid": model.jid,
                                          "name": getNicknameByJid(model.jid),
                                          "avatar": avatar})
            }
        }
        onParticipantRemoved: {
            if (gjid == page.jid) {
                for (var i = 0; i < participantsModel.count; i ++) {
                    var model = participantsModel.get(i)
                    if (pjid == model.jid) {
                        participantsModel.remove(i)
                        break;
                    }
                }
            }
        }
        onPictureUpdated: {
            if (pjid == page.jid && path.length > 0) {
                page.avatar = ""
                page.avatar = path
            }
        }
        onMediaListReceived: {
            if (pjid === page.jid) {
                mediaListModel.clear()
                for (var i = 0; i < mediaList.length; i++) {
                    mediaListModel.append(mediaList[i])
                }
            }
        }
    }

    SilicaFlickable {
        id: flickable
        anchors.fill: page
        pressDelay: 0

        PullDownMenu {
            MenuItem {
                text: qsTr("Add contacts", "Group profile page menu item")
                enabled: listView.count > 0
                visible: page.ownerJid === Mitakuuluu.myJid
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("SelectContact.qml"), {"jid": page.jid, "noGroups": true, "multiple": true, "selected": participantsModel})
                    pageStack.currentPage.done.connect(listView.selectFinished)
                    pageStack.currentPage.added.connect(listView.contactAdded)
                    pageStack.currentPage.removed.connect(listView.contactRemoved)
                }
            }

            MenuItem {
                text: qsTr("Change background")
                onClicked: {
                    pageStack.push(backgroundPickerPage.createObject(root))
                }
            }

            MenuItem {
                text: qsTr("Clear background")
                onClicked: {
                    wallpaperConfig.value = "unset"
                    Theme.clearBackgroundImage()
                }
            }

            MenuItem {
                text: qsTr("Clear chat history", "User profile page menu item")
                onClicked: {
                    var rjid = page.jid
                    remorse.execute(text, function() { ContactsBaseModel.clearChat(rjid) })
                }
            }

            MenuItem {
                text: qsTr("Save chat history", "Group profile page menu item")
                onClicked: {
                    Mitakuuluu.saveHistory(page.jid, page.subject)
                    banner.notify(qsTr("History saved to Documents", "Banner notification text"))
                }
            }
        }

        PageHeader {
            id: title
            title: qsTr("Group profile", "Group profile page title")
            //second: participantsModel.count + " participants"
        }

        Label {
            id: subjectLabel
            anchors.left: parent.left
            anchors.leftMargin: Theme.paddingMedium
            wrapMode: Text.NoWrap
            anchors.top: subjectArea.top
            anchors.topMargin: Theme.paddingSmall
            text: qsTr("Subject: ", "Group profile subject label")
        }

        TextField {
            id: subjectArea
            anchors.top: title.bottom
            anchors.topMargin: - Theme.paddingLarge
            anchors.left: subjectLabel.right
            anchors.right: parent.right
            text: page.subject
            errorHighlight: text.length == 0 || text.length > 25
            EnterKey.enabled: !errorHighlight
            EnterKey.highlighted: EnterKey.enabled
            EnterKey.iconSource: "image://theme/icon-m-enter-next"
            EnterKey.onClicked: {
                Mitakuuluu.setGroupSubject(page.jid, text.trim())
                hsubject = text.trim()
                subjectArea.focus = false
                page.forceActiveFocus()
            }
            onActiveFocusChanged: {
                if (activeFocus) {
                    hsubject = page.subject
                }
                else {
                    text = hsubject
                }
            }
            property string hsubject: ""
        }

        AvatarHolder {
            id: ava
            width: Theme.iconSizeLarge
            height: Theme.iconSizeLarge
            anchors.top: subjectArea.bottom
            anchors.topMargin: - Theme.paddingLarge
            anchors.left: parent.left
            anchors.leftMargin: Theme.paddingMedium
            source: page.avatar
            emptySource: "../images/avatar-empty-group.png"
        }

        BusyIndicator {
            anchors.centerIn: ava
            running: visible
            visible: false
            size: BusyIndicatorSize.Large
        }

        MouseArea {
            anchors.fill: ava
            onClicked: {
                pageStack.push(Qt.resolvedUrl("AvatarHistory.qml"), {"jid": page.jid, "avatar": page.avatar, "owner": true})
            }
        }

        Label {
            id: labelOwner
            text: qsTr("Owner: %1", "Group profile owner label").arg(Utilities.emojify(page.owner, emojiPath))
            anchors.top: subjectArea.bottom
            anchors.topMargin: - Theme.paddingLarge
            anchors.right: page.isPortrait ? parent.right : listView.left
            anchors.rightMargin: Theme.paddingMedium
            anchors.left: ava.right
            anchors.leftMargin: Theme.paddingMedium
            wrapMode: Text.NoWrap
            horizontalAlignment: page.isPortrait ? Text.AlignRight : Text.AlignLeft
            font.pixelSize: Theme.fontSizeExtraSmall
        }

        Label {
            id: labelCreation
            text: qsTr("Creation: %1", "Group profile creation label").arg(timestampToFullDate(page.creation))
            anchors.top: labelOwner.bottom
            anchors.topMargin: Theme.paddingSmall
            anchors.right: page.isPortrait ? parent.right : listView.left
            anchors.rightMargin: Theme.paddingMedium
            anchors.left: ava.right
            anchors.leftMargin: Theme.paddingMedium
            wrapMode: Text.NoWrap
            horizontalAlignment: page.isPortrait ? Text.AlignRight : Text.AlignLeft
            font.pixelSize: Theme.fontSizeExtraSmall
        }

        Label {
            id: subjectOwner
            text: qsTr("Subject by: %1", "Group profile subject owner label").arg(Utilities.emojify(page.sowner, emojiPath))
            anchors.top: labelCreation.bottom
            anchors.topMargin: Theme.paddingSmall
            anchors.right: page.isPortrait ? parent.right : listView.left
            anchors.rightMargin: Theme.paddingMedium
            anchors.left: ava.right
            anchors.leftMargin: Theme.paddingMedium
            wrapMode: Text.NoWrap
            horizontalAlignment: page.isPortrait ? Text.AlignRight : Text.AlignLeft
            font.pixelSize: Theme.fontSizeExtraSmall
        }

        Label {
            id: subjectCreation
            text: qsTr("Subject set: %1", "Group profile subject timestamp label").arg(timestampToFullDate(page.screation))
            anchors.top: subjectOwner.bottom
            anchors.topMargin: Theme.paddingSmall
            anchors.right: page.isPortrait ? parent.right : listView.left
            anchors.rightMargin: Theme.paddingMedium
            anchors.left: ava.right
            anchors.leftMargin: Theme.paddingMedium
            wrapMode: Text.NoWrap
            horizontalAlignment: page.isPortrait ? Text.AlignRight : Text.AlignLeft
            font.pixelSize: Theme.fontSizeExtraSmall
        }

        Rectangle {
            anchors {
                left: parent.left
                right: page.isPortrait ? parent.right : listView.left
                top: mediaHeader.top
                topMargin: Theme.paddingMedium
                bottom: mediaListView.bottom
                bottomMargin: - Theme.paddingMedium
            }
            visible: mediaListView.count > 0
            color: (mAreaHeader.pressed && mAreaHeader.containsMouse) ? Theme.rgba(Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity) : "transparent"
        }

        SectionHeader {
            id: mediaHeader
            text: qsTr("Media")
            visible: mediaListView.count > 0
            anchors {
                top: subjectCreation.bottom
                topMargin: Theme.paddinSmall
                left: parent.left
                right: page.isPortrait ? parent.right : listView.left
                rightMargin: Theme.paddingLarge
            }
            MouseArea {
                id: mAreaHeader
                anchors.fill: parent
                onClicked: {
                    pageStack.push(mediaPageComponent)
                }
            }
        }

        SilicaListView {
            id: mediaListView
            anchors {
                left: parent.left
                leftMargin: Theme.paddingLarge
                right: page.isPortrait ? parent.right : listView.left
                rightMargin: Theme.paddingLarge
                top: mediaHeader.bottom
                topMargin: Theme.paddingSmall
            }
            height: Theme.itemSizeMedium
            orientation: ListView.Horizontal
            model: mediaListModel
            delegate: mediaListDelegate
            visible: count > 0
            clip: true
            spacing: Theme.paddingMedium

            HorizontalScrollDecorator {}
        }

        SilicaListView {
            id: listView
            clip: true
            anchors.top: page.isPortrait ? (mediaListView.visible ? mediaListView.bottom: subjectCreation.bottom) : subjectArea.bottom
            anchors.topMargin: page.isPortrait ? Theme.paddingLarge: ( - Theme.paddingLarge)
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            width: page.isPortrait ? page.width : (page.width / 2)
            model: participantsModel
            delegate: listDelegate
            pressDelay: 0

            function contactAdded(pjid) {
                if (pjid !== Mitakuuluu.myJid) {
                    if (listView.count < 51)
                        Mitakuuluu.addParticipant(page.jid, pjid)
                    else
                        banner.notify(qsTr("Max group participants count reached", "Group profile maximum participants banner"))
                }
            }

            function contactRemoved(pjid) {
                if (pjid !== Mitakuuluu.myJid)
                    Mitakuuluu.removeParticipant(page.jid, pjid)
            }

            function selectFinished() {
                pageStack.currentPage.done.disconnect(listView.selectFinished)
                pageStack.currentPage.added.disconnect(listView.contactAdded)
                pageStack.currentPage.removed.disconnect(listView.contactRemoved)
            }

            VerticalScrollDecorator {}
        }

        BusyIndicator {
            id: busy
            anchors.centerIn: listView
            visible: listView.count == 0
            running: visible
            size: BusyIndicatorSize.Large
        }

        Label {
            anchors.top: busy.bottom
            anchors.left: parent.left
            anchors.leftMargin: Theme.paddingMedium
            anchors.right: parent.right
            anchors.rightMargin: Theme.paddingMedium
            text: qsTr("Fetching participants...", "Group profile loading text")
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.secondaryHighlightColor
            horizontalAlignment: Text.AlignHCenter
            visible: listView.count == 0
        }
    }

    RemorsePopup {
        id: remorse
    }

    ListModel {
        id: participantsModel
    }

    ListModel {
        id: mediaListModel
    }

    Component {
        id: listDelegate
        BackgroundItem {
            id: item
            width: parent.width
            height: Theme.itemSizeMedium
            highlightedColor: Theme.rgba((model.jid == page.ownerJid && !down) ? "lime" : Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity)
            highlighted: model.jid == page.ownerJid || down

            AvatarHolder {
                id: contactava
                height: Theme.iconSizeLarge
                width: Theme.iconSizeLarge
                source: settings.usePhonebookAvatars || (model.jid.indexOf("-") > 0)
                        ? (model.avatar == "undefined" ? "" : (model.avatar))
                        : (model.owner == "undefined" ? "" : (model.owner.length > 0 ? model.owner : model.avatar))
                emptySource: "../images/avatar-empty.png"
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingLarge
                anchors.verticalCenter: parent.verticalCenter
            }

            Label {
                id: contact
                anchors.left: contactava.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: remove.visible ? remove.left : parent.right
                anchors.rightMargin: Theme.paddingSmall
                font.pixelSize: Theme.fontSizeMedium
                text: Utilities.emojify(model.name, emojiPath)
                color: item.highlighted ? Theme.highlightColor : Theme.primaryColor
                truncationMode: TruncationMode.Fade
            }

            IconButton {
                id: remove
                width: Theme.iconSizeLarge
                height: Theme.iconSizeLarge
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingSmall
                anchors.verticalCenter: parent.verticalCenter
                visible: page.ownerJid == Mitakuuluu.myJid && model.jid != Mitakuuluu.myJid
                icon.source: "image://theme/icon-m-clear"
                highlighted: pressed
                onClicked: {
                    Mitakuuluu.removeParticipant(page.jid, model.jid)
                    participantsModel.remove(index)
                }
            }

            onPressAndHold: {
                if (pageStack.previousPage(page).objectName === "conversationPage") {
                    pageStack.navigateBack()
                    conversationPage.addMention(model.jid)
                }
            }

            onClicked: {
                pageStack.push(Qt.resolvedUrl("UserProfile.qml"), {"jid": model.jid})
            }
        }
    }

    Component {
        id: mediaListDelegate
        MouseArea {
            id: item
            width: GridView.view ? (GridView.view.cellWidth - 1) : Theme.itemSizeMedium
            height: GridView.view ? (GridView.view.cellHeight - 1) : Theme.itemSizeMedium

            Thumbnail {
                id: image
                source: model.path
                height: parent.height
                width: parent.width
                sourceSize.height: parent.height
                sourceSize.width: parent.width
                anchors.centerIn: parent
                clip: true
                smooth: true
                mimeType: model.mime

                states: [
                    State {
                        name: 'loaded'; when: image.status == Thumbnail.Ready
                        PropertyChanges { target: image; opacity: 1; }
                    },
                    State {
                        name: 'loading'; when: image.status != Thumbnail.Ready
                        PropertyChanges { target: image; opacity: 0; }
                    }
                ]

                Behavior on opacity {
                    FadeAnimation {}
                }
            }
            Rectangle {
                anchors.fill: parent
                color: Theme.rgba(Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity)
                visible: pressed && containsMouse
            }
            Image {
                source: "image://theme/icon-m-play"
                visible: typeof(model.mime) != "undefined" && model.mime.indexOf("video") == 0
                anchors.centerIn: parent
                asynchronous: true
                cache: true
            }
            onClicked: {
                Qt.openUrlExternally(model.path)
            }
        }
    }

    DConfValue {
        id: wallpaperConfig
        key: "/apps/harbour-mitakuuluu2/wallpaper/" + page.jid
        defaultValue: "unset"
    }

    Component {
        id: backgroundPickerPage

        AvatarPickerCrop {
            id: avatarPicker
            objectName: "backgroundPicker"
            aspectRatio: 0.562

            onAvatarSourceChanged: {
                console.log("background from: " + avatarSource)
                var wallpaper = Mitakuuluu.saveWallpaper(avatarSource, page.jid)
                wallpaperConfig.value = wallpaper
                Theme.setBackgroundImage(Qt.resolvedUrl(wallpaper), Screen.width, Screen.height)

                avatarPicker.destroy()
            }
        }
    }

    Component {
        id: avatarPickerPage

        AvatarPickerCrop {
            id: avatarPicker
            objectName: "avatarPicker"

            onAvatarSourceChanged: {
                page.avatar = ""
                page.avatar = Mitakuuluu.saveAvatarForJid(page.jid, avatarSource)
                Mitakuuluu.setPicture(page.jid, page.avatar)
                avatarPicker.destroy()
            }
        }
    }

    Component {
        id: mediaPageComponent
        Page {
            id: mediaPage
            objectName: "allMediaPage"
            allowedOrientations: globalOrientation

            SilicaGridView {
                id: mediaGrid
                anchors.fill: parent
                header: PageHeader {
                    title: qsTr("Group media")
                }
                cellWidth: mediaPage.isPortrait ? width / 3 : width / 5
                cellHeight: cellWidth
                model: mediaListModel
                delegate: mediaListDelegate

                VerticalScrollDecorator {}
            }
        }
    }
}
