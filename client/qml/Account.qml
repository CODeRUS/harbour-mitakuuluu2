import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.mitakuuluu2.client 1.0
import org.nemomobile.configuration 1.0

Dialog {
    id: page
    objectName: "account"
    allowedOrientations: globalOrientation

    property string pushname: ""
    property string presence: ""
    property int creation: 0
    property int expiration: 0
    property bool active: true
    property string kind: "free"
    property string avatar: Mitakuuluu.getAvatarForJid(Mitakuuluu.myJid)

    property var presenceHistory: ["I'm using Mitakuuluu", "Working", "Sleeping", "Away", "Do not disturb"]
    onPresenceHistoryChanged: {
        var val = presenceHistory
        console.log("presenceHistory: " + JSON.stringify(val) + " firstChange: " + historyConfig.firstChange)
        if (!historyConfig.firstChange) {
            console.log("saving value to dconf")
            historyConfig.value = val
        }
    }

    canAccept: (Mitakuuluu.connectionStatus == Mitakuuluu.LoggedIn)
               && (pushnameArea.text.length > 0)
               && (presenceArea.text.length > 0)

    function accept() {
        if (canAccept) {
            _dialogDone(DialogResult.Accepted)
        }
        else {
            negativeFeedback()
        }

        // Attempt to navigate even if it will fail, so that feedback can be generated
        pageStack.navigateForward()
    }

    function resetAccount() {
        accountGroup.unset()
        if (Mitakuuluu.connectionStatus == Mitakuuluu.LoggedIn) {
            Mitakuuluu.disconnect()
        }
        pageStack.pop()
    }

    DConfValue {
        id: accountGroup
        key: "/apps/harbour-mitakuuluu2/account/"
    }

    property bool cantAcceptReally: pageStack._forwardFlickDifference > 0 && pageStack._preventForwardNavigation
    onCantAcceptReallyChanged: {
        if (cantAcceptReally)
            negativeFeedback()
    }

    function negativeFeedback() {
        if (Mitakuuluu.connectionStatus != Mitakuuluu.LoggedIn) {
            banner.notify(qsTr("You should be online!", "Account page cant accept feedback"))
        }
        if (pushnameArea.text.trim().length == 0) {
            pushnameArea.forceActiveFocus()
        }
        if (presenceArea.text.trim().length == 0) {
            presenceArea.forceActiveFocus()
        }
    }

    function tr_noop() {
        qsTr("free", "Account type")
        qsTr("paid", "Account type")
        qsTr("blocked", "Account type")
        qsTr("expired", "Account type")
    }

    Connections {
        target: Mitakuuluu

        onPictureUpdated: {
            if (pjid === Mitakuuluu.myJid) {
                avatarSet(path)
            }
        }
    }

    function avatarSet(avatarPath) {
        console.log("updated avatar: " + avatarPath)
        page.avatar = ""
        page.avatar = avatarPath
    }

    onStatusChanged: {
        if (status == DialogStatus.Opened) {
            pushname = accountConfiguration.pushname
            pushnameArea.text = pushname
            presence = accountConfiguration.presence
            presenceArea.text = presence
            creation = accountConfiguration.creation
            expiration = accountConfiguration.expiration
            kind = accountConfiguration.kind
            active = accountConfiguration.accountstatus

            Mitakuuluu.getPicture(Mitakuuluu.myJid)
            Mitakuuluu.getContactStatus(Mitakuuluu.myJid)
        }
    }

    onAccepted: {
        page.pushname = pushnameArea.text
        accountConfiguration.pushname = pushnameArea.text.trim();
        Mitakuuluu.setMyPushname(pushnameArea.text)
        ContactsBaseModel.renameContact(Mitakuuluu.myJid, pushnameArea.text.trim())
        pushnameArea.focus = false
        page.forceActiveFocus()

        page.presence = presenceArea.text
        accountConfiguration.presence = presenceArea.text.trim();
        Mitakuuluu.setMyPresence(presenceArea.text)
        presenceArea.focus = false
        page.forceActiveFocus()

        if (presenceHistory.indexOf(accountConfiguration.presence) < 0) {
            var arr = presenceHistory
            arr.splice(0, 0, accountConfiguration.presence)
            presenceHistory = arr
        }
    }

    ConfigurationGroup {
        id: accountConfiguration
        path: "/apps/harbour-mitakuuluu2/account"

        property string pushname: "Mitakuuluu user"
        property string presence: "I love Mitakuuluu!"

        property int creation: 0
        property int expiration: 0
        property string kind: "free"

        property string accountstatus: "active"
    }

    function timestampToFullDate(stamp) {
        var d = new Date(stamp*1000)
        return Qt.formatDateTime(d, "dd MMM yyyy")
    }

    SilicaFlickable {
        id: flick
        anchors.fill: page
        clip: true
        pressDelay: 0
        contentHeight: content.height

        PullDownMenu {
            MenuItem {
                text: Mitakuuluu.connectionStatus == Mitakuuluu.LoggedIn ? qsTr("Remove account", "Account page menu item") :
                                                                           qsTr("Remove local data", "Account page menu item")
                onClicked: {
                    if (Mitakuuluu.connectionStatus == Mitakuuluu.LoggedIn) {
                        deleteDialog.open()
                    }
                    else {
                        resetAccount()
                    }
                }
            }
            MenuItem {
                text: qsTr("Renew subscription", "Account page menu item")
                //visible: ((page.expiration * 1000) - (new Date().getTime())) < 259200000
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("Payments.qml"))
                }
            }
            MenuItem {
                text: qsTr("Privacy settings", "Account page menu item")
                visible: Mitakuuluu.connectionStatus == Mitakuuluu.LoggedIn
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("PrivacySettings.qml"))
                }
            }
        }

        Column {
            id: content
            width: parent.width
            spacing: Theme.paddingSmall

            DialogHeader {
                id: header
                title: qsTr("Account", "Account page title")
                acceptText: qsTr("Save", "Account page accept button text")
            }

            Row {
                id: infoRow
                height: Math.max(ava.height, infoColumn.height)
                spacing: Theme.paddingSmall

                Item { width: Theme.paddingLarge; height: 1 }

                AvatarHolder {
                    id: ava
                    width: 128
                    height: 128
                    source: page.avatar
                    emptySource: "../images/avatar-empty.png"

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            var avatarHistory = pageStack.push(Qt.resolvedUrl("AvatarHistory.qml"), {"jid": Mitakuuluu.myJid, "avatar": page.avatar, "owner": true})
                            avatarHistory.avatarSet.connect(page.avatarSet)
                        }
                    }
                }

                Column {
                    id: infoColumn
                    width: content.width - ava.width - parent.spacing - Theme.paddingLarge * 2
                    spacing: Theme.paddingSmall

                    Label {
                        id: labelCreated
                        text: qsTr("Created: %1", "Account page created title").arg(timestampToFullDate(page.creation))
                        anchors.right: parent.right
                        wrapMode: Text.NoWrap
                        horizontalAlignment: Text.AlignRight
                        font.pixelSize: Theme.fontSizeSmall
                    }

                    Label {
                        id: labelExpired
                        text: qsTr("Expiration: %1", "Account page expiration title").arg(timestampToFullDate(page.expiration))
                        anchors.right: parent.right
                        wrapMode: Text.NoWrap
                        horizontalAlignment: Text.AlignRight
                        font.pixelSize: Theme.fontSizeSmall
                    }

                    Label {
                        id: labelActive
                        text: page.active ? qsTr("Account is active", "Account page account active label")
                                          : qsTr("Account is blocked", "Account page account blocked label")
                        anchors.right: parent.right
                        wrapMode: Text.NoWrap
                        horizontalAlignment: Text.AlignRight
                        font.pixelSize: Theme.fontSizeSmall
                    }

                    Label {
                        id: labelType
                        text: qsTr("Account type: %1", "Account page account type label").arg(qsTr(page.kind))
                        anchors.right: parent.right
                        wrapMode: Text.NoWrap
                        horizontalAlignment: Text.AlignRight
                        font.pixelSize: Theme.fontSizeSmall
                    }
                }
            }

            Row {
                id: pushnameRow
                spacing: Theme.paddingSmall
                height: pushnameLabel.height + Theme.paddingMedium//Math.max(pushnameLabel.height, pushnameArea.height)
                clip: true

                Item { width: Theme.paddingLarge; height: 1 }

                Label {
                    id: pushnameLabel
                    text: qsTr("Nickname:", "Account page nickname title")
                }

                TextField {
                    id: pushnameArea
                    width: content.width - pushnameLabel.width - parent.spacing - Theme.paddingLarge * 2
                    text: page.pushname
                    errorHighlight: text.length == 0
                    EnterKey.enabled: false
                    EnterKey.highlighted: EnterKey.enabled
                    onActiveFocusChanged: {
                        if (activeFocus)
                            selectAll()
                    }
                }
            }

            Row {
                id: presenceRow
                spacing: Theme.paddingSmall
                height: presenceLabel.height + Theme.paddingMedium//Math.max(presenceLabel.height, presenceArea.height)
                clip: true

                Item { width: Theme.paddingLarge; height: 1 }

                Label {
                    id: presenceLabel
                    text: qsTr("Status:", "Account page status title")
                }

                TextField {
                    id: presenceArea
                    width: content.width - presenceLabel.width - parent.spacing - Theme.paddingLarge * 2
                    text: page.presence
                    errorHighlight: text.length == 0
                    EnterKey.enabled: false
                    EnterKey.highlighted: EnterKey.enabled
                    onActiveFocusChanged: {
                        if (activeFocus)
                            selectAll()
                    }
                }
            }

            SectionHeader {
                text: qsTr("Status history")
            }

            Repeater {
                width: parent.width
                delegate: histDelegate
                model: presenceHistory
            }
        }

        VerticalScrollDecorator {}
    }

    DConfValue {
        id: historyConfig
        key: "/apps/harbour-mitakuuluu2/settings/presenceHistory"
        property bool firstChange: true
        Component.onCompleted: {
            var val = value
            page.presenceHistory = val
            firstChange = false
        }
    }

    Component {
        id: histDelegate
        ListItem {
            id: item
            width: content.width
            menu: contextMenu

            function remove() {
                remorseAction("Deleting", function() {
                    var arr = []
                    var val = page.presenceHistory
                    arr = arr.concat(val)
                    arr.splice(index, 1)
                    console.log("new history: " + JSON.stringify(arr))
                    page.presenceHistory = arr
                }, 2000)
            }

            Component {
                id: contextMenu
                ContextMenu {
                    MenuItem {
                        text: qsTr("Remove")
                        onClicked: remove()
                    }
                }
            }

            Label {
                anchors {
                    left: parent.left
                    leftMargin: Theme.paddingLarge
                    right: parent.right
                    rightMargin: Theme.paddingLarge
                    verticalCenter: parent.verticalCenter
                }
                text: modelData
                truncationMode: TruncationMode.Fade
                color: item.highlighted || presence == modelData || presenceArea.text.trim() == modelData ? Theme.highlightColor : Theme.primaryColor
            }

            onClicked: {
                pushname = modelData
                presenceArea.text = modelData
                flick.scrollToTop()
            }
        }
    }

    RemorsePopup {
        id: remorseAccount
    }

    Dialog {
        id: deleteDialog
        SilicaFlickable {
            anchors.fill: parent
            DialogHeader {
                id: dheader
                title: qsTr("Remove account", "Account page remove dialog title")
            }
            Column {
                width: parent.width - (Theme.paddingLarge * 2)
                anchors.centerIn: parent
                spacing: Theme.paddingLarge
                Label {
                    width: parent.width
                    text: qsTr("This action will delete your account information from phone and from WhatsApp server.", "Account page remove dialog description")
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }
                Button {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: qsTr("No, remove only local information")
                    onClicked: {
                        deleteDialog.reject()
                        resetAccount()
                    }
                }
            }
        }
        onAccepted: {
            Mitakuuluu.removeAccountFromServer()
            resetAccount()
        }
    }
}
