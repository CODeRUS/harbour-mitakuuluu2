import QtQuick 2.0
import org.nemomobile.thumbnailer 1.0

// Base item for thumbnails in a Grid to get default behavior for free.
// Make sure that this is a top level delegate item for a grid
MouseArea {
    id: thumbnail

    property url source
    property bool down: pressed && containsMouse
    property string mimeType
    property bool pressedAndHolded
    property int size: GridView.view.cellSize
    property real contentYOffset
    property real contentXOffset
    property GridView grid: GridView.view

    width: size
    height: size
    opacity: GridView.isCurrentItem && GridView.view.unfocusHighlightEnabled
             ? 1.0
             : GridView.view._unfocusedOpacity

    // Default behavior for each thumbnail
    onPressed: GridView.view.currentIndex = index
    onPressAndHold: pressedAndHolded = true
    onReleased: pressedAndHolded = false

}
