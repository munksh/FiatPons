import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"
import ".."

Page {
    id: page

    property bool editMode: false

    function paint() {
        FiatPonsTheme.applyPalette(page)
    }

    Component.onCompleted: paint()

    Connections {
        target: FiatPonsTheme
        onAmbientChanged: page.paint()
    }

    Rectangle {
        anchors.fill: parent
        visible: !FiatPonsTheme.ambient

        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: FiatPonsTheme.backgroundHigh
            }

            GradientStop {
                position: 1.0
                color: FiatPonsTheme.backgroundLow
            }
        }
    }

    SilicaListView {
        id: listView

        anchors.fill: parent
        model: app.queue.model
        clip: true

        header: Column {
            width: listView.width

            PageHeader {
                title: page.editMode
                       ? "Reorder queue"
                       : "Queue"
            }

            Label {
                width: parent.width
                        - Theme.horizontalPageMargin * 2
                anchors.horizontalCenter: parent.horizontalCenter

                visible: page.editMode
                text: "Drag the handles to change the order"
                color: FiatPonsTheme.secondaryText
                font.pixelSize: Theme.fontSizeExtraSmall
                horizontalAlignment: Text.AlignHCenter
            }

            Item {
                width: 1
                height: page.editMode
                        ? Theme.paddingMedium
                        : 0
            }
        }

        PullDownMenu {
            backgroundColor: FiatPonsTheme.surface
            highlightColor: FiatPonsTheme.accent

            MenuItem {
                text: page.editMode
                      ? "Done"
                      : "Edit order"
                color: FiatPonsTheme.primaryText

                onClicked:
                    page.editMode = !page.editMode
            }

            MenuItem {
                text: "Clear queue"
                color: FiatPonsTheme.primaryText
                visible: !page.editMode
                onClicked: app.queue.clear()
            }
        }

        delegate: ListItem {
            id: delegateItem

            property int dragTarget: -1

            width: listView.width
            contentHeight: Theme.itemSizeMedium
            highlighted: !page.editMode
                         && (down
                             || index === app.queue.currentIndex)

            onClicked: {
                if (!page.editMode)
                    app.queue.goTo(index)
            }

            menu: page.editMode ? null : queueMenu

            Component {
                id: queueMenu

                ContextMenu {
                    MenuItem {
                        text: "Play"
                        onClicked: app.queue.goTo(index)
                    }

                    MenuItem {
                        text: "Remove"
                        onClicked: app.queue.removeAt(index)
                    }
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom

                height: 1
                color: FiatPonsTheme.innerBorder
            }

            Row {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.horizontalPageMargin
                anchors.rightMargin: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter

                spacing: Theme.paddingMedium

                Rectangle {
                    id: coverTile

                    width: Theme.itemSizeMedium
                           - Theme.paddingMedium
                    height: width
                    anchors.verticalCenter: parent.verticalCenter

                    radius: Theme.paddingSmall / 2
                    color: FiatPonsTheme.recessFill
                    border.color: FiatPonsTheme.recessBorder
                    border.width: 1
                    clip: true

                    Image {
                        anchors.fill: parent

                        source: model.cover_url === undefined
                                ? ""
                                : model.cover_url
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                    }

                    Label {
                        anchors.centerIn: parent

                        text: "\u266A"
                        color: FiatPonsTheme.secondaryText
                        font.pixelSize: Theme.fontSizeLarge

                        visible:
                            model.cover_url === undefined
                            || model.cover_url.length === 0
                    }
                }

                Column {
                    width: parent.width
                           - coverTile.width
                           - dragHandle.width
                           - Theme.paddingMedium * 2
                    anchors.verticalCenter: parent.verticalCenter

                    spacing: Theme.paddingSmall / 2

                    Label {
                        width: parent.width

                        text: model.title === undefined
                              ? ""
                              : model.title
                        color: delegateItem.highlighted
                               ? FiatPonsTheme.accent
                               : FiatPonsTheme.primaryText
                        font.pixelSize: Theme.fontSizeMedium
                        truncationMode: TruncationMode.Fade
                    }

                    Label {
                        width: parent.width

                        text: (model.artist === undefined
                               ? ""
                               : model.artist)
                              + " \u2014 "
                              + (model.album === undefined
                                 ? ""
                                 : model.album)

                        color: FiatPonsTheme.secondaryText
                        font.pixelSize: Theme.fontSizeExtraSmall
                        truncationMode: TruncationMode.Fade
                    }
                }

                Item {
                    id: dragHandle

                    width: page.editMode
                           ? Theme.itemSizeSmall
                           : 0
                    height: Theme.itemSizeMedium
                    visible: page.editMode
                    clip: true

                    Label {
                        anchors.centerIn: parent

                        text: "\u2261"
                        color: handleMouse.pressed
                               ? FiatPonsTheme.accent
                               : FiatPonsTheme.secondaryText
                        font.pixelSize: Theme.fontSizeLarge
                    }

                    MouseArea {
                        id: handleMouse

                        anchors.fill: parent
                        enabled: page.editMode
                        preventStealing: true

                        onPressed:
                            delegateItem.dragTarget = index

                        onPositionChanged: {
                            if (!pressed)
                                return

                            var point = mapToItem(
                                listView.contentItem,
                                mouse.x,
                                mouse.y
                            )

                            var target = listView.indexAt(
                                listView.width / 2,
                                point.y
                            )

                            if (target >= 0
                                    && target !== index
                                    && target !== delegateItem.dragTarget) {
                                app.queue.move(index, target)
                                delegateItem.dragTarget = target
                            }
                        }

                        onReleased:
                            delegateItem.dragTarget = -1

                        onCanceled:
                            delegateItem.dragTarget = -1
                    }
                }
            }
        }

        ViewPlaceholder {
            enabled: app.queue.model.count === 0
            text: "Queue is empty"
            hintText: "Search and tap a track to start"
        }

        VerticalScrollDecorator {}
    }
}
