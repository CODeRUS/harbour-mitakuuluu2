.pragma library

var textarea = null

var emojiComponent = null

function submitDebugInfo(comment, replyto, data, callback) {
    var doc = new XMLHttpRequest();
    doc.onreadystatechange = function() {
        if (doc.readyState == XMLHttpRequest.HEADERS_RECEIVED) {
            var status = doc.status;
            if(status!=200) {
                console.log("Debug info submit " + status + " " + doc.statusText);
                callback(false, doc.statusText);
            }
        } else if (doc.readyState == XMLHttpRequest.DONE && doc.status == 200) {
            var contentType = doc.getResponseHeader("Content-Type");
            var result = JSON.parse(doc.responseText);
            callback(result.status,result.message);
        }
    }

    var params = "content="+encodeURIComponent(data)+"&comment="+encodeURIComponent(comment)+"&replyto="+encodeURIComponent(replyto);

    doc.open("POST", "https://coderus.openrepos.net/gebug_log.php");
    doc.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
    doc.setRequestHeader("Content-length", params.length);
    doc.setRequestHeader("Connection", "close");
    doc.send(params);
}

function emojiKeyboard() {
    if (!emojiComponent) {
        emojiComponent = Qt.createComponent("EmojiDialog/EmojiComponent.qml")
    }
    return emojiComponent
}

function createPage(parent, path) {
    var component = Qt.createComponent(path);
    var object = component.createObject(parent);
    return object
}

var prevCode = 0

function findPage(item) {
    var parentItem = item.parent
    while (parentItem) {
        if (parentItem.hasOwnProperty('__isPage')) {
            return parentItem
        }
        parentItem = parentItem.parent
    }
    return null
}

/*
  Get the first flickable in hierarchy.
*/
function findFlickable(item)
{
    var next = item;

    while (next) {
        if (next.flicking !== undefined && next.flickableDirection !== undefined)
            return next;

        next = next.parent;
    }

    return null;
}

/*
  Get the root item given an element and root item's name.
  If root item name is not given, default is 'windowContent'.
*/
function findRootItem(item, objectName)
{
    var next = item;
    
    var rootItemName = "windowContent";
    if (typeof(objectName) != 'undefined') {
        rootItemName = objectName;
    }

    if (next) {
        while (next.parent) {
            next = next.parent;

            if (rootItemName == next.objectName) {
                break;
            }
        }
    }

    return next;
}

/*
  Get the root item for Notification banner
  It will return 'appWindowContent' or 'windowContent' element if found.
*/
function findRootItemNotificationBanner(item)
{
    var next = item;

    if (next) {
        while (next.parent) {
            if (next.objectName == "appWindowContent")
                break;

            if (next.objectName == "windowContent")
                break;

            next = next.parent;
        }
    }

    return next;
}

/*
  Get the height that is actually covered by the statusbar (0 if the statusbar is not shown.
*/
function statusBarCoveredHeight(item) {
    return ( findRootItem(item, "pageStackWindow") != null
             && findRootItem(item, "pageStackWindow").__statusBarHeight )
}

Array.prototype.getUnique = function(){
   var u = {}, a = [];
   for(var i = 0, l = this.length; i < l; ++i){
      if(u.hasOwnProperty(this[i])) {
         continue;
      }
      a.push(this[i]);
      u[this[i]] = 1;
   }
   return a;
}

function decimalToHex(d, padding) {
    var hex = Number(d).toString(16);
    padding = typeof (padding) === "undefined" || padding === null ? padding = 2 : padding;
    while (hex.length < padding) {
        hex = "0" + hex;
    }
    //console.log("CODE HEX= "+hex)
    return hex;
}

function ord(string) {
    var str = string + ''
    var code = str.charCodeAt(0);

    //console.log("PROCESSING: " + code + " - PrevCode: " + prevCode)
    if (code<10550) {
        //console.log("OLD EMOJI CODE: "+code)
        prevCode = 0
        return code;
    } 

    if (prevCode==0) {
        //console.log("SAVING PREV CODE: "+code)
        prevCode = code;
        return 0
    }

    if (prevCode>0) {
        var hi = prevCode
        var lo = code
        if (0xD800 <= hi && hi <= 0xDBFF) {
            prevCode = 0
            //console.log("NEW CODE= "+((hi - 0xD800) * 0x400) + (lo - 0xDC00) + 0x10000)
            return ((hi - 0xD800) * 0x400) + (lo - 0xDC00) + 0x10000;
        }
    } 

}

function getUnicodeCharacter(cp) {
    if (cp >= 0 && cp <= 0xD7FF || cp >= 0xE000 && cp <= 0xFFFF) {
        return [String.fromCharCode(cp), 0];
    } else if (cp >= 0x10000 && cp <= 0x10FFFF) {
        cp -= 0x10000;
        var first = ((0xffc00 & cp) >> 10) + 0xD800
        var second = (0x3ff & cp) + 0xDC00;
        //console.log("RESULT= "+ String.fromCharCode(first) + String.fromCharCode(second))
        return [String.fromCharCode(first) + String.fromCharCode(second), 1];
    }
}

function getCode(inputText) {

    var replacedText,
        positions = 0,
        //regx = /<img src=\".*\/([a-fA-F0-9]+).png\" \/>/g
        regx = /<img src=\"[^\>]+\/([a-fA-F0-9]+).png\" \/>/g

    replacedText = inputText.replace( regx, function(s, eChar){
            var tmp = s.split(' />')[0].split('/'),
                filenameArr = tmp[tmp.length-1].split('.'),
                emojiChar,
                result,
                n;

            if(filenameArr.length != 2) return s;

            emojiChar = filenameArr[0]

            result = getUnicodeCharacter('0x'+emojiChar);
            n = result[0]
            positions = positions + result[1]
            return n;
    });
    return [replacedText, positions]

}

function linkify(inputText, color) {
    var replacedText, replacePattern1, replacePattern2, replacePattern3;

    //URLs starting with http://, https://, or ftp://
    replacePattern1 = /(\b(https?|ftp):\/\/[-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|])/gim;
    replacedText = inputText.replace(replacePattern1, '<a href="$1">$1</a>');

    //URLs starting with "www." (without // before it, or it'd re-link the ones done above).
    replacePattern2 = /(^|[^\/])(www\.[\S]+(\b|$))/gim;
    replacedText = replacedText.replace(replacePattern2, '$1<a href="http://$2">$2</a>');

    //Change email addresses to mailto:: links.
    //replacePattern3 = /(\w+@[a-zA-Z_]+?\.[a-zA-Z]{2,6})/gim;
    //replacedText = replacedText.replace(replacePattern3, '<a href="mailto:$1">$1</a>');
    replacePattern3 = /([0-9a-zA-Z]+[-._+&])*[0-9a-zA-Z]+@([-0-9a-zA-Z]+[.])+[a-zA-Z]{2,6}/gim
    replacedText = replacedText.replace(replacePattern3, '<a href="mailto:$&">$&</a>');

    return '<style type="text/css">a:link {color:'+color+';}</style>' + replacedText
}

