import QtQuick 2.1
import Sailfish.Silica 1.0
import harbour.mitakuuluu2.client 1.0

Capture {
    id: page
    objectName: "captureAvatar"

    property string jid

    property string targetDir: "/tmp"

    signal avatarSet(string avatarPath)
    function setAvatar(avatarPath) {
    	page.avatarSet(avatarPath)
    }

    function _captureHandler() {
        var target = page.targetDir + "/" + page.imagePath.split("/").pop()
        console.log("starting handler: " + target)
        var avatarCrop = openAvatarCrop(page.imagePath, target, page.jid, pageStack.previousPage(page))
        avatarCrop.avatarSet.connect(page.setAvatar)
    }
} 
