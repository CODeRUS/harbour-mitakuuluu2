import QtQuick 2.1
import Sailfish.Silica 1.0
import Sailfish.Email 1.1
import harbour.mitakuuluu2.client 1.0

EmailComposerPage {
    id: sharePage
    objectName: "sendLogs"
    allowedOrientations: globalOrientation

    emailTo: "coderusinbox@gmail.com"
    emailSubject: "Mitakuuluu v" + Mitakuuluu.version + " bug"
    emailBody: "Please enter bug description here. In english. Step-by-step:\n\n1. Started Mitakuuluu at {time}\n2. Did something at {time}\n3. Expected some behaviour\n4. Got wrong result at {time}\n\nMessages with this line will be deleted without checking."

    Component.onCompleted: {
        if (Mitakuuluu.compressLogs()) {
            attachmentsModel.append({"url": 'file:///tmp/mitakuuluu2log.zip', "title": "mitakuuluu2log.zip", "mimeType": "application/x-zip-compressed"})
        }
    }
}
