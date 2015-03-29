import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0

BackgroundItem {
    id: root

    property alias name: label.text
    property alias icon: image

    width: parent.width
    implicitHeight: Theme.itemSizeSmall

    Row {
        id: row
        x: Theme.paddingLarge
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.paddingMedium

        Image {
            id: image

            fillMode: Image.PreserveAspectCrop

            property string _highlightSource
            property color highlightColor: Theme.highlightColor

            function updateHighlightSource() {
                if (state === "") {
                    if (source != "") {
                        var tmpSource = image.source.toString()
                        var index = tmpSource.lastIndexOf("?")
                        if (index !== -1) {
                            tmpSource = tmpSource.substring(0, index)
                        }
                        _highlightSource = tmpSource + "?" + highlightColor
                    } else {
                        _highlightSource = ""
                    }
                }
            }

            onHighlightColorChanged: updateHighlightSource()
            onSourceChanged: updateHighlightSource()
            Component.onCompleted: updateHighlightSource()

            states: State {
                when: root.highlighted && image._highlightSource != ""
                PropertyChanges {
                    target: image
                    source: image._highlightSource
                }
            }
        }
        Label {
            id: label
            anchors.verticalCenter: parent.verticalCenter
            color: root.highlighted ? Theme.highlightColor : Theme.primaryColor
        }
    }
} 
