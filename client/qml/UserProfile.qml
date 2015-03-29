import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.thumbnailer 1.0
import harbour.mitakuuluu2.client 1.0
import "Utilities.js" as Utilities

Page {
    id: page
    objectName: "profilePage"
    allowedOrientations: globalOrientation

    property string jid: ""
    onJidChanged: {
        phone = jid.split("@")[0]
        var model = ContactsBaseModel.getModel(jid)
        pushname = model.nickname || model.name
        presence = model.message
        timestamp = model.subtimestamp
        picture = settings.usePhonebookAvatars || (model.jid.indexOf("-") > 0)
                ? (model.avatar == "undefined" ? "" : (model.avatar))
                : (model.owner == "undefined" ? "" : (model.owner.length > 0 ? model.owner : model.avatar))
        blocked = model.blocked
    }
    property string pushname: ""
    property string presence: ""
    property int timestamp: 0
    property string phone: ""
    property string picture: ""
    property bool blocked: false

    property var conversationModel: null

    Connections {
        target: ContactsBaseModel
        onNicknameChanged: {
            if (pjid == page.jid) {
                pushname = nickname
            }
        }
        onStatusChanged: {
            if (pjid == page.jid) {
                presence = message
                timestamp = ptimestamp
            }
        }
    }

    Connections {
        target: Mitakuuluu
        onPictureUpdated: {
            if (pjid == page.jid && (!settings.usePhonebookAvatars || picture.length == 0)) {
                picture = ""
                picture = path
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

    onStatusChanged: {
        if (status == PageStatus.Inactive) {

        }
        else if (status == PageStatus.Active) {
            Mitakuuluu.requestContactMedia(jid)
        }
    }

    function timestampToFullDate(stamp) {
        var d = new Date(stamp*1000)
        return Qt.formatDateTime(d, "dd MMM yyyy")
    }

    DConfValue {
        id: wallpaperConfig
        key: "/apps/harbour-mitakuuluu2/wallpaper/" + page.jid
        defaultValue: "unset"
    }

    SilicaFlickable {
        id: flick
        anchors.fill: parent
        contentHeight: content.height

        PullDownMenu {
            MenuItem {
                enabled: Mitakuuluu.connectionStatus == Mitakuuluu.LoggedIn
                text: blocked ? qsTr("Unblock contact", "User profile page menu item")
                              : qsTr("Block contact", "User profile page menu item")
                onClicked: {
                    page.blocked = !page.blocked
                    Mitakuuluu.blockOrUnblockContact(page.jid)
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
                text: qsTr("Save chat history", "User profile page menu item")
                onClicked: {
                    Mitakuuluu.saveHistory(page.jid, page.pushname)
                    banner.notify(qsTr("History saved to Documents", "User profile page history saved banner"))
                }
            }
        }

        Column {
            id: content
            width: parent.width

            spacing: Theme.paddingMedium

            PageHeader {
                id: header
                title: pushname
            }

            AvatarHolder {
                id: ava
                width: Theme.iconSizeLarge * 4
                height: Theme.iconSizeLarge * 4
                anchors.horizontalCenter: parent.horizontalCenter
                source: page.picture
                emptySource: "../images/avatar-empty.png"

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        //avatarView.show(page.picture)
                        pageStack.push(Qt.resolvedUrl("AvatarHistory.qml"), {"jid": page.jid, "avatar": page.picture, "owner": false})
                    }
                }
            }

            Label {
                id: pushnameLabel
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.paddingLarge
                }
                text: qsTr("Nickname: %1", "User profile page nickname label").arg(Utilities.emojify(pushname, emojiPath))
                textFormat: Text.RichText
            }

            Label {
                id: presenceLabel
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.paddingLarge
                }
                text: qsTr("Status: %1", "User profile page status label").arg(Utilities.emojify(presence, emojiPath))
                textFormat: Text.RichText
                wrapMode: Text.WordWrap
            }

            Label {
                id: presenceTimestamp
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.paddingLarge
                }
                text: qsTr("Status set: %1", "User profile page status timestamp").arg(timestampToDateTime(timestamp))
                wrapMode: Text.WordWrap
            }

            Label {
                id: ifBlocked
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.paddingLarge
                }
                text: qsTr("Contact blocked", "User profile page contact blocked label")
                visible: page.blocked
            }

            IconItem {
                width: parent.width
                icon.source: "image://theme/icon-l-answer"
                icon.height: Theme.itemSizeSmall
                icon.width: Theme.itemSizeSmall
                name: qsTr("Call +%1").arg(phone)
                onClicked: {
                    Qt.openUrlExternally("tel:+" + phone)
                }
            }

            IconItem {
                width: parent.width
                icon.source: "image://theme/icon-m-people"
                icon.height: Theme.itemSizeSmall
                icon.width: Theme.itemSizeSmall
                name: qsTr("Save +%1").arg(phone)
                onClicked: {
                    Mitakuuluu.openProfile(pushname, "+" + phone)
                }
            }

            SectionHeader {
                text: qsTr("Media", "User profile page media section name")
                visible: mediaGrid.count > 0
            }

            SilicaGridView {
                id: mediaGrid
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.paddingLarge
                }

                delegate: gridDelegate
                model: mediaListModel
                cellWidth: page.isPortrait ? width / 3 : width / 5
                cellHeight: cellWidth
                clip: true
                height: mediaGrid.contentHeight
                interactive: false
            }
        }

        VerticalScrollDecorator {}
    }

    AvatarView {
        id: avatarView
    }

    RemorsePopup {
        id: remorse
    }

    ListModel {
        id: mediaListModel
    }

    Component {
        id: gridDelegate
        MouseArea {
            id: item
            width: GridView.view.cellWidth - 1
            height: GridView.view.cellHeight - 1

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
}
