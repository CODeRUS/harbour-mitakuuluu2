import QtQuick 2.1
import Sailfish.Silica 1.0
import harbour.mitakuuluu2.client 1.0

Page {
    id: page
    objectName: "registrationPage"
    allowedOrientations: globalOrientation

    property string method: "sms"

    property bool canSendLogs: false

    Component.onCompleted: {
        loadCountryCode(Mitakuuluu.mcc)
        Mitakuuluu.checkAndroid()
    }

    onStatusChanged: {
        if (page.status == PageStatus.Inactive && remorse.visible) {
            remorse.cancel()
        }
    }

    Connections {
        target: Mitakuuluu
        onAndroidReady: {
            remorse.execute(qsTr("Importing Android account"), function() {
                Mitakuuluu.importCredentials(creds)
            }, 7000)
        }
        onMccChanged: {
            loadCountryCode(Mitakuuluu.mcc)
        }
        onRegistrationFailed: {
            busy.hide()
            errorArea.show(qsTr("Registration failed\n\n", "Red registration failed screen text") + parseServerReply(reason))
            codeField.visible = false
            canSendLogs = true
        }
        onAccountExpired: {
            busy.hide()
            banner.notify(qsTr("Account expired\n\n", "Red account expired screen text") + JSON.stringify(reason))
            pageStack.push(Qt.resolvedUrl("Payments.qml"))
        }
        onCodeRequestFailed: {
            busy.hide()
            errorArea.show(qsTr("Code request failed\n\n", "Red code request failed screen text") + parseServerReply(serverReply))
            canSendLogs = true
        }
        onCodeRequested: {
            busy.hide()
            banner.notify(qsTr("Activation code requested. Wait for %1 soon", "Activation code requested text")
                               .arg(page.method == "sms"
                                    ? qsTr("sms message", "Activation code requested text information")
                                    : qsTr("voice call", "Activation code requested text information")))
            codeField.visible = true
            codeField.forceActiveFocus()
        }
        onRegistrationComplete: {
            busy.hide()
            banner.notify(qsTr("Successfully registered!", "Registered successfully banner"))
            codeField.visible = false
            Mitakuuluu.setMyPushname(pushname.text.trim())
            pageStack.replace(Qt.resolvedUrl("ChatsPage.qml"))
        }
        onDissectError: {
            busy.hide()
            errorArea.show(qsTr("Cannot detect your country code. You should use international number format for registration.", "Red wrong number entered screen text"))
        }
    }

    SilicaFlickable {
        id: view
        anchors.fill: parent
        contentHeight: content.height

        PullDownMenu {
            MenuItem {
                text: qsTr("Send logfile to author")
                visible: canSendLogs
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("SendLogs.qml"))
                }
            }

            MenuItem {
                text: qsTr("System status")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("StatusFeatures.qml"))
                }
            }

            MenuItem {
                text: qsTr("I have code")
                enabled: phoneField.text.length > 0 && pushname.text.length > 0 && !busy.running
                onClicked: {
                    codeField.visible = true
                    codeField.forceActiveFocus()
                }
            }
        }

        Column {
            id: content
            anchors {
                left: parent.left
                right: parent.right
                margins: Theme.paddingLarge
            }
            spacing: Theme.paddingMedium

            PageHeader { title: qsTr("Registration", "Registration page title") }

            Label {
                width: parent.width
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("Welcome to Mitakuuluu v%1!\n\nNative WhatsApp-compatible clent for Sailfish OS.\nBefore switching to Mitakuuluu from official application please use <Remove account> option in your current application, or do it inside Mitakuuluu after registering.", "Registration welcome message. %1 stands for version name").arg(Mitakuuluu.version)
            }

            RegistrationCombo {
                id: countrySelect
                enabled: !codeField.visible
                label: qsTr("Country", "Registration country selector label")
                model: countriesModel
                onCurrentIndexChanged: {
                    ccLabel.text = "+" + countriesModel.get(currentIndex).cc
                    phoneField.forceActiveFocus()
                }
            }

            TextField {
                id: phoneField
                width: parent.width
                enabled: !codeField.visible
                errorHighlight: text.length == 0
                textLeftMargin: ccLabel.paintedWidth + Theme.paddingLarge
                inputMethodHints: Qt.ImhDialableCharactersOnly
                validator: RegExpValidator{ regExp: /[0-9]*/;}
                label: qsTr("In international format", "Registration phone number text field label")
                _labelItem.anchors.leftMargin: Theme.paddingLarge
                placeholderText: "123456789"
                EnterKey.enabled: text.length > 0
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: pushname.forceActiveFocus()
                property string number: ccLabel.text + phoneField.text

                Component.onCompleted: {
                    _backgroundItem.x = Theme.paddingLarge
                    _backgroundItem.width = _contentItem.width
                }

                Label {
                    id: ccLabel
                    anchors {
                        right: parent.left
                        top: parent.top
                    }
                }
            }

            TextField {
                id: pushname
                enabled: !busy.running
                width: parent.width
                label: qsTr("Profile nickname", "Registration nickname text field label")
                placeholderText: qsTr("Enter your nickname", "Registration nickname text field placeholder")
                errorHighlight: text.length == 0
                EnterKey.enabled: text.length > 0
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: salt.forceActiveFocus()
            }

            TextField {
                id: salt
                enabled: !busy.running
                width: parent.width
                errorHighlight: text.length == 0
                label: qsTr("Protect your registration", "Registration password field label")
                placeholderText: qsTr("Random password", "Registration password field placeolder")
                inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
                echoMode: TextInput.Password
                EnterKey.enabled: text.length > 0
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: page.forceActiveFocus()
                text: Mitakuuluu.generateSalt()
            }

            Row {
                width: parent.width
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingSmall
                visible: !codeField.visible

                Button {
                    text: qsTr("Sms", "Sms registration button text")
                    enabled: phoneField.text.length > 0 && pushname.text.length > 0 && salt.text.length > 0 && !busy.running
                    onClicked: {
                        page.method = "sms"
                        doRegister()
                    }
                }

                Button {
                    text: qsTr("Voice", "Voice registration button text")
                    enabled: phoneField.text.length > 0 && pushname.text.length > 0 && salt.text.length > 0 && !busy.running
                    onClicked: {
                        page.method = "voice"
                        doRegister()
                    }
                }
            }

            TextField {
                id: codeField
                visible: false
                enabled: !busy.running
                width: parent.width
                errorHighlight: text.length == 0
                validator: RegExpValidator { regExp: /^[0-9]{6}$/; }
                inputMethodHints: Qt.ImhDigitsOnly
                label: qsTr("Sms code", "Registration registration code label")
                placeholderText: "123456"
                onTextChanged: {
                    if (acceptableInput) {
                        busy.show(qsTr("Registering account...", "Registering account text"))
                        Mitakuuluu.enterCode(countriesModel.get(countrySelect.currentIndex).cc, phoneField.text.trim(), codeField.text.trim(), salt.text.trim())
                    }
                }
            }

            Row {
                width: parent.width
                height: busy.height
                spacing: Theme.paddingMedium

                BusyIndicator {
                    id: busy
                    size: BusyIndicatorSize.Medium
                    visible: running
                    running: false
                    function show(data) {
                        actionLabel.text = data
                        running = true
                    }
                    function hide() {
                        running = false
                    }
                }

                Label {
                    id: actionLabel
                    wrapMode: Text.Wrap
                    anchors.verticalCenter: parent.verticalCenter
                    visible: busy.visible
                }
            }
        }
    }

    MouseArea {
        id: errorArea
        property string text
        x: page.width
        width: page.width
        height: page.height

        function show(data) {
            page.forceActiveFocus()
            text = data
            showAnimation.start()
        }
        function hide() {
            hideAnimation.start()
        }

        onClicked: hide()

        PropertyAnimation {
            id: showAnimation
            target: errorArea
            easing.type: Easing.OutQuad
            property: "x"
            from: page.width
            to: 0
            duration: 500
        }

        PropertyAnimation {
            id: hideAnimation
            target: errorArea
            easing.type: Easing.OutQuad
            property: "x"
            from: 0
            to: 0 - page.width
            duration: 500
        }

        Rectangle {
            anchors {
                fill: parent
                margins: Theme.paddingLarge
            }
            color: Theme.rgba("red", 0.9)
            radius: Theme.paddingMedium

            Label {
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                text: errorArea.text
            }
        }
    }

    RemorsePopup {
        id: remorse
    }

    function doRegister() {
        if (countrySelect.currentIndex >= 0) {
            Mitakuuluu.regRequest(countriesModel.get(countrySelect.currentIndex).cc, phoneField.text.trim(), page.method, salt.text, Mitakuuluu.mcc, Mitakuuluu.mnc)
            busy.show(qsTr("Checking account...", "Registration checking account text"))
        }
        else {
            banner.notify(qsTr("You should select country first!", "Registration banner text"))
        }
    }

    function loadCountryCode(mcccode) {
        for (var i = 0; i < countriesModel.count; i++)
        {
            if (countriesModel.get(i).mcc && countriesModel.get(i).mcc.split(',').indexOf(mcccode) >= 0)
            {
                countrySelect.currentIndex = i
                break;
            }
        }
    }

    function parseServerReply(reply) {
        var text = ""
        if (reply.status == "sent") {
            text += qsTr("Code successfully requested.", "Registration information constructor")
        }
        else {
            var reason = reply.reason
            var param = reply.param
            if (reply.param == 'in')
                param = qsTr("phone number", "Registration information constructor")
            if (reply.param == 'token')
                param = qsTr("secure token", "Registration information constructor")

            if (reply.reason == "too_recent")
                reason = qsTr("Too frequent attempts to request the code.", "Registration information constructor")
            else if (reply.reason == "too_many_guesses")
                reason = qsTr("Too many wrong code guesses.", "Registration information constructor")
            else if (reply.reason == "too_many")
                reason = qsTr("Too many attempts. Try again tomorrow.", "Registration information constructor")
            else if (reply.reason == 'old_version' || reply.reason == 'bad_token')
                reason = qsTr("Protocol version outdated, sorry. Please contact me at coderusinbox@gmail.com or via twitter: @icoderus", "Registration information constructor")
            else if (reply.reason == "stale")
                reason = qsTr("Registration code expired. You need to request a new one.", "Registration information constructor")
            else if (reply.reason == "missing") {
                if (typeof(reply.param) == "undefined")
                    reason = qsTr("Registration code expired. You need to request a new one.", "Registration information constructor")
                else
                    reason = qsTr("Missing request param: %1", "Registration information constructor").arg(param)
            }
            else if (reply.reason == "mismatch") {
                reason = qsTr("Invalid registration code entered. Please try again.", "Registration information constructor")
            }
            else if (reply.reason == "bad_param") {
                reason = qsTr("Bad parameters passed to code request: %1", "Registration information constructor").arg(param)
            }
            else if (reply.reason == "no_routes")
                reason = qsTr("No cell routes for %1 caused by your operator. Please try other method [sms/voice]", "Registration information constructor")
                              .arg(reply.method == 'voice'
                                   ? qsTr("making call", "Registration information constructor")
                                   : qsTr("sending sms", "Registration information constructor"))
            text += qsTr("Reason: %1").arg(reason)
        }
        if (reply.retry_after > 0) {
            var retry = reply.retry_after / 60
            var hours = Math.abs(retry / 60)
            var mins = Math.abs(retry % 60)
            var after = ""
            if (hours > 0) {
                after += qsTr("%n hours", "Registration information constructor", hours)
                after += " "
            }
            after += qsTr("%n minutes", "Registration information constructor", mins)
            text += "\n"
            text += qsTr("You can retry requesting code after %1", "Registration information constructor").arg(after)
        }
        return text
    }

    ListModel{
        id:countriesModel

        ListElement{name: "Afghanistan"; cc:"93"; mcc:"412"}
        ListElement{name: "Albania"; cc:"355"; mcc:"276"}
        ListElement{name: "Algeria"; cc:"213"; mcc:"603"}
        ListElement{name: "Andorra"; cc:"376"; mcc:"213"}
        ListElement{name: "Angola"; cc:"244"; mcc:"631"}
        ListElement{name: "Anguilla"; cc:"1"; mcc:"365"}
        ListElement{name: "Antarctica (Australian bases)"; cc:"6721"; mcc:"232"} //FIXME no info in wikipedia
        ListElement{name: "Antigua and Barbuda"; cc:"1"; mcc:"344"}
        ListElement{name: "Argentina"; cc:"54"; mcc:"722"}
        ListElement{name: "Armenia"; cc:"374"; mcc:"283"}
        ListElement{name: "Aruba"; cc:"297"; mcc:"363"}
        ListElement{name: "Ascension"; cc:"247"; mcc:"658"}
        ListElement{name: "Australia"; cc:"61"; mcc:"505"}
        ListElement{name: "Austria"; cc:"43"; mcc:"232"}
        ListElement{name: "Azerbaijan"; cc:"994"; mcc:"400"}
        ListElement{name: "Bahamas"; cc:"1"; mcc:"364"}
        ListElement{name: "Bahrain"; cc:"973"; mcc:"426"}
        ListElement{name: "Bangladesh"; cc:"880"; mcc:"470"}
        ListElement{name: "Barbados"; cc:"1"; mcc:"342"}
        ListElement{name: "Belarus"; cc:"375"; mcc:"257"}
        ListElement{name: "Belgium"; cc:"32"; mcc:"206"}
        ListElement{name: "Belize"; cc:"501"; mcc:"702"}
        ListElement{name: "Benin"; cc:"229"; mcc:"616"}
        ListElement{name: "Bermuda"; cc:"1"; mcc:"350"}
        ListElement{name: "Bhutan"; cc:"975"; mcc:"402"}
        ListElement{name: "Bolivia"; cc:"591"; mcc:"736"}
        ListElement{name: "Bosnia and Herzegovina"; cc:"387"; mcc:"218"}
        ListElement{name: "Botswana"; cc:"267"; mcc:"652"}
        ListElement{name: "Brazil"; cc:"55"; mcc:"724"}
        ListElement{name: "British Indian Ocean Territory"; cc:"246"; mcc:"348"} //FIXME no info in wikipedia
        ListElement{name: "British Virgin Islands"; cc:"1"; mcc:"348"}
        ListElement{name: "Brunei"; cc:"673"; mcc:"528"}
        ListElement{name: "Bulgaria"; cc:"359"; mcc:"284"}
        ListElement{name: "Burkina Faso"; cc:"226"; mcc:"613"}
        ListElement{name: "Burundi"; cc:"257"; mcc:"642"}
        ListElement{name: "Cambodia"; cc:"855"; mcc:"456"}
        ListElement{name: "Cameroon"; cc:"237"; mcc:"624"}
        ListElement{name: "Canada"; cc:"1"; mcc:"302"}
        ListElement{name: "Cape Verde"; cc:"238"; mcc:"625"}
        ListElement{name: "Cayman Islands"; cc:"1"; mcc:"346"}
        ListElement{name: "Central African Republic"; cc:"236"; mcc:"623"}
        ListElement{name: "Chad"; cc:"235"; mcc:"622"}
        ListElement{name: "Chile"; cc:"56"; mcc:"730"}
        ListElement{name: "China"; cc:"86"; mcc:"460,461"}
        ListElement{name: "Colombia"; cc:"57"; mcc:"732"}
        ListElement{name: "Comoros"; cc:"269"; mcc:"654"}
        ListElement{name: "Congo, Democratic Republic of the"; cc:"243"; mcc:"630"}
        ListElement{name: "Congo, Republic of the"; cc:"242"; mcc:"629"}
        ListElement{name: "Cook Islands"; cc:"682"; mcc:"548"}
        ListElement{name: "Costa Rica"; cc:"506"; mcc:"658"}
        ListElement{name: "Cote d'Ivoire"; cc:"712"}
        ListElement{name: "Croatia"; cc:"385"; mcc:"219"}
        ListElement{name: "Cuba"; cc:"53"; mcc:"368"}
        ListElement{name: "Cyprus"; cc:"357"; mcc:"280"}
        ListElement{name: "Czech Republic"; cc:"420"; mcc:"230"}
        ListElement{name: "Denmark"; cc:"45"; mcc:"238"}
        ListElement{name: "Djibouti"; cc:"253"; mcc:"638"}
        ListElement{name: "Dominica"; cc:"1"; mcc:"366"}
        ListElement{name: "Dominican Republic"; cc:"1"; mcc:"370"}
        ListElement{name: "East Timor"; cc:"670"; mcc:"514"}
        ListElement{name: "Ecuador"; cc:"593"; mcc:"740"}
        ListElement{name: "Egypt"; cc:"20"; mcc:"602"}
        ListElement{name: "El Salvador"; cc:"503"; mcc:"706"}
        ListElement{name: "Equatorial Guinea"; cc:"240"; mcc:"627"}
        ListElement{name: "Eritrea"; cc:"291"; mcc:"657"}
        ListElement{name: "Estonia"; cc:"372"; mcc:"248"}
        ListElement{name: "Ethiopia"; cc:"251"; mcc:"636"}
        ListElement{name: "Falkland Islands"; cc:"500"; mcc:"750"}
        ListElement{name: "Faroe Islands"; cc:"298"; mcc:"288"}
        ListElement{name: "Fiji"; cc:"679"; mcc:"542"}
        ListElement{name: "Finland"; cc:"358"; mcc:"244"}
        ListElement{name: "France"; cc:"33"; mcc:"208"}
        ListElement{name: "French Guiana"; cc:"594"; mcc:"742"}
        ListElement{name: "French Polynesia"; cc:"689"; mcc:"547"}
        ListElement{name: "Gabon"; cc:"241"; mcc:"628"}
        ListElement{name: "Gambia"; cc:"220"; mcc:"607"}
        ListElement{name: "Gaza Strip"; cc:"970"; mcc:"0"} // FIXME no info avialable
        ListElement{name: "Georgia"; cc:"995"; mcc:"282"}
        ListElement{name: "Germany"; cc:"49"; mcc:"262"}
        ListElement{name: "Ghana"; cc:"233"; mcc:"620"}
        ListElement{name: "Gibraltar"; cc:"350"; mcc:"266"}
        ListElement{name: "Greece"; cc:"30"; mcc:"202"}
        ListElement{name: "Greenland"; cc:"299"; mcc:"290"}
        ListElement{name: "Grenada"; cc:"1"; mcc:"352"}
        ListElement{name: "Guadeloupe"; cc:"590"; mcc:"340"}
        ListElement{name: "Guam"; cc:"1"; mcc:"535"}
        ListElement{name: "Guatemala"; cc:"502"; mcc:"704"}
        ListElement{name: "Guinea"; cc:"224"; mcc:"611"}
        ListElement{name: "Guinea-Bissau"; cc:"245"; mcc:"632"}
        ListElement{name: "Guyana"; cc:"592"; mcc:"738"}
        ListElement{name: "Haiti"; cc:"509"; mcc:"372"}
        ListElement{name: "Honduras"; cc:"504"; mcc:"708"}
        ListElement{name: "Hong Kong"; cc:"852"; mcc:"454"}
        ListElement{name: "Hungary"; cc:"36"; mcc:"216"}
        ListElement{name: "Iceland"; cc:"354"; mcc:"274"}
        ListElement{name: "India"; cc:"91"; mcc:"404,405,406"}
        ListElement{name: "Indonesia"; cc:"62"; mcc:"510"}
        ListElement{name: "Iraq"; cc:"964"; mcc:"418"}
        ListElement{name: "Iran"; cc:"98"; mcc:"432"}
        ListElement{name: "Ireland (Eire)"; cc:"353"; mcc:"272"}
        ListElement{name: "Israel"; cc: "972"; mcc:"425"}
        ListElement{name: "Italy"; cc:"39"; mcc:"222"}
        ListElement{name: "Jamaica"; cc:"1"; mcc:"338"}
        ListElement{name: "Japan"; cc:"81"; mcc:"440,441"}
        ListElement{name: "Jordan"; cc:"962"; mcc:"416"}
        ListElement{name: "Kazakhstan"; cc:"7"; mcc:"401"}
        ListElement{name: "Kenya"; cc:"254"; mcc:"639"}
        ListElement{name: "Kiribati"; cc:"686"; mcc:"545"}
        ListElement{name: "Kuwait"; cc:"965"; mcc:"419"}
        ListElement{name: "Kyrgyzstan"; cc:"996"; mcc:"437"}
        ListElement{name: "Laos"; cc:"856"; mcc:"457"}
        ListElement{name: "Latvia"; cc:"371"; mcc:"247"}
        ListElement{name: "Lebanon"; cc:"961"; mcc:"415"}
        ListElement{name: "Lesotho"; cc:"266"; mcc:"651"}
        ListElement{name: "Liberia"; cc:"231"; mcc:"618"}
        ListElement{name: "Libya"; cc:"218"; mcc:"606"}
        ListElement{name: "Liechtenstein"; cc:"423"; mcc:"295"}
        ListElement{name: "Lithuania"; cc:"370"; mcc:"246"}
        ListElement{name: "Luxembourg"; cc:"352"; mcc:"270"}
        ListElement{name: "Macau"; cc:"853"; mcc:"455"}
        ListElement{name: "Macedonia, Republic of"; cc:"389"; mcc:"294"}
        ListElement{name: "Madagascar"; cc:"261"; mcc:"646"}
        ListElement{name: "Malawi"; cc:"265"; mcc:"650"}
        ListElement{name: "Malaysia"; cc:"60"; mcc:"502"}
        ListElement{name: "Maldives"; cc:"960"; mcc:"472"}
        ListElement{name: "Mali"; cc:"223"; mcc:"610"}
        ListElement{name: "Malta"; cc:"356"; mcc:"278"}
        ListElement{name: "Marshall Islands"; cc:"692"; mcc:"551"}
        ListElement{name: "Martinique"; cc:"596"; mcc:"340"}
        ListElement{name: "Mauritania"; cc:"222"; mcc:"609"}
        ListElement{name: "Mauritius"; cc:"230"; mcc:"617"}
        ListElement{name: "Mayotte"; cc:"262"; mcc:"654"}
        ListElement{name: "Mexico"; cc:"52"; mcc:"334"}
        ListElement{name: "Micronesia, Federated States of"; cc:"691"; mcc:"550"}
        ListElement{name: "Moldova"; cc:"373"; mcc:"259"}
        ListElement{name: "Monaco"; cc:"377"; mcc:"212"}
        ListElement{name: "Mongolia"; cc:"976"; mcc:"428"}
        ListElement{name: "Montenegro"; cc:"382"; mcc:"297"}
        ListElement{name: "Montserrat"; cc:"1"; mcc:"354"}
        ListElement{name: "Morocco"; cc:"212"; mcc:"604"}
        ListElement{name: "Mozambique"; cc:"258"; mcc:"643"}
        ListElement{name: "Myanmar"; cc:"95"; mcc:"414"}
        ListElement{name: "Namibia"; cc:"264"; mcc:"649"}
        ListElement{name: "Nauru"; cc:"674"; mcc:"536"}
        ListElement{name: "Netherlands"; cc:"31"; mcc:"204"}
        ListElement{name: "Netherlands Antilles"; cc:"599"; mcc:"362"}
        ListElement{name: "Nepal"; cc:"977"; mcc:"429"}
        ListElement{name: "New Caledonia"; cc:"687"; mcc:"546"}
        ListElement{name: "New Zealand"; cc:"64"; mcc:"530"}
        ListElement{name: "Nicaragua"; cc:"505"; mcc:"710"}
        ListElement{name: "Niger"; cc:"227"; mcc:"614"}
        ListElement{name: "Nigeria"; cc:"234"; mcc:"621"}
        ListElement{name: "Niue"; cc:"683"; mcc:"555"}
        ListElement{name: "Norfolk Island"; cc:"6723"; mcc:"505"}
        ListElement{name: "North Korea"; cc:"850"; mcc:"467"}
        ListElement{name: "Northern Ireland 44"; cc:"28"; mcc:"272"} // FIXME may be wrong
        ListElement{name: "Northern Mariana Islands"; cc:"1"; mcc:"534"}
        ListElement{name: "Norway"; cc:"47"; mcc:"242"}
        ListElement{name: "Oman"; cc:"968"; mcc:"422"}
        ListElement{name: "Pakistan"; cc:"92"; mcc:"410"}
        ListElement{name: "Palau"; cc:"680"; mcc:"552"}
        ListElement{name: "Palestine"; cc:"970"; mcc:"425"}
        ListElement{name: "Panama"; cc:"507"; mcc:"714"}
        ListElement{name: "Papua New Guinea"; cc:"675"; mcc:"537"}
        ListElement{name: "Paraguay"; cc:"595"; mcc:"744"}
        ListElement{name: "Peru"; cc:"51"; mcc:"716"}
        ListElement{name: "Philippines"; cc:"63"; mcc:"515"}
        ListElement{name: "Poland"; cc:"48"; mcc:"260"}
        ListElement{name: "Portugal"; cc:"351"; mcc:"268"}
        ListElement{name: "Qatar"; cc:"974"; mcc:"427"}
        ListElement{name: "Reunion"; cc:"262"; mcc:"647"}
        ListElement{name: "Romania"; cc:"40"; mcc:"226"}
        ListElement{name: "Russia"; cc:"7"; mcc:"250"}
        ListElement{name: "Rwanda"; cc:"250"; mcc:"635"}
        ListElement{name: "Saint-Barthelemy"; cc:"590"; mcc:"340"} // FIXME possible wrong
        ListElement{name: "Saint Helena"; cc:"290"; mcc:"658"}
        ListElement{name: "Saint Kitts and Nevis"; cc:"1"; mcc:"356"}
        ListElement{name: "Saint Lucia"; cc:"1"; mcc:"358"}
        ListElement{name: "Saint Martin (French side)"; cc:"590"; mcc:"340"}
        ListElement{name: "Saint Pierre and Miquelon"; cc:"508"; mcc:"308"}
        ListElement{name: "Saint Vincent and the Grenadines"; cc:"1"; mcc:"360"}
        ListElement{name: "Samoa"; cc:"685"; mcc:"549"}
        ListElement{name: "Sao Tome and Principe"; cc:"239"; mcc:"626"}
        ListElement{name: "Saudi Arabia"; cc:"966"; mcc:"420"}
        ListElement{name: "Senegal"; cc:"221"; mcc:"608"}
        ListElement{name: "Serbia"; cc:"381"; mcc:"220"}
        ListElement{name: "Seychelles"; cc:"248"; mcc:"633"}
        ListElement{name: "Sierra Leone"; cc:"232"; mcc:"619"}
        ListElement{name: "Singapore"; cc:"65"; mcc:"525"}
        ListElement{name: "Slovakia"; cc:"421"; mcc:"231"}
        ListElement{name: "Slovenia"; cc:"386"; mcc:"293"}
        ListElement{name: "Solomon Islands"; cc:"677"; mcc:"540"}
        ListElement{name: "Somalia"; cc:"252"; mcc:"637"}
        ListElement{name: "South Africa"; cc:"27"; mcc:"655"}
        ListElement{name: "South Korea"; cc:"82"; mcc:"450"}
        ListElement{name: "South Sudan"; cc:"211"; mcc:"659"}
        ListElement{name: "Spain"; cc:"34"; mcc:"214"}
        ListElement{name: "Sri Lanka"; cc:"94"; mcc:"413"}
        ListElement{name: "Sudan"; cc:"249"; mcc:"634"}
        ListElement{name: "Suriname"; cc:"597"; mcc:"746"}
        ListElement{name: "Swaziland"; cc:"268"; mcc:"653"}
        ListElement{name: "Sweden"; cc:"46"; mcc:"240"}
        ListElement{name: "Switzerland"; cc:"41"; mcc:"228"}
        ListElement{name: "Syria"; cc:"963"; mcc:"417"}
        ListElement{name: "Taiwan"; cc:"886"; mcc:"466"}
        ListElement{name: "Tajikistan"; cc:"992"; mcc:"436"}
        ListElement{name: "Tanzania"; cc:"255"; mcc:"640"}
        ListElement{name: "Thailand"; cc:"66"; mcc:"520"}
        ListElement{name: "Togo"; cc:"228"; mcc:"615"}
        ListElement{name: "Tokelau"; cc:"690"; mcc:"690"} // FIXME not avialable
        ListElement{name: "Tonga"; cc:"676"; mcc:"539"}
        ListElement{name: "Trinidad and Tobago"; cc:"1"; mcc:"374"}
        ListElement{name: "Tunisia"; cc:"216"; mcc:"605"}
        ListElement{name: "Turkey"; cc:"90"; mcc:"286"}
        ListElement{name: "Turkmenistan"; cc:"993"; mcc:"438"}
        ListElement{name: "Turks and Caicos Islands"; cc:"1"; mcc:"376"}
        ListElement{name: "Tuvalu"; cc:"688"; mcc:"553"}
        ListElement{name: "Uganda"; cc:"256"; mcc:"641"}
        ListElement{name: "Ukraine"; cc:"380"; mcc:"255"}
        ListElement{name: "United Arab Emirates"; cc:"971"; mcc:"424,430,431"}
        ListElement{name: "United Kingdom"; cc:"44"; mcc:"234,235"}
        ListElement{name: "United States of America"; cc:"1"; mcc:"310,311,312,313,314,315,316"}
        ListElement{name: "Uruguay"; cc:"598"; mcc:"748"}
        ListElement{name: "Uzbekistan"; cc:"998"; mcc:"434"}
        ListElement{name: "Vanuatu"; cc:"678"; mcc:"541"}
        ListElement{name: "Venezuela"; cc:"58"; mcc:"734"}
        ListElement{name: "Vietnam"; cc:"84"; mcc:"452"}
        ListElement{name: "U.S. Virgin Islands"; cc:"1"; mcc:"332"}
        ListElement{name: "Wallis and Futuna"; cc:"681"; mcc:"543"}
        ListElement{name: "West Bank"; cc:"970"; mcc:"0"} // FIXME no info avialable
        ListElement{name: "Yemen"; cc:"967"; mcc:"421"}
        ListElement{name: "Zambia"; cc:"260"; mcc:"645"}
        ListElement{name: "Zimbabwe"; cc:"263"; mcc:"648"}
    }
}
