import QtQuick 2.1
import Sailfish.Silica 1.0
import harbour.mitakuuluu2.client 1.0

Page {
    id: page
    objectName: "paymentsPage"
    allowedOrientations: globalOrientation

    SilicaFlickable {
        id: flick
        anchors.fill: parent

        PageHeader {
            id: header
            title: qsTr("Payment", "Payment page title")
        }

        Column {
            anchors.top: header.bottom
            width: parent.width
            spacing: Theme.paddingMedium

            ComboBox {
                id: period
                width: parent.width
                label: qsTr("Subscription period:", "Subscription period text")
                menu: ContextMenu {
                    MenuItem {
                        text: qsTr("1 year ($0.99)", "1 year subscription text")
                    }
                    MenuItem {
                        text: qsTr("3 years ($2.67) *10% off", "3 years subscription text")
                    }
                    MenuItem {
                        text: qsTr("5 years ($3.71) *25% off", "5 years subscription text")
                    }
                }
                Component.onCompleted: {
                    currentIndex = 0
                }
            }

            Label {
                anchors {
                    left: parent.left
                    leftMargin: Theme.paddingLarge
                    right: parent.right
                }
                wrapMode: Text.Wrap
                text: qsTr("Select preferred payment method to purchase WhatsApp service for: +%1", "Payment method text").arg(Mitakuuluu.myJid.split("@")[0])
            }

            BackgroundItem {
            	width: parent.width
            	height: googlewallet.height
                onClicked: {
                    Mitakuuluu.renewAccount("google", period.currentIndex == 0 ? 1 : (period.currentIndex == 1 ? 3 : 5))
                }
	            Image {
	            	id: googlewallet
	                anchors.horizontalCenter: parent.horizontalCenter
	                source: "../images/googlewallet.png"
	                cache: true
	                asynchronous: true
	            }
            }

            BackgroundItem {
            	width: parent.width
            	height: paypal.height
                onClicked: {
                    Mitakuuluu.renewAccount("paypal", period.currentIndex == 0 ? 1 : (period.currentIndex == 1 ? 3 : 5))
                }
	            Image {
	            	id: paypal
	                anchors.horizontalCenter: parent.horizontalCenter
	                source: "../images/paypal_logo.png"
	                cache: true
	                asynchronous: true
	            }
	        }

            Label {
                anchors {
                    left: parent.left
                    leftMargin: Theme.paddingLarge
                    right: parent.right
                }
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                text: qsTr("PayPal is recommended. Neither PayPal nor Google Wallet requires you to make an account.", "Payment description text")
            }
        }
    }
}
