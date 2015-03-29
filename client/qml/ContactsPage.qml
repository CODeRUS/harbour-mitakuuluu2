import QtQuick 2.1
import Sailfish.Silica 1.0
import harbour.mitakuuluu2.client 1.0
import "Utilities.js" as Utilities

Page {
    id: page
    objectName: "contactsPage"
    allowedOrientations: globalOrientation

    property string searchPattern
    onSearchPatternChanged: {
        contactsModel.filter = searchPattern
    }

    property bool searchEnabled: false

    onStatusChanged: {
        if (status == PageStatus.Active) {
            page.forceActiveFocus()
            searchPattern = ""
            contactsModel.filter = ""
            fastScroll.init()

            var firstStartContacts = settings.firstStartContacts
            if (firstStartContacts) {
                horizontalHint.stop()
                horizontalHint.direction = TouchInteraction.Right
                horizontalHint.start()
                settings.firstStartContacts = false
            }
            horizontalHint.visible = firstStartContacts
            hintLabel.visible = firstStartContacts
        }
    }

    SilicaListView {
        id: listView
        model: contactsModel
        delegate: listDelegate
        anchors.fill: parent
        clip: true
        cacheBuffer: page.height * 2
        pressDelay: 0
        currentIndex: -1
        section.property: "nickname"
        section.criteria: ViewSection.FirstCharacter
        section.delegate: Component {
            SectionHeader {
                text: section
            }
        }
        header: headerComponent

        Component.onCompleted: {
            if (listView.hasOwnProperty("quickScroll")) {
                listView.quickScroll = false
            }
        }

        onCountChanged: {
            fastScroll.init()
        }

        FastScroll {
            id: fastScroll
            listView: listView
            __hasPageHeight: false
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Blacklist", "Contacts page menu item")
                enabled: Mitakuuluu.connectionStatus == Mitakuuluu.LoggedIn
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("PrivacyList.qml"))
                }
            }
            MenuItem {
                text: qsTr("Add contact", "Contacts page menu item")
                enabled: Mitakuuluu.connectionStatus == Mitakuuluu.LoggedIn
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("SelectPhonebook.qml"))
                }
            }
            MenuItem {
                text: qsTr("Settings", "Contacts page menu item")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("Settings.qml"))
                }
            }
            MenuItem {
                text: searchEnabled
                      ? qsTr("Hide search field")
                      : qsTr("Show search field")
                enabled: listView.count > 0
                onClicked: {
                    searchEnabled = !searchEnabled
                }
            }
        }
    }

    Component {
        id: headerComponent
        Item {
            id: componentItem
            width: parent.width
            height: header.height + searchPlaceholder.height

            PageHeader {
                id: header
                title: qsTr("Contacts", "Contacts page title")
            }

            Item {
                id: searchPlaceholder
                width: componentItem.width
                height: searchEnabled ? searchField.height : 0
                anchors.top: header.bottom
                Behavior on height {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.InOutQuad
                        property: "height"
                    }
                }
                clip: true
                SearchField {
                    id: searchField
                    anchors.bottom: parent.bottom
                    width: parent.width
                    placeholderText: qsTr("Search contacts", "Contacts page search text")
                    inputMethodHints: Qt.ImhNoPredictiveText
                    enabled: searchEnabled
                    onEnabledChanged: {
                        if (!enabled) {
                            text = ''
                        }
                    }
                    focus: enabled
                    visible: opacity > 0
                    opacity: searchEnabled ? 1 : 0
                    Behavior on opacity {
                        FadeAnimation {
                            duration: 300
                        }
                    }
                    onTextChanged: {
                        searchPattern = searchField.text
                        fastScroll.init()
                    }
                }
            }
        }
    }

    InteractionHintLabel {
        id: hintLabel
        anchors.bottom: page.bottom
        Behavior on opacity { FadeAnimation { duration: 1000 } }
        text: qsTr("Flick right to return to Chats page")
        visible: false
    }

    TouchInteractionHint {
        id: horizontalHint
        loops: Animation.Infinite
        anchors.verticalCenter: page.verticalCenter
        visible: false
    }

    function getMuting(jid, def) {
        mutingConfig.key = "/apps/harbour-mitakuuluu2/muting/" + jid
        mutingConfig.defaultValue = def
        return mutingConfig.value
    }
    DConfValue {
        id: mutingConfig
    }

    Component {
        id: listDelegate
        ListItem {
            id: item
            width: ListView.view.width
            contentHeight: Theme.itemSizeMedium
            ListView.onRemove: animateRemoval(item)
            menu: contextMenu
            property bool muted: false
            property Timer mutingTimer
            property bool secure: hiddenList.indexOf(model.jid) >= 0

            function removeContact() {
                remorseAction(qsTr("Delete", "Delete contact remorse action text"),
                function() {
                    ContactsBaseModel.deleteContact(model.jid)
                })
            }

            function leaveGroup() {
                remorseAction(qsTr("Leave group %1", "Group leave remorse action text").arg(model.nickname),
                function() {
                    Mitakuuluu.groupLeave(model.jid)
                    ContactsBaseModel.deleteContact(model.jid)
                })
            }

            function removeGroup() {
                remorseAction(qsTr("Delete group %1", "Group delete remorse action text").arg(model.nickname),
                function() {
                    Mitakuuluu.groupRemove(model.jid)
                    ContactsBaseModel.deleteContact(model.jid)
                })
            }

            Loader {
                id: dconfLoader
                sourceComponent: dconfComponent
                asynchronous: true
            }

            Component {
                id: dconfComponent
                DConfValue {
                    key: "/apps/harbour-mitakuuluu2/muting/" + model.jid
                    defaultValue: 0
                    onValueChanged: {
                        var timeNow = new Date().getTime()
                        var mutingInterval = parseInt(value)
                        if (mutingInterval > timeNow) {
                            if (!mutingTimer) {
                                mutingTimer = mutingTimerComponent.createObject(null, {"interval": parseInt(mutingInterval) - new Date().getTime(), "running": true})
                            }
                            muted = true
                        }
                        else {
                            if (mutingTimer) {
                                removeMuting()
                            }
                        }
                    }
                }
            }

            Component.onDestruction: {
                removeMuting()
            }

            function removeMuting() {
                if (item.mutingTimer)
                    item.mutingTimer.destroy()
                muted = false
            }

            Component {
                id: mutingTimerComponent
                Timer {
                    onTriggered: {
                        item.muted = false
                        item.mutingTimer.destroy()
                    }
                }
            }

            Rectangle {
                id: presence
                height: ava.height
                anchors.left: parent.left
                anchors.right: ava.left
                anchors.verticalCenter: ava.verticalCenter
                color: model.blocked ? Theme.rgba("red", 0.6) : (Mitakuuluu.connectionStatus === Mitakuuluu.LoggedIn ? (model.available ? Theme.rgba(Theme.highlightColor, 0.6) : "transparent") : "transparent")
                border.width: model.blocked ? 1 : 0
                border.color: (Mitakuuluu.connectionStatus === Mitakuuluu.LoggedIn && model.blocked) ? Theme.rgba(Theme.highlightColor, 0.6) : "transparent"
                smooth: true
            }

            AvatarHolder {
                id: ava
                source: settings.usePhonebookAvatars || (model.jid.indexOf("-") > 0)
                        ? (model.avatar == "undefined" ? "" : (model.avatar))
                        : (model.owner == "undefined" ? "" : (model.owner.length > 0 ? model.owner : model.avatar))
                emptySource: "../images/avatar-empty" + (model.jid.indexOf("-") > 0 ? "-group" : "") + ".png"
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingLarge
                anchors.top: parent.top
                anchors.topMargin: Theme.paddingSmall / 2
                width: Theme.iconSizeLarge
                height: Theme.iconSizeLarge

                Rectangle {
                    id: unreadCount
                    width: Theme.iconSizeSmall
                    height: Theme.iconSizeSmall
                    smooth: true
                    radius: Theme.iconSizeSmall / 4
                    border.width: 1
                    border.color: Theme.highlightColor
                    color: Theme.secondaryHighlightColor
                    visible: model.unread > 0
                    anchors.right: parent.right
                    anchors.top: parent.top

                    Label {
                        anchors.centerIn: parent
                        font.pixelSize: Theme.fontSizeExtraSmall
                        text: model.unread
                        color: Theme.primaryColor
                    }
                }

                Rectangle {
                    width: Theme.iconSizeSmall
                    height: Theme.iconSizeSmall
                    smooth: true
                    radius: Theme.iconSizeSmall / 4
                    border.width: 1
                    border.color: Theme.highlightColor
                    color: Theme.secondaryHighlightColor
                    visible: item.muted
                    anchors.left: parent.left
                    anchors.top: parent.top

                    Image {
                        source: "image://theme/icon-m-speaker-mute"
                        smooth: true
                        width: Theme.iconSizeSmall
                        height: Theme.iconSizeSmall
                        anchors.centerIn: parent
                    }
                }

                Rectangle {
                    width: Theme.iconSizeSmall
                    height: Theme.iconSizeSmall
                    smooth: true
                    radius: Theme.iconSizeSmall / 4
                    border.width: 1
                    border.color: Theme.highlightColor
                    color: Theme.secondaryHighlightColor
                    visible: item.secure
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom

                    Image {
                        source: "image://theme/icon-s-secure"
                        smooth: true
                        width: Theme.iconSizeSmall
                        height: Theme.iconSizeSmall
                        anchors.centerIn: parent
                    }
                }
            }

            Column {
                anchors.left: ava.right
                anchors.leftMargin: Theme.paddingMedium
                anchors.verticalCenter: ava.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingSmall
                clip: true
                spacing: Theme.paddingSmall

                Label {
                    id: nickname
                    font.pixelSize: Theme.fontSizeMedium
                    width: parent.width
                    text: Theme.highlightText(Utilities.emojify(model.nickname, emojiPath), searchPattern, Theme.highlightColor)
                    //text: Utilities.emojify(model.nickname, emojiPath)
                    wrapMode: Text.NoWrap
                    elide: Text.ElideRight
                    color: item.highlighted ? Theme.highlightColor : Theme.primaryColor
                    textFormat: Text.RichText
                }

                Label {
                    id: status
                    width: parent.width
                    text: model.jid.indexOf("-") > 0 ? qsTr("Group chat", "Contacts group page text in status message line")
                                                     : Utilities.emojify(model.message, emojiPath)
                    wrapMode: Text.NoWrap
                    elide: Text.ElideRight
                    color: item.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                    textFormat: Text.RichText
                    font.pixelSize: Theme.fontSizeExtraSmall
                }
            }

            onClicked: {
                pageStack.push(Qt.resolvedUrl("ConversationPage.qml"), {"initialModel": model})
            }

            Component {
                id: contextMenu
                ContextMenu {
                    MenuItem {
                        text: qsTr("Profile", "Contact context menu profile item")
                        enabled: Mitakuuluu.connectionStatus === Mitakuuluu.LoggedIn
                        onClicked: {
                            if (model.jid.indexOf("-") > 0) {
                                pageStack.push(Qt.resolvedUrl("GroupProfile.qml"), {"jid": model.jid})
                            }
                            else {
                                if (model.jid === Mitakuuluu.myJid) {
                                    pageStack.push(Qt.resolvedUrl("Account.qml"))
                                }
                                else {
                                    pageStack.push(Qt.resolvedUrl("UserProfile.qml"), {"jid": model.jid})
                                }
                            }
                        }
                    }

                    MenuItem {
                        text: qsTr("Refresh", "Contact context menu refresh item")
                        enabled: Mitakuuluu.connectionStatus === Mitakuuluu.LoggedIn
                        onClicked: {
                            Mitakuuluu.refreshContact(model.jid)
                        }
                    }

                    MenuItem {
                        text: item.secure ? qsTr("Un-hide contact") : qsTr("Hide contact")
                        onClicked: {
                            updateHidden(model.jid)
                        }
                    }

                    MenuItem {
                        text: qsTr("Rename", "Contact context menu profile item")
                        visible: model.jid.indexOf("-") < 0 && model.jid !== Mitakuuluu.myJid
                        onClicked: {
                            pageStack.push(Qt.resolvedUrl("RenameContact.qml"), {"jid": model.jid})
                        }
                    }

                    MenuItem {
                        text: qsTr("Delete group", "Contact context menu delete group item")
                        enabled: Mitakuuluu.connectionStatus === Mitakuuluu.LoggedIn
                        visible: model.owner === Mitakuuluu.myJid
                        onClicked: {
                            removeGroup()
                        }
                    }

                    MenuItem {
                        text: (model.jid.indexOf("-") > 0)
                                ? qsTr("Leave group", "Contact context menu leave group item")
                                : qsTr("Delete", "Contact context menu delete contact item")
                        enabled: Mitakuuluu.connectionStatus === Mitakuuluu.LoggedIn
                        onClicked: {
                            if (model.jid.indexOf("-") > 0)
                                leaveGroup()
                            else
                                removeContact()
                        }
                    }

                    /*MenuItem {
                        text: model.jid.indexOf("-") > 0
                        //% "Contact context menu contact mute item"
                                ? (model.blocked ? qsTr("Unmute")
                        //% "Contact context menu contact unmute item"
                                                 : qsTr("Mute"))
                        //% "Contact context menu contact block item"
                                : (model.blocked ? qsTr("Unblock")
                        //% "Contact context menu contact unblock item"
                                                 : qsTr("Block"))
                        enabled: Mitakuuluu.connectionStatus === Mitakuuluu.LoggedIn
                        onClicked: {
                            if (model.jid.indexOf("-") > 0)
                                Mitakuuluu.muteOrUnmuteGroup(model.jid)
                            else
                                Mitakuuluu.blockOrUnblockContact(model.jid)
                        }
                    }*/
                }
            }
        }
    }

    ContactsFilterModel {
        id: contactsModel
        contactsModel: ContactsBaseModel
        showActive: false
        showUnknown: settings.acceptUnknown
        hideGroups: true
        filterContacts: checkHiddenList(settings.showMyJid, hidden, hiddenList)
        onContactsModelChanged: {
            fastScroll.init()
        }
        Component.onCompleted: {
            init()
        }
    }
}
