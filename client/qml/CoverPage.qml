import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.mitakuuluu2.client 1.0

CoverBackground {
    id: root
    property bool registration: pageStack.currentPage.objectName === "registrationPage"

    Image {
        id: bgimg
        source: "../images/cover.png"
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        height: sourceSize.height * width / sourceSize.width
    }

    Label {
        id: wastatus
        text: Mitakuuluu.connectionString
        font.pixelSize: Theme.fontSizeLarge
        horizontalAlignment: Text.AlignHCenter
        anchors.left: root.left
        anchors.right: root.right
        anchors.top: parent.top
        anchors.margins: Theme.paddingLarge
        wrapMode: Text.WordWrap
        visible: !registration
    }

    Label {
        id: wacount
        text: registration ? qsTr("Registration", "Cover item label text")
                           : (Mitakuuluu.totalUnread > 1 ? (qsTr("Unread messages: %n", "", Mitakuuluu.totalUnread))
                                                         : (Mitakuuluu.totalUnread == 1 ? qsTr("One unread message", "Cover item label text")
                                                                                        : qsTr("No unread messages", "Cover item label text")))
        font.pixelSize: Theme.fontSizeMedium
        horizontalAlignment: Text.AlignHCenter
        anchors.left: root.left
        anchors.leftMargin: Theme.paddingSmall
        anchors.right: root.right
        anchors.rightMargin: Theme.paddingSmall
        anchors.bottom: parent.bottom
        anchors.bottomMargin: (registration ? (parent.height / 4.5) : (parent.height / 1.8)) - height
        wrapMode: Text.WordWrap
    }

    CoverActionList {
        enabled: !registration && !coverActionActive

        CoverAction {
            iconSource: coverIconLeft
            onTriggered: coverLeftClicked()
        }

        CoverAction {
            iconSource: coverIconRight
            onTriggered: coverRightClicked()
        }
    }
}