function unicodeEscape(str) {
    var code, pref = {1: '\\x0', 2: '\\x', 3: '\\u0', 4: '\\u'};
    return str.replace(/\W/g, function(c) {
        return pref[(code = c.charCodeAt(0).toString(16)).length] + code;
    });
}

function toWhatsapp(charCode) {
    
    if(emoji_replace.hasOwnProperty(charCode)) {
        return getUnicodeCharacter('0x'+emoji_replace[charCode])[0];
    }

    return false;
}

function to_softbank(inputText) {
    var replacedText = inputText
    for (var key in softbank_replacer) {
        if (replacedText.indexOf(key) !== -1)
            replacedText = replacedText.replace(new RegExp(key, "g"), softbank_replacer[key]);
    }
    return replacedText
}

function makeEmoji(path) {
    return '<img src="'+path+'.png">';
}

function emojify(inputText, emojiPath) {
    var replacedText = inputText.replace(/\&/g, "&amp;").replace(/\</g, "&lt;").replace(/\>/g, "&gt;").replace(/\n/g, "<br />").replace(/\ufe0f/g, "").replace(/\ufffc/g, "<br />")//.replace('\ud83c', '')
    //var replacedText = inputText.replace(/\ufe0f/g, "")
    prevCode = 0
    var regb = /([\ue001-\ue537])/g
    var regc = /([\u2001-\u3030])/g

    replacedText = to_softbank(replacedText)

    replacedText = replacedText.replace(regb, function(s, eChar){
        return makeEmoji(emojiPath+eChar.charCodeAt(0).toString(16).toUpperCase())
    });

    replacedText = replacedText.replace(regc, function(s, eChar){
        var res = eChar.charCodeAt(0).toString(16).toUpperCase()
        //console.log(res)
        if (emoji_code.indexOf(res) != -1)
            return makeEmoji(emojiPath+res)
        else
            return eChar;
    });

    replacedText = replacedText.replace(multiByteEmojiRegex, function(str, p1) {
             var p = ord(p1.toString(16))
             if (p>0) {
                 var res = decimalToHex(p).toString().toUpperCase()
                 if (p>8252)
                 //if (emoji_code.indexOf(res) != -1)
                     return makeEmoji(emojiPath+res.replace(/^([\da-f]+)$/i,'$1'))
                 else
                     return p1
             } else {
                 return ''
             }
        });

    return replacedText;//.replace(/<br \/>/gim, "<br \/>&nbsp;").replace(/\n/gim, "\n&nbsp;");
}

