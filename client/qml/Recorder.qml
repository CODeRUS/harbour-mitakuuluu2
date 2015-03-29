import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.mitakuuluu2.client 1.0
import QtMultimedia 5.0

Dialog {
    id: page
    objectName: "recorder"
    allowedOrientations: globalOrientation

    canAccept: false

    function accept() {
        if (canAccept) {
            _dialogDone(DialogResult.Accepted)
        }
        else {
            negativeFeedback()
        }

        // Attempt to navigate even if it will fail, so that feedback can be generated
        pageStack.navigateForward()
    }

    property bool cantAcceptReally: pageStack._forwardFlickDifference > 0 && pageStack._preventForwardNavigation
    onCantAcceptReallyChanged: {
        if (cantAcceptReally)
            negativeFeedback()
    }

    function negativeFeedback() {
        banner.notify(qsTr("Recorder is not ready!", "Recorder page cant accept feedback"))
    }

    property bool broadcastMode: false
    property AudioRecorder recorder
    property Audio player

    property string savePath: ""

    onAccepted: {
        console.log("accepting: " + recorder.path)
        savePath = Mitakuuluu.saveVoice(recorder.path)
        destroyComponents()
    }

    onRejected: {
        Mitakuuluu.rejectMediaCapture(recorder.path)
        destroyComponents()
    }

    function destroyComponents() {
        if (recorder) {
            recorder.destroy()
            recorder = null
        }
        if (player) {
            player.destroy()
            player = null
        }
    }

    onStatusChanged: {
        if (status == PageStatus.Inactive) {
        }
        else if (status == PageStatus.Active) {
            recorder = recorderComponent.createObject(null)
            player = playerComponent.createObject(null)
        }
    }

    DialogHeader {
        id: header
        title: qsTr("Voice note", "Voice recorder page title")
    }

    ProgressBar {
        id: progress
        width: parent.width
        minimumValue: 0
        maximumValue: 1
        //label: qsTr("Duration")

        anchors.bottom: parent.bottom

        Label {
            id: minLabel
            anchors {
                left: parent.left
                leftMargin: Theme.paddingLarge
                bottom: parent.bottom
            }
            text: Format.formatDuration(progress.minimumValue / 1000, Format.DurationShort)
        }

        Label {
            id: maxLabel
            anchors {
                right: parent.right
                rightMargin: Theme.paddingLarge
                bottom: parent.bottom
            }
            text: Format.formatDuration(progress.maximumValue / 1000, Format.DurationShort)
        }
    }

    Rectangle {
        id: recBtn
        anchors.centerIn: parent
        width: parent.width - (Theme.paddingLarge * 2)
        height: width
        radius: width / 2
        color: recorder.state == AudioRecorder.RecordingState ? Theme.rgba("#FF4040", 0.6) : Theme.rgba("red", 0.8)
        border.width: mAreaRec.pressed ? Theme.paddingSmall : (Theme.paddingSmall / 2)
        border.color: mAreaRec.pressed ? Theme.highlightColor : Theme.primaryColor
        opacity: player.playbackState != Audio.PlayingState ? 1.0 : 0.2

        Image {
            anchors.centerIn: parent
            width: parent.width / 3
            height: width
            cache: true
            asynchronous: true
            source: "image://theme/icon-" + (recorder.state == AudioRecorder.RecordingState ? "camera-stop" : "cover-unmute")
        }

        MouseArea {
            id: mAreaRec
            anchors.fill: parent
            enabled: player.playbackState != Audio.PlayingState
            onClicked: {
                if (recorder.state == AudioRecorder.RecordingState) {
                    progress.indeterminate = false
                    recorder.stop()
                }
                else {
                    progress.maximumValue = 120000
                    progress.indeterminate = true
                    recorder.record()
                }
            }
        }
    }

    Rectangle {
        id: playBtn
        anchors {
            right: recBtn.right
            bottom: recBtn.bottom
        }
        width: recBtn.width / 6
        height: width
        radius: width / 2
        color: player.playbackState == Audio.PlayingState ? Theme.rgba("#00FF40", 0.6) : Theme.rgba("green", 0.8)
        border.width: mAreaPlay.pressed ? Theme.paddingSmall : (Theme.paddingSmall / 2)
        border.color: mAreaPlay.pressed ? Theme.highlightColor : Theme.primaryColor
        opacity: recorder.state == AudioRecorder.StoppedState ? 1.0 : 0.2

        Image {
            anchors.centerIn: parent
            width: parent.width / 2
            height: width
            cache: true
            asynchronous: true
            source: "image://theme/icon-" + (player.playbackState == Audio.PlayingState ? "camera-stop" : "cover-play")
        }

        MouseArea {
            id: mAreaPlay
            anchors.fill: parent
            enabled: recorder.state == AudioRecorder.StoppedState
            onClicked: {
                if (player.playbackState == Audio.PlayingState) {
                    player.stop()
                }
                else {
                    progress.indeterminate = false
                    player.source = recorder.path
                    //player.seek(0)
                    progress.maximumValue = player.duration
                    progress.value = 0
                    player.play()
                }
            }
        }
    }

    Component {
        id: recorderComponent
        AudioRecorder {
            /*onPathChanged: {
                console.log("recorder new path: " + path)
            }
            onStatusChanged: {
                console.log("recorder status: " + status)
            }*/
            onStateChanged: {
                //console.log("recorder state: " + state)
                if (state == AudioRecorder.StoppedState) {
                    page.canAccept = player.playbackState == Audio.StoppedState
                    player.source = recorder.path
                }
            }
            /*onErrorOccured: {
                console.log("recorder error: " + error)
            }
            onAvailabilityChanged: {
                console.log("recorder availability: " + availability)
            }*/
            onDurationChanged: {
                //console.log("recorder duration: " + duration)
                progress.value = duration
                progress.label = Format.formatDuration(duration / 1000, Format.DurationShort)
            }
            /*Component.onCompleted: {
                console.log("location: " + recorder.path)
            }*/
        }
    }

    Component {
        id: playerComponent
        Audio {
            onPlaybackStateChanged: {
                page.canAccept = player.playbackState == Audio.StoppedState && recorder.state == AudioRecorder.StoppedState
            }
            onPositionChanged: {
                //console.log("playback position: " + position)
                progress.value = position
                progress.label = Format.formatDuration(position / 1000, Format.DurationShort)
            }
            onDurationChanged: {
                //console.log("playback duration: " + duration)
                progress.maximumValue = duration
            }
            /*onSourceChanged: {
                console.log("playback source: " + source)
            }
            onFilesizeChanged: {
                console.log("playback filesize: " + filesize)
            }*/
        }
    }
}
