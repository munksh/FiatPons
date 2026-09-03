import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.0
import se.munkstolen.fiatpons 1.0
import "../components"
import ".."

Page {
    id: page

    property string trackTitle: "Nothing playing"
    property string trackArtist: ""
    property string trackAlbum: ""
    property int trackId: 0
    property string statusLine: ""

    function applySelectedTrack(track) {
        trackTitle = track.title
        trackArtist = track.artist
        trackAlbum = track.album
        trackId = track.id
        statusLine = "Resolving…"
        backend.streamUrl(track.id)
    }

    function handleStream(json) {
        var data
        try { data = JSON.parse(json) }
        catch (e) { statusLine = "Bad response"; return }
        if (data.error) { statusLine = "Error: " + data.error; return }
        statusLine = ""
        player.source = data.url
        player.play()
    }

    function paint() { FiatPonsTheme.applyPalette(page) }
    Component.onCompleted: paint()
    Connections {
        target: FiatPonsTheme
        onAmbientChanged: page.paint()
    }

    Backend {
        id: backend
        onStreamReady: page.handleStream(json)
    }

    MediaPlayer {
        id: player
        autoPlay: false
        onError: page.statusLine = "Playback error: " + errorString
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
                        visible: text.length > 0
                    }
                    Label {
                        width: parent.width
                        text: page.trackAlbum
                        color: FiatPonsTheme.secondaryText
                        font.pixelSize: Theme.fontSizeExtraSmall
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        visible: text.length > 0
                    }
                }
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Play / Pause"
                enabled: page.trackId !== 0
                onClicked: {
                    if (player.playbackState === MediaPlayer.PlayingState)
                        player.pause()
                    else
                        player.play()
                }
            }

            Label {
                width: parent.width
                text: page.statusLine
                color: FiatPonsTheme.accent
                font.pixelSize: Theme.fontSizeExtraSmall
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                visible: text.length > 0
            }
        }

        VerticalScrollDecorator { flickable: mainFlickable }
    }
}
