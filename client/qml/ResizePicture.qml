import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.mitakuuluu2.client 1.0

Dialog {
    id: page
    objectName: "resizePicture"
    allowedOrientations: globalOrientation
    
    property string picture
    onPictureChanged: {
        pinch.rotate(Mitakuuluu.getExifRotation(picture))
    }

    property int maximumSize
    property int minimumSize
    property bool avatar: true
    property string jid
    
    property string filename
    
    signal selected(string path)

    forwardNavigation: !pinch.pressed
    backNavigation: !pinch.pressed

    onAccepted: {
        filename = Mitakuuluu.transformPicture(picture, jid, pinch.rectX, pinch.rectY, pinch.rectW, pinch.rectH, maximumSize, pinch.angle)    }

    DialogHeader {
        id: title
        title: qsTr("Resize picture", "Resize picture page title")
    }

    InteractionArea {
        id: pinch
        anchors.top: title.bottom
        width: page.width
        anchors.bottom: page.bottom
        avatar: page.avatar
        source: picture
        bucketMinSize: minimumSize
    }

    Rectangle {
        anchors.top: pinch.top
        anchors.right: parent.right
        anchors.margins: Theme.paddingMedium
        width: iconButton.width
        height: iconButton.height
        radius: width / 2
        color: iconButton.pressed ? "#40FFFFFF" : "#20FFFFFF"
        IconButton {
            id: iconButton
            icon.source: "image://theme/icon-m-refresh"
            highlighted: pressed
            onClicked: {
                pinch.rotate()
            }
        }
    }
}
