import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"
import ".."

Page {
    id: page

    // Placeholder state -- replaced by real playback state once the Rust
    // bridge is wired in. Deliberately obvious fake data, not zeros, so a
    // screenshot never looks like a bug.
    property string trackTitle: "Clair de Lune"
    property string trackArtist: "Claude Debussy"
    property string trackAlbum: "Suite Bergamasque"
    property bool isPlaying: false

    // Passed to SearchPage as a callback so it can hand a chosen track
    // back to this page without a global signal bus.
    function applySelectedTrack(track) {
        trackTitle = track.title
        trackArtist = track.artist
        trackAlbum = track.album
    }

    function paint() { FiatPonsTheme.applyPalette(page) }
    Component.onCompleted: paint()
    Connections {
        target: FiatPonsTheme
        onAmbientChanged: page.paint()
    }

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: contentColumn.height + wordmarkRow.height

        Rectangle {
            anchors.fill: parent
            visible: !FiatPonsTheme.ambient
            gradient: Gradient {
                GradientStop { position: 0.0; color: FiatPonsTheme.backgroundHigh }
                GradientStop { position: 1.0; color: FiatPonsTheme.backgroundLow }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: !FiatPonsTheme.ambient
        gradient: Gradient {
            GradientStop { position: 0.0; color: FiatPonsTheme.backgroundHigh }
            GradientStop { position: 1.0; color: FiatPonsTheme.backgroundLow }
        }
    }

    SilicaFlickable {
        id: mainFlickable
        anchors.fill: parent
        contentHeight: contentColumn.height + wordmarkRow.height

        PullDownMenu {
            backgroundColor: FiatPonsTheme.surface
            highlightColor: FiatPonsTheme.accent

            MenuItem {
                text: "Search"
                color: FiatPonsTheme.primaryText
                onClicked: pageStack.push(
                    Qt.resolvedUrl("SearchPage.qml"),
                    { onTrackSelected: page.applySelectedTrack }
                )
            }

            MenuItem {
                text: FiatPonsTheme.ambient ? "Fiat colours" : "Follow ambience"
                color: FiatPonsTheme.primaryText
                onClicked: FiatPonsTheme.setAmbient(!FiatPonsTheme.ambient)
            }
        }

        // Wordmark, top-left, centred on the system indicator row.
        Item {
            id: wordmarkRow
            width: parent.width
            height: FiatPonsTheme.statusRowCenter + wordmark.height / 2 + Theme.paddingMedium

            Label {
                id: wordmark
                anchors.left: parent.left
                anchors.leftMargin: Theme.horizontalPageMargin
                anchors.top: parent.top
                anchors.topMargin: Math.max(0, FiatPonsTheme.statusRowCenter - height / 2)
                text: "fiat pons"
                color: FiatPonsTheme.primaryText
                font.pixelSize: Theme.fontSizeLarge
                font.family: FiatPonsTheme.serif
                font.italic: true
            }
        }

        Column {
            id: contentColumn
            anchors.top: wordmarkRow.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: Theme.paddingLarge
            anchors.leftMargin: Theme.horizontalPageMargin
            anchors.rightMargin: Theme.horizontalPageMargin
            spacing: Theme.paddingLarge

            // The "instrument" card: now-playing readout.
            Rectangle {
                width: parent.width
                height: nowPlayingColumn.height + Theme.paddingLarge * 2
                radius: FiatPonsTheme.cardRadius
                color: FiatPonsTheme.card
                border.color: FiatPonsTheme.cardBorder
                border.width: FiatPonsTheme.cardBorderWidth

                Column {
                    id: nowPlayingColumn
                    anchors.centerIn: parent
                    width: parent.width - Theme.paddingLarge * 2
                    spacing: Theme.paddingSmall

                    Label {
                        width: parent.width
                        text: page.trackTitle
                        color: FiatPonsTheme.primaryText
                        font.pixelSize: Theme.fontSizeLarge
                        font.family: FiatPonsTheme.serif
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                    }

                    Label {
                        width: parent.width
                        text: page.trackArtist
                        color: FiatPonsTheme.secondaryText
                        font.pixelSize: Theme.fontSizeMedium
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                    }

                    Label {
                        width: parent.width
                        text: page.trackAlbum
                        color: FiatPonsTheme.secondaryText
                        font.pixelSize: Theme.fontSizeExtraSmall
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                    }
                }
            }

            // Transport control -- placeholder only, no real playback yet.
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingLarge * 2

                IconButton {
                    icon.source: "image://theme/icon-m-previous"
                    onClicked: console.log("previous (not wired yet)")
                }

                IconButton {
                    icon.source: page.isPlaying ? "image://theme/icon-m-pause" : "image://theme/icon-m-play"
                    onClicked: page.isPlaying = !page.isPlaying
                }

                IconButton {
                    icon.source: "image://theme/icon-m-next"
                    onClicked: console.log("next (not wired yet)")
                }
            }

            Label {
                width: parent.width
                text: "Not yet connected to Qobuz. This is a placeholder screen."
                color: FiatPonsTheme.secondaryText
                font.pixelSize: Theme.fontSizeExtraSmall
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
            }
        }

        VerticalScrollDecorator { flickable: mainFlickable }
    }
}
