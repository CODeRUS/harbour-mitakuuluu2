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
		height: width * 3
		color: Qt.rgba(cr, cg, cb, ca)
	}

	Rectangle {
		id: id2
		width: height * 2
		height: itemSize
		anchors {
			left: id1.right
			top: id1.top
		}
		color: id1.color
	}

	Rectangle {
		id: id3
		width: height * 2
		height: itemSize
		anchors {
			left: id1.right
			bottom: id1.bottom
		}
		color: id1.color
	}

	Rectangle {
		id: id4
		width: itemSize
		height: width * 2
		anchors {
			top: id3.bottom
			right: id3.right
		}
		color: id1.color
	}

	Rectangle {
		id: id5
		width: height * 2
		height: itemSize
		anchors {
			right: id4.left
			bottom: id4.bottom
		}
		color: id1.color
	}

	Rectangle {
		id: id6
		width: height * 3
		height: itemSize
		anchors {
			left: id2.right
			leftMargin: height
		}
		color: id1.color
	}

	Rectangle {
		id: id7
		width: itemSize
		height: width * 4
		anchors {
			left: id6.left
			top: id6.bottom
		}
		color: id1.color
	}

	Rectangle {
		id: id8
		width: itemSize
		height: width * 4
		anchors {
			right: id6.right
			top: id6.bottom
		}
		color: id1.color
	}

	Rectangle {
		id: id9
		width: itemSize
		height: width
		anchors {
			right: id8.left
			top: id6.top
			topMargin: height * 2
		}
		color: id1.color
	}

	Rectangle {
		id: id10
		width: itemSize
		height: width * 5
		anchors {
			left: id8.right
			leftMargin: width
		}
		color: id1.color
	}

	Rectangle {
		id: id11
		width: itemSize
		height: width * 5
		anchors {
			left: id10.right
			leftMargin: width
		}
		color: id1.color
	}

	Rectangle {
		id: id12
		width: height * 2
		height: itemSize
		anchors {
			left: id11.right
			bottom: id11.bottom
		}
		color: id1.color
	}

	Rectangle {
		id: id13
		width: itemSize
		height: width * 5
		anchors {
			left: id12.right
			leftMargin: width
		}
		color: id1.color
	}

	Rectangle {
		id: id14
		width: height * 2
		height: itemSize
		anchors {
			left: id13.right
			top: id13.top
		}
		color: id1.color
	}

	Rectangle {
		id: id15
		width: height * 2
		height: itemSize
		anchors {
			left: id13.right
			top: id13.top
			topMargin: width
		}
		color: id1.color
	}

	Rectangle {
		id: id16
		width: itemSize
		height: width * 5
		anchors {
			left: id15.right
			leftMargin: width
		}
		color: id1.color
	}

	Rectangle {
		id: id17
		width: itemSize
		height: width * 3
		anchors {
			left: id16.right
			leftMargin: width
		}
		color: id1.color
	}

	Rectangle {
		id: id18
		width: height * 2
		height: itemSize
		anchors {
			left: id17.right
			top: id17.top
		}
		color: id1.color
	}

	Rectangle {
		id: id19
		width: height * 2
		height: itemSize
		anchors {
			left: id17.right
			bottom: id17.bottom
		}
		color: id1.color
	}

	Rectangle {
		id: id20
		width: itemSize
		height: width * 2
		anchors {
			top: id19.bottom
			right: id19.right
		}
		color: id1.color
	}

	Rectangle {
		id: id21
		width: height * 2
		height: itemSize
		anchors {
			right: id20.left
			bottom: id20.bottom
		}
		color: id1.color
	}

	Rectangle {
		id: id22
		width: itemSize
		height: width * 5
		anchors {
			left: id20.right
			leftMargin: width
		}
		color: id1.color
	}

	Rectangle {
		id: id23
		width: itemSize
		height: width
		anchors {
			top: id22.top
			topMargin: height * 2
			left: id22.right
		}
		color: id1.color
	}

	Rectangle {
		id: id24
		width: itemSize
		height: width * 5
		anchors {
			left: id23.right
		}
		color: id1.color
	}
} 
