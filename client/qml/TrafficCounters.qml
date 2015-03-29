import QtQuick 2.1
import Sailfish.Silica 1.0
import harbour.mitakuuluu2.client 1.0
import "Utilities.js" as Utilities

Page {
    id: page
    objectName: "settingsCounter"
    allowedOrientations: globalOrientation

    onStatusChanged: {
        if (status == PageStatus.Inactive) {
        }
        else if (status == PageStatus.Active) {
            Mitakuuluu.getNetworkUsage()
        }
    }

    Connections {
        target: Mitakuuluu
        onNetworkUsage: {
            console.log("networkUsage received")
            msgRecv.text = qsTr("Messages received: %1").arg(networkUsage[0])
            msgSent.text = qsTr("Messages sent: %1").arg(networkUsage[1])
            msgRecvBytes.text = qsTr("Messages bytes received: %1").arg(Format.formatFileSize(networkUsage[2], 2))
            msgSentBytes.text = qsTr("Messages bytes sent: %1").arg(Format.formatFileSize(networkUsage[3], 2))
            imgRecv.text = qsTr("Image bytes received: %1").arg(Format.formatFileSize(networkUsage[4], 2))
            imgSent.text = qsTr("Image bytes sent: %1").arg(Format.formatFileSize(networkUsage[5], 2))
            videoRecv.text = qsTr("Video bytes received: %1").arg(Format.formatFileSize(networkUsage[6], 2))
            videoSent.text = qsTr("Video bytes sent: %1").arg(Format.formatFileSize(networkUsage[7], 2))
            audioRecv.text = qsTr("Audio bytes received: %1").arg(Format.formatFileSize(networkUsage[8], 2))
            audioSent.text = qsTr("Audio bytes sent: %1").arg(Format.formatFileSize(networkUsage[9], 2))
            profileRecv.text = qsTr("Profile bytes received: %1").arg(Format.formatFileSize(networkUsage[10], 2))
            profileSent.text = qsTr("Profile bytes sent: %1").arg(Format.formatFileSize(networkUsage[11], 2))
            //syncRecv.text = qsTr("Sync bytes received: %1").arg(Format.formatFileSize(networkUsage[12], 2))
            //syncSent.text = qsTr("Sync bytes sent: %1").arg(Format.formatFileSize(networkUsage[13], 2))
            protocolRecv.text = qsTr("Protocol bytes received: %1").arg(Format.formatFileSize(networkUsage[14], 2))
            protocolSent.text = qsTr("Protocol bytes sent: %1").arg(Format.formatFileSize(networkUsage[15], 2))
            totalRecv.text = qsTr("Total bytes received: %1").arg(Format.formatFileSize(networkUsage[16], 2))
            totalSent.text = qsTr("Total bytes sent: %1").arg(Format.formatFileSize(networkUsage[17], 2))
        }
    }

    SilicaFlickable {
        id: flick
        anchors.fill: page

        clip: true

        contentHeight: content.height

        PullDownMenu {
            MenuItem {
                text: qsTr("Reset counters")
                onClicked: {
                    Mitakuuluu.resetNetworkUsage()
                }
            }
        }

        Column {
            id: content
            spacing: Theme.paddingMedium
            anchors {
                left: parent.left
                leftMargin: Theme.paddingLarge
                right: parent.right
                rightMargin: Theme.paddingLarge
            }

            PageHeader {
                id: header
                title: qsTr("Data counters")
            }

            SectionHeader {
                text: qsTr("Messages")
            }

            Label {
                id: msgSent
                width: parent.width
            }

            Label {
                id: msgRecv
                width: parent.width
            }

            SectionHeader {
                text: qsTr("Received data")
            }

            Label {
                id: totalRecv
                width: parent.width
            }

            Label {
                id: msgRecvBytes
                width: parent.width
            }

            Label {
                id: imgRecv
                width: parent.width
            }

            Label {
                id: videoRecv
                width: parent.width
            }

            Label {
                id: audioRecv
                width: parent.width
            }

            Label {
                id: profileRecv
                width: parent.width
            }

            /*Label {
                id: syncRecv
                width: parent.width
            }*/

            Label {
                id: protocolRecv
                width: parent.width
            }

            SectionHeader {
                text: qsTr("Sent data")
            }

            Label {
                id: totalSent
                width: parent.width
            }

            Label {
                id: msgSentBytes
                width: parent.width
            }

            Label {
                id: imgSent
                width: parent.width
            }

            Label {
                id: videoSent
                width: parent.width
            }

            Label {
                id: audioSent
                width: parent.width
            }

            Label {
                id: profileSent
                width: parent.width
            }

            /*Label {
                id: syncSent
                width: parent.width
            }*/

            Label {
                id: protocolSent
                width: parent.width
            }
        }

        VerticalScrollDecorator {}
    }
}