var softbank_replacer = {
    '\uD83D\uDE04':'\uE415', // Unified: 1F604
    '\uD83D\uDE0A':'\uE056', // Unified: 1F60A
    '\uD83D\uDE03':'\uE057', // Unified: 1F603
    '\u263A':'\uE414', // Unified: 263A
    '\uD83D\uDE09':'\uE405', // Unified: 1F609
    '\uD83D\uDE0D':'\uE106', // Unified: 1F60D
    '\uD83D\uDE18':'\uE418', // Unified: 1F618
    '\uD83D\uDE1A':'\uE417', // Unified: 1F61A
    '\uD83D\uDE33':'\uE40D', // Unified: 1F633
    '\uD83D\uDE0C':'\uE40A', // Unified: 1F60C
    '\uD83D\uDE01':'\uE404', // Unified: 1F601
    '\uD83D\uDE1C':'\uE105', // Unified: 1F61C
    '\uD83D\uDE1D':'\uE409', // Unified: 1F61D
    '\uD83D\uDE12':'\uE40E', // Unified: 1F612
    '\uD83D\uDE0F':'\uE402', // Unified: 1F60F
    '\uD83D\uDE13':'\uE108', // Unified: 1F613
    '\uD83D\uDE14':'\uE403', // Unified: 1F614
    '\uD83D\uDE1E':'\uE058', // Unified: 1F61E
    '\uD83D\uDE16':'\uE407', // Unified: 1F616
    '\uD83D\uDE25':'\uE401', // Unified: 1F625
    '\uD83D\uDE30':'\uE40F', // Unified: 1F630
    '\uD83D\uDE28':'\uE40B', // Unified: 1F628
    '\uD83D\uDE23':'\uE406', // Unified: 1F623
    '\uD83D\uDE22':'\uE413', // Unified: 1F622
    '\uD83D\uDE2D':'\uE411', // Unified: 1F62D
    '\uD83D\uDE02':'\uE412', // Unified: 1F602
    '\uD83D\uDE32':'\uE410', // Unified: 1F632
    '\uD83D\uDE31':'\uE107', // Unified: 1F631
    '\uD83D\uDE20':'\uE059', // Unified: 1F620
    '\uD83D\uDE21':'\uE416', // Unified: 1F621
    '\uD83D\uDE2A':'\uE408', // Unified: 1F62A
    '\uD83D\uDE37':'\uE40C', // Unified: 1F637
    '\uD83D\uDC7F':'\uE11A', // Unified: 1F47F
    '\uD83D\uDC7D':'\uE10C', // Unified: 1F47D
    '\uD83D\uDC9B':'\uE32C', // Unified: 1F49B
    '\uD83D\uDC99':'\uE32A', // Unified: 1F499
    '\uD83D\uDC9C':'\uE32D', // Unified: 1F49C
    '\uD83D\uDC97':'\uE328', // Unified: 1F497
    '\uD83D\uDC9A':'\uE32B', // Unified: 1F49A
    '\u2764':'\uE022', // Unified: 2764
    '\uD83D\uDC94':'\uE023', // Unified: 1F494
    '\uD83D\uDC93':'\uE327', // Unified: 1F493
    '\uD83D\uDC98':'\uE329', // Unified: 1F498
    '\u2728':'\uE32E', // Unified: 2728
    '\u2B50':'\uE32F', // Unified: 2B50
    '\uD83C\uDF1F':'\uE335', // Unified: 1F31F
    '\uD83D\uDCA2':'\uE334', // Unified: 1F4A2
    '\u2757':'\uE021', // Unified: 2757
    '\u2755':'\uE337', // Unified: 2755
    '\u2753':'\uE020', // Unified: 2753
    '\u2754':'\uE336', // Unified: 2754
    '\uD83D\uDCA4':'\uE13C', // Unified: 1F4A4
    '\uD83D\uDCA8':'\uE330', // Unified: 1F4A8
//    '\uD83D\uDE05':'\uE331', // Unified: 1F605
    '\uD83C\uDFB6':'\uE326', // Unified: 1F3B6
    '\uD83C\uDFB5':'\uE03E', // Unified: 1F3B5
    '\uD83D\uDD25':'\uE11D', // Unified: 1F525
    '\uD83D\uDCA9':'\uE05A', // Unified: 1F4A9
    '\uD83D\uDC4D':'\uE00E', // Unified: 1F44D
    '\uD83D\uDC4E':'\uE421', // Unified: 1F44E
    '\uD83D\uDC4C':'\uE420', // Unified: 1F44C
    '\uD83D\uDC4A':'\uE00D', // Unified: 1F44A
    '\u270A':'\uE010', // Unified: 270A
    '\u270C':'\uE011', // Unified: 270C
    '\uD83D\uDC4B':'\uE41E', // Unified: 1F44B
    '\u270B':'\uE012', // Unified: 1F64B
    '\uD83D\uDC50':'\uE422', // Unified: 1F450
    '\uD83D\uDC46':'\uE22E', // Unified: 1F446
    '\uD83D\uDC47':'\uE22F', // Unified: 1F447
    '\uD83D\uDC49':'\uE231', // Unified: 1F449
    '\uD83D\uDC48':'\uE230', // Unified: 1F448
    '\uD83D\uDE4C':'\uE427', // Unified: 1F64C
    '\uD83D\uDE4F':'\uE41D', // Unified: 1F64F
    '\u261D':'\uE00F', // Unified: 261D
    '\uD83D\uDC4F':'\uE41F', // Unified: 1F44F
    '\uD83D\uDCAA':'\uE14C', // Unified: 1F4AA
    '\uD83D\uDEB6':'\uE201', // Unified: 1F6B6
    '\uD83C\uDFC3':'\uE115', // Unified: 1F3C3
    '\uD83D\uDC6B':'\uE428', // Unified: 1F46B
    '\uD83D\uDC83':'\uE51F', // Unified: 1F483
    '\uD83D\uDC6F':'\uE429', // Unified: 1F46F
    '\uD83D\uDE46':'\uE424', // Unified: 1F646
    '\uD83D\uDE45':'\uE423', // Unified: 1F645
    '\uD83D\uDC81':'\uE253', // Unified: 1F481
    '\uD83D\uDE47':'\uE426', // Unified: 1F647
    '\uD83D\uDC8F':'\uE111', // Unified: 1F48F
    '\uD83D\uDC91':'\uE425', // Unified: 1F491
    '\uD83D\uDC86':'\uE31E', // Unified: 1F486
    '\uD83D\uDC87':'\uE31F', // Unified: 1F487
    '\uD83D\uDC85':'\uE31D', // Unified: 1F485
    '\uD83D\uDC66':'\uE001', // Unified: 1F466
    '\uD83D\uDC67':'\uE002', // Unified: 1F467
    '\uD83D\uDC69':'\uE005', // Unified: 1F469
    '\uD83D\uDC68':'\uE004', // Unified: 1F468
    '\uD83D\uDC76':'\uE51A', // Unified: 1F476
    '\uD83D\uDC75':'\uE519', // Unified: 1F475
    '\uD83D\uDC74':'\uE518', // Unified: 1F474
    '\uD83D\uDC71':'\uE515', // Unified: 1F471
    '\uD83D\uDC72':'\uE516', // Unified: 1F472
    '\uD83D\uDC73':'\uE517', // Unified: 1F473
    '\uD83D\uDC77':'\uE51B', // Unified: 1F477
    '\uD83D\uDC6E':'\uE152', // Unified: 1F46E
    '\uD83D\uDC7C':'\uE04E', // Unified: 1F47C
    '\uD83D\uDC78':'\uE51C', // Unified: 1F478
    '\uD83D\uDC82':'\uE51E', // Unified: 1F482
    '\uD83D\uDC80':'\uE11C', // Unified: 1F480
//    '\uD83D\uDC3E':'\uE536', // Unified: 1F43E
    '\uD83D\uDC63':'\uE536', // Unified: 1F463
    '\uD83D\uDC8B':'\uE003', // Unified: 1F48B
    '\uD83D\uDC44':'\uE41C', // Unified: 1F444
    '\uD83D\uDC42':'\uE41B', // Unified: 1F442
    '\uD83D\uDC40':'\uE419', // Unified: 1F440
    '\uD83D\uDC43':'\uE41A', // Unified: 1F443
    // Beginning of section 2 (Nature)
    '\u2600':'\uE04A', // Unified: 2600
    '\u2614':'\uE04B', // Unified: 2614
    '\u2601':'\uE049', // Unified: 2601
    '\u26C4':'\uE048', // Unified: 26C4
    '\uD83C\uDF19':'\uE04C', // Unified: 1F319
    '\u26A1':'\uE13D', // Unified: 26A1
    '\uD83C\uDF00':'\uE443', // Unified: 1F300
    '\uD83C\uDF0A':'\uE43E', // Unified: 1F30A
    '\uD83D\uDC31':'\uE04F', // Unified: 1F431
    '\uD83D\uDC36':'\uE052', // Unified: 1F436
    '\uD83D\uDC2D':'\uE053', // Unified: 1F42D
    '\uD83D\uDC39':'\uE524', // Unified: 1F439
    '\uD83D\uDC30':'\uE52C', // Unified: 1F430
    '\uD83D\uDC3A':'\uE52A', // Unified: 1F43A
    '\uD83D\uDC38':'\uE531', // Unified: 1F438
    '\uD83D\uDC2F':'\uE050', // Unified: 1F42F
    '\uD83D\uDC28':'\uE527', // Unified: 1F428
    '\uD83D\uDC3B':'\uE051', // Unified: 1F43B
    '\uD83D\uDC37':'\uE10B', // Unified: 1F437
    '\uD83D\uDC2E':'\uE52B', // Unified: 1F42E
    '\uD83D\uDC17':'\uE52F', // Unified: 1F417
    '\uD83D\uDC12':'\uE528', // Unified: 1F412
    '\uD83D\uDC34':'\uE01A', // Unified: 1F434
    '\uD83D\uDC0E':'\uE134', // Unified: 1F40E
    '\uD83D\uDC2B':'\uE530', // Unified: 1F42B
    '\uD83D\uDC11':'\uE529', // Unified: 1F411
    '\uD83D\uDC18':'\uE526', // Unified: 1F418
    '\uD83D\uDC0D':'\uE52D', // Unified: 1F40D
    '\uD83D\uDC26':'\uE521', // Unified: 1F426
    '\uD83D\uDC24':'\uE523', // Unified: 1F424
    '\uD83D\uDC14':'\uE52E', // Unified: 1F414
    '\uD83D\uDC27':'\uE055', // Unified: 1F427
    '\uD83D\uDC1B':'\uE525', // Unified: 1F41B
    '\uD83D\uDC19':'\uE10A', // Unified: 1F419
    '\uD83D\uDC35':'\uE109', // Unified: 1F435
    '\uD83D\uDC20':'\uE522', // Unified: 1F420
    '\uD83D\uDC1F':'\uE019', // Unified: 1F41F
    '\uD83D\uDC33':'\uE054', // Unified: 1F433
    '\uD83D\uDC2C':'\uE520', // Unified: 1F42C
    '\uD83D\uDC90':'\uE306', // Unified: 1F490
    '\uD83C\uDF38':'\uE030', // Unified: 1F338
    '\uD83C\uDF37':'\uE304', // Unified: 1F337
    '\uD83C\uDF40':'\uE110', // Unified: 1F340
    '\uD83C\uDF39':'\uE032', // Unified: 1F339
    '\uD83C\uDF3B':'\uE305', // Unified: 1F33B
    '\uD83C\uDF3A':'\uE303', // Unified: 1F33A
    '\uD83C\uDF41':'\uE118', // Unified: 1F341
    '\uD83C\uDF43':'\uE447', // Unified: 1F343
    '\uD83C\uDF42':'\uE119', // Unified: 1F342
    '\uD83C\uDF34':'\uE307', // Unified: 1F334
    '\uD83C\uDF35':'\uE308', // Unified: 1F335
    '\uD83C\uDF3E':'\uE444', // Unified: 1F33E
    '\uD83D\uDC1A':'\uE441', // Unified: 1F41A
    // Beginning of section 3 (Misc)
    '\uD83C\uDF8D':'\uE436', // Unified: 1F38D
    '\uD83D\uDC9D':'\uE437', // Unified: 1F49D
    '\uD83C\uDF8E':'\uE438', // Unified: 1F38E
    '\uD83C\uDF92':'\uE43A', // Unified: 1F392
    '\uD83C\uDF93':'\uE439', // Unified: 1F393
    '\uD83C\uDF8F':'\uE43B', // Unified: 1F38F
    '\uD83C\uDF86':'\uE117', // Unified: 1F386
    '\uD83C\uDF87':'\uE440', // Unified: 1F387
    '\uD83C\uDF90':'\uE442', // Unified: 1F390
    '\uD83C\uDF91':'\uE446', // Unified: 1F391
    '\uD83C\uDF83':'\uE445', // Unified: 1F383
    '\uD83D\uDC7B':'\uE11B', // Unified: 1F47B
    '\uD83C\uDF85':'\uE448', // Unified: 1F385
    '\uD83C\uDF84':'\uE033', // Unified: 1F384
    '\uD83C\uDF81':'\uE112', // Unified: 1F381
    '\uD83D\uDD14':'\uE325', // Unified: 1F514
    '\uD83C\uDF89':'\uE312', // Unified: 1F389
    '\uD83C\uDF88':'\uE310', // Unified: 1F388
    '\uD83D\uDCBF':'\uE126', // Unified: 1F4BF
    '\uD83D\uDCC0':'\uE127', // Unified: 1F4C0
    '\uD83D\uDCF7':'\uE008', // Unified: 1F4F7
    '\uD83C\uDFA5':'\uE03D', // Unified: 1F4F9
    '\uD83D\uDCBB':'\uE00C', // Unified: 1F4BB
    '\uD83D\uDCFA':'\uE12A', // Unified: 1F4FA
    '\uD83D\uDCF1':'\uE00A', // Unified: 1F4F1
    '\uD83D\uDCE0':'\uE00B', // Unified: 1F4E0
    '\u260E':'\uE009', // Unified: 260E
    '\uD83D\uDCBD':'\uE316', // Unified: 1F4BD
    '\uD83D\uDCFC':'\uE129', // Unified: 1F4FC
    '\uD83D\uDD0A':'\uE141', // Unified: 1F50A
    '\uD83D\uDCE2':'\uE142', // Unified: 1F4E2
    '\uD83D\uDCE3':'\uE317', // Unified: 1F4E3
    '\uD83D\uDCFB':'\uE128', // Unified: 1F4FB
    '\uD83D\uDCE1':'\uE14B', // Unified: 1F4E1
    '\u27BF':'\uE211', // Unified: 27BF
    '\uD83D\uDD0D':'\uE114', // Unified: 1F50D
    '\uD83D\uDD13':'\uE145', // Unified: 1F513
    '\uD83D\uDD12':'\uE144', // Unified: 1F512
    '\uD83D\uDD11':'\uE03F', // Unified: 1F511
    '\u2702':'\uE313', // Unified: 2702
    '\uD83D\uDD28':'\uE116', // Unified: 1F528
    '\uD83D\uDCA1':'\uE10F', // Unified: 1F4A1
    '\uD83D\uDCF2':'\uE104', // Unified: 1F4F2
    '\uD83D\uDCE9':'\uE103', // Unified: 1F4E9
    '\uD83D\uDCEB':'\uE101', // Unified: 1F4EB
    '\uD83D\uDCEE':'\uE102', // Unified: 1F4EE
    '\uD83D\uDEC0':'\uE13F', // Unified: 1F6C0
    '\uD83D\uDEBD':'\uE140', // Unified: 1F6BD
    '\uD83D\uDCBA':'\uE11F', // Unified: 1F4BA
    '\uD83D\uDCB0':'\uE12F', // Unified: 1F4B0
    '\uD83D\uDD31':'\uE031', // Unified: 1F531
    '\uD83D\uDEAC':'\uE30E', // Unified: 1F6AC
    '\uD83D\uDCA3':'\uE311', // Unified: 1F4A3
    '\uD83D\uDD2B':'\uE113', // Unified: 1F52B
    '\uD83D\uDC8A':'\uE30F', // Unified: 1F48A
    '\uD83D\uDC89':'\uE13B', // Unified: 1F489
    '\uD83C\uDFC8':'\uE42B', // Unified: 1F3C8
    '\uD83C\uDFC0':'\uE42A', // Unified: 1F3C0
    '\u26BD':'\uE018', // Unified: 26BD
    '\u26BE':'\uE016', // Unified: 26BE
    '\uD83C\uDFBE':'\uE015', // Unified: 1F3BE
    '\u26F3':'\uE014', // Unified: 26F3
    '\uD83C\uDFB1':'\uE42C', // Unified: 1F3B1
    '\uD83C\uDFCA':'\uE42D', // Unified: 1F3CA
    '\uD83C\uDFC4':'\uE017', // Unified: 1F3C4
    '\uD83C\uDFBF':'\uE013', // Unified: 1F3BF
    '\u2660':'\uE20E', // Unified: 2660
    '\u2665':'\uE20C', // Unified: 2665
    '\u2663':'\uE20F', // Unified: 2663
    '\u2666':'\uE20D', // Unified: 2666
    '\uD83C\uDFC6':'\uE131', // Unified: 1F3C6
    '\uD83D\uDC7E':'\uE12B', // Unified: 1F47E
    '\uD83C\uDFAF':'\uE130', // Unified: 1F3AF
    '\uD83C\uDC04':'\uE12D', // Unified: 1F004
    '\uD83C\uDFAC':'\uE324', // Unified: 1F3AC
    '\uD83D\uDCDD':'\uE301', // Unified: 1F4DD
//    '\uD83D\uDCD3':'\uE148', // Unified: 1F4D3
    '\uD83D\uDCD6':'\uE148', // Unified: 1F4D6
    '\uD83C\uDFA8':'\uE502', // Unified: 1F3A8
    '\uD83C\uDFA4':'\uE03C', // Unified: 1F3A4
    '\uD83C\uDFA7':'\uE30A', // Unified: 1F3A7
    '\uD83C\uDFBA':'\uE042', // Unified: 1F3BA
    '\uD83C\uDFB7':'\uE040', // Unified: 1F3B7
    '\uD83C\uDFB8':'\uE041', // Unified: 1F3B8
    '\u303D':'\uE12C', // Unified: 303D
//    '\uD83D\uDC5E':'\uE007', // Unified: 1F45E
    '\uD83D\uDC5F':'\uE007', // Unicode: 1F45F
    '\uD83D\uDC61':'\uE31A', // Unified: 1F461
    '\uD83D\uDC60':'\uE13E', // Unified: 1F460
    '\uD83D\uDC62':'\uE31B', // Unified: 1F462
    '\uD83D\uDC55':'\uE006', // Unified: 1F455
    '\uD83D\uDC54':'\uE302', // Unified: 1F454
    '\uD83D\uDC57':'\uE319', // Unified: 1F457
    '\uD83D\uDC58':'\uE321', // Unified: 1F458
    '\uD83D\uDC59':'\uE322', // Unified: 1F459
    '\uD83C\uDF80':'\uE314', // Unified: 1F380
    '\uD83C\uDFA9':'\uE503', // Unified: 1F3A9
    '\uD83D\uDC51':'\uE10E', // Unified: 1F451
    '\uD83D\uDC52':'\uE318', // Unified: 1F452
    '\uD83C\uDF02':'\uE43C', // Unified: 1F302
    '\uD83D\uDCBC':'\uE11E', // Unified: 1F4BC
    '\uD83D\uDC5C':'\uE323', // Unified: 1F45C
    '\uD83D\uDC84':'\uE31C', // Unified: 1F484
    '\uD83D\uDC8D':'\uE034', // Unified: 1F48D
    '\uD83D\uDC8E':'\uE035', // Unified: 1F48E
    '\u2615':'\uE045', // Unified: 2615
    '\uD83C\uDF75':'\uE338', // Unified: 1F375
    '\uD83C\uDF7A':'\uE047', // Unified: 1F37A
    '\uD83C\uDF7B':'\uE30C', // Unified: 1F37B
    '\uD83C\uDF78':'\uE044', // Unified: 1F378
    '\uD83C\uDF76':'\uE30B', // Unified: 1F376
    '\uD83C\uDF74':'\uE043', // Unified: 1F374
    '\uD83C\uDF54':'\uE120', // Unified: 1F354
    '\uD83C\uDF5F':'\uE33B', // Unified: 1F35F
    '\uD83C\uDF5D':'\uE33F', // Unified: 1F35D
    '\uD83C\uDF5B':'\uE341', // Unified: 1F35B
    '\uD83C\uDF71':'\uE34C', // Unified: 1F371
    '\uD83C\uDF63':'\uE344', // Unified: 1F363
    '\uD83C\uDF59':'\uE342', // Unified: 1F359
    '\uD83C\uDF58':'\uE33D', // Unified: 1F358
    '\uD83C\uDF5A':'\uE33E', // Unified: 1F35A
    '\uD83C\uDF5C':'\uE340', // Unified: 1F35C
    '\uD83C\uDF72':'\uE34D', // Unified: 1F372
    '\uD83C\uDF5E':'\uE339', // Unified: 1F35E
    '\uD83C\uDF73':'\uE147', // Unified: 1F373
    '\uD83C\uDF62':'\uE343', // Unified: 1F362
    '\uD83C\uDF61':'\uE33C', // Unified: 1F361
    '\uD83C\uDF66':'\uE33A', // Unified: 1F366
    '\uD83C\uDF67':'\uE43F', // Unified: 1F367
    '\uD83C\uDF82':'\uE34B', // Unified: 1F382
    '\uD83C\uDF70':'\uE046', // Unified: 1F370
    '\uD83C\uDF4E':'\uE345', // Unified: 1F34E
    '\uD83C\uDF4A':'\uE346', // Unified: 1F34A
    '\uD83C\uDF49':'\uE348', // Unified: 1F349
    '\uD83C\uDF53':'\uE347', // Unified: 1F353
    '\uD83C\uDF46':'\uE34A', // Unified: 1F346
    '\uD83C\uDF45':'\uE349', // Unified: 1F345
    // Beginning of section 4 (Buildings)
    '\uD83C\uDFE0':'\uE036', // Unified: 1F3E0
    '\uD83C\uDFEB':'\uE157', // Unified: 1F3EB
    '\uD83C\uDFE2':'\uE038', // Unified: 1F3E2
    '\uD83C\uDFE3':'\uE153', // Unified: 1F3E3
    '\uD83C\uDFE5':'\uE155', // Unified: 1F3E5
    '\uD83C\uDFE6':'\uE14D', // Unified: 1F3E6
    '\uD83C\uDFEA':'\uE156', // Unified: 1F3EA
    '\uD83C\uDFE9':'\uE501', // Unified: 1F3E9
    '\uD83C\uDFE8':'\uE158', // Unified: 1F3E8
    '\uD83D\uDC92':'\uE43D', // Unified: 1F492
    '\u26EA':'\uE037', // Unified: 26EA
    '\uD83C\uDFEC':'\uE504', // Unified: 1F3EC
    '\uD83C\uDF07':'\uE44A', // Unified: 1F307
    '\uD83C\uDF06':'\uE146', // Unified: 1F306
    '\uD83C\uDFE7':'\uE50A', // Unified: 1F3E7
    '\uD83C\uDFEF':'\uE505', // Unified: 1F3EF
    '\uD83C\uDFF0':'\uE506', // Unified: 1F3F0
    '\u26FA':'\uE122', // Unified: 26FA
    '\uD83C\uDFED':'\uE508', // Unified: 1F3ED
    '\uD83D\uDDFC':'\uE509', // Unified: 1F5FC
    '\uD83D\uDDFB':'\uE03B', // Unified: 1F5FB
    '\uD83C\uDF04':'\uE04D', // Unified: 1F304
    '\uD83C\uDF05':'\uE449', // Unified: 1F305
    '\uD83C\uDF03':'\uE44B', // Unified: 1F303
    '\uD83D\uDDFD':'\uE51D', // Unified: 1F5FD
    '\uD83C\uDF08':'\uE44C', // Unified: 1F308
    '\uD83C\uDFA1':'\uE124', // Unified: 1F3A1
    '\u26F2':'\uE121', // Unified: 26F2
    '\uD83C\uDFA2':'\uE433', // Unified: 1F3A2
    '\uD83D\uDCA6':'\uE331', // Unified: 1F4A6
    '\uD83D\uDEA2':'\uE202', // Unified: 1F6A2
    '\uD83D\uDEA4':'\uE135', // Unified: 1F6A4
    '\u26F5':'\uE01C', // Unified: 26F5
    '\u2708':'\uE01D', // Unified: 2708
    '\uD83D\uDE80':'\uE10D', // Unified: 1F680
    '\uD83D\uDEB2':'\uE136', // Unified: 1F6B2
    '\uD83D\uDE99':'\uE42E', // Unified: 1F699
    '\uD83D\uDE97':'\uE01B', // Unified: 1F697
    '\uD83D\uDE95':'\uE15A', // Unified: 1F695
    '\uD83D\uDE8C':'\uE159', // Unified: 1F68C
    '\uD83D\uDE93':'\uE432', // Unified: 1F693
    '\uD83D\uDE92':'\uE430', // Unified: 1F692
    '\uD83D\uDE91':'\uE431', // Unified: 1F691
    '\uD83D\uDE9A':'\uE42F', // Unified: 1F69A
    '\uD83D\uDE83':'\uE01E', // Unified: 1F683
    '\uD83D\uDE89':'\uE039', // Unified: 1F689
    '\uD83D\uDE84':'\uE435', // Unified: 1F684
    '\uD83D\uDE85':'\uE01F', // Unified: 1F685
    '\uD83C\uDFAB':'\uE125', // Unified: 1F3AB
    '\u26FD':'\uE03A', // Unified: 26FD
    '\uD83D\uDEA5':'\uE14E', // Unified: 1F6A5
    '\u26A0':'\uE252', // Unified: 26A0
    '\uD83D\uDEA7':'\uE137', // Unified: 1F6A7
    '\uD83D\uDD30':'\uE209', // Unified: 1F530
    '\uD83C\uDFE7':'\uE154', // Unified: 1F3E7
    '\uD83C\uDFB0':'\uE133', // Unified: 1F3B0
    '\uD83D\uDE8F':'\uE150', // Unified: 1F68F
    '\uD83D\uDC88':'\uE320', // Unified: 1F488
    '\u2668':'\uE123', // Unified: 2668
    '\uD83C\uDFC1':'\uE132', // Unified: 1F3C1
    '\uD83C\uDF8C':'\uE143', // Unified: 1F38C
    '\uD83C\uDDEF\uD83C\uDDF5':'\uE50B', // Unified: 1F1EF 1F1F5
    '\uD83C\uDDF0\uD83C\uDDF7':'\uE514', // Unified: 1F1F0 1F1F7
    '\uD83C\uDDE8\uD83C\uDDF3':'\uE513', // Unified: 1F1E8 1F1F3
    '\uD83C\uDDFA\uD83C\uDDF8':'\uE50C', // Unified: 1F1FA 1F1F8
    '\uD83C\uDDEB\uD83C\uDDF7':'\uE50D', // Unified: 1F1EB 1F1F7
    '\uD83C\uDDEA\uD83C\uDDF8':'\uE511', // Unified: 1F1EA 1F1F8
    '\uD83C\uDDEE\uD83C\uDDF9':'\uE50F', // Unified: 1F1EE 1F1F9
    '\uD83C\uDDF7\uD83C\uDDFA':'\uE512', // Unified: 1F1F7 1F1FA
    '\uD83C\uDDEC\uD83C\uDDE7':'\uE510', // Unified: 1F1EC 1F1E7
    '\uD83C\uDDE9\uD83C\uDDEA':'\uE50E', // Unified: 1F1E9 1F1EA
    // Beginning of section 5 (Symbols)
    '\u0031\u20E3':'\uE21C', // Unified: 0031 20E3
    '\u0032\u20E3':'\uE21D', // Unified: 0032 20E3
    '\u0033\u20E3':'\uE21E', // Unified: 0033 20E3
    '\u0034\u20E3':'\uE21F', // Unified: 0034 20E3
    '\u0035\u20E3':'\uE220', // Unified: 0035 20E3
    '\u0036\u20E3':'\uE221', // Unified: 0036 20E3
    '\u0037\u20E3':'\uE222', // Unified: 0037 20E3
    '\u0038\u20E3':'\uE223', // Unified: 0038 20E3
    '\u0039\u20E3':'\uE224', // Unified: 0039 20E3
    '\u0030\u20E3':'\uE225', // Unified: 0030 20E3
    '\u0023\u20E3':'\uE210', // Unified: 0023 20E3
    '\u2B06':'\uE232', // Unified: 2B06
    '\u2B07':'\uE233', // Unified: 2B07
    '\u2B05':'\uE235', // Unified: 2B05
    '\u27A1':'\uE234', // Unified: 27A1
    '\u2197':'\uE236', // Unified: 2197
    '\u2196':'\uE237', // Unified: 2196
    '\u2198':'\uE238', // Unified: 2198
    '\u2199':'\uE239', // Unified: 2199
    '\u25C0':'\uE23B', // Unified: 25C0
    '\u25B6':'\uE23A', // Unified: 25B6
    '\u23EA':'\uE23D', // Unified: 23EA
    '\u23E9':'\uE23C', // Unified: 23E9
    '\uD83C\uDD97':'\uE24D', // Unified: 1F197
    '\uD83C\uDD95':'\uE212', // Unified: 1F195
    '\uD83D\uDD1D':'\uE24C', // Unified: 1F51D
    '\uD83C\uDD99':'\uE213', // Unified: 1F199
    '\uD83C\uDD92':'\uE214', // Unified: 1F192
    '\uD83C\uDFA6':'\uE507', // Unified: 1F3A6
    '\uD83C\uDE01':'\uE203', // Unified: 1F201
    '\uD83D\uDCF6':'\uE20B', // Unified: 1F4F6
    '\uD83C\uDE35':'\uE22A', // Unified: 1F235
    '\uD83C\uDE33':'\uE22B', // Unified: 1F233
    '\uD83C\uDE50':'\uE226', // Unified: 1F250
    '\uD83C\uDE39':'\uE227', // Unified: 1F239
    '\uD83C\uDE2F':'\uE22C', // Unified: 1F22F
    '\uD83C\uDE3A':'\uE22D', // Unified: 1F23A
    '\uD83C\uDE36':'\uE215', // Unified: 1F236
    '\uD83C\uDE1A':'\uE216', // Unified: 1F21A
    '\uD83C\uDE37':'\uE217', // Unified: 1F237
    '\uD83C\uDE38':'\uE218', // Unified: 1F238
    '\uD83C\uDE02':'\uE228', // Unified: 1F202
    '\uD83D\uDEBB':'\uE151', // Unified: 1F6BB
    '\uD83D\uDEB9':'\uE138', // Unified: 1F6B9
    '\uD83D\uDEBA':'\uE139', // Unified: 1F6BA
    '\uD83D\uDEBC':'\uE13A', // Unified: 1F6BC
    '\uD83D\uDEAD':'\uE208', // Unified: 1F6AD
    '\uD83C\uDD7F':'\uE14F', // Unified: 1F17F
    '\u267F':'\uE20A', // Unified: 267F
    '\uD83D\uDE87':'\uE434', // Unified: 1F687
    '\uD83D\uDEBE':'\uE309', // Unified: 1F6BE
    '\u3299':'\uE315', // Unified: 3299
    '\u3297':'\uE30D', // Unified: 3297
    '\uD83D\uDD1E':'\uE207', // Unified: 1F51E
    '\uD83C\uDD94':'\uE229', // Unified: 1F194
    '\u2733':'\uE206', // Unified: 2733
    '\u2734':'\uE205', // Unified: 2734
    '\uD83D\uDC9F':'\uE204', // Unified: 1F49F
    '\uD83C\uDD9A':'\uE12E', // Unified: 1F19A
    '\uD83D\uDCF3':'\uE250', // Unified: 1F4F3
    '\uD83D\uDCF4':'\uE251', // Unified: 1F4F4
    '\uD83D\uDCB9':'\uE14A', // Unified: 1F4B9
    '\uD83D\uDCB1':'\uE149', // Unified: 1F4B1
    '\u2648':'\uE23F', // Unified: 2648
    '\u2649':'\uE240', // Unified: 2649
    '\u264A':'\uE241', // Unified: 264A
    '\u264B':'\uE242', // Unified: 264B
    '\u264C':'\uE243', // Unified: 264C
    '\u264D':'\uE244', // Unified: 264D
    '\u264E':'\uE245', // Unified: 264E
    '\u264F':'\uE246', // Unified: 264F
    '\u2650':'\uE247', // Unified: 2650
    '\u2651':'\uE248', // Unified: 2651
    '\u2652':'\uE249', // Unified: 2652
    '\u2653':'\uE24A', // Unified: 2653
    '\u26CE':'\uE24B', // Unified: 26CE
    '\uD83D\uDD2F':'\uE23E', // Unified: 1F52F
    '\uD83C\uDD70':'\uE532', // Unified: 1F170
    '\uD83C\uDD71':'\uE533', // Unified: 1F171
    '\uD83C\uDD8E':'\uE534', // Unified: 1F18E
    '\uD83C\uDD7E':'\uE535', // Unified: 1F17E
    '\uD83D\uDD32':'\uE21A', // Unified: 1F532
    '\uD83D\uDD34':'\uE219', // Unified: 1F534
    '\uD83D\uDD33':'\uE21B', // Unified: 1F533
    '\uD83D\uDD5B':'\uE02F', // Unified: 1F55B
    '\uD83D\uDD50':'\uE024', // Unified: 1F550
    '\uD83D\uDD51':'\uE025', // Unified: 1F551
    '\uD83D\uDD52':'\uE026', // Unified: 1F552
    '\uD83D\uDD53':'\uE027', // Unified: 1F553
    '\uD83D\uDD54':'\uE028', // Unified: 1F554
    '\uD83D\uDD55':'\uE029', // Unified: 1F555
    '\uD83D\uDD56':'\uE02A', // Unified: 1F556
    '\uD83D\uDD57':'\uE02B', // Unified: 1F557
    '\uD83D\uDD58':'\uE02C', // Unified: 1F558
    '\uD83D\uDD59':'\uE02D', // Unified: 1F559
    '\uD83D\uDD5A':'\uE02E', // Unified: 1F55A
    '\u2B55':'\uE332', // Unified: 2B55
    '\u274C':'\uE333', // Unified: 274C
    '\u00A9':'\uE24E', // Unified: 00A9
    '\u00AE':'\uE24F', // Unified: 00AE
    '\u2122':'\uE537' // Unified: 2122
}

