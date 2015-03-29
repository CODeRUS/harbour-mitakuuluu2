import QtQuick 2.1
import Sailfish.Silica 1.0
import harbour.mitakuuluu2.client 1.0

AvatarPickerCrop {
    id: page
    objectName: "avatarPicker"
    allowedOrientations: globalOrientation

    property string jid
    signal avatarSet(string avatarPath)
    function setAvatar(avatarPath) {
        page.avatarSet(avatarPath)
    }

    onAvatarSourceChanged: {
        var avatar = Mitakuuluu.saveAvatarForJid(page.jid, avatarSource)
        Mitakuuluu.setPicture(page.jid, avatar)
        page.avatarSet(avatar)
    }

    function _customSelectionHandler(model, index, selected) {
        model.updateSelected(index, selected)
        var selectedContentProperties = model.get(index)
        // Hardcoded path will be removed once get JB5266 fixed
        console.log("selected: " + selectedContentProperties.filePath)
        var target = page.targetDir + "/" + selectedContentProperties.filePath.split("/").pop()
        console.log("target: " + target)
        var avatarCrop = openAvatarCrop(selectedContentProperties.filePath, target, page.jid, pageStack.previousPage(page))
        avatarCrop.avatarSet.connect(page.setAvatar)
    }
}
