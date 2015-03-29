import QtQuick 2.1
import Sailfish.Silica 1.0
import harbour.mitakuuluu2.client 1.0
import QtMultimedia 5.0
import com.jolla.camera 1.0
import org.nemomobile.time 1.0
import QtSensors 5.1

Page {
    id: page
    objectName: "capture"

    allowedOrientations: Orientation.Landscape

    //canNavigateForward: canAccept
    //canAccept: false

    property string imagePath: ""
    property bool broadcastMode: true
    property string jid: ""

    signal captured

    property alias cameraState: camera.cameraState

    property int _recordingDuration: ((clock.enabled ? clock.time : page._endTime) - page._startTime) / 1000
    property var _startTime: new Date()
    property var _endTime: _startTime

    property bool _complete
    property bool _unload

    function _captureHandler() {
        camera.cameraState = Camera.UnloadedState
        console.log("Capture saved to", imagePath)
        //page.canAccept = true
        pageStack.replace(Qt.resolvedUrl("MediaPreview.qml"), {"canRemove": true,
                                                               "path": imagePath,
                                                               "jid": page.jid,
                                                               "mimeType": camera.captureMode == Camera.CaptureStillImage ? "image/jpeg" : "video/x-matroska"})
    }

    onStatusChanged: {
        if (status == PageStatus.Inactive) {
            if (camera.cameraState != Camera.UnloadedState) {
                console.log("deactivating camera")
                camera.cameraState = Camera.UnloadedState
            }
            rejectCoverOperation()
        }
        //else if (status == PageStatus.Active && !canAccept) {
        //}
    }

    //onRejected: {
    //    console.log("capture rejected")
    //    Mitakuuluu.rejectMediaCapture(imagePath)
    //}

    Component.onCompleted: {
        Mitakuuluu.setCamera(camera)
        page._complete = true
    }

    Component.onDestruction: {
        if (camera.cameraState != Camera.UnloadedState) {
            console.log("camera destruction")
            camera.cameraState = Camera.UnloadedState
        }
    }

    function reload() {
        if (page._complete) {
            page._unload = true;
        }
    }

    Timer {
        id: reloadTimer
        interval: 100
        running: page._unload && camera.cameraStatus == Camera.UnloadedStatus
        onTriggered: {
            page._unload = false
        }
    }

    VideoOutput {
        id: mPreview
        x: 0
        y: 0
        z: -1
        width: page.width
        height: page.height
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
        orientation: page.orientation == Orientation.Portrait ? 0 : 90
        //visible: !page.canAccept
        source: camera
        property bool mirror: extensions.device == "secondary"
    }

    Camera {
        id: camera

        cameraState: page._complete && !page._unload
                    ? Camera.ActiveState
                    : Camera.UnloadedState

        captureMode: Camera.CaptureStillImage
        onCaptureModeChanged: reload()

        focus {
            focusMode: Camera.FocusContinuous
            focusPointMode: Camera.FocusPointAuto
        }
        flash.mode: Camera.FlashAuto

        imageCapture {
            resolution: extensions.viewfinderResolution

            onImageCaptured:{
            }

            // Called when the image is saved.
            onImageSaved: {
                camera.cameraState = Camera.UnloadedState
                imagePath = path
                _captureHandler()
            }

            // Called when a capture fails for some reason.
            onCaptureFailed: {
                console.log("Capture failed")
            }
        }

        videoRecorder{
            resolution: extensions.viewfinderResolution

            audioSampleRate: 48000
            audioBitRate: 96
            audioChannels: 1
            audioCodec: "audio/mpeg, mpegversion=(int)4"

            frameRate: 30
            videoCodec: "video/x-h264"
            mediaContainer: "video/x-matroska"

            onRecorderStateChanged: {
                if (camera.videoRecorder.recorderState == CameraRecorder.StoppedState) {
                    console.log("saved to: " + camera.videoRecorder.outputLocation)
                }
            }
        }

        // This will tell us when focus lock is gained.
        onLockStatusChanged: {
            if (lockStatus == Camera.Locked) {
                console.log("locked")
                if (shutter.autoMode)
                    camera.imageCapture.capture()
            }
        }

        function _finishRecording() {
            console.log("recording state: " + videoRecorder.recorderState)
            if (videoRecorder.recorderState == CameraRecorder.StoppedState) {
                console.log("finish recordig")
                videoRecorder.recorderStateChanged.disconnect(_finishRecording)
                camera.cameraState = Camera.UnloadedState
                imagePath = videoRecorder.outputLocation
                _captureHandler()
            }
        }
    }

    CameraExtensions {
        id: extensions
        camera: camera

        device: "primary"
        onDeviceChanged: reload()

        viewfinderResolution: "1280x720"


        manufacturer: "Jolla"
        model: "Jolla"

        rotation: sensor.rotationAngle
    }



    CircleButton {
        id: cameraModeButton

        anchors.left: parent.left
        anchors.top: page.top
        anchors.topMargin: Theme.itemSizeMedium
        anchors.margins: Theme.paddingSmall
        //visible: !page.canAccept
        rotation: sensor.rotationAngle - 90

        iconSource: camera.captureMode == Camera.CaptureStillImage ? "image://theme/icon-camera-camera-mode"
                                                                   : "image://theme/icon-camera-video"

        onClicked: {
            if (camera.captureMode == Camera.CaptureStillImage) {
                camera.captureMode = Camera.CaptureVideo
            }
            else {
                camera.captureMode = Camera.CaptureStillImage
            }
        }
    }

    CircleButton {
        id: cameraSourceButton

        anchors.left: parent.left
        anchors.top: cameraModeButton.bottom
        anchors.margins: Theme.paddingSmall
        //visible: !page.canAccept
        rotation: sensor.rotationAngle - 90

        iconSource: "image://theme/icon-camera-front-camera"

        onClicked: {
            extensions.viewfinderResolution = "1280x720"
            if (extensions.device == "primary") {
                extensions.device = "secondary"
            }
            else {
                extensions.device = "primary"
            }
        }
    }

    CircleButton {
        id: cameraQualityButton
        property bool hdQuality: true

        anchors.left: parent.left
        anchors.top: cameraSourceButton.bottom
        anchors.margins: Theme.paddingSmall
        visible: camera.captureMode == Camera.CaptureVideo
        rotation: sensor.rotationAngle - 90

        Label {
            anchors.centerIn: parent
            text: cameraQualityButton.hdQuality ? "HD" : "VGA"
        }

        onClicked: {
            if (hdQuality) {
                extensions.viewfinderResolution = "640x480"
            }
            else {
                extensions.viewfinderResolution = "1280x720"
            }
            hdQuality = !hdQuality
            reload()
        }
    }

    Item {
        anchors.right: parent.right
        anchors.top: page.top
        anchors.topMargin: Theme.itemSizeMedium
        anchors.margins: Theme.paddingSmall
        width: timerLabel.implicitWidth + (2 * Theme.paddingMedium)
        height: timerLabel.implicitWidth + (2 * Theme.paddingMedium)
        visible: camera.captureMode == Camera.CaptureVideo
        rotation: sensor.rotationAngle - 90

        Behavior on rotation {
            NumberAnimation {
                duration: 500
                easing.type: Easing.InOutQuad
                properties: "rotation"
            }
        }

        Rectangle {
            radius: Theme.paddingSmall / 2
            anchors.centerIn: parent
            width: timerLabel.implicitWidth + (2 * Theme.paddingMedium)
            height: timerLabel.implicitHeight + (2 * Theme.paddingSmall)
            color: Theme.highlightBackgroundColor
            opacity: 0.6
        }
        Label {
            id: timerLabel

            anchors.centerIn: parent

            text: Format.formatDuration(
                      page._recordingDuration,
                      page._recordingDuration >= 3600 ? Formatter.DurationLong : Formatter.DurationShort)
            font.pixelSize: Theme.fontSizeMedium

        }

        WallClock {
            id: clock
            updateFrequency: WallClock.Second
            enabled: camera.videoRecorder.recorderState == CameraRecorder.RecordingState
            onEnabledChanged: {
                if (enabled) {
                    page._startTime = clock.time
                    page._endTime = page._startTime
                } else {
                    page._endTime = page._startTime
                }
            }
        }
    }

    CircleButton {
        id: flashButton

        anchors.top: page.top
        anchors.topMargin: Theme.itemSizeMedium
        anchors.right: parent.right
        anchors.margins: Theme.paddingSmall
        visible: camera.captureMode == Camera.CaptureStillImage
        rotation: sensor.rotationAngle - 90

        iconSource: flashModeIcon(camera.flash.mode)

        function flashModeIcon(mode) {
            switch (mode) {
            case Camera.FlashAuto:
                return "image://theme/icon-camera-flash-automatic"
            case Camera.FlashOff:
                return "image://theme/icon-camera-flash-off"
            default:
                return "image://theme/icon-camera-flash-on"
            }
        }

        function nextFlashMode(mode) {
            switch (mode) {
            case Camera.FlashAuto:
                return Camera.FlashOff
            case Camera.FlashOff:
                return Camera.FlashOn
            case Camera.FlashOn:
                return Camera.FlashAuto
            default:
                return Camera.FlashOff
            }
        }

        onClicked: camera.flash.mode = flashButton.nextFlashMode(camera.flash.mode)
    }

    CircleButton {
        id: shutter
        property bool autoMode: false

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Theme.paddingSmall
        //visible: !page.canAccept
        rotation: sensor.rotationAngle - 90

        iconSource: camera.captureMode == Camera.CaptureStillImage ? "image://theme/icon-camera-shutter-release"
                                                                   : (camera.videoRecorder.recorderState == CameraRecorder.StoppedState ? "image://theme/icon-camera-record"
                                                                                                                                        : "image://theme/icon-camera-stop")

        onPressed: {
            if (camera.captureMode == Camera.CaptureStillImage) {
                console.log("shutter pressed")
                shutter.autoMode = false
                if (camera.captureMode == Camera.CaptureStillImage
                        && camera.lockStatus == Camera.Unlocked) {
                    camera.searchAndLock()
                }
            }
        }
        onReleased: {
            if (camera.captureMode == Camera.CaptureStillImage) {
                console.log("shutter released")
                shutter.autoMode = false
                if (camera.lockStatus == Camera.Locked) {
                    extensions.captureTime = new Date()
                    camera.imageCapture.capture()
                }
            }
        }
        onClicked: {
            if (camera.videoRecorder.recorderState == CameraRecorder.RecordingState) {
                camera.videoRecorder.stop()
            } else if (camera.captureMode == Camera.CaptureStillImage) {

                console.log("shutter clicked")
                shutter.autoMode = true

                extensions.captureTime = new Date()

                camera.imageCapture.capture()
            } else {
                extensions.captureTime = new Date()
                camera.videoRecorder.record()
                if (camera.videoRecorder.recorderState == CameraRecorder.RecordingState) {
                    camera.videoRecorder.recorderStateChanged.connect(camera._finishRecording)
                }
            }
        }
    }

    Image {
        id: wrongOrientationPhone
        source: "image://theme/icon-push-display-off?" + Theme.highlightColor
        anchors.centerIn: parent
        rotation: rotatePhoneTimer.showmode > 1 ? 0 : rotatePhoneTimer.needAngle //90
        visible: rotatePhoneTimer.running

        Behavior on rotation {
            NumberAnimation {
                duration: 1000
                easing.type: Easing.InOutQuad
                properties: "rotation"
            }
        }
    }

    Image {
        id: wrongOrientationCircle
        source: "image://theme/icon-push-restart?" + (rotation == 0 ? "#00FF00" : "#FF0000")
        anchors.centerIn: parent
        rotation: rotatePhoneTimer.showmode > 1 ? 0 : rotatePhoneTimer.needAngle //90
        visible: rotatePhoneTimer.running

        Behavior on rotation {
            NumberAnimation {
                duration: 1000
                easing.type: Easing.InOutQuad
                properties: "rotation"
            }
        }
    }

    Image {
        source: "image://theme/icon-header-" + (wrongOrientationCircle.rotation == 0 ? "accept?#00FF00" : "cancel?#FF0000")
        anchors.centerIn: parent
        visible: rotatePhoneTimer.running
        rotation: sensor.rotationAngle - rotatePhoneTimer.needAngle //90
    }

    Timer {
        id: rotatePhoneTimer
        property int showmode: 0
        interval: 1000
        running: camera.captureMode == Camera.CaptureVideo && sensor.rotationAngle != needAngle
        property int needAngle: extensions.device == "primary" ? 90 : 180
        repeat: true
        onTriggered: {
            showmode++
            if (showmode == 4)
                showmode = 0
        }
    }

    OrientationSensor {
        id: sensor
        active: true
        property int rotationAngle: reading.orientation ? _getOrientation(reading.orientation) : 0
        function _getOrientation(value) {
            switch (value) {
            case 1:
                return 0
            case 2:
                return 180
            case 3:
                return 270
            default:
                return 90
            }
        }
    }

    /*Rectangle {
        anchors.fill: header
        z: 1
        color: Theme.rgba(Theme.highlightColor, 0.2)
    }*/

    /*DialogHeader {
        id: header
        title: page.canAccept ? qsTr("Send", "Capture page send title")
                              : qsTr("Camera", "Capture page default title")
    }*/
}