var emoji_replace = {
    '263A':'E414',
    '270C':'E011',
    '2764':'E022',
    '2B50':'E32F',
    '2600':'E04A',
    '2601':'E049',
    '26A1':'E13D',
    '2614':'E04B',
    '26C4':'E048',
    '2702':'E313',
    'DFC1':'E132',
    'DC04':'E12D',
    '2197':'E236',
    '26BD':'E018',
    '26BE':'E016',
    '26F3':'E014',
    '2615':'E045',
    '26EA':'E037',
    '26FA':'E122',
    '26F5':'E01C',
    '2708':'E01D',
    '26A0':'E252',
    '26FD':'E03A',
    '2B06':'E232',
    '2B07':'E233',
    '2B05':'E235',
    '27A1':'E234',
    'DE2F':'E22C',
    'DE1A':'E417',
    'DD7F':'E14F',
    '267F':'E20A',
    '2733':'E206',
    '2734':'E205',
    '2648':'E23F',
    '2649':'E240',
    '264A':'E241',
    '264B':'E242',
    '264C':'E243',
    '264D':'E244',
    '264E':'E245',
    '264F':'E246',
    '2650':'E247',
    '2651':'E248',
    '2652':'E249',
    '2653':'E24A',
    '2757':'E021',
    '2B55':'E332',
    '303D':'E12C',
    '260E':'E049',
    '2668':'E123',
    //'2191',
    '2196':'E237',
    '2198':'E238',
    '2199':'E239',
    '25C0':'E23B',
    '25B6':'E23A',
    '3299':'E315',
    '3297':'E30D',
    '2660':'E20E',
    '2665':'E20C',
    '2663':'E20F',
    '2666':'E20D'
}

