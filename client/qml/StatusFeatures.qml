import QtQuick 2.1
import Sailfish.Silica 1.0
import harbour.mitakuuluu2.client 1.0

Page {
    id: page
    objectName: "statusFeatures"
    allowedOrientations: globalOrientation

    property bool loading: false

    QtObject {
        id: serverFeatures

        property bool email: true
        property bool last: true
        property bool sync: true
        property bool chat: true
        property bool group: true
        property bool multimedia: true
        property bool online: true
        property bool profile: true
        property bool push: true
        property bool registration: true
        property bool status: true
        property bool broadcast: true
        property bool version: true
    }

    onStatusChanged: {
        if (status == PageStatus.Active) {
            page.loading = true
            Mitakuuluu.checkWhatsappStatus()
        }
    }

    Connections {
        target: Mitakuuluu
        onWhatsappStatusReply: {
            for (var key in features) {
                serverFeatures[key] = features[key].available
            }
            page.loading = false
        }
    }

    SilicaFlickable {
        id: flick
        anchors.fill: page
        contentHeight: content.height

        Column {
            id: content
            anchors {
                left: parent.left
                right: parent.right
                margins: Theme.paddingLarge
            }

            spacing: Theme.paddingMedium

            PageHeader { title: qsTr("System status") }

            Label { color: serverFeatures.email ? Theme.primaryColor : "red"; text: qsTr("Email: %1").arg(serverFeatures.email ? qsTr("available") : qsTr("unavailable")) }
            Label { color: serverFeatures.last ? Theme.primaryColor : "red"; text: qsTr("Last: %1").arg(serverFeatures.last ? qsTr("available") : qsTr("unavailable")) }
            Label { color: serverFeatures.sync ? Theme.primaryColor : "red"; text: qsTr("Sync: %1").arg(serverFeatures.sync ? qsTr("available") : qsTr("unavailable")) }
            Label { color: serverFeatures.chat ? Theme.primaryColor : "red"; text: qsTr("Chat: %1").arg(serverFeatures.chat ? qsTr("available") : qsTr("unavailable")) }
            Label { color: serverFeatures.group ? Theme.primaryColor : "red"; text: qsTr("Group: %1").arg(serverFeatures.group ? qsTr("available") : qsTr("unavailable")) }
            Label { color: serverFeatures.multimedia ? Theme.primaryColor : "red"; text: qsTr("Multimedia: %1").arg(serverFeatures.multimedia ? qsTr("available") : qsTr("unavailable")) }
            Label { color: serverFeatures.online ? Theme.primaryColor : "red"; text: qsTr("Online: %1").arg(serverFeatures.online ? qsTr("available") : qsTr("unavailable")) }
            Label { color: serverFeatures.profile ? Theme.primaryColor : "red"; text: qsTr("Profile: %1").arg(serverFeatures.profile ? qsTr("available") : qsTr("unavailable")) }
            Label { color: serverFeatures.push ? Theme.primaryColor : "red"; text: qsTr("Push: %1").arg(serverFeatures.push ? qsTr("available") : qsTr("unavailable")) }
            Label { color: serverFeatures.registration ? Theme.primaryColor : "red"; text: qsTr("Registration: %1").arg(serverFeatures.registration ? qsTr("available") : qsTr("unavailable")) }
            Label { color: serverFeatures.broadcast ? Theme.primaryColor : "red"; text: qsTr("Broadcast: %1").arg(serverFeatures.broadcast ? qsTr("available") : qsTr("unavailable")) }
            Label { color: serverFeatures.status ? Theme.primaryColor : "red"; text: qsTr("Status: %1").arg(serverFeatures.status ? qsTr("available") : qsTr("unavailable")) }
            Label { color: serverFeatures.version ? Theme.primaryColor : "red"; text: qsTr("Version: %1").arg(serverFeatures.version ? qsTr("available") : qsTr("unavailable")) }
        }

        VerticalScrollDecorator{}
    }

    BusyIndicator {
        size: BusyIndicatorSize.Large
        anchors.centerIn: parent
        visible: page.loading
        running: visible
    }
}
