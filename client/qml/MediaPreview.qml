import QtQuick 2.1
import Sailfish.Silica 1.0
import org.nemomobile.thumbnailer 1.0
import harbour.mitakuuluu2.client 1.0

Dialog {
    id: dialog
    objectName: "mediaPreview"
    allowedOrientations: globalOrientation

    property bool canRemove: false
    property string path: ""
    property string mediaTitle: ""
    property string jid: ""
    property string mimeType: ""

    readonly property int _imageRotation: _extension == "jpg" || _extension == "jpeg" ? Mitakuuluu.getExifRotation(path) : 0
    readonly property bool _transpose: (_imageRotation % 180) != 0
    readonly property string _extension: path.toLowerCase().split(".").pop()

    readonly property int _fullWidth: isPortrait ? Screen.width : Screen.height
    readonly property int _fullHeight: isPortrait ? Screen.height : Screen.width

    onRejected: {
        if (canRemove) {
            Mitakuuluu.rejectMediaCapture(dialog.path)
        }
        rejectCoverOperation()
    }

    onAccepted: {
        if (dialog.jid.length > 0) {
            Mitakuuluu.sendMedia([dialog.jid], dialog.path, dialog.mediaTitle)
        }
        else {
            proceedCaptureSend(dialog.path, dialog.mediaTitle)
        }
    }

    Loader {
        anchors.centerIn: dialog
        width: _fullWidth
        height: _fullHeight
        sourceComponent: mimeType.indexOf("image/") === 0 ? componentImagePreview : componentVideoPreview
    }

    DialogHeader {
        title: canRemove ? qsTr("Send capture") : qsTr("Send media")
    }

    Rectangle {
        anchors.fill: mediaTitleField
        color: Theme.rgba(Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity * 2)
    }

    TextField {
        id: mediaTitleField
        width: dialog.width
        anchors.bottom: dialog.bottom
        anchors.bottomMargin: - Theme.paddingLarge * 2
        placeholderText: qsTr("Add a caption")
        EnterKey.enabled: false
        color: Theme.highlightColor
        placeholderColor: Theme.highlightColor
        onTextChanged: {
            dialog.mediaTitle = text
        }
    }

    Component {
        id: componentImagePreview
        Image {
            fillMode: Image.PreserveAspectCrop
            source: "image://nemoThumbnail/" + path
            //horizontalAlignment: Image.AlignVCenter
            //verticalAlignment: Image.AlignVCenter
            smooth: true
            cache: false
            clip: false
            sourceSize.width: _transpose ? height : width
            sourceSize.height: _transpose ? width : height
        }
    }

    Component {
        id: componentVideoPreview
        Thumbnail {
            fillMode: Thumbnail.PreserveAspectCrop
            source: path
            sourceSize.width: width
            sourceSize.height: height
            clip: false
            smooth: true
            mimeType: dialog.mimeType
        }
    }
}