var emoji_code = [

'E415','E057','1F600','E056','E414','E405','E106','E418','E417','1F617','1F619','E105','E409','1F61B','E40D','E404','E403',
'E40A','E40E','E058','E406','E413','E412','E411','E408','E401','E40F','1F605','E108','1F629','1F62B','E40B','E107','E059',
'E416','1F624','E407','1F606','1F60B','E40C','1F60E','1F634','1F635','E410','1F61F','1F626','1F627','1F608','E11A','1F62E',
'1F62C','1F610','1F615','1F62F','1F636','1F607','E402','1F611','E516','E517','E152','E51B','E51E','E51A','E001','E002','E004',
'E005','E518','E519','E515','E04E','E51C','1F63A','1F638','1F63B','1F63D','1F63C','1F640','1F63F','1F639','1F63E','1F479',
'1F47A','1F648','1F649','1F64A','E11C','E10C','E05A','E11D','E32E','E335','1F4AB','1F4A5','E334','E331','1F4A7','E13C','E330',
'E41B','E419','E41A','1F445','E41C','E00E','E421','E420','E00D','E010','E011','E41E','E012','E422','E22E','E22F','E231','E230',
'E427','E41D','E00F','E41F','E14C','E201','E115','E51F','E428','1F46A','1F46C','1F46D','E111','E425','E429','E424','E423',
'E253','1F64B','E31E','E31F','E31D','1F470','1F64E','1F64D','E426','E503','E10E','E318','E007','1F45E','E31A','E13E','E31B',
'E006','E302','1F45A','E319','1F3BD','1F456','E321','E322','E11E','E323','1F45D','1F45B','1F453','E314','E43C','E31C','E32C',
'E32A','E32D','E32B','E022','E023','E328','E327','1F495','1F496','1F49E','E329','1F48C','E003','E034','E035','1F464','1F465',
'1F4AC','E536','1F4AD',

'E052','E52A','E04F','E053','E524','E52C','E531','E050','E527','E051','E10B','1F43D','E52B','E52F','E109','E528','E01A','E529',
'E526','1F43C','E055','E521','E523','1F425','1F423','E52E','E52D','1F422','E525','1F41D','1F41C','1F41E','1F40C','E10A','E441',
'E522','E019','E520','E054','1F40B','1F404','1F40F','1F400','1F403','1F405','1F407','1F409','E134','1F410','1F413','1F415',
'1F416','1F401','1F402','1F432','1F421','1F40A','E530','1F42A','1F406','1F408','1F429','1F43E','E306','E030','E304','E110',
'E032','E305','E303','E118','E447','E119','1F33F','E444','1F344','E308','E307','1F332','1F333','1F330','1F331','1F33C','1F310',
'1F31E','1F31D','1F31A','1F311','1F312','1F313','1F314','1F315','1F316','1F317','1F318','1F31C','1F31B','E04C','1F30D','1F30E',
'1F30F','1F30B','1F30C','1F320','E32F','E04A','26C5','E049','E13D','E04B','2744','E048','E443','1F301','E44C','E43E',

'E436','E437','E438','E43A','E439','E43B','E117','E440','E442','E446','E445','E11B','E448','E033','E112','1F38B','E312','1F38A',
'E310','E143','1F52E','E03D','E008','1F4F9','E129','E126','E127','E316','1F4BE','E00C','E00A','E009','1F4DE','1F4DF','E00B',
'E14B','E12A','E128','E141','1F509','1F508','1F507','E325','1F515','E142','E317','23F3','231B','23F0','231A','E145','E144',
'1F50F','1F510','E03F','1F50E','E10F','1F526','1F506','1F505','1F50C','1F50B','E114','1F6C1','E13F','1F6BF','E140','1F527',
'1F529','E116','1F6AA','E30E','E311','E113','1F52A','E30F','E13B','E12F','1F4B4','1F4B5','1F4B7','1F4B6','1F4B3','1F4B8','E104',
'1F4E7','1F4E5','1F4E4','2709','E103','1F4E8','1F4EF','E101','1F4EA','1F4EC','1F4ED','E102','1F4E6','E301','1F4C4','1F4C3','1F4D1',
'1F4CA','1F4C8','1F4C9','1F4DC','1F4CB','1F4C5','1F4C6','1F4C7','1F4C1','1F4C2','E313','1F4CC','1F4CE','2712','270F','1F4CF',
'1F4D0','1F4D5','1F4D7','1F4D8','1F4D9','1F4D3','1F4D4','1F4D2','1F4DA','E148','1F516','1F4DB','1F52C','1F52D','1F4F0','E502',
'E324','E03C','E30A','1F3BC','E03E','E326','1F3B9','1F3BB','E042','E040','E041','E12B','1F3AE','1F0CF','1F3B4','E12D','1F3B2',
'E130','E42B','E42A','E018','E016','E015','E42C','1F3C9','1F3B3','E014','1F6B5','1F6B4','E132','1F3C7','E131','E013','1F3C2',
'E42D','E017','1F3A3','E045','E338','E30B','1F37C','E047','E30C','E044','1F379','1F377','E043','1F355','E120','E33B','1F357',
'1F356','E33F','E341','1F364','E34C','E344','1F365','E342','E33D','E33E','E340','E34D','E343','E33C','E147','E339','1F369',
'1F36E','E33A','1F368','E43F','E34B','E046','1F36A','1F36B','1F36C','1F36D','1F36F','E345','1F34F','E346','1F34B','1F352',
'1F347','E348','E347','1F351','1F348','1F34C','1F350','1F34D','1F360','E34A','E349','1F33D',

'E036','1F3E1','E157','E038','E153','E155','E14D','E156','E501','E158','E43D','E037','E504','1F3E4','E44A','E146','E505',
'E506','E122','E508','E509','1F5FE','E03B','E04D','E449','E44B','E51D','1F309','1F3A0','E124','E121','E433','E202','E01C',
'E135','1F6A3','2693','E10D','E01D','E11F','1F681','1F682','1F68A','E039','1F69E','1F686','E435','E01F','1F688','E434',
'1F69D','E01E','1F68B','1F68E','E159','1F68D','E42E','1F698','E01B','E15A','1F696','1F69B','E42F','1F6A8','E432','1F694',
'E430','E431','1F690','E136','1F6A1','1F69F','1F6A0','1F69C','E320','E150','E125','1F6A6','E14E','E252','E137','E209','E03A',
'1F3EE','E133','E123','1F5FF','1F3AA','1F3AD','1F4CD','1F6A9','E50B','E514','E50E','E513','E50C','E50D','E511','E50F','E512',
'E510','E50A',

'E21C','E21D','E21E','E21F','E220','E221','E222','E223','E224','E225','1F51F','1F522','E210','1F523','E232','E233','E235',
'E234','1F520','1F521','1F524','E236','E237','E238','E239','2194','2195','1F504','E23B','E23A','1F53C','1F53D','21A9','21AA',
'2139','E23D','E23C','23EB','23EC','2935','2934','E24D','1F500','1F501','1F502','E212','E213','E214','1F193','1F196','E20B',
'E507','E203','E22C','E22B','E22A','1F234','1F232','E226','E227','E22D','E215','E216','E151','E138','E139','E13A','E309',
'1F6B0','1F6AE','E14F','E20A','E208','E217','E218','E228','24C2','1F6C2','1F6C4','1F6C5','1F6C3','1F251','E315','E30D','1F191',
'1F198','E229','1F6AB','E207','1F4F5','1F6AF','1F6B1','1F6B3','1F6B7','1F6B8','26D4','E206','2747','274E','2705','E205','E204',
'E12E','E250','E251','E532','E533','E534','E535','1F4A0','E211','267B','E23F','E240','E241','E242','E243','E244','E245','E246',
'E247','E248','E249','E24A','E24B','E23E','E154','E14A','1F4B2','E149','E24E','E24F','E537','E12C','3030','E24C','1F51A',
'1F519','1F51B','1F51C','E333','E332','E021','E020','E337','E336','1F503','E02F','1F567','E024','1F55C','E025','1F55D','E026',
'1F55E','E027','1F55F','E028','1F560','E029','E02A','E02B','E02C','E02D','E02E','1F561','1F562','1F563','1F564','1F565',
'1F566','2716','2795','2796','2797','E20E','E20C','E20F','E20D','1F4AE','1F4AF','2714','2611','1F518','1F517','27B0','E031',
'E21A','E21B','2B1B','2B1C','25FE','25FD','25AA','25AB','1F53A','25FB','25FC','26AB','26AA','E219','1F535','1F53B','1F536',
'1F537','1F538','1F539','2049','203C' 


];

var multiByteEmojiRegex = new RegExp("("+"\\u"+emoji_code.filter(function(el){return el.indexOf("1F")==0}).map(function(el){var uni =getUnicodeCharacter("0x"+el)[0]; return uni.charCodeAt(0).toString(16)+"|"+uni.charCodeAt(1).toString(16) }).join("|").split("|").getUnique().join("|\\u")+")", "g")

