import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.contacts 1.0
import harbour.mitakuuluu2.client 1.0

Dialog {
    id: page
    objectName: "selectPhonebook"
    allowedOrientations: globalOrientation

    property string searchPattern
    onSearchPatternChanged: {
        allContactsModel.search(searchPattern)
    }

    property bool searchEnabled: false

    property var numbers: []
    property var names: []
    property var avatars: []

    signal finished

    property PeopleModel allContactsModel: PeopleModel {
        filterType: PeopleModel.FilterAll
        requiredProperty: PeopleModel.PhoneNumberRequired
    }

    onStatusChanged: {
        if (status == DialogStatus.Closed) {
            page.finished()
            numbers = []
            names = []
            avatars = []
        }
        else if (status == DialogStatus.Opening) {
            allContactsModel.search("")
        }
        else if (status == DialogStatus.Opened) {
            fastScroll.init()
        }
    }

    canAccept: numbers.length > 0

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
        banner.notify(qsTr("You should select contacts!", "Select phonebook page cant accept feedback"))
    }

    onAccepted: {
        Mitakuuluu.syncContacts(numbers, names, avatars)
    }

    SilicaListView {
        id: listView
        anchors.fill: parent
        currentIndex: -1
        header: headerComponent
        model: allContactsModel
        delegate: contactsDelegate
        clip: true
        cacheBuffer: page.height * 2
        pressDelay: 0
        spacing: Theme.paddingMedium
        section {
            property: "sectionBucket"
            criteria: ViewSection.FirstCharacter
            delegate: sectionDelegate
        }

        Component.onCompleted: {
            if (listView.hasOwnProperty("quickScroll")) {
                listView.quickScroll = false
            }
        }

        FastScroll {
            id: fastScroll
            __hasPageHeight: false
            listView: listView
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Sync all phonebook", "Add contacts page menu item")
                onClicked: {
                    Mitakuuluu.syncAllPhonebook()
                    page.reject()
                }
            }

            MenuItem {
                text: qsTr("Add number", "Add contacts page menu item")
                onClicked: {
                    pageStack.replace(Qt.resolvedUrl("AddContact.qml"))
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

            /*MenuItem {
                text: (page.numbers.length > 0) ? "Deselect all" : "Select all"
                    onClicked: {
                    if (page.numbers.length > 0) {
                        page.numbers = []
                        page.names = []
                        page.avatars = []
                    }
                    else {
                        var vnumbers = []
                        var vnames = []
                        var vavatars = []
                        for (var i = 0; i < phonebookmodel.length; i++) {
                            vnumbers.splice(0, 0, phonebookmodel[i].number)
                            vnames.splice(0, 0, phonebookmodel[i].nickname)
                            vavatars.splice(0, 0, phonebookmodel[i].avatar)
                        }
                        page.numbers = vnumbers
                        page.names = vnames
                        page.avatars = vavatars
                    }
                }
            }*/
        }

        BusyIndicator {
            anchors.centerIn: listView
            size: BusyIndicatorSize.Large
            visible: listView.count == 0
            running: visible
        }
    }

    Component {
        id: headerComponent
        Item {
            id: componentItem
            width: parent.width
            height: header.height + searchPlaceholder.height

            DialogHeader {
                id: header
                title: numbers.length > 0
                       ? ((numbers.length == 1) ? qsTr("Sync contact", "Add contacts page title")
                                                : qsTr("Sync %n contacts", "Add contacts page title", numbers.length))
                       : qsTr("Select contacts", "Add contacts page title")
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

    Component {
        id: sectionDelegate
        SectionHeader {
            text: section
        }
    }

    Component {
        id: contactsDelegate

        Column {
            width: parent.width
            Repeater {
                id: internal
                width: parent.width
                property var effectiveIndecies: constructIndecies()
                function constructIndecies() {
                    var indecies = []
                    var effectiveNumbers = []
                    var numbers = person.phoneDetails
                    for (var i = 0; i < numbers.length; i++) {
                        var normalized = numbers[i].normalizedNumber
                        if (effectiveNumbers.indexOf(normalized) < 0) {
                            indecies.splice(0, 0, i)
                            effectiveNumbers.splice(0, 0, normalized)
                        }
                    }
                    return indecies
                }

                model: effectiveIndecies.length
                delegate: BackgroundItem {
                    id: innerItem
                    width: parent.width
                    height: Theme.itemSizeMedium
                    highlighted: down || checked
                    property bool checked: page.numbers.indexOf(number) != -1
                    property string number: person.phoneDetails[internal.effectiveIndecies[index]].normalizedNumber

                    // while nemo-qml-plugin-contacts bug not fixed
                    // https://github.com/nemomobile/nemo-qml-plugin-contacts/issues/103
                    function generateDisplayLabel() {
                        var displayLabel = ""

                        var nameStr1 = null
                        var nameStr2 = null
                        if (allContactsModel.displayLabelOrder == PeopleModel.LastNameFirst) {
                            nameStr1 = person.lastName
                            nameStr2 = person.firstName
                        } else {
                            nameStr1 = person.firstName
                            nameStr2 = person.lastName
                        }

                        if (nameStr1)
                            displayLabel += nameStr1

                        if (nameStr2) {
                            if (displayLabel.length > 0)
                                displayLabel += " "
                            displayLabel += nameStr2
                        }

                        if (displayLabel.length > 0) {
                            return displayLabel;
                        }

                        // Try to generate a label from the contact details, in our preferred order

                        for (var i=0; i<person.nicknameDetails.length; i++) {
                            if (person.nicknameDetails[i].nickname) {
                                return person.nicknameDetails[i].nickname
                            }
                        }

                        if (person.displayLabel)
                            return person.displayLabel

                        if (person.emailDetails)
                            return person.emailDetails.address

                        if (person.companyName)
                            return person.companyName

                        for (var i=0; person.phoneDetails.length; i++) {
                            if (person.phoneDetails[i].normalizedNumber) {
                                return person.phoneDetails[i].normalizedNumber
                            }
                        }

                        return qsTr("Unnamed contact");
                    }

                    onClicked: {
                        var vnumbers = page.numbers
                        var vnames = page.names
                        var vavatars = page.avatars
                        var exists = vnumbers.indexOf(number)
                        if (exists != -1) {
                            vnumbers.splice(exists, 1)
                            vnames.splice(exists, 1)
                            vavatars.splice(exists, 1)
                        }
                        else {
                            vnumbers.splice(0, 0, number)
                            vnames.splice(0, 0, displayLabel)
                            vavatars.splice(0, 0, person.avatarPath)
                        }
                        page.numbers = vnumbers
                        page.names = vnames
                        page.avatars = vavatars
                    }

                    Rectangle {
                        id: avaplaceholder
                        anchors {
                            left: parent.left
                            leftMargin: Theme.paddingLarge
                            verticalCenter: parent.verticalCenter
                        }

                        width: ava.width
                        height: ava.height
                        color: ava.status == Image.Ready ? "transparent" : "#40FFFFFF"

                        Image {
                            id: ava
                            width: Theme.itemSizeMedium
                            height: width
                            source: person.avatarPath
                            cache: true
                            asynchronous: true
                        }
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
                            text: innerItem.generateDisplayLabel()
                            color: innerItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                        }

                        Label {
                            width: parent.width
                            wrapMode: Text.NoWrap
                            elide: Text.ElideRight
                            font.pixelSize: Theme.fontSizeSmall
                            text: number
                            color: innerItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                        }
                    }
                }
            }
        }
    }
}
