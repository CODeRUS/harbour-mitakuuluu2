import QtQuick 2.1
import Sailfish.Silica 1.0

MouseArea {
    id: root

    property alias iconSource: icon.source
    property bool down: pressed && containsMouse

    width: Theme.itemSizeMedium
    height: Theme.itemSizeMedium
    z: 1

    Behavior on rotation {
        NumberAnimation {
            duration: 500
            easing.type: Easing.InOutQuad
            properties: "rotation"
        }
    }

    Rectangle {
    	anchors.fill: root
	    radius: width / 2
	    color: root.down ? Theme.highlightColor : Theme.secondaryHighlightColor
    }

    Image {
        id: icon
        anchors.centerIn: parent
    }
}
