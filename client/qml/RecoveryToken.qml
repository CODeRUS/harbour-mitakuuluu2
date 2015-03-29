import QtQuick 2.1
import Sailfish.Silica 1.0
import harbour.mitakuuluu2.client 1.0

Page {
    id: page
    objectName: "recoveryToken"

    SilicaFlickable {
        id: flick
        anchors.fill: parent
        contentHeight: content.height

        Column {
            id: content
            width: parent.width
            spacing: Theme.paddingSmall

            PageHeader {
                title: qsTr("Recovery token")
            }

            TextField {
                id: tokenField
                width: parent.width
                EnterKey.enabled: text.length > 0
                EnterKey.onClicked: {
                    Mitakuuluu.setRecoveryToken(text)
                }
            }
        }

        VerticalScrollDecorator {}
    }
}
