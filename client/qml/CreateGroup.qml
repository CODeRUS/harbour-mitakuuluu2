import QtQuick 2.1
import Sailfish.Silica 1.0
import harbour.mitakuuluu2.client 1.0
import "Utilities.js" as Utilities

Dialog {
    id: page
    canAccept: false
    allowedOrientations: globalOrientation

    property var jids: []

    function checkCanAccept() {
        page.canAccept = !groupTitle.errorHighlight && groupTitle.text.trim().length > 0 && jids.length > 0
    }

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

    property bool cantAcceptReally: pageStack._forwardFlickDifference > 0 && pageStack._preventForwardNavigation
    onCantAcceptReallyChanged: {
        if (cantAcceptReally)
            negativeFeedback()
    }

    function negativeFeedback() {
        if (groupTitle.text.trim().length == 0) {
            groupTitle.forceActiveFocus()
        }
        if (jids.length == 0) {
            banner.notify(qsTr("You should add participants!", "Create group page cant accept feedback"))
        }
    }

    onStatusChanged: {
        if (status == DialogStatus.Opened) {
            if (groupTitle.text.length == 0) {
                groupTitle.forceActiveFocus()
            }
        }
    }

    onDone: {
        groupTitle.focus = false
        page.forceActiveFocus()
    }

    onAccepted: {
        groupTitle.deselect()
        Mitakuuluu.createGroup(groupTitle.text.trim(), avaholder.source, jids)
    }

    SilicaFlickable {
        id: flick
        anchors.fill: parent
        pressDelay: 0

        PullDownMenu {
            MenuItem {
                text: qsTr("Add contacts", "Group profile page menu item")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("SelectContact.qml"), {"jid": page.jid, "noGroups": true, "multiple": true, "selected": participantsModel})
                    pageStack.currentPage.done.connect(listView.selectFinished)
                    pageStack.currentPage.itemAdded.connect(listView.contactAdded)
                    pageStack.currentPage.removed.connect(listView.contactRemoved)
                }
            }
        }

        DialogHeader {
            id: header
            title: qsTr("Create group", "Greate group page title")
        }

        Row {
            id: detailsrow
            anchors {
                top: header.bottom
                left: parent.left
                leftMargin: Theme.paddingLarge
                right: parent.right
                rightMargin: Theme.paddingLarge
            }
            height: avaholder.height

            spacing: Theme.paddingMedium

            AvatarHolder {
                id: avaholder
                width: Theme.itemSizeMedium
                height: Theme.itemSizeMedium
                emptySource: "../images/avatar-empty-group.png"

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        pageStack.push(avatarPickerPage.createObject(root))
                    }
                }
            }

            TextField {
                id: groupTitle
                anchors.verticalCenter: avaholder.verticalCenter
                width: parent.width - avaholder.width - Theme.paddingMedium
                onTextChanged: checkCanAccept()
                errorHighlight: text.length > 25 || text.length == 0
                placeholderText: qsTr("Write name of new group here", "Create group subject area subtitle")
                EnterKey.enabled: text.length > 0
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: listView.forceActiveFocus()
            }
        }

        SilicaListView {
            id: listView
            anchors {
                top: detailsrow.bottom
                topMargin: Theme.paddingLarge
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            pressDelay: 0

            model: participantsModel
            delegate: listDelegate
            clip: true

            function contactAdded(pmodel) {
                if (pmodel.jid !== Mitakuuluu.myJid) {
                    var value = page.jids
                    value.splice(0, 0, pmodel.jid)
                    page.jids = value
                    checkCanAccept()

                    if (listView.count < 51)
                        participantsModel.append({"jid": pmodel.jid, "name": pmodel.nickname, "avatar": pmodel.avatar})
                    else
                        banner.notify(qsTr("Max group participants count reached", "Group profile maximum participants banner"))
                }
            }

            function contactRemoved(pjid) {
                if (pjid !== Mitakuuluu.myJid) {
                    var value = page.jids
                    var exists = value.indexOf(pjid)
                    if (exists != -1) {
                        value.splice(exists, 1)
                    }
                    page.jids = value
                    checkCanAccept()

                    for (var i = 0; i < participantsModel.count; i++) {
                        if (participantsModel.get(i).jid == pjid) {
                            participantsModel.remove(i)
                        }
                    }
                }
            }

            function selectFinished() {
                pageStack.currentPage.done.disconnect(listView.selectFinished)
                pageStack.currentPage.itemAdded.disconnect(listView.contactAdded)
                pageStack.currentPage.removed.disconnect(listView.contactRemoved)
            }

            VerticalScrollDecorator {}

            ViewPlaceholder {
                enabled: listView.count == 0 && _active
                text: qsTr("Participants list is empty", "Create group empty paricipants list placeholder")
                property bool _active: false
                Component.onCompleted: {
                    flickable = flick
                    parent = flick.contentItem
                    _active = true
                }
            }
        }
    }

    ContactsFilterModel {
        id: contactsModel
        contactsModel: ContactsBaseModel
        hideGroups: true
        showUnknown: settings.acceptUnknown
        showActive: false
        filterContacts: settings.showMyJid ? [] : [Mitakuuluu.myJid]
        Component.onCompleted: {
            init()
        }
    }

    ListModel {
        id: participantsModel
    }

    Component {
        id: listDelegate
        BackgroundItem {
            id: item
            width: parent.width
            height: Theme.itemSizeMedium

            AvatarHolder {
                id: contactava
                height: Theme.iconSizeLarge
                width: Theme.iconSizeLarge
                source: model.avatar
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
                anchors.right: remove.left
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
                visible: model.jid != Mitakuuluu.myJid
                icon.source: "image://theme/icon-m-clear"
                highlighted: pressed
                onClicked: {
                    participantsModel.remove(index)
                }
            }
        }
    }

    Component {
        id: avatarPickerPage

        AvatarPickerCrop {
            id: avatarPicker
            objectName: "avatarPicker"

            onAvatarSourceChanged: {
                avaholder.source = ""
                avaholder.source = Mitakuuluu.saveAvatarForJid(Mitakuuluu.myJid, avatarSource)
                avatarPicker.destroy()
            }
        }
    }
}
