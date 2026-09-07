import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

// Top-level LIBRARY tab. A calm landing that drills into Playlists and
// Favourites. Pure navigation -- the data lives on the pages it opens.
Item {
    id: section
    clip: true

    function paint() { FiatPonsTheme.applyPalette(section) }
    Component.onCompleted: paint()
    Connections { target: FiatPonsTheme; onAmbientChanged: section.paint() }

    // One reusable entry row.
    Component {
        id: entryComp
        Item {}
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: col.height + Theme.paddingLarge * 2

        Column {
            id: col
            width: parent.width
            anchors.top: parent.top
            anchors.topMargin: Theme.paddingLarge
            spacing: 0

            // ---- Playlists ----
            BackgroundItem {
                width: parent.width
                height: Theme.itemSizeLarge
                onClicked: pageStack.push(Qt.resolvedUrl("../pages/PlaylistsPage.qml"))
                Row {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: Theme.horizontalPageMargin
                    anchors.rightMargin: Theme.horizontalPageMargin
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.paddingLarge
                    Rectangle {
                        width: Theme.itemSizeMedium
                        height: width
                        anchors.verticalCenter: parent.verticalCenter
                        radius: FiatPonsTheme.cardRadius
                        color: FiatPonsTheme.recessFill
                        border.color: FiatPonsTheme.recessBorder
                        border.width: 1
                        Label {
                            anchors.centerIn: parent
                            text: "\u266B"
                            color: FiatPonsTheme.accent
                            font.pixelSize: Theme.fontSizeExtraLarge
                            font.family: FiatPonsTheme.serif
                        }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.paddingSmall / 2
                        Label {
                            text: "Playlists"
                            color: FiatPonsTheme.primaryText
                            font.pixelSize: Theme.fontSizeLarge
                            font.family: FiatPonsTheme.serif
                        }
                        Label {
                            text: "Your saved playlists"
                            color: FiatPonsTheme.secondaryText
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: FiatPonsTheme.innerBorder }

            // ---- Favourites ----
            BackgroundItem {
                width: parent.width
                height: Theme.itemSizeLarge
                onClicked: pageStack.push(Qt.resolvedUrl("../pages/FavouritesPage.qml"))
                Row {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: Theme.horizontalPageMargin
                    anchors.rightMargin: Theme.horizontalPageMargin
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.paddingLarge
                    Rectangle {
                        width: Theme.itemSizeMedium
                        height: width
                        anchors.verticalCenter: parent.verticalCenter
                        radius: FiatPonsTheme.cardRadius
                        color: FiatPonsTheme.recessFill
                        border.color: FiatPonsTheme.recessBorder
                        border.width: 1
                        Label {
                            anchors.centerIn: parent
                            text: "\u2665"
                            color: FiatPonsTheme.accent
                            font.pixelSize: Theme.fontSizeExtraLarge
                        }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.paddingSmall / 2
                        Label {
                            text: "Favourites"
                            color: FiatPonsTheme.primaryText
                            font.pixelSize: Theme.fontSizeLarge
                            font.family: FiatPonsTheme.serif
                        }
                        Label {
                            text: "Tracks, albums and artists you love"
                            color: FiatPonsTheme.secondaryText
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: FiatPonsTheme.innerBorder }
        }

        VerticalScrollDecorator {}
    }
}
