import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Media 1.0
import harbour.mitakuuluu2.client 1.0
import com.jolla.settings 1.0
import com.jolla.settings.system 1.0
import org.nemomobile.systemsettings 1.0
import "Utilities.js" as Utilities

Page {
    id: page
    objectName: "settings"
    allowedOrientations: globalOrientation

    property var coverNames: []

    onStatusChanged: {
        if (status === PageStatus.Inactive) {

        }
        else if (status === PageStatus.Active) {
            updatePresence()
        }
    }

    function coverActionName(index) {
        if (typeof(coverNames[index]) == "undefined") {
            coverNames = [
                        qsTr("Quit", "Settings cover action name text"),
                        qsTr("Change presence", "Settings cover action name text"),
                        qsTr("Mute/unmute", "Settings cover action name text"),
                        qsTr("Take picture", "Settings cover action name text"),
                        qsTr("Send location", "Settings cover action name text"),
                        qsTr("Send voice note", "Settings cover action name text"),
                        qsTr("Send text", "Settings cover action name text"),
                        qsTr("Connect/Disconnect", "Settings cover action name text")
                    ]
        }
        return coverNames[index]
    }

    Connections {
        target: settings
        onFollowPresenceChanged: updatePresence()
        onAlwaysOfflineChanged: updatePresence()
        onConnectionServerChanged: {
            connServer.currentIndex = (settings.connectionServer == "c.whatsapp.net" ? 0
                                    : (settings.connectionServer == "c1.whatsapp.net" ? 1
                                    : (settings.connectionServer == "c2.whatsapp.net" ? 2
                                                                                      : 3)))
        }
    }

    function updatePresence() {
        presenceStatus.currentIndex = settings.followPresence ? 0 : (settings.alwaysOffline ? 2 : 1)
    }

    SilicaFlickable {
        id: flick
        anchors.fill: page

        contentHeight: content.height

        PullDownMenu {
            MenuItem {
                text: qsTr("About", "Settings page menu item")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("About.qml"))
                }
            }
            MenuItem {
                text: qsTr("System status", "Settings page menu item")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("StatusFeatures.qml"))
                }
            }
            MenuItem {
                text: qsTr("Traffic counter", "Settings page menu item")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("TrafficCounters.qml"))
                }
            }
            MenuItem {
                text: qsTr("Account", "Settings page menu item")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("Account.qml"))
                }
            }
            MenuItem {
                text: qsTr("Send logfile to author", "Settings page menu item")
                visible: settings.keepLogs && Mitakuuluu.checkLogfile()
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("SendLogs.qml"))
                }
            }
        }

        Column {
            id: content
            spacing: Theme.paddingSmall
            width: parent.width

            PageHeader {
                id: title
                title: qsTr("Settings", "Settings page title")
            }

            SectionHeader {
                text: qsTr("Conversation", "Settings page section name")
            }

            /*ComboBox {
                label: qsTr("Conversation theme")
                currentIndex: 0
                menu: ContextMenu {
                    MenuItem {
                        text: "Oldschool"
                    }
                    MenuItem {
                        text: "Bubbles"
                    }
                    MenuItem {
                        text: "Modern"
                    }
                    Repeater {
                        width: parent.width
                        model: conversationDelegates
                        delegate: MenuItem {
                            text: modelData
                        }
                    }
                }
                onCurrentItemChanged: {
                    if (pageStack.currentPage.objectName !== "roster") {
                        if (currentIndex == 0) {
                            conversationTheme = "/usr/share/harbour-mitakuuluu2/qml/DefaultDelegate.qml"
                        }
                        else if (currentIndex == 1) {
                            conversationTheme = "/usr/share/harbour-mitakuuluu2/qml/BubbleDelegate.qml"
                        }
                        else if (currentIndex == 2) {
                            conversationTheme = "/usr/share/harbour-mitakuuluu2/qml/ModernDelegate.qml"
                        }
                        else {
                            conversationTheme = "/home/nemo/.whatsapp/delegates/" + conversationDelegates[currentIndex - 3]
                        }
                        conversationIndex = parseInt(currentIndex)
                    }
                }
                Component.onCompleted: {
                    currentIndex = settings.value("conversationIndex", parseInt(0))
                }
            }*/

            TextSwitch {
                checked: settings.sentLeft
                text: qsTr("Show sent messages at left side", "Settings option name")
                onClicked: settings.sentLeft = checked
            }

            TextSwitch {
                checked: settings.notifyActive
                text: qsTr("Vibrate in active conversation", "Settings option name")
                onClicked: settings.notifyActive = checked
            }

            TextSwitch {
                checked: settings.showTimestamp
                text: qsTr("Show messages timestamp", "Settings option name")
                onClicked: settings.showTimestamp = checked
            }

            TextSwitch {
                checked: settings.showSeconds
                text: qsTr("Show seconds in messages timestamp", "Settings option name")
                enabled: settings.showTimestamp
                onClicked: settings.showSeconds = checked
            }

            TextSwitch {
                checked: settings.sendByEnter
                text: qsTr("Send messages by Enter", "Settings option name")
                onClicked: settings.sendByEnter = checked
            }

            TextSwitch {
                checked: settings.showKeyboard
                text: qsTr("Automatically show keyboard when opening conversation", "Settings option name")
                onClicked:settings. showKeyboard = checked
            }

            TextSwitch {
                checked: settings.hideKeyboard
                text: qsTr("Hide keyboard after sending message", "Settings option name")
                onClicked: settings.hideKeyboard = checked
            }

            /*TextSwitch {
                checked: settingsdeleteMediaFiles
                text: qsTr("Delete media files")
                description: qsTr("Delete received media files when deleting message")
                onClicked: settings.deleteMediaFiles = checked
            }*/

            ComboBox {
                label: qsTr("Map source", "Settings option name")
                menu: ContextMenu {
                    Repeater {
                        width: parent.width
                        model: mapSourceModel
                        delegate: MenuItem { text: model.name }
                    }
                }
                onCurrentItemChanged: {
                    if (pageStack.currentPage.objectName === "settings" || pageStack.currentPage.objectName === "") {
                        settings.mapSource = mapSourceModel.get(currentIndex).value
                    }
                }
                Component.onCompleted: {
                    _updating = false
                    for (var i = 0; i < mapSourceModel.count; i++) {
                        if (mapSourceModel.get(i).value == settings.mapSource) {
                            currentIndex = i
                            break
                        }
                    }
                }
            }

            TextSwitch {
                checked: settings.lockPortrait
                text: qsTr("Lock conversation orientation in portrait", "Settings option name")
                onClicked: settings.lockPortrait = checked
            }

            TextSwitch {
                checked: settings.lockPortraitPages
                text: qsTr("Lock other pages orientation in portrait", "Settings option name")
                onClicked: settings.lockPortraitPages = checked
            }

            TextSwitch {
                checked: settings.allowLandscapeInverted
                text: qsTr("Allow rotating UI to landscape-inverted position")
                onClicked: settings.allowLandscapeInverted = checked
            }

            ListModel {
                id: mapSourceModel
                Component.onCompleted: {
                    append({name: qsTr("Here", "Map source selection"), value: "here"})
                    append({name: qsTr("Nokia", "Map source selection"), value: "nokia"})
                    append({name: qsTr("Google", "Map source selection"), value: "google"})
                    append({name: qsTr("OpenStreetMaps", "Map source selection"), value: "osm"})
                    append({name: qsTr("Bing", "Map source selection"), value: "bing"})
                    append({name: qsTr("MapQuest", "Map source selection"), value: "mapquest"})
                    append({name: qsTr("Yandex", "Map source selection"), value: "yandex"})
                    append({name: qsTr("Yandex usermap", "Map source selection"), value: "yandexuser"})
                    append({name: qsTr("2Gis", "Map source selection"), value: "2gis"})
                }
            }

            Slider {
                id: fontSlider
                width: parent.width
                maximumValue: 60
                minimumValue: 8
                label: qsTr("Chat font size", "Settings option name")
                value: settings.fontSize
                valueText: qsTr("%1 px", "Settings option value label").arg(parseInt(value))
                onReleased: {
                    settings.fontSize = parseInt(value)
                }
            }

            SectionHeader {
                text: qsTr("Notifications", "Settings page section name")
            }

            Binding {
                target: muteSwitch
                property: "checked"
                value: !settings.notificationsMuted
            }

            TextSwitch {
                id: muteSwitch
                checked: !settings.notificationsMuted
                text: qsTr("Show new messages notifications", "Settings option name")
                onClicked: settings.notificationsMuted = !checked
            }

            Binding {
                target: notifySwitch
                property: "checked"
                value: settings.notifyMessages
            }

            TextSwitch {
                id: notifySwitch
                checked: settings.notifyMessages
                enabled: !settings.notificationsMuted
                text: qsTr("Display messages text in notifications", "Settings option name")
                onClicked: settings.notifyMessages = checked
            }

            TextSwitch {
                width: parent.width
                enabled: !settings.notificationsMuted
                text: qsTr("Use system Chat notifier", "Settings option name")
                checked: settings.systemNotifier
                onClicked: settings.systemNotifier = checked
            }

            ValueButton {
                label: qsTr("Private message", "Settings page Private message tone selection")
                enabled: !settings.systemNotifier && !settings.notificationsMuted
                value: Mitakuuluu.privateToneEnabled ? metadataReader.getTitle(Mitakuuluu.privateTone) : qsTr("no sound", "Private message tone not set")
                onClicked: {
                    var dialog = pageStack.push(dialogComponent, {
                        activeFilename: Mitakuuluu.privateTone,
                        activeSoundTitle: value,
                        activeSoundSubtitle: qsTr("Private message tone", "Sound chooser description text"),
                        noSound: !Mitakuuluu.privateToneEnabled
                        })

                    dialog.accepted.connect(
                       function() {
                            console.log("path: " + dialog.selectedFilename)
                            console.log("enabled: " + !dialog.noSound)
                            Mitakuuluu.privateToneEnabled = !dialog.noSound
                            if (!dialog.noSound) {
                                Mitakuuluu.privateTone = dialog.selectedFilename
                            }
                        })
                }
            }

            ComboBox {
                label: qsTr("Private message color", "Settings page Private message color selection")
                enabled: !settings.systemNotifier && !settings.notificationsMuted
                menu: ContextMenu {
                    id: privatePatterns
                    Repeater {
                        id: privateItems
                        width: parent.width
                        model: patternsModel
                        delegate: MenuItem { text: model.color }
                    }
                }
                onCurrentItemChanged: {
                    if (pageStack.currentPage.objectName === "settings" || pageStack.currentPage.objectName === "") {
                        console.log("private pattern: " + patternsModel.get(currentIndex).name)
                        Mitakuuluu.privateLedColor = patternsModel.get(currentIndex).name
                        console.log("success: " + Mitakuuluu.privateLedColor)
                    }
                }
                Component.onCompleted: {
                    _updating = false
                    for (var i = 0; i < patternsModel.count; i++) {
                        if (patternsModel.get(i).name == Mitakuuluu.privateLedColor) {
                            currentIndex = i
                            break
                        }
                    }
                }
            }

            ValueButton {
                label: qsTr("Group message", "Settings page Group message tone selection")
                enabled: !settings.systemNotifier && !settings.notificationsMuted
                value: Mitakuuluu.groupToneEnabled ? metadataReader.getTitle(Mitakuuluu.groupTone) : qsTr("no sound", "Group message tone not set")
                onClicked: {
                    var dialog = pageStack.push(dialogComponent, {
                        activeFilename: Mitakuuluu.groupTone,
                        activeSoundTitle: value,
                        activeSoundSubtitle: qsTr("Group message tone", "Sound chooser description text"),
                        noSound: !Mitakuuluu.groupToneEnabled
                        })

                    dialog.accepted.connect(
                        function() {
                            Mitakuuluu.groupToneEnabled = !dialog.noSound
                            if (!dialog.noSound) {
                                Mitakuuluu.groupTone = dialog.selectedFilename
                            }
                        })
                }
            }

            ComboBox {
                label: qsTr("Group message color", "Settings page Group message color selection")
                enabled: !settings.systemNotifier && !settings.notificationsMuted
                menu: ContextMenu {
                    Repeater {
                        width: parent.width
                        model: patternsModel
                        delegate: MenuItem { text: model.color }
                    }
                }
                onCurrentItemChanged: {
                    if (pageStack.currentPage.objectName === "settings" || pageStack.currentPage.objectName === "") {
                        console.log("group pattern: " + patternsModel.get(currentIndex).name)
                        Mitakuuluu.groupLedColor = patternsModel.get(currentIndex).name
                    }
                }
                Component.onCompleted: {
                    _updating = false
                    for (var i = 0; i < patternsModel.count; i++) {
                        if (patternsModel.get(i).name == Mitakuuluu.groupLedColor) {
                            currentIndex = i
                            break
                        }
                    }
                }
            }

            ValueButton {
                label: qsTr("Media message", "Settings page Media message tone selection")
                enabled: !settings.systemNotifier && !settings.notificationsMuted
                value: Mitakuuluu.mediaToneEnabled ? metadataReader.getTitle(Mitakuuluu.mediaTone) : qsTr("no sound", "Medi message tone not set")
                onClicked: {
                    var dialog = pageStack.push(dialogComponent, {
                        activeFilename: Mitakuuluu.mediaTone,
                        activeSoundTitle: value,
                        activeSoundSubtitle: qsTr("Media message tone", "Sound chooser description text"),
                        noSound: !Mitakuuluu.mediaToneEnabled
                        })

                    dialog.accepted.connect(
                        function() {
                            Mitakuuluu.mediaToneEnabled = !dialog.noSound
                            if (!dialog.noSound) {
                                Mitakuuluu.mediaTone = dialog.selectedFilename
                            }
                        })
                }
            }

            ComboBox {
                label: qsTr("Media message color", "Settings page Media message color selection")
                enabled: !settings.systemNotifier && !settings.notificationsMuted
                menu: ContextMenu {
                    Repeater {
                        width: parent.width
                        model: patternsModel
                        delegate: MenuItem { text: model.color }
                    }
                }
                onCurrentItemChanged: {
                    if (pageStack.currentPage.objectName === "settings" || pageStack.currentPage.objectName === "") {
                        console.log("media pattern: " + patternsModel.get(currentIndex).name)
                        Mitakuuluu.mediaLedColor = patternsModel.get(currentIndex).name
                    }
                }
                Component.onCompleted: {
                    _updating = false
                    for (var i = 0; i < patternsModel.count; i++) {
                        if (patternsModel.get(i).name == Mitakuuluu.mediaLedColor) {
                            currentIndex = i
                            break
                        }
                    }
                }
            }

            TextSwitch {
                checked: settings.showConnectionNotifications
                text: qsTr("Show notifications when connection changing", "Settings option name")
                onClicked: settings.showConnectionNotifications = checked
            }

            Slider {
                width: parent.width
                maximumValue: 360
                minimumValue: 1
                label: qsTr("Notifications delay", "Settings option name")
                value: settings.notificationsDelay
                valueText: qsTr("%n seconds", "Settings option value label", parseInt(value))
                onReleased: {
                    settings.notificationsDelay = parseInt(value)
                }
            }

            SectionHeader {
                text: qsTr("Common", "Settings page section name")
            }

            ComboBox {
                label: qsTr("Language")
                menu: ContextMenu {
                    Repeater {
                        width: parent.width
                        model: Mitakuuluu.getLocalesNames()
                        delegate: MenuItem {
                            text: modelData
                        }
                    }
                }
                onCurrentItemChanged: {
                    if (pageStack.currentPage.objectName === "settings" || pageStack.currentPage.objectName === "") {
                        Mitakuuluu.setLocale(currentIndex)
                        banner.notify(qsTr("Restart application to change language", "Language changing banner text"))
                    }
                }
                Component.onCompleted: {
                    //console.log("default: " + localeNames[localeIndex] + " locale: " + locales[localeIndex] + " index: " + localeIndex)
                    currentIndex = Mitakuuluu.getCurrentLocaleIndex()
                }
            }

            ComboBox {
                id: connServer
                label: qsTr("Connection server", "Settings option name") + " (*)"
                menu: ContextMenu {
                    MenuItem {
                        text: "c.whatsapp.net"
                        onClicked: {
                            settings.connectionServer = "c.whatsapp.net"
                        }
                    }
                    MenuItem {
                        text: "c1.whatsapp.net"
                        onClicked: {
                            settings.connectionServer = "c1.whatsapp.net"
                        }
                    }
                    MenuItem {
                        text: "c2.whatsapp.net"
                        onClicked: {
                            settings.connectionServer = "c2.whatsapp.net"
                        }
                    }
                    MenuItem {
                        text: "c3.whatsapp.net"
                        onClicked: {
                            settings.connectionServer = "c3.whatsapp.net"
                        }
                    }
                }
                Component.onCompleted: {
                    currentIndex = (settings.connectionServer == "c.whatsapp.net" ? 0
                                : (settings.connectionServer == "c1.whatsapp.net" ? 1
                                : (settings.connectionServer == "c2.whatsapp.net" ? 2
                                                                                  : 3)))
                }
            }

            TextSwitch {
                checked: settings.useKeepalive
                text: qsTr("Use connection keepalive (*)", "Settings option name")
                onClicked: settings.useKeepalive = checked
            }

            Slider {
                width: parent.width
                maximumValue: 60
                minimumValue: 1
                label: qsTr("Reconnection interval (*)", "Settings option name")
                value: settings.reconnectionInterval
                valueText: qsTr("%n minutes", "Settings option value label", parseInt(value))
                onReleased: {
                    settings.reconnectionInterval = parseInt(value)
                }
            }

            Slider {
                width: parent.width
                maximumValue: 30
                minimumValue: 1
                label: qsTr("Reconnection limit (*)", "Settings option name")
                value: settings.reconnectionLimit
                valueText: qsTr("%n reconnections", "Settings option value label", parseInt(value))
                onReleased: {
                    settings.reconnectionLimit = parseInt(value)
                }
            }

            TextSwitch {
                checked: Mitakuuluu.checkAutostart()
                text: qsTr("Autostart", "Settings option name")
                onClicked: {
                    Mitakuuluu.setAutostart(checked)
                }
            }

            TextSwitch {
                checked: settings.keepLogs
                text: qsTr("Allow saving application logs", "Settings option name")
                onClicked: {
                    settings.keepLogs = checked
                    if (checked) {
                        banner.notify(qsTr("You need to full quit application to start writing logs. Send logfile to author appear in settings menu.", "Allow application logs option description"))
                    }
                }
            }

            TextSwitch {
                checked: settings.importToGallery
                text: qsTr("Download media to Gallery", "Settings option name")
                description: qsTr("If checked downloaded files will be shown in Gallery", "Settings option description")
                onClicked: settings.importToGallery = checked
            }

            TextSwitch {
                checked: settings.showMyJid
                text: qsTr("Show yourself in contact list, if present", "Settings option name")
                onClicked: settings.showMyJid = checked
            }

            TextSwitch {
                checked: settings.acceptUnknown
                text: qsTr("Accept messages from unknown contacts", "Settings option name")
                onClicked: settings.acceptUnknown = checked
            }

            TextSwitch {
                checked: settings.usePhonebookAvatars
                text: qsTr("Show phonebok avatars", "Settings option name")
                onClicked: settings.usePhonebookAvatars = checked
            }

            SectionHeader {
                text: qsTr("Presence", "Settings page section name")
            }

            ComboBox {
                id: presenceStatus
                label: qsTr("Display presence", "Settings option name")
                menu: ContextMenu {
                    MenuItem {
                        text: qsTr("Display online when app is open", "Settings option value text")
                        onClicked: {
                            settings.followPresence = true
                            settings.alwaysOffline = false
                        }
                    }
                    MenuItem {
                        text: qsTr("Always display online", "Settings option value text")
                        onClicked: {
                            settings.alwaysOffline = false
                            settings.followPresence = false
                        }
                    }
                    MenuItem {
                        text: qsTr("Always display offline", "Settings option value text")
                        onClicked: {
                            settings.alwaysOffline = true
                            settings.followPresence = false
                        }
                    }
                }
                Component.onCompleted: {
                    currentIndex = settings.followPresence ? 0 : (settings.alwaysOffline ? 2 : 1)
                }
            }

            SectionHeader {
                text: qsTr("Cover", "Settings page section name")
            }

            Binding {
                target: leftCoverAction
                property: "currentIndex"
                value: settings.coverLeftAction
            }

            ComboBox {
                id: leftCoverAction
                label: qsTr("Left cover action", "Settings option name")
                menu: ContextMenu {
                    Repeater {
                        width: parent.width
                        model: 8
                        delegate: MenuItem {
                            text: coverActionName(index)
                            //onClicked: coverLeftAction = index
                        }
                    }
                }
                onCurrentItemChanged: {
                    settings.coverLeftAction = currentIndex
                }
            }

            Binding {
                target: rightCoverAction
                property: "currentIndex"
                value: settings.coverRightAction
            }

            ComboBox {
                id: rightCoverAction
                label: qsTr("Right cover action", "Settings option name")
                menu: ContextMenu {
                    Repeater {
                        width: parent.width
                        model: 8
                        delegate: MenuItem {
                            text: coverActionName(index)
                            //onClicked: coverRightAction = index
                        }
                    }
                }
                onCurrentItemChanged: {
                    settings.coverRightAction = currentIndex
                }
            }

            SectionHeader {
                text: qsTr("Media", "Settings page section name")
            }

            Item {
                width: parent.width
                height: downloadSlider.height

                TextSwitch {
                    id: autoDownload
                    text: ""
                    width: Theme.itemSizeSmall
                    checked: settings.automaticDownload
                    onClicked: {
                        settings.automaticDownload = checked
                    }
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                }

                Slider {
                    id: downloadSlider
                    enabled: settings.automaticDownload
                    anchors.left: autoDownload.right
                    anchors.right: parent.right
                    maximumValue: 10485760
                    minimumValue: 204800
                    label: qsTr("Automatic download bytes", "Settings option name")
                    value: settings.automaticDownloadBytes
                    valueText: Format.formatFileSize(parseInt(value))
                    onReleased: {
                        settings.automaticDownloadBytes = parseInt(value)
                    }
                }
            }

            TextSwitch {
                text: qsTr("Auto download on WLAN only", "Settings option name")
                width: parent.width
                checked: settings.autoDownloadWlan
                enabled: settings.automaticDownload
                onClicked: settings.autoDownloadWlan = checked
            }

            TextSwitch {
                checked: settings.resizeImages
                text: qsTr("Resize sending images", "Settings option name")
                onClicked: {
                    settings.resizeImages = checked
                    if (!checked) {
                        sizeResize.checked = false
                        pixResize.checked = false
                    }
                }
            }

            TextSwitch {
                text: qsTr("Don't resize on WLAN", "Settings option name")
                width: parent.width
                checked: !settings.resizeWlan
                enabled: settings.resizeImages
                onClicked: settings.resizeWlan = !checked
            }

            Item {
                width: parent.width
                height: sizeSlider.height

                TextSwitch {
                    id: sizeResize
                    text: ""
                    width: Theme.itemSizeSmall
                    enabled: settings.resizeImages
                    checked: settings.resizeImages && settings.resizeBySize
                    onClicked: {
                        settings.resizeBySize = checked
                        pixResize.checked = !checked
                    }
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                }


                Slider {
                    id: sizeSlider
                    enabled: settings.resizeImages && sizeResize.checked
                    anchors.left: sizeResize.right
                    anchors.right: parent.right
                    maximumValue: 5242880
                    minimumValue: 204800
                    label: qsTr("Maximum image size by file size", "Settings option name")
                    value: settings.resizeImagesTo
                    valueText: Format.formatFileSize(parseInt(value))
                    onReleased: {
                        settings.resizeImagesTo = parseInt(value)
                    }
                }
            }

            Item {
                width: parent.width
                height: pixSlider.height

                TextSwitch {
                    id: pixResize
                    text: ""
                    width: Theme.itemSizeSmall
                    enabled: settings.resizeImages
                    checked: settings.resizeImages && !settings.resizeBySize
                    onClicked: {
                        settings.resizeBySize = !checked
                        sizeResize.checked = !checked
                    }
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                }

                Slider {
                    id: pixSlider
                    enabled: settings.resizeImages && pixResize.checked
                    anchors.left: pixResize.right
                    anchors.right: parent.right
                    maximumValue: 9.0
                    minimumValue: 0.2
                    label: qsTr("Maximum image size by resolution", "Settings option name")
                    value: settings.resizeImagesToMPix
                    valueText: qsTr("%1 MPx", "Settings option value text").arg(parseFloat(value.toPrecision(2)))
                    onReleased: {
                        settings.resizeImagesToMPix = parseFloat(value.toPrecision(2))
                    }
                }
            }

            Label {
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.paddingLarge
                }
                wrapMode: Text.Wrap
                text: qsTr("Options marked with (*) will take effect after reconnection", "Settings (*) options description")
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
            }
        }

        VerticalScrollDecorator {}
    }

    ListModel {
        id: patternsModel
        Component.onCompleted: {
            append({"name": "PatternMitakuuluuRed", "color": qsTr("red", "Pattern led color")})
            append({"name": "PatternMitakuuluuGreen", "color": qsTr("green", "Pattern led color")})
            append({"name": "PatternMitakuuluuBlue", "color": qsTr("blue", "Pattern led color")})
            append({"name": "PatternMitakuuluuWhite", "color": qsTr("white", "Pattern led color")})
            append({"name": "PatternMitakuuluuYellow", "color": qsTr("yellow", "Pattern led color")})
            append({"name": "PatternMitakuuluuCyan", "color": qsTr("cyan", "Pattern led color")})
            append({"name": "PatternMitakuuluuPink", "color": qsTr("pink", "Pattern led color")})
        }
    }

    AlarmToneModel {
        id: alarmToneModel
    }

    MetadataReader {
        id: metadataReader
    }

    Component {
        id: dialogComponent

        SoundDialog {
            alarmModel: alarmToneModel
        }
    }
}
