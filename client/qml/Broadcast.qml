import QtQuick 2.1
import Sailfish.Silica 1.0

Page {
    id: page
    objectName: "broadcastPage"
    allowedOrientations: globalOrientation

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height

        Column {
            id: content
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader { title: qsTr("Broadcast", "Broadcast page title") }

            IconItem {
                width: parent.width
                icon.source: "image://theme/icon-m-message"
                name: qsTr("Text", "Broadcast page text message item")
                onClicked: {
                    pageStack.pop(undefined, PageStackAction.Immediate)
                    typeAndSend()
                }
            }

            IconItem {
                width: parent.width
                icon.source: "image://theme/icon-m-media"
                name: qsTr("Media", "Broadcast page media item")
                onClicked: {
                    pageStack.pop(undefined, PageStackAction.Immediate)
                    getMediaAndSend()
                }
            }

            IconItem {
                width: parent.width
                icon.source: "image://theme/icon-m-gps"
                name: qsTr("Location", "Broadcast page location item")
                onClicked: {
                    pageStack.pop(undefined, PageStackAction.Immediate)
                    locateAndSend()
                }
            }

            IconItem {
                width: parent.width
                icon.source: "image://theme/icon-m-mic"
                name: qsTr("Voice", "Broadcast page voice item")
                onClicked: {
                    pageStack.pop(undefined, PageStackAction.Immediate)
                    recordAndSend()
                }
            }

            IconItem {
                width: parent.width
                icon.source: "image://theme/icon-m-camera"
                name: qsTr("Camera", "Broadcast page camera item")
                onClicked: {
                    pageStack.pop(undefined, PageStackAction.Immediate)
                    captureAndSend()
                }
            }
        }
    }
}
