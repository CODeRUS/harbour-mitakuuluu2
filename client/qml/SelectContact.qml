import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.mitakuuluu2.client 1.0
import "Utilities.js" as Utilities

Dialog {
    id: page
    objectName: "selectContact"
    canAccept: false
    allowedOrientations: globalOrientation

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
        banner.notify(qsTr("You should select contacts!", "Select contact page cant accept feedback"))
    }

    property string jid: ""
    property var jids: []
    property bool multiple: false
    property bool noGroups: false
    property bool showMyself: false

    signal added(string pjid)
    signal removed(string pjid)

    signal itemAdded(variant pitem)

    property ListModel selected
    onSelectedChanged: select(selected)
    function select(selected) {
        for (var i = 0; i < selected.count; i ++) {
            var model = selected.get(i)
            var value = page.jids
            value.splice(0, 0, model.jid)
            page.jids = value
        }
    }

    onStatusChanged: {
        if(status === DialogStatus.Closed) {
            page.jids = []
            page.jid = ""
        }
        else if (status === DialogStatus.Opened) {
            page.canAccept = false
            fastScroll.init()
        }
    }

    DialogHeader {
        id: title
        title: jids.length == 0 ? qsTr("Select contacts", "Select contact page title")
                                : qsTr("Selected %n contacts", "Select contact page title", jids.length)
    }

    SearchField {
        id: searchItem
        width: parent.width
        anchors.top: title.bottom
        placeholderText: qsTr("Search", "Contacts selector")

        onTextChanged: {
            contactsModel.filter = text
            fastScroll.init()
        }
    }

    SilicaListView {
        id: listView
        anchors {
            top: searchItem.bottom
            bottom: parent.bottom
        }
        width: parent.width
        model: contactsModel
        delegate: contactsDelegate
        clip: true
        section.property: "nickname"
        section.criteria: ViewSection.FirstCharacter
        section.delegate: Component {
            SectionHeader {
                text: section
            }
        }
        currentIndex: -1
        onCountChanged: {
            fastScroll.init()
        }
        FastScroll {
            id: fastScroll
            listView: listView
            __hasPageHeight: false
        }
    }

    ContactsFilterModel {
        id: contactsModel
        contactsModel: ContactsBaseModel
        hideGroups: noGroups
        showActive: false
        showUnknown: settings.acceptUnknown
        filterContacts: showMyself ? [] : [Mitakuuluu.myJid]
        Component.onCompleted: {
            init()
        }
    }

    Component {
        id: contactsDelegate

        BackgroundItem {
            id: item
            width: parent.width
            height: Theme.itemSizeMedium
            highlighted: down || checked
            property bool checked: page.jids.indexOf(model.jid) != -1

            AvatarHolder {
                id: ava
                width: Theme.iconSizeLarge
                height: Theme.iconSizeLarge
                source: settings.usePhonebookAvatars || (model.jid.indexOf("-") > 0)
                        ? (model.avatar == "undefined" ? "" : (model.avatar))
                        : (model.owner == "undefined" ? "" : (model.owner.length > 0 ? model.owner : model.avatar))
                emptySource: "../images/avatar-empty" + (model.jid.indexOf("-") > 0 ? "-group" : "") + ".png"
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingLarge
                anchors.verticalCenter: parent.verticalCenter
                backgroundVisible: (status !== Image.Ready) || (model.jid.indexOf("@broadcast") >= 0)
            }

            Label {
                id: nickname
                font.pixelSize: Theme.fontSizeMedium
                text: getNickname(model.jid, model.nickname, model.subowner)
                anchors.left: ava.right
                anchors.leftMargin: 16
                anchors.top: parent.top
                anchors.topMargin: Theme.paddingSmall
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingMedium
                wrapMode: Text.NoWrap
                color: item.highlighted ? Theme.highlightColor : Theme.primaryColor
                truncationMode: TruncationMode.Fade
            }

            Label {
                id: status
                font.pixelSize: Theme.fontSizeSmall
                text: model.jid.indexOf("-") > 0 ? qsTr("Group chat", "Contacts group page text in status message line")
                                                 : ((model.jid.indexOf("@broadcast") >= 0 ? qsTr("Broadcast list", "Contacts group page text in status message line")
                                                                                          : Utilities.emojify(model.message, emojiPath)))
                anchors.left: ava.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Theme.paddingSmall
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingMedium
                wrapMode: Text.NoWrap
                color: item.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                truncationMode: TruncationMode.Fade
            }

            onClicked: {
                if ((multiple && noGroups) || (page.jids.length > 1 && model.jid.indexOf("-") == -1 && page.jids[0].indexOf("-") == -1)) {
                    selectMany(model.jid)
                }
                else {
                    selectOne(model.jid)
                }
            }
            onPressAndHold: {
                if (multiple && model.jid.indexOf("-") == -1 && page.jids[0].indexOf("-") == -1) {
                    selectMany(model.jid)
                }
                else {
                    selectOne(model.jid)
                }
            }

            function selectMany(jid) {
                var value = page.jids
                var exists = value.indexOf(jid)
                if (exists != -1) {
                    value.splice(exists, 1)
                    page.removed(jid)
                }
                else {
                    value.splice(0, 0, jid)
                    page.added(jid)
                    page.itemAdded(model)
                }
                page.jids = value
                page.canAccept = page.jids.length > 0
            }

            function selectOne(jid) {
                if (page.jids.length > 0) {
                    page.removed(page.jids[0])
                }
                page.added(jid)
                page.itemAdded(model)
                page.jids = [model.jid]
                page.canAccept = page.jids.length > 0
            }
        }
    }
}
