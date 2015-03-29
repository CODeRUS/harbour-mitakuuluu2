import QtQuick 2.1
import Sailfish.Silica 1.0
import harbour.mitakuuluu2.client 1.0

Dialog {
    id: renewDialog
    objectName: "renewDialog"
    allowedOrientations: globalOrientation

    onAccepted: mitakuuluu.renewAccount()

    DialogHeader {
        acceptText: qsTr("Renew", "Renew account page title")
    }

    Label {
        anchors.fill: parent
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: qsTr("Your WhatsApp subscription expired.\nClick Renew to purchase one year of WhatsApp service.", "Renew account page description text")
        font.pixelSize: Theme.fontSizeLarge
        wrapMode: Text.Wrap
    }
}
