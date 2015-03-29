import QtQuick 2.0
import Sailfish.Silica 1.0

Item{
	id: root

	width: parent.width
	height: parent.height

	property color pressedColor: "#7727a01b"
	property alias source: image.source
	property bool avatar: true

    property int rectX: avatar ? Math.round(bucketContainer.x) : (image.rotatedSourceWidth * flickable.visibleArea.xPosition)
    property int rectY: avatar ? Math.round(bucketContainer.y) : (image.rotatedSourceHeight * flickable.visibleArea.yPosition)
    property int rectW: avatar ? bucketContainer.width : (image.rotatedSourceWidth * flickable.visibleArea.widthRatio)
    property int rectH: avatar ? bucketContainer.height : (orientation == 1 ? Math.round(rectW * 1.779) : Math.round (rectW * 0.562))
	property int angle: image.rotation

	property int bucketMinSize
	property int oldOrientation

    property bool pressed: bucketResizeMouseArea.pressed || bucketMouseArea.pressed || pinchArea.pinch.active || flickable.flicking

    onHeightChanged: {
        image.fitToScreen()
    }

    function rotate(angle) {
        if (angle) {
            image.rotation = angle
        }
        else {
            image.rotation = image.rotation + 90
            if (image.rotation == 360)
                image.rotation = 0
        }

		image.fitToScreen()
		flickable.returnToBounds()
	}

    SilicaFlickable{
		id: flickable

		width: parent.width
		height: parent.height
		anchors.centerIn: parent
		contentHeight: imageContainer.height
		contentWidth: imageContainer.width
		interactive: !bucketMouseArea.pressed && !bucketResizeMouseArea.pressed
		clip: true

		Item{
			id: imageContainer
			width: image.rotatedWidth * image.scale
			height: image.rotatedHeight * image.scale

			Loader{
				anchors.left: parent.left
				anchors.top: parent.top
				sourceComponent: {
					switch(image.status){
						case Image.Loading:
						return loadingIndicator
						case Image.Error:
						return failedLoading
						default:
						return undefined
					}
				}
			}

			Component{
				id: loadingIndicator

				BusyIndicator{
					id: busyIndicator
					running: image.status == Image.Ready ? false : true 
					visible: running
                    size: BusyIndicatorSize.Large
                    //platformStyle: BusyIndicatorStyle{ size: "large" }
				}
			}

            Component{ id: failedLoading; Label{ text: qsTr("Error loading image", "Image component error loading text") } }

			Image{
				id: image
				property int rotatedWidth: (image.rotation%180==90)?height:width
				property int rotatedHeight: (image.rotation%180==90)?width:height
				property int rotatedSourceWidth: (image.rotation%180==90)?sourceSize.height:sourceSize.width
				property int rotatedSourceHeight: (image.rotation%180==90)?sourceSize.width:sourceSize.height

				function fitToScreen(){
					scale = Math.min(flickable.width / rotatedWidth, flickable.height / rotatedHeight, 1)
					pinchArea.minScale = scale
					previousScale = scale
				}

				property real previousScale

				smooth: true

				asynchronous: true
				anchors.centerIn: parent
				fillMode: Image.PreserveAspectFit

				onStatusChanged: {
					if(status === Image.Ready) {
						image.rotation = 0
						image.fitToScreen()
                        bucketContainer.height = Math.min(image.sourceSize.width, image.sourceSize.height) - 10
                        bucketContainer.width = Math.min(image.sourceSize.width, image.sourceSize.height) - 10
                        bucketContainer.x = 5
                        bucketContainer.y = 5
						flickable.returnToBounds()
					}
				}

				onScaleChanged: {
					var scaled = scale / previousScale
					if ((width * scale) > flickable.width) {
						var xoff = (flickable.width / 2 + flickable.contentX) * scaled;
						flickable.contentX = xoff - flickable.width / 2
					}
					if ((height * scale) > flickable.height) {
						var yoff = (flickable.height / 2 + flickable.contentY) * scaled;
						flickable.contentY = yoff - flickable.height / 2
					}
					previousScale = scale
				}

				PinchArea{
					id: pinchArea

					property real minScale: 1.0
					property real maxScale: 2.0

					anchors.fill: parent
					pinch.target: image
					pinch.minimumScale: minScale * 0.5
					pinch.maximumScale: maxScale * 1.5

					onPinchFinished: {
						flickable.returnToBounds()
						if(image.scale < pinchArea.minScale){
							bounceBackAnimation.to = pinchArea.minScale
							bounceBackAnimation.start()
						}
						else if(image.scale > pinchArea.maxScale){
							bounceBackAnimation.to = pinchArea.maxScale
							bounceBackAnimation.start()
						}
					}

					NumberAnimation{
						id: bounceBackAnimation
						target: image
						duration: 250
						property: "scale"
						from: image.scale
					}
				}

				Item{
					id: bucketContainer

                    x: 5
                    y: 5
                    height: Math.min(image.sourceSize.width, image.sourceSize.height) - 10
                    width: Math.min(image.sourceSize.width, image.sourceSize.height) - 10
					rotation: 0 - image.rotation
					visible: avatar

					Rectangle{
						id: bucketBorder
						anchors.fill: parent
						border.width: 4 / image.scale
						border.color: (bucketMouseArea.pressed || bucketResizeMouseArea.pressed) ? pressedColor : "lightgray"
						color: "transparent"
						visible: image.status == Image.Ready
					}

					MouseArea{
						id: bucketMouseArea
						anchors.fill: parent
						drag.target: bucketContainer
						drag.minimumX: 0
						drag.minimumY: 0
						drag.maximumX: image.width - bucketBorder.width - 4 
						drag.maximumY: image.height - bucketBorder.height - 4
					}

					Image{
						id: resizeIndicator
						anchors{ right: parent.right; bottom: parent.bottom }
                        source: "/usr/share/harbour-mitakuuluu2/images/imageInteractor.png"
						height: sourceSize.height / image.scale
						width: sourceSize.width / image.scale
						visible: image.status == Image.Ready
					}

					MouseArea{
						id: bucketResizeMouseArea

						property int oldMouseX
						property int oldMouseY

						anchors.fill: resizeIndicator

						onPressed: {
							oldMouseX = mouseX
							oldMouseY = mouseY
						}

						onPositionChanged: {
							if (pressed) {
								var delta = Math.round(Math.min((mouseX - oldMouseX),(mouseY - oldMouseY)))
								var deltaX = 0
								var deltaY = 0
								switch (image.rotation)
								{
									case 90:	deltaY=-delta
												break
									case 180:	deltaX=-delta
												deltaY=-delta
												break
									case 270:	deltaX=-delta
												break
								}
								if ((bucketContainer.height + bucketContainer.x + delta <= image.sourceSize.width) && 
									(bucketContainer.width + bucketContainer.y + delta <= image.sourceSize.height) && 
									(bucketContainer.width + delta >= bucketMinSize) &&
									(bucketContainer.height + delta >= resizeIndicator.height) &&
									(bucketContainer.x + deltaX >= 0) &&
									(bucketContainer.y + deltaY >= 0)) 
								{
									bucketContainer.height += delta
									bucketContainer.width += delta
									bucketContainer.x += deltaX
									bucketContainer.y += deltaY
								}
							}
						}
					}
				}
			}
		}
	}
    ScrollDecorator{ flickable: flickable }
}

