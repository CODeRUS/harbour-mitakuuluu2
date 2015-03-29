import QtQuick 2.1
import Sailfish.Silica 1.0

Dialog {
    id: page
    objectName: "messageComposer"
    allowedOrientations: globalOrientation

    property string message

    canAccept: textArea.text.trim().length > 0

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
        textArea.forceActiveFocus()
    }

    onAccepted: {
        page.message = textArea.text.trim()
    }

    onStatusChanged: {
        if (page.status == DialogStatus.Opened) {
            textArea.forceActiveFocus()
        }
    }

    DialogHeader {
        id: header
        title: qsTr("Text message", "Broadcast text page title")
    }

    TextArea {
        id: textArea
        errorHighlight: text.length == 0
        anchors {
            top: header.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
    }
}
