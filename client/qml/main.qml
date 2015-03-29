import QtQuick 2.0
import Sailfish.Silica 1.0
import QtFeedback 5.0
import harbour.mitakuuluu2.client 1.0
import Sailfish.Gallery.private 1.0
import org.nemomobile.configuration 1.0
import QtSensors 5.1
import "Utilities.js" as Utilities

ApplicationWindow {
    id: appWindow
    objectName: "appWindow"
    cover: Qt.resolvedUrl("CoverPage.qml")
    initialPage: (phoneNumber.value === "unregistered") ?
                     Qt.resolvedUrl("RegistrationPage.qml") : Qt.resolvedUrl("ChatsPage.qml")

    DConfValue {
        id: phoneNumber
        key: "/apps/harbour-mitakuuluu2/account/phoneNumber"
        defaultValue: "unregistered"
    }

    property int globalOrientation: settings.lockPortraitPages ? Orientation.Portrait : (Orientation.Portrait | (settings.allowLandscapeInverted ? (Orientation.Landscape | Orientation.LandscapeInverted) : Orientation.Landscape))
    property int conversationOrientation: settings.lockPortrait ? Orientation.Portrait : (Orientation.Portrait | (settings.allowLandscapeInverted ? (Orientation.Landscape | Orientation.LandscapeInverted) : Orientation.Landscape))

    property bool hidden: true
    onHiddenChanged: {
        console.log("hide contacts: " + hidden)
    }

    property var hiddenList: []
    onHiddenListChanged: {
        console.log("hidden contacts: " + JSON.stringify(hiddenList))
    }

    function updateHidden(hjid) {
        var toHide = hiddenList
        var index = toHide.indexOf(hjid)
        var secure = index >= 0
        if (secure) {
            toHide.splice(index, 1)
        }
        else {
            var val = hjid
            toHide.splice(index, 0, hjid)
        }

        hiddenList = toHide

        hiddenConfig.key = "/apps/harbour-mitakuuluu2/hidden/" + hjid
        hiddenConfig.value = !secure
    }
    DConfValue {
        id: hiddenConfig
    }

    //dont ask me how it working, i dont know, but it still better than !==
    function version_compare (v1, v2, operator) {
        // From: http://phpjs.org/functions
        // +      original by: Philippe Jausions (http://pear.php.net/user/jausions)
        // +      original by: Aidan Lister (http://aidanlister.com/)
        // + reimplemented by: Kankrelune (http://www.webfaktory.info/)
        // +      improved by: Brett Zamir (http://brett-zamir.me)
        // +      improved by: Scott Baker
        // +      improved by: Theriault
        // *        example 1: version_compare('8.2.5rc', '8.2.5a');
        // *        returns 1: 1
        // *        example 2: version_compare('8.2.50', '8.2.52', '<');
        // *        returns 2: true
        // *        example 3: version_compare('5.3.0-dev', '5.3.0');
        // *        returns 3: -1
        // *        example 4: version_compare('4.1.0.52','4.01.0.51');
        // *        returns 4: 1
        // Important: compare must be initialized at 0.
        var i = 0,
        x = 0,
        compare = 0,
        // vm maps textual PHP versions to negatives so they're less than 0.
        // PHP currently defines these as CASE-SENSITIVE. It is important to
        // leave these as negatives so that they can come before numerical versions
        // and as if no letters were there to begin with.
        // (1alpha is < 1 and < 1.1 but > 1dev1)
        // If a non-numerical value can't be mapped to this table, it receives
        // -7 as its value.
        vm = {
            'dev': -6,
            'alpha': -5,
            'a': -5,
            'beta': -4,
            'b': -4,
            'RC': -3,
            'rc': -3,
            '#': -2,
            'p': 1,
            'pl': 1
        },
        // This function will be called to prepare each version argument.
        // It replaces every _, -, and + with a dot.
        // It surrounds any nonsequence of numbers/dots with dots.
        // It replaces sequences of dots with a single dot.
        //    version_compare('4..0', '4.0') == 0
        // Important: A string of 0 length needs to be converted into a value
        // even less than an unexisting value in vm (-7), hence [-8].
        // It's also important to not strip spaces because of this.
        //   version_compare('', ' ') == 1
        prepVersion = function (v) {
            v = ('' + v).replace(/[_\-+]/g, '.');
            v = v.replace(/([^.\d]+)/g, '.$1.').replace(/\.{2,}/g, '.');
            return (!v.length ? [-8] : v.split('.'));
        },
        // This converts a version component to a number.
        // Empty component becomes 0.
        // Non-numerical component becomes a negative number.
        // Numerical component becomes itself as an integer.
        numVersion = function (v) {
            return !v ? 0 : (isNaN(v) ? vm[v] || -7 : parseInt(v, 10));
        };
        v1 = prepVersion(v1);
        v2 = prepVersion(v2);
        x = Math.max(v1.length, v2.length);
        for (i = 0; i < x; i++) {
            if (v1[i] == v2[i]) {
                continue;
            }
            v1[i] = numVersion(v1[i]);
            v2[i] = numVersion(v2[i]);
            if (v1[i] < v2[i]) {
                compare = -1;
                break;
            } else if (v1[i] > v2[i]) {
                compare = 1;
                break;
            }
        }
        if (!operator) {
            return compare;
        }

        // Important: operator is CASE-SENSITIVE.
        // "No operator" seems to be treated as "<."
        // Any other values seem to make the function return null.
        switch (operator) {
            case '>':
            case 'gt':
                return (compare > 0);
            case '>=':
            case 'ge':
                return (compare >= 0);
            case '<=':
            case 'le':
                return (compare <= 0);
            case '==':
            case '=':
            case 'eq':
                return (compare === 0);
            case '<>':
            case '!=':
            case 'ne':
                return (compare !== 0);
            case '':
            case '<':
            case 'lt':
                return (compare < 0);
            default:
            return null;
        }
    }

    function timestampToDateTime(stamp) {
        var d = new Date(stamp*1000)
        if (timeFormat24) {
            return Qt.formatDateTime(d, "dd.MM hh:mm:ss")
        }
        else {
            return Qt.formatDateTime(d, "dd.MM h:mm:ss ap")
        }
    }

    function timestampToTime(stamp) {
        var d = new Date(stamp*1000)
        if (settings.showSeconds) {
            if (timeFormat24) {
                return Qt.formatDateTime(d, "hh:mm:ss")
            }
            else {
                return Qt.formatDateTime(d, "h:mm:ss ap")
            }
        }
        else {
            if (timeFormat24) {
                return Qt.formatDateTime(d, "hh:mm")
            }
            else {
                return Qt.formatDateTime(d, "h:mm ap")
            }
        }
    }

    function getNicknameByJid(jid) {
        if (jid == Mitakuuluu.myJid)
            return qsTr("You", "Display You instead of your own nickname")
        var model = ContactsBaseModel.getModel(jid)
        if (model && model.nickname)
            return model.nickname
        else
            return jid.split("@")[0]
    }

    function getContactColor(jid, isGroup) {
        if (isGroup) {
            if (jid == Mitakuuluu.myJid) {
                return Theme.highlightColor
            }
            else {
                return ContactsBaseModel.getColorForJid(jid)
            }
        }
        else {
            if (jid == Mitakuuluu.myJid) {
                return Theme.highlightColor
            }
            else {
                return "#FFFFFF"
            }
        }
    }

    function msgStatusColor(model) {
        if (model.author != Mitakuuluu.myJid) {
            return "transparent"
        }
        else {
            if  (model.msgstatus == 4)
                return "#60ffff00"
            else if  (model.msgstatus == 5)
                return "#6000ff00"
            else
                return "#60ff0000"
        }
    }

    function checkLocationEnabled() {
        return Mitakuuluu.locationEnabled()
    }

    function checkHiddenList(showMyJid, hiddenConfig, hiddenJids) {
        var hiddenValues
        if (showMyJid) {
            if (hiddenConfig) {
                hiddenValues = hiddenJids
            }
            else {
                hiddenValues = []
            }
        }
        else {
            if (hiddenConfig) {
                hiddenValues = hiddenJids
                hiddenValues.splice(0, 0, Mitakuuluu.MyJid)
            }
            else {
                hiddenValues = [Mitakuuluu.MyJid]
            }
        }
        return hiddenValues
    }

    property alias settings: configuration
    ConfigurationGroup {
        id: configuration
        path: "/apps/harbour-mitakuuluu2/settings"

        property bool sendByEnter: false
        property bool showTimestamp: true
        property int fontSize: 32
        property bool followPresence: false
        onFollowPresenceChanged: {
            updateCoverActions()
        }

        property bool showSeconds: true
        property bool showMyJid: false
        property bool showKeyboard: false
        property bool acceptUnknown: true
        property bool notifyActive: true
        property bool resizeImages: false
        property bool resizeBySize: true
        property int resizeImagesTo: 1048546
        property double resizeImagesToMPix: 5.01
        property string conversationTheme: "/usr/share/harbour-mitakuuluu2/qml/ModernDelegate.qml"
        property int conversationIndex: 0
        property bool alwaysOffline: false
        onAlwaysOfflineChanged: {
            if (alwaysOffline)
                Mitakuuluu.setPresenceUnavailable()
            else
                Mitakuuluu.setPresenceAvailable()
            updateCoverActions()
        }
        property bool deleteMediaFiles: false
        property bool importToGallery: true
        property bool showConnectionNotifications: false
        property bool lockPortrait: false
        property bool lockPortraitPages: false
        property bool allowLandscapeInverted: false
        property string connectionServer: "c3.whatsapp.net"
        property bool notificationsMuted: false
        onNotificationsMutedChanged: {
            updateCoverActions()
        }

        property bool threading: true
        property bool hideKeyboard: false
        property bool notifyMessages: false
        property bool keepLogs: true
        property string mapSource: "here"
        property bool automaticDownload: false
        property int automaticDownloadBytes: 524288
        property bool sentLeft: false
        property bool autoDownloadWlan: true
        property bool resizeWlan: false
        property bool systemNotifier: false
        property bool useKeepalive: true
        property int reconnectionInterval: 1
        property int reconnectionLimit: 20
        property bool usePhonebookAvatars: false
        property int notificationsDelay: 5

        property int coverLeftAction: 4
        onCoverLeftActionChanged: {
            updateCoverActions()
        }
        property int coverRightAction: 3
        onCoverRightActionChanged: {
            updateCoverActions()
        }

        property bool firstStartConversation: true
        property bool firstStartContacts: true
        property bool firstStartChats: true
    }

    property bool updateAvailable: false

    property int currentOrientation: pageStack._currentOrientation

    property string coverIconLeft: "../images/icon-cover-location-left.png"
    property string coverIconRight: "../images/icon-cover-camera-right.png"
    property bool coverActionActive: false

    property bool timeFormat24: timeFormat.value === "24"
    ConfigurationValue {
        id: timeFormat
        key: "/sailfish/i18n/lc_timeformat24h"
    }

    function coverLeftClicked() {
        coverAction(settings.coverLeftAction)
    }

    function coverRightClicked() {
        coverAction(settings.coverRightAction)
    }

    function coverAction(index) {
        switch (index) {
        case 0: //exit
            shutdownEngine()
            break
        case 1: //presence
            if (settings.followPresence) {
                settings.followPresence = false
                settings.alwaysOffline = false
            }
            else {
                if (settings.alwaysOffline) {
                    settings.followPresence = true
                    settings.alwaysOffline = false
                }
                else {
                    settings.followPresence = false
                    settings.alwaysOffline = true
                }
            }
            break
        case 2: //global muting
            settings.notificationsMuted = !settings.notificationsMuted
            break
        case 3: //camera
            if (Mitakuuluu.connectionStatus !== Mitakuuluu.LoggedIn)
                return
            coverActionActive = true
            captureAndSend()
            //pageStack.currentPage.rejected.connect(coverReceiver.operationRejected)
            appWindow.activate()
            break
        case 4: //location
            if (Mitakuuluu.connectionStatus !== Mitakuuluu.LoggedIn)
                return
            coverActionActive = true
            locateAndSend()
            pageStack.currentPage.rejected.connect(coverReceiver.operationRejected)
            appWindow.activate()
            break
        case 5: //voice
            if (Mitakuuluu.connectionStatus !== Mitakuuluu.LoggedIn)
                return
            coverActionActive = true
            recordAndSend()
            pageStack.currentPage.rejected.connect(coverReceiver.operationRejected)
            appWindow.activate()
            break
        case 6: //text
            if (Mitakuuluu.connectionStatus !== Mitakuuluu.LoggedIn)
                return
            coverActionActive = true
            typeAndSend()
            pageStack.currentPage.rejected.connect(coverReceiver.operationRejected)
            appWindow.activate()
            break
        case 7: //connect/disconnect
            connectDisconnectAction(true)
            break
        default:
            break
        }
        updateCoverActions()
    }

    QtObject {
        id: coverReceiver

        function operationRejected() {
            rejectCoverOperation()
        }
    }

    function captureAndSend() {
        pageStack.push(Qt.resolvedUrl("Capture.qml"), {"broadcastMode": true})
        //pageStack.currentPage.accepted.connect(captureReceiver.captureAccepted)
    }

    function proceedCaptureSend(path, title) {
        captureReceiver.imagePath = path
        captureReceiver.mediaTitle = title
        console.log("capture proceed: " + captureReceiver.imagePath)
        pageStack.busyChanged.connect(captureReceiver.transitionDone)
    }

    function rejectCoverOperation() {
        coverActionActive = false
    }

    QtObject {
        id: captureReceiver
        property string imagePath: ""
        property string mediaTitle: ""

        function captureAccepted() {
            pageStack.currentPage.accepted.disconnect(captureReceiver.captureAccepted)
            captureReceiver.imagePath = pageStack.currentPage.imagePath
            captureReceiver.mediaTitle = pageStack.currentPage.mediaTitle
            console.log("capture accepted: " + captureReceiver.imagePath)
            pageStack.busyChanged.connect(captureReceiver.transitionDone)
        }

        function transitionDone() {
            if (!pageStack.busy) {
                pageStack.busyChanged.disconnect(captureReceiver.transitionDone)
                pageStack.push(Qt.resolvedUrl("SelectContact.qml"), {"multiple": true})
                pageStack.currentPage.accepted.connect(captureReceiver.contactsSelected)
                pageStack.currentPage.rejected.connect(captureReceiver.contactsRejected)
            }
        }

        function contactsUnbind() {
            pageStack.currentPage.accepted.disconnect(captureReceiver.contactsSelected)
            pageStack.currentPage.rejected.disconnect(captureReceiver.contactsRejected)
            coverReceiver.operationRejected()
        }

        function contactsRejected() {
            contactsUnbind()
            Mitakuuluu.rejectMediaCapture(captureReceiver.imagePath)
        }

        function contactsSelected() {
            contactsUnbind()
            if (pageStack.currentPage.jids.length > 0) {
                Mitakuuluu.sendMedia(["@broadcast"], captureReceiver.imagePath, captureReceiver.mediaTitle, pageStack.currentPage.jids)
            }
            else {
                Mitakuuluu.sendMedia(pageStack.currentPage.jids, captureReceiver.imagePath, captureReceiver.mediaTitle)
            }
        }
    }

    function locateAndSend() {
        pageStack.push(Qt.resolvedUrl("Location.qml"), {"broadcastMode": true})
        pageStack.currentPage.accepted.connect(locationReceiver.locationAccepted)
    }

    QtObject {
        id: locationReceiver
        property real latitude: 55.159479
        property real longitude: 61.402796
        property int zoom: 16

        function locationAccepted() {
            pageStack.currentPage.accepted.disconnect(locationReceiver.locationAccepted)
            latitude = pageStack.currentPage.latitude
            longitude = pageStack.currentPage.longitude
            zoom = pageStack.currentPage.zoom
            pageStack.busyChanged.connect(locationReceiver.transitionDone)
        }

        function transitionDone() {
            if (!pageStack.busy) {
                pageStack.busyChanged.disconnect(locationReceiver.transitionDone)
                pageStack.push(Qt.resolvedUrl("SelectContact.qml"), {"multiple": true})
                pageStack.currentPage.accepted.connect(locationReceiver.contactsSelected)
                pageStack.currentPage.rejected.connect(locationReceiver.contactsRejected)
            }
        }

        function contactsRejected() {
            pageStack.currentPage.accepted.disconnect(locationReceiver.contactsSelected)
            pageStack.currentPage.rejected.disconnect(locationReceiver.contactsRejected)
            coverReceiver.operationRejected()
        }

        function contactsSelected() {
            contactsRejected()
            Mitakuuluu.sendLocation(pageStack.currentPage.jids, latitude, longitude, zoom, settings.mapSource)
        }
    }

    function recordAndSend() {
        pageStack.push(Qt.resolvedUrl("Recorder.qml"), {"broadcastMode": true})
        pageStack.currentPage.accepted.connect(recorderReceiver.recordingAccepted)
    }

    QtObject {
        id: recorderReceiver
        property string voicePath: ""

        function recordingAccepted() {
            console.log("recorder accepted")
            pageStack.currentPage.accepted.disconnect(recorderReceiver.recordingAccepted)
            recorderReceiver.voicePath = pageStack.currentPage.savePath
            pageStack.busyChanged.connect(recorderReceiver.transitionDone)
        }

        function transitionDone() {
            if (!pageStack.busy) {
                pageStack.busyChanged.disconnect(recorderReceiver.transitionDone)
                pageStack.push(Qt.resolvedUrl("SelectContact.qml"), {"multiple": true})
                pageStack.currentPage.accepted.connect(recorderReceiver.contactsSelected)
                pageStack.currentPage.rejected.connect(recorderReceiver.contactsRejected)
            }
        }

        function contactsUnbind() {
            pageStack.currentPage.accepted.disconnect(recorderReceiver.contactsSelected)
            pageStack.currentPage.rejected.disconnect(recorderReceiver.contactsRejected)
            coverReceiver.operationRejected()
        }

        function contactsRejected() {
            contactsUnbind()
            Mitakuuluu.rejectMediaCapture(recorderReceiver.voicePath)
        }

        function contactsSelected() {
            contactsUnbind()
            if (pageStack.currentPage.jids.length > 1) {
                Mitakuuluu.sendMedia(["@broadcast"], recorderReceiver.voicePath, "", pageStack.currentPage.jids)
            }
            else {
                Mitakuuluu.sendMedia(pageStack.currentPage.jids, recorderReceiver.voicePath)
            }
        }
    }

    function getMediaAndSend() {
        pageStack.push(Qt.resolvedUrl("MediaSelector.qml"), {"mode": "image", "datesort": true, "multiple": false})
        pageStack.currentPage.accepted.connect(mediaReceiver.mediaAccepted)
    }

    QtObject {
        id: mediaReceiver
        property var mediaFile

        function mediaAccepted() {
            console.log("media accepted")
            pageStack.currentPage.accepted.disconnect(mediaReceiver.mediaAccepted)
            mediaFile = pageStack.currentPage.selectedFiles[0]
            pageStack.busyChanged.connect(mediaReceiver.transitionDone)
        }

        function transitionDone() {
            if (!pageStack.busy) {
                pageStack.busyChanged.disconnect(mediaReceiver.transitionDone)
                pageStack.push(Qt.resolvedUrl("SelectContact.qml"), {"multiple": true})
                pageStack.currentPage.accepted.connect(mediaReceiver.contactsSelected)
                pageStack.currentPage.rejected.connect(mediaReceiver.contactsRejected)
            }
        }

        function contactsRejected() {
            pageStack.currentPage.accepted.disconnect(mediaReceiver.contactsSelected)
            pageStack.currentPage.rejected.disconnect(mediaReceiver.contactsRejected)
            coverReceiver.operationRejected()
        }

        function contactsSelected() {
            contactsRejected()
            if (pageStack.currentPage.jids.length > 1) {
                Mitakuuluu.sendMedia(["@broadcast"], mediaReceiver.mediaFile, "", pageStack.currentPage.jids)
            }
            else {
                Mitakuuluu.sendMedia(pageStack.currentPage.jids, mediaReceiver.mediaFile)
            }
        }
    }

    function createBroadcast() {
        pageStack.push(Qt.resolvedUrl("SelectContact.qml"), {"multiple": true, "noGroups": true})
        pageStack.currentPage.accepted.connect(broadcastReceiver.contactsSelected)
        pageStack.currentPage.rejected.connect(broadcastReceiver.contactsRejected)
    }

    QtObject {
        id: broadcastReceiver

        function transitionDone() {
            if (!pageStack.busy) {
                pageStack.busyChanged.disconnect(broadcastReceiver.transitionDone)
                ContactsBaseModel.createBroadcast(pageStack.currentPage.jids)
            }
        }

        function contactsRejected() {
            pageStack.currentPage.accepted.disconnect(broadcastReceiver.contactsSelected)
            pageStack.currentPage.rejected.disconnect(broadcastReceiver.contactsRejected)
        }

        function contactsSelected() {
            pageStack.busyChanged.connect(broadcastReceiver.transitionDone)
            contactsRejected()
        }
    }

    function typeAndSend() {
        pageStack.push(Qt.resolvedUrl("MessageComposer.qml"))
        pageStack.currentPage.accepted.connect(textReceiver.textAccepted)
    }

    QtObject {
        id: textReceiver
        property string message

        function textAccepted() {
            console.log("text accepted")
            pageStack.currentPage.accepted.disconnect(textReceiver.textAccepted)
            message = pageStack.currentPage.message
            pageStack.busyChanged.connect(textReceiver.transitionDone)
        }

        function transitionDone() {
            if (!pageStack.busy) {
                pageStack.busyChanged.disconnect(textReceiver.transitionDone)
                pageStack.push(Qt.resolvedUrl("SelectContact.qml"), {"multiple": true})
                pageStack.currentPage.accepted.connect(textReceiver.contactsSelected)
                pageStack.currentPage.rejected.connect(textReceiver.contactsRejected)
            }
        }

        function contactsRejected() {
            pageStack.currentPage.accepted.disconnect(textReceiver.contactsSelected)
            pageStack.currentPage.rejected.disconnect(textReceiver.contactsRejected)
            coverReceiver.operationRejected()
        }

        function contactsSelected() {
            contactsRejected()
            Mitakuuluu.sendBroadcast(pageStack.currentPage.jids, textReceiver.message)
        }
    }

    function connectDisconnectAction(immediate) {
        if (Mitakuuluu.connectionStatus < Mitakuuluu.Connecting) {
            Mitakuuluu.forceConnection()
        }
        else if (Mitakuuluu.connectionStatus > Mitakuuluu.WaitingForConnection && Mitakuuluu.connectionStatus < Mitakuuluu.LoginFailure) {
            if (immediate) {
                Mitakuuluu.disconnect()
            }
            else {
                remorseDisconnect.execute(qsTr("Disconnecting", "Disconnect remorse popup"),
                                           function() {
                                               Mitakuuluu.disconnect()
                                           },
                                           5000)
            }
        }
        else if (Mitakuuluu.connectionStatus == Mitakuuluu.Disconnected)
            Mitakuuluu.authenticate()
        else
            pageStack.replace(Qt.resolvedUrl("RegistrationPage.qml"))
    }

    function updateCoverActions() {
        coverIconLeft = getCoverActionIcon(settings.coverLeftAction, true)
        coverIconRight = getCoverActionIcon(settings.coverRightAction, false)
    }

    function getCoverActionIcon(index, left) {
        switch (index) {
        case 0: //quit
            return "../images/icon-cover-quit-" + (left ? "left" : "right") + ".png"
        case 1: //presence
            if (settings.followPresence)
                return "../images/icon-cover-autoavailable-" + (left ? "left" : "right") + ".png"
            else {
                if (settings.alwaysOffline)
                    return "../images/icon-cover-unavailable-" + (left ? "left" : "right") + ".png"
                else
                    return "../images/icon-cover-available-" + (left ? "left" : "right") + ".png"
            }
        case 2: //global muting
            if (settings.notificationsMuted)
                return "../images/icon-cover-muted-" + (left ? "left" : "right") + ".png"
            else
                return "../images/icon-cover-unmuted-" + (left ? "left" : "right") + ".png"
        case 3: //camera
            return "../images/icon-cover-camera-" + (left ? "left" : "right") + ".png"
        case 4: //location
            return "../images/icon-cover-location-" + (left ? "left" : "right") + ".png"
        case 5: //recorder
            return "../images/icon-cover-recorder-" + (left ? "left" : "right") + ".png"
        case 6: //text
            return "../images/icon-cover-text-" + (left ? "left" : "right") + ".png"
        case 7: //connect/disconnect
            if (Mitakuuluu.connectionStatus < Mitakuuluu.Connecting) {
                return "../images/icon-cover-disconnected-" + (left ? "left" : "right") + ".png"
            }
            else if (Mitakuuluu.connectionStatus > Mitakuuluu.WaitingForConnection && Mitakuuluu.connectionStatus < Mitakuuluu.LoginFailure) {
                return "../images/icon-cover-connected-" + (left ? "left" : "right") + ".png"
            }
            else
                return "../images/icon-cover-disconnected-" + (left ? "left" : "right") + ".png"
        default:
            return ""
        }
    }

    function locationPreview(w, h, lat, lon, z, source) {
        if (!source || source === undefined || typeof(source) === "undefined")
            source = "here"

        if (source === "here") {
            return "https://maps.nlp.nokia.com/mia/1.6/mapview?app_id=ZXpeEEIbbZQHDlyl5vEn&app_code=GQvKkpzHomJpzKu-hGxFSQ&nord&f=0&poithm=1&poilbl=0&ctr="
                    + lat
                    + ","
                    + lon
                    + "&w=" + w
                    + "&h=" + h
                    //+ "&poix0="
                    //+ lat
                    //+ ","
                    //+ lon
                    //+ ";red;white;20;.;"
                    + "&z=" + z
        }
        else if (source === "osm") {
            return "https://coderus.openrepos.net/staticmaplite/staticmap.php?maptype=mapnik&center="
                    + lat
                    + ","
                    + lon
                    + "&size=" + w
                    + "x" + h
                    //+ "&markers="
                    //+ lat
                    //+ ","
                    //+ lon
                    //+ ",ol-marker"
                    + "&zoom=" + z
        }
        else if (source === "google") {
            return "http://maps.googleapis.com/maps/api/staticmap?maptype=roadmap&sensor=false&"
                    + "&size=" + w
                    + "x" + h
                    //+ "&markers=color:red|label:.|"
                    //+ lat
                    //+ ","
                    //+ lon
                    + "&center="
                    + lat
                    + ","
                    + lon
                    + "&zoom=" + z
        }
        else if (source === "nokia") {
            return "http://m.nok.it/?nord&f=0&poithm=1&poilbl=0&ctr="
                    + lat
                    + ","
                    + lon
                    + "&w=" + w
                    + "&h=" + h
                    //+ "&poix0="
                    //+ lat
                    //+ ","
                    //+ lon
                    //+ ";red;white;20;.;"
                    + "&z=" + z
        }
        else if (source === "bing") {
            return "http://dev.virtualearth.net/REST/v1/Imagery/Map/Road/"
                    + lat
                    + ","
                    + lon
                    + "/"
                    + z
                    + "?mapSize=" + w
                    + "," + h
                    + "&key=AvkH1TAJ9k4dkzOELMutZbk_t3L4ImPPW5LXDvw16XNRd5U36a018XJo2Z1jsPbW"
        }
        else if (source === "mapquest") {
            return "http://www.mapquestapi.com/staticmap/v4/getmap?key=Fmjtd%7Cluur2q0y2q%2Cbw%3Do5-9abn5f"
                    + "&center="+ lat
                    + "," + lon
                    + "&zoom=" + z
                    + "&size=" + w
                    + "," + h
                    + "&type=map&imagetype=png"
        }
        else if (source === "yandexuser") {
            return "http://static-maps.yandex.ru/1.x/"
                    + "?ll=" + lon
                    + "," + lat
                    + "&z=" + z
                    + "&l=pmap&size=" + Math.min(w, 450)
                    + "," + Math.min(h, 450)
        }
        else if (source === "yandex") {
            return "http://static-maps.yandex.ru/1.x/"
                    + "?ll=" + lon
                    + "," + lat
                    + "&z=" + z
                    + "&l=map&size=" + Math.min(w, 450)
                    + "," + Math.min(h, 450)
        }
        else if (source === "2gis") {
            return "http://static.maps.api.2gis.ru/1.0"
                    + "?center=" + lon
                    + "," + lat
                    + "&zoom=" + z
                    + "&size=" + w
                    + "," + h
        }
    }

    function shutdownEngine() {
        Mitakuuluu.shutdown()
        Qt.quit()
    }

    function getNickname(cjid, cnick, cjids) {
        if (cjid.indexOf("@broadcast") < 0 || cnick != cjid.split("@")[0]) {
            return Utilities.emojify(cnick, emojiPath)
        }
        else {
            var nick
            var list = cjids
            var jids = list.split(";")
            var names = []

            for (var i = 0; i < jids.length; i++) {
                var model = ContactsBaseModel.getModel(jids[i])
                if (model && model.nickname) {
                    names.splice(names.length, 0, Utilities.emojify(model.nickname, emojiPath))
                }
                else {
                    var name = jids[i].split("@")[0]
                    names.splice(names.length, 0, name)
                }
            }
            return names.join(", ")
        }
    }

    onCurrentOrientationChanged: {
        if (Qt.inputMethod.visible) {
            Qt.inputMethod.hide()
        }
        pageStack.currentPage.forceActiveFocus()
    }

    onApplicationActiveChanged: {
        console.log("Application " + (applicationActive ? "active" : "inactive"))
        if (pageStack.currentPage.objectName === "conversationPage") {
            if (applicationActive) {
                Mitakuuluu.setActiveJid(pageStack.currentPage.jid)
            }
            else {
                Mitakuuluu.setActiveJid("")
            }
        }
        if (settings.followPresence && Mitakuuluu.connectionStatus === Mitakuuluu.LoggedIn) {
            console.log("follow presence")
            if (applicationActive) {
                Mitakuuluu.setPresenceAvailable()
            }
            else {
                Mitakuuluu.setPresenceUnavailable()
            }
        }
        if (applicationActive) {
            Mitakuuluu.windowActive()
        }

        if (!applicationActive) {
            hidden = true
        }
    }

    property Page _cropDialog
    function openAvatarCrop(sourceImage, targetImage, targetJid, destinationPage) {
        _cropDialog = imageEditPage.createObject(appWindow, {
                                                        acceptDestination: destinationPage,
                                                        acceptDestinationAction: PageStackAction.Pop,
                                                        source: sourceImage,
                                                        target: targetImage,
                                                        jid: targetJid
                                                       }
                                                 )
        return pageStack.push(_cropDialog)
    }

    Component {
        id: imageEditPage

        CropDialog {
            id: avatarCropDialog
            objectName: "avatarCrop"
            allowedOrientations: Orientation.Portrait

            property alias source: imageEditPreview.source
            property alias target: imageEditPreview.target
            property alias cropping: imageEditPreview.editInProgress
            property var selectedContentProperties
            property alias orientation: imageEditPreview.orientation

            property string jid
            signal avatarSet(string avatarPath)

            splitOpen: false
            avatarCrop: true
            foreground: CropEditPreview {
                id: imageEditPreview

                editOperation: ImageEditor.Crop
                isPortrait: splitView.isPortrait
                aspectRatio: 1.0
                splitView: avatarCropDialog
                anchors.fill: parent
                active: !splitView.splitOpen
                explicitWidth: avatarCropDialog.width
                explicitHeight: avatarCropDialog.height
            }

            onEdited: {
                console.log("edit target: " + target)
                var avatar = Mitakuuluu.saveAvatarForJid(avatarCropDialog.jid, target)
                console.log("edit avatar: " + avatar)
                Mitakuuluu.setPicture(avatarCropDialog.jid, avatar)
                avatarCropDialog.avatarSet(avatar)
                _cropDialog = null
            }

            onCropRequested: {
                console.log("crop requested")
                imageEditPreview.crop()
            }
        }
    }

    Connections {
        target: pageStack
        onCurrentPageChanged: {
            console.log("[PageStack] " + pageStack.currentPage.objectName)
        }
    }

    Connections {
        target: ContactsBaseModel
        onBroadcastCreated: {
            if (bjid.length > 0) {
                console.log("should open " + bjid)
                while (pageStack.depth > 1) {
                    pageStack.navigateBack(PageStackAction.Immediate)
                }
                pageStack.push(Qt.resolvedUrl("ConversationPage.qml"), {"initialParticipants": bjids, "initialModel": ContactsBaseModel.getModel(bjid)}, PageStackAction.Immediate)
            }
        }
    }

    Connections {
        target: Mitakuuluu
        onConnectionStatusChanged: {
            console.log("connectionStatus: " + Mitakuuluu.connectionStatus)
            updateCoverActions()
        }
        onNotificationOpenJid: {
            activate()
            if (njid.length > 0) {
                console.log("should open " + njid)
                while (pageStack.depth > 1) {
                    pageStack.navigateBack(PageStackAction.Immediate)
                }
                pageStack.push(Qt.resolvedUrl("ConversationPage.qml"), {"initialModel": ContactsBaseModel.getModel(njid)}, PageStackAction.Immediate)
            }
        }
        onWhatsappStatusReply: {
            var offlineFeatures = []
            for (var key in features) {
                if (!features[key].available) {
                    offlineFeatures.splice(0, 0, key)
                }
            }
            if (pageStack.currentPage.objectName != "statusFeatures" && offlineFeatures.length > 0) {
                banner.notify(qsTr("Server experiencing problems with following feature(s): %1").arg(offlineFeatures.join(", ")))
            }
        }
        onWebVersionChanged: {
            console.log("checking verion " + Mitakuuluu.fullVersion + " and " + Mitakuuluu.webVersion.version)
            updateAvailable = false
            if (Mitakuuluu.webVersion.version && Mitakuuluu.fullVersion !== "n/a" && version_compare(Mitakuuluu.fullVersion, Mitakuuluu.webVersion.version, "<")) {
                updateAvailable = true
                var updateDialogComponent = Qt.createComponent(Qt.resolvedUrl("NewVersion.qml"));
                var updateDialog = updateDialogComponent.createObject(appWindow)
                updateDialog.open()
            }
        }
    }

    Component.onCompleted: {
        var hiddenContacts = dconfObject.listValues("/apps/harbour-mitakuuluu2/hidden/")
        var toHide = []
        for (var i = 0; i < hiddenContacts.length; i++) {
            if (hiddenContacts[i].value) {
                var hjid = hiddenContacts[i].key.substr(33)
                toHide.splice(0, 0, hjid)
            }
        }
        hiddenList = toHide
        hidden = true

        updateCoverActions()
    }

    DConfValue {
        id: dconfObject
    }

    Popup {
        id: banner
    }

    RemorsePopup {
        id: remorseDisconnect
    }

    HapticsEffect {
        id: vibration
        intensity: 1.0
        duration: 200
        attackTime: 250
        fadeTime: 250
        attackIntensity: 0.0
        fadeIntensity: 0.0
    }

    SensorGesture {
        id: shake
        gestures: ["QtSensors.shake", "QtSensors.shake2", "QtSensors.doubletap"]
        enabled: applicationActive && hidden && hiddenList.length > 0
        onDetected:{
            hidden = false
        }
    }
}

