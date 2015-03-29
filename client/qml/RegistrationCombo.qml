import QtQuick 2.0
import Sailfish.Silica 1.0

ValueButton {
    id: comboBox

    property int currentIndex: -1

    property bool _completed
    property bool _currentIndexSet
    property Page _menuDialogItem

    property ListModel model

    value: currentIndex < 0 ? qsTr("Select country") : countriesModel.get(currentIndex).name

    onCurrentIndexChanged: {
        _currentIndexSet = true
    }

    onClicked: {
        _menuDialogItem = pageStack.push(menuDialogComponent)
    }

    Component.onCompleted: {
        _completed = true
    }

    Component {
        id: menuDialogComponent

        Page {
            anchors.fill: parent

            Component.onCompleted: {
                view.searchField.text = ""
            }

            ListModel {
                id: items
                function update() {
                    clear()
                    for (var i=0; i<comboBox.model.count; i++) {
                        if (view.searchField.text == "" || countriesModel.get(i).name.search(new RegExp(view.searchField.text, "i")) >= 0) {
                            append({"name": countriesModel.get(i).name, "parentIndex": i})
                        }
                    }
                }
                Component.onCompleted: update()
            }

            PageHeader {
                id: header
                title: comboBox.label
            }

            SilicaListView {
                id: view
                property SearchField searchField: headerItem

                anchors {
                    fill: parent
                    topMargin: header.height
                }
                model: items
                currentIndex: -1

                header: searchComponent

                Component {
                    id: searchComponent
                    SearchField {
                        id: searchItem
                        width: parent.width
                        placeholderText: qsTr("Search", "Registration country selector")

                        onTextChanged: {
                            items.update()
                        }
                        Component.onCompleted: view.searchField = searchItem
                    }
                }

                delegate: BackgroundItem {
                    id: delegateItem

                    onClicked: {
                        comboBox.currentIndex = model.parentIndex
                        pageStack.pop()
                    }

                    Label {
                        x: Theme.paddingLarge
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - x*2
                        wrapMode: Text.Wrap
                        text: model.name
                        color: (delegateItem.highlighted || model.parentIndex === comboBox.currentIndex)
                               ? Theme.highlightColor
                               : Theme.primaryColor
                    }
                }
                VerticalScrollDecorator {}
            }
        }
    }
}

