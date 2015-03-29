import QtQuick 2.1
import Sailfish.Silica 1.0

Item {
	id: root
	anchors {
		left: parent.left
		right: parent.right
		margins: Theme.paddingLarge
	}
	height: itemSize * 5

	property real cr: 1.0
	property real cg: 0.0
	property real cb: 0.0
	property real ca: 0.5

	property bool cru: true
	property bool cgu: true
	property bool cbu: true
	property bool cau: true

	property int itemSize: 16

	Timer {
		running: true
		interval: 50
		repeat: true
		onTriggered: {
			if (cru) {
				cr += 0.11
			}
			else {
				cr -= 0.11
			}
			if (cr >= 1) {
				cru = false
			}
			else if (cr <= 0) {
				cru = true
			}
			
			if (cgu) {
				cg += 0.12
			}
			else {
				cg -= 0.12
			}
			if (cg >= 1) {
				cgu = false
			}
			else if (cg <= 0) {
				cgu = true
			}
			
			if (cbu) {
				cb += 0.13
			}
			else {
				cb -= 0.13
			}
			if (cb >= 1) {
				cbu = false
			}
			else if (cb <= 0) {
				cbu = true
			}
			
			if (cau) {
				ca += 0.05
			}
			else {
				ca -= 0.05
			}
			if (ca >= 1) {
				cau = false
			}
			else if (ca <= 0.1) {
				cau = true
			}
		}
	}

	Rectangle {
		id: id1
		width: itemSize
		height: width * 5
		color: Qt.rgba(cr, cg, cb, ca)
	}

	Rectangle {
		id: id2
		width: height * 2
		height: itemSize
		color: Qt.rgba(cr, cg, cb, ca)
		anchors {
			top: id1.top
			left: id1.right
		}
	}

	Rectangle {
		id: id3
		width: height * 2
		height: itemSize
		color: Qt.rgba(cr, cg, cb, ca)
		anchors {
			bottom: id1.bottom
			left: id1.right
		}
	}

	Rectangle {
		id: id4
		width: height * 3
		height: itemSize
		color: Qt.rgba(cr, cg, cb, ca)
		anchors {
			left: id2.right
			leftMargin: height
		}
	}

	Rectangle {
		id: id5
		width: itemSize
		height: width * 3
		color: Qt.rgba(cr, cg, cb, ca)
		anchors {
			top: id4.bottom
			left: id4.left
		}
	}

	Rectangle {
		id: id6
		width: itemSize
		height: width * 3
		color: Qt.rgba(cr, cg, cb, ca)
		anchors {
			top: id4.bottom
			right: id4.right
		}
	}

	Rectangle {
		id: id7
		width: height * 3
		height: itemSize
		color: Qt.rgba(cr, cg, cb, ca)
		anchors {
			top: id6.bottom
			left: id5.left
		}
	}

	Rectangle {
		id: id8
		width: itemSize
		height: width * 5
		color: Qt.rgba(cr, cg, cb, ca)
		anchors {
			left: id7.right
			leftMargin: width
		}
	}

	Rectangle {
		id: id9
		width: itemSize
		height: width
		color: Qt.rgba(cr, cg, cb, ca)
		anchors {
			left: id8.right
		}
	}

	Rectangle {
		id: id10
		width: itemSize
		height: width
		color: Qt.rgba(cr, cg, cb, ca)
		anchors {
			left: id8.right
			bottom: id8.bottom
		}
	}

	Rectangle {
		id: id11
		width: itemSize
		height: width * 3
		color: Qt.rgba(cr, cg, cb, ca)
		anchors {
			top: id9.bottom
			left: id9.right
		}
	}

	Rectangle {
		id: id12
		width: itemSize
		height: width * 5
		color: Qt.rgba(cr, cg, cb, ca)
		anchors {
			left: id11.right
			leftMargin: width
		}
	}

	Rectangle {
		id: id13
		width: height * 2
		height: itemSize
		color: Qt.rgba(cr, cg, cb, ca)
		anchors {
			left: id12.right
		}
	}

	Rectangle {
		id: id14
		width: height * 2
		height: itemSize
		color: Qt.rgba(cr, cg, cb, ca)
		anchors {
			left: id13.left
			top: id13.bottom
			topMargin: height
		}
	}

	Rectangle {
		id: id15
		width: height * 2
		height: itemSize
		color: Qt.rgba(cr, cg, cb, ca)
		anchors {
			left: id14.left
			top: id14.bottom
			topMargin: height
		}
	}

	Rectangle {
		id: id16
		width: itemSize
		height: width * 5
		color: Qt.rgba(cr, cg, cb, ca)
		anchors {
			left: id15.right
			leftMargin: width
		}
	}

	Rectangle {
		id: id17
		width: itemSize
		height: width
		color: Qt.rgba(cr, cg, cb, ca)
		anchors {
			left: id16.right
		}
	}

	Rectangle {
		id: id18
		width: itemSize
		height: width * 2
		color: Qt.rgba(cr, cg, cb, ca)
		anchors {
			left: id17.right
		}
	}

	Rectangle {
		id: id19
		width: itemSize
		height: width
		color: Qt.rgba(cr, cg, cb, ca)
		anchors {
			left: id17.left
			top: id17.bottom
			topMargin: height
		}
	}

	Rectangle {
		id: id20
		width: itemSize
		height: width * 2
		color: Qt.rgba(cr, cg, cb, ca)
		anchors {
			left: id19.right
			top: id19.bottom
		}
	}

	Rectangle {
		id: id21
		width: itemSize
		height: width * 5
		color: Qt.rgba(cr, cg, cb, ca)
		anchors {
			left: id20.right
			leftMargin: width
		}
	}

	Rectangle {
		id: id22
		width: itemSize
		height: width
		color: Qt.rgba(cr, cg, cb, ca)
		anchors {
			bottom: id21.bottom
			left: id21.right
		}
	}

	Rectangle {
		id: id23
		width: itemSize
		height: width * 5
		color: Qt.rgba(cr, cg, cb, ca)
		anchors {
			left: id22.right
			bottom: id22.bottom
		}
	}

	Rectangle {
		id: id24
		width: itemSize
		height: width * 3
		color: Qt.rgba(cr, cg, cb, ca)
		anchors {
			left: id23.right
			leftMargin: width
		}
	}

	Rectangle {
		id: id25
		width: height * 2
		height: itemSize
		anchors {
			left: id24.right
			top: id24.top
		}
		color: id1.color
	}

	Rectangle {
		id: id26
		width: height * 2
		height: itemSize
		anchors {
			left: id24.right
			bottom: id24.bottom
		}
		color: id1.color
	}

	Rectangle {
		id: id27
		width: itemSize
		height: width * 2
		anchors {
			top: id26.bottom
			right: id26.right
		}
		color: id1.color
	}

	Rectangle {
		id: id28
		width: height * 2
		height: itemSize
		anchors {
			right: id27.left
			bottom: id27.bottom
		}
		color: id1.color
	}
}
