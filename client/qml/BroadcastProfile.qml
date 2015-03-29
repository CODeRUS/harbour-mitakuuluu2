import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.thumbnailer 1.0
import harbour.mitakuuluu2.client 1.0
import "Utilities.js" as Utilities

Page {
    id: page
    objectName: "broadcastProfile"
    allowedOrientations: globalOrientation

    property string jid: ""
    property string subject: ""
    onJidChanged: {
        var model = ContactsBaseModel.getModel(jid)
        jid = model.jid

        //Mitakuuluu.getBroadcastList(jid)
    }
    property Page conversationPage
    property var initialParticipants: []
    onInitialParticipantsChanged: {
        for (var i = 0; i < initialParticipants.length; i++) {
            var model = ContactsBaseModel.getModel(initialParticipants[i])
            participantsModel.append({"jid": model.jid,
                                      "name": getNicknameByJid(model.jid),
                                      "avatar": model.avatar,
                                      "owner": model.owner})
        }
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
                text: qsTr("Add contacts", "Broadcast profile page menu item")
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
                text: qsTr("Save chat history", "Broadcast profile page menu item")
                onClicked: {
                    Mitakuuluu.saveHistory(page.jid, page.subject)
                    banner.notify(qsTr("History saved to Documents", "Banner notification text"))
                }
            }
        }

        PageHeader {
            id: title
            title: qsTr("Broadcast list", "Broadcast profile page title")
            //second: participantsModel.count + " participants"
        }

        TextField {
            id: subjectArea
            anchors.top: title.bottom
            anchors.topMargin: - Theme.paddingLarge
            anchors.left: parent.left
            anchors.right: parent.right
            text: page.subject
            errorHighlight: text.length == 0 || text.length > 25
            placeholderText: qsTr("Enter broadcast list name")
            label: qsTr("Broadcast list name")
            EnterKey.enabled: !errorHighlight
            EnterKey.highlighted: EnterKey.enabled
            EnterKey.iconSource: "image://theme/icon-m-enter-next"
            EnterKey.onClicked: {
                hsubject = text.trim()
                ContactsBaseModel.renameBroadcast(page.jid, hsubject)
                conversationPage.name = Utilities.emojify(hsubject, emojiPath)
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

        SectionHeader {
            id: mediaHeader
            text: qsTr("Media")
            visible: mediaListView.count > 0
            anchors {
                top: subjectArea.bottom
                topMargin: Theme.paddinSmall
                left: parent.left
                right: parent.right
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
            anchors.top: mediaListView.visible ? mediaListView.bottom: subjectArea.bottom
            anchors.topMargin: Theme.paddingLarge
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            model: participantsModel
            delegate: listDelegate
            pressDelay: 0

            function contactAdded(pjid) {
                if (pjid !== Mitakuuluu.myJid) {
                    if (listView.count < 51)
                        Mitakuuluu.addParticipant(page.jid, pjid)
                    else
                        banner.notify(qsTr("Max broadcast participants count reached", "Broadcast profile maximum participants banner"))
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
            text: qsTr("Fetching participants...", "Broadcast profile loading text")
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
                    title: qsTr("Broadcast media")
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
