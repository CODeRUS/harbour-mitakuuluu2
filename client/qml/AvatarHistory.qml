import QtQuick 2.1
import Sailfish.Silica 1.0
import Sailfish.Gallery 1.0
import harbour.mitakuuluu2.client 1.0
import harbour.mitakuuluu2.filemodel 1.0

Page {
    id: page
    objectName: "avatarHistory"
    allowedOrientations: globalOrientation

    property string jid
    property string avatar
    property bool owner: false

    signal avatarSet(string avatarPath)
    function setAvatar(avatarPath) {
        page.avatarSet(avatarPath)
    }

    onStatusChanged: {
        if (status == PageStatus.Active) {
            filesourcemodel.showRecursive(["avatars"])
        }
    }

    Connections {
        target: Mitakuuluu

        onPictureUpdated: {
            if (pjid === page.jid && path.length > 0) {
                filesourcemodel.showRecursive(["avatars"])
            }
        }
    }

    FileSortModel {
        id: filemodel
        sorting: false
        fileModel: FileSourceModel {
            id: filesourcemodel
            filter: [jid + "-*"]
            showHidden: true
        }
    }

    SilicaFlickable {
        id: flick
        anchors.fill: parent
        contentHeight: content.height

        Column {
            id: content
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader { title: qsTr("Avatar") }

            IconItem {
                icon.source: "image://theme/icon-m-image"
                name: qsTr("Select picture")
                visible: owner
                onClicked: {
                    var avatarPicker = pageStack.replace(Qt.resolvedUrl("AvatarPicker.qml"), {"jid": page.jid})
                    avatarPicker.avatarSet.connect(page.setAvatar)
                }
            }

            IconItem {
                icon.source: "image://theme/icon-camera-shutter-release"
                name: qsTr("Take picture")
                visible: owner
                onClicked: {
                    var avatarPicker = pageStack.replace(Qt.resolvedUrl("CaptureAvatar.qml"), {"jid": page.jid})
                    avatarPicker.avatarSet.connect(page.setAvatar)
                }
            }

            IconItem {
                icon.source: "image://theme/icon-m-clear"
                name: qsTr("Remove avatar")
                visible: owner
                onClicked: {
                    page.setAvatar("")
                    Mitakuuluu.setPicture(page.jid, "")
                    pageStack.pop()
                }
            }

            SectionHeader {
                text: qsTr("History")
                visible: owner && avatarGrid.count > 0
            }

            ImageGridView {
                id: avatarGrid
                width: parent.width
                delegate: gridDelegate
                model: filemodel
                clip: true
                height: avatarGrid.contentHeight + (expandItem != null ? expandHeight : 0)
                interactive: false

                property alias contextMenu: contextMenuItem
                property Item expandItem: null
                property int expandIndex: -1
                property real expandHeight: contextMenu.height
                property int minOffsetIndex: expandItem != null
                                             ? expandItem.modelIndex + columnCount - (expandItem.modelIndex % columnCount)
                                             : 0

                unfocusHighlightEnabled: true
                forceUnfocusHighlight: expandHeight > 0

                ContextMenu {
                    id: contextMenuItem
                    x: parent !== null ? -parent.x : 0.0

                    property bool expanded: contextMenuItem._expanded
                    onExpandedChanged: {
                        if (expanded) {
                            var endPos = avatarGrid.y + avatarGrid.expandItem.y + avatarGrid.expandItem.height - flick.contentY
                            if (endPos > page.height) {
                                flick.contentY += (endPos - page.height)
                            }
                        }
                    }

                    MenuItem {
                        text: qsTr("Save to Gallery")
                        visible: avatarGrid.expandItem && avatarGrid.expandItem.inCache
                        onClicked: {
                            var path = Mitakuuluu.saveImage(avatarGrid.expandItem.source)
                            banner.notify(qsTr("Avatar saved to; %1").arg(path))
                        }
                    }

                    MenuItem {
                        objectName: "deleteItem"
                        visible: avatarGrid.expandItem && avatarGrid.expandItem.source != page.avatar
                        text: qsTr("Delete")
                        onClicked: avatarGrid.expandItem.remove()
                    }
                }
            }

            ViewPlaceholder {
                text: qsTr("Avatar history is empty")
                enabled: avatarGrid.count == 0
            }
        }

        VerticalScrollDecorator {}
    }

    Component {
        id: gridDelegate
        GalleryImage {
            id: item
            source: model.path
            size: GridView.view.cellSize
            height: isItemExpanded ? avatarGrid.contextMenu.height + GridView.view.cellSize : GridView.view.cellSize

            property bool isItemExpanded: avatarGrid.expandItem === item
            property int modelIndex: index
            property bool inCache: model.path.indexOf(".cache") > 0

            contentYOffset: index >= avatarGrid.minOffsetIndex ? avatarGrid.expandHeight : 0

            z: isItemExpanded ? 1000 : 1
            enabled: isItemExpanded || !avatarGrid.contextMenu.active

            GridView.onAdd: AddAnimation { target: item; duration: 150 }
            GridView.onRemove: SequentialAnimation {
                PropertyAction { target: item; property: "GridView.delayRemove"; value: true }
                NumberAnimation { target: item; properties: "opacity,scale"; to: 0; duration: 250; easing.type: Easing.InOutQuad }
                PropertyAction { target: item; property: "GridView.delayRemove"; value: false }
            }

            onPressAndHold: {
                avatarGrid.expandItem = item
                avatarGrid.expandIndex = index
                avatarGrid.contextMenu.show(item)
            }
            onClicked: {
                if (owner) {
                    console.log("set avatar from history: " + model.path)
                    page.setAvatar(model.path)
                    Mitakuuluu.setPicture(page.jid, model.path)
                    pageStack.pop()
                }
                else {
                    Qt.openUrlExternally(model.path)
                }
            }
            function remove() {
                var remorse = removalComponent.createObject(null)
                remorse.z = item.z + 1
                remorse.wrapMode = Text.Wrap
                remorse.horizontalAlignment = Text.AlignHCenter

                remorse.execute(remorseContainerComponent.createObject(item),
                                qsTr("Deleting avatar file"),
                                function() {
                                    filemodel.remove(avatarGrid.expandIndex)
                                    if (avatarGrid.expandIndex == 0) {
                                        page.setAvatar("")
                                        Mitakuuluu.setPicture(page.jid, "")
                                    }
                                })
            }
        }
    }

    Component {
        id: remorseContainerComponent
        Item {
            y: parent.contentYOffset
            width: parent.width
            height: parent.height
        }
    }

    Component {
        id: removalComponent
        RemorseItem {
            cancelText: qsTr("Cancel")
        }
    }
}
