import QtQuick 2.1
import Sailfish.Silica 1.0
import harbour.mitakuuluu2.client 1.0
import "Utilities.js" as Utilities

Page {
    id: page
    objectName: "privacyList"
    allowedOrientations: globalOrientation

    onStatusChanged: {
        if (status === PageStatus.Inactive) {
            listModel.clear()
        }
        else if (status == PageStatus.Activating) {
            Mitakuuluu.getPrivacyList()
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

    Connections {
        target: Mitakuuluu
        onContactsBlocked: {
            listModel.clear()
            for (var i = 0; i < list.length; i++) {
                var jid = list[i]
                var model = ContactsBaseModel.getModel(jid)
                if (model.jid) {
                    var avatar = settings.usePhonebookAvatars || (model.jid.indexOf("-") > 0)
                            ? (model.avatar == "undefined" ? "" : (model.avatar))
                            : (model.owner == "undefined" ? "" : (model.owner.length > 0 ? model.owner : model.avatar))
                    listModel.append({"jid": model.jid,
                                      "name": getNicknameByJid(model.jid),
                                      "avatar": avatar})
                }
                else {
                    listModel.append({"jid": jid,
                                      "name": getNicknameByJid(jid),
                                      "avatar": ""})
                }
            }
        }
    }

    SilicaListView {
        id: listView
        anchors.fill: page
        clip: true
        model: listModel
        delegate: listDelegate

        PullDownMenu {
            MenuItem {
                text: qsTr("Add number", "Privacy list page menu item")
                onClicked: {
                    addDialog.open()
                    addNumber.forceActiveFocus()
                }
            }

            MenuItem {
                text: qsTr("Select contacts", "Privacy list page menu item")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("SelectContact.qml"), {"multiple": true, "noGroups": true, "selected": listModel})
                    pageStack.currentPage.accepted.connect(listView.selectionFinished)
                    pageStack.currentPage.rejected.connect(listView.removeBindings)
                }
            }
        }

        header: PageHeader {
            id: title
            title: qsTr("Blacklist", "Privacy list page title")
        }

        function removeBindings() {
            pageStack.currentPage.accepted.disconnect(listView.selectionFinished)
            pageStack.currentPage.rejected.disconnect(listView.removeBindings)
        }

        function selectionFinished() {
            removeBindings()
            listModel.clear()
            var jids = pageStack.currentPage.jids
            for (var i = 0; i < jids.length; i ++) {
                var model = ContactsBaseModel.getModel(jids[i])
                var avatar = (typeof(model.avatar) !== "undefined" && model.avatar !== "undefined" && model.avatar.length > 0) ? model.avatar : ""
                listModel.append({"jid": model.jid,
                                  "name": getNicknameByJid(model.jid),
                                  "avatar": avatar})
            }
            Mitakuuluu.sendBlockedJids(jids)
        }

        ViewPlaceholder {
            enabled: listView.count == 0
            text: qsTr("Blacklist is empty", "Privacy empty list placeholder text")
        }

        VerticalScrollDecorator {}
    }

    Dialog {
        id: addDialog
        canAccept: addNumber.text.trim().length > 0
        onDone: {
            addNumber.focus = false
            page.forceActiveFocus()
        }
        onAccepted: {
            var bjid = text + "@s.whatsapp.net"
            var exists = false
            for (var i = 0; i < listModel.count; i++) {
                if (listModel.get(i).jid === bjid) {
                    exists = true
                    break
                }
            }
            if (!exists)
                Mitakuuluu.blockOrUnblockContact(bjid)
        }

        DialogHeader {
            title: qsTr("Add to blacklist", "Privacy list adding contact page title")
        }

        TextField {
            id: addNumber
            width: parent.width
            textLeftMargin: ccLabel.paintedWidth + Theme.paddingLarge
            inputMethodHints: Qt.ImhDialableCharactersOnly
            validator: RegExpValidator{ regExp: /[0-9]*/;}
            label: qsTr("In international format", "Phone number text field label")
            _labelItem.anchors.leftMargin: Theme.paddingLarge
            placeholderText: "123456789"

            Component.onCompleted: {
                _backgroundItem.x = Theme.paddingLarge
                _backgroundItem.width = _contentItem.width
            }

            Label {
                id: ccLabel
                anchors {
                    right: parent.left
                    top: parent.top
                }
                text: "+"
            }
        }
    }

    ListModel {
        id: listModel
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
                emptySource: "../images/avatar-empty" + (model.jid.indexOf("-") > 0 ? "-group" : "") + ".png"
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingLarge
                anchors.verticalCenter: parent.verticalCenter
            }

            Label {
                id: contact
                anchors.left: contactava.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.verticalCenter: contactava.verticalCenter
                anchors.right: remove.left
                anchors.rightMargin: Theme.paddingSmall
                font.pixelSize: Theme.fontSizeMedium
                text: Utilities.emojify(model.name, emojiPath)
                truncationMode: TruncationMode.Fade
                color: item.highlighted ? Theme.highlightColor : Theme.primaryColor
            }

            IconButton {
                id: remove
                width: Theme.iconSizeLarge
                height: Theme.iconSizeLarge
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingSmall
                anchors.verticalCenter: parent.verticalCenter
                icon.source: "image://theme/icon-m-clear"
                onClicked: {
                    Mitakuuluu.blockOrUnblockContact(model.jid)
                    listModel.remove(index)
                }
            }
        }
    }
}
