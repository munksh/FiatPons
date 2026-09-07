import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"
import ".."

Page {
    id: page

    function paint() { FiatPonsTheme.applyPalette(page) }
    Component.onCompleted: paint()
    Connections { target: FiatPonsTheme; onAmbientChanged: page.paint() }

    Rectangle {
        anchors.fill: parent
        visible: !FiatPonsTheme.ambient
        gradient: Gradient {
            GradientStop { position: 0.0; color: FiatPonsTheme.backgroundHigh }
            GradientStop { position: 1.0; color: FiatPonsTheme.backgroundLow }
        }
    }

    SilicaListView {
        id: listView
        anchors.fill: parent
        model: app.queue.model

        header: PageHeader { title: "Queue" }

        PullDownMenu {
            backgroundColor: FiatPonsTheme.surface
            highlightColor: FiatPonsTheme.accent
            MenuItem {
                text: "Clear queue"
                color: FiatPonsTheme.primaryText
                onClicked: app.queue.clear()
            }
        }

        delegate: ListItem {
            id: delegateItem
            width: listView.width
            contentHeight: Theme.itemSizeMedium
            highlighted: down || index === app.queue.currentIndex

            onClicked: app.queue.goTo(index)

            menu: ContextMenu {
                MenuItem { text: "Play";   onClicked: app.queue.goTo(index) }
                MenuItem { text: "Remove"; onClicked: delegateItem.remove() }
            }

            function remove() {
                var cur = app.queue.currentIndex
                if (index === cur) {
                    app.queue.model.remove(index)
                    if (app.queue.model.count === 0) app.queue.clear()
                    else app.queue.goTo(Math.min(index, app.queue.model.count - 1))
                } else {
                    app.queue.model.remove(index)
                    if (index < cur) app.queue.currentIndex = cur - 1
                    app.queue.persist()
                }
            }

            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
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
                    width: Theme.itemSizeMedium - Theme.paddingMedium
                    height: width
                    anchors.verticalCenter: parent.verticalCenter
                    radius: Theme.paddingSmall / 2
                    color: FiatPonsTheme.recessFill
                    border.color: FiatPonsTheme.recessBorder
                    border.width: 1
                    clip: true
                    Image {
                        anchors.fill: parent
                        source: (model.cover_url === undefined) ? "" : model.cover_url
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                    }
                    Label {
                        anchors.centerIn: parent
                        text: "\u266A"
                        color: FiatPonsTheme.secondaryText
                        font.pixelSize: Theme.fontSizeLarge
                        visible: (model.cover_url === undefined || model.cover_url.length === 0)
                    }
                }

                Column {
                    width: parent.width - coverTile.width - Theme.paddingMedium
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.paddingSmall / 2
                    Label {
                        width: parent.width
                        text: model.title === undefined ? "" : model.title
                        color: delegateItem.highlighted ? FiatPonsTheme.accent : FiatPonsTheme.primaryText
                        font.pixelSize: Theme.fontSizeMedium
                        truncationMode: TruncationMode.Fade
                    }
                    Label {
                        width: parent.width
                        text: (model.artist === undefined ? "" : model.artist)
                            + " \u2014 " + (model.album === undefined ? "" : model.album)
                        color: FiatPonsTheme.secondaryText
                        font.pixelSize: Theme.fontSizeExtraSmall
                        truncationMode: TruncationMode.Fade
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
