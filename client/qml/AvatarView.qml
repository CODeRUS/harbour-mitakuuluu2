import QtQuick 2.1
import Sailfish.Silica 1.0
import harbour.mitakuuluu2.client 1.0

Rectangle {
    id: avatarView
    anchors.fill: parent
    color: "#A0000000"
    opacity: 0.0
    Behavior on opacity {
        FadeAnimation {}
    }
    function show(path) {
        console.log("show: " + path)
        avaView.source = path
        avatarView.opacity = 1.0
        page.backNavigation = false
    }
    function hide() {
        avaView.source = ""
        avatarView.opacity = 0.0
        page.backNavigation = true
    }
    Image {
        id: avaView
        anchors.centerIn: parent
        asynchronous: true
        cache: false
    }
    MouseArea {
        enabled: avatarView.opacity > 0
        anchors.fill: parent
        onClicked: avatarView.hide()
    }
    IconButton {
        anchors {
            right: parent.right
            top: parent.top
        }
        icon.source: "image://theme/icon-m-download"
        visible: avaView.status == Image.Ready
        onClicked: {
            var fname = Mitakuuluu.saveImage(avaView.source)
            if (fname.length > 0) {
                banner.notify(qsTr("Image saved as %1", "Avatar view image saved to gallery banner").arg(fname))
            }
        }
    }
} 
