import QtQuick 2.1
import Sailfish.Silica 1.0
import harbour.mitakuuluu2.client 1.0

Page {
    id: page
    objectName: "searchMessage"
    allowedOrientations: globalOrientation

    property string jid
    property bool isGroup: jid.indexOf("-") > 0

    onStatusChanged: {
        if (page.status == PageStatus.Active) {
            searchField.forceActiveFocus()
        }
    }

    PageHeader {
        id: pageHeader
        title: qsTr("Search message")
    }

    SearchField {
        id: searchField
        anchors.top: pageHeader.bottom
        width: parent.width
        placeholderText: qsTr("message text")
        onTextChanged: {
            filterModel.filter = text
        }
    }

    SilicaListView {
        id: conversationView
        anchors {
            top: searchField.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        clip: true
        cacheBuffer: height * 2
        pressDelay: 0
        spacing: Theme.paddingMedium
        interactive: contentHeight > height
        currentIndex: -1
        verticalLayoutDirection: ListView.BottomToTop
        model: filterModel
        delegate: Component {
            id: delegateComponent
            Loader {
                width: parent.width
                asynchronous: false
                source: Qt.resolvedUrl(settings.conversationTheme)
            }
        }
    }

    ConversationFilterModel {
        id: filterModel
        jid: page.jid
    }
}
