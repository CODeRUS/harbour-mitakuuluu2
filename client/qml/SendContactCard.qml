import QtQuick 2.1
import Sailfish.Silica 1.0
import org.nemomobile.contacts 1.0

Dialog {
    id: page
    objectName: "selectContactCard"
    allowedOrientations: globalOrientation

    property int selectedIndex: -1
    property bool broadcastMode: true

    property PeopleModel allContactsModel: PeopleModel {
        filterType: PeopleModel.FilterAll
        requiredProperty: PeopleModel.PhoneNumberRequired
    }

    property var vCardData
    property string displayLabel

    canAccept: false

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
        banner.notify("You should select contacts!", "Send contact page cant accept feedback")
    }

    onStatusChanged: {
        if (status == DialogStatus.Opened) {
            allContactsModel.search("")
            fastScroll.init()
        }
        else if (status == DialogStatus.Closed) {
            listView.header.text = ""
        }
    }

    DialogHeader {
        id: header
        title: selectedIndex > -1 ? qsTr("Send contact", "Send contact card page title")
                                  : qsTr("Select contact", "Send contact card page title")
    }

    Component {
        id: searchComponent
        SearchField {
            width: parent.width
            placeholderText: qsTr("Search contacts", "Send contact card page search text")
            onTextChanged: {
                if (page.status == DialogStatus.Opened) {
                    allContactsModel.search(text)
                }
            }
        }
    }

    SilicaListView {
        id: listView
        anchors {
            top: header.bottom
            left: page.left
            right: page.right
            bottom: page.bottom
        }
        model: allContactsModel
        delegate: listDelegate
        section {
            property: "displayLabel"
            delegate: sectionDelegate
            criteria: ViewSection.FirstCharacter
        }
        currentIndex: -1
        header: searchComponent

        onCountChanged: {
            fastScroll.init()
        }

        FastScroll {
            id: fastScroll
            __hasPageHeight: false
            listView: listView
        }
    }

    Component {
        id: sectionDelegate
        SectionHeader {
            text: section
        }
    }

    Component {
        id: listDelegate
        BackgroundItem {
            id: item
            width: parent.width
            height: Theme.itemSizeMedium
            highlighted: down || (page.selectedIndex == index)

            onClicked: {
                if (page.selectedIndex == index) {
                    page.selectedIndex = -1
                    page.displayLabel = ""
                    page.vCardData = null
                    page.canAccept = false
                }
                else {
                    page.selectedIndex = index
                    page.displayLabel = model.person.displayLabel
                    page.vCardData = model.person.vCard()
                    page.canAccept = true
                }
            }

            AvatarHolder {
                id: avaplaceholder
                anchors {
                    left: parent.left
                    leftMargin: Theme.paddingLarge
                    verticalCenter: parent.verticalCenter
                }
                width: ava.width
                height: ava.height
                source: model.person.avatarPath
            }

            Column {
                id: content
                anchors {
                    left: avaplaceholder.right
                    right: parent.right
                    margins: Theme.paddingLarge
                    verticalCenter: parent.verticalCenter
                }
                spacing: Theme.paddingMedium

                Label {
                    width: parent.width
                    wrapMode: Text.NoWrap
                    elide: Text.ElideRight
                    text: model.displayLabel
                    color: item.highlighted ? Theme.highlightColor : Theme.primaryColor
                }

                Label {
                    width: parent.width
                    wrapMode: Text.NoWrap
                    elide: Text.ElideRight
                    font.pixelSize: Theme.fontSizeSmall
                    text: model.person.phoneDetails[0].normalizedNumber
                    color: item.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                }
            }
        }
    }
}
