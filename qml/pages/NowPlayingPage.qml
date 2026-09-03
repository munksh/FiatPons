import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.0
import se.munkstolen.fiatpons 1.0
import "../components"
import ".."

Page {
    id: page
    property string statusLine: ""

    readonly property var track: app.queue.currentTrack
    readonly property string trackTitle:  track ? track.title  : "Nothing playing"
    readonly property string trackArtist: track ? track.artist : ""
    readonly property string trackAlbum:  track ? track.album  : ""

    // When the queue's current track changes, resolve its URL and play.
    property int playingId: 0

    onTrackChanged: {
        var id = track ? track.id : 0
        if (id === playingId) return   // model changed but the current song didn't
        playingId = id
        if (track) {
            statusLine = "Resolving…"
            backend.streamUrl(track.id)
        } else {
            player.stop()
        }
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
        // Track finished → advance to the next queued track (which retriggers
        // onTrackChanged → resolve → play). If none, just stop.
        onStopped: {
            if (playbackState === MediaPlayer.StoppedState && status === MediaPlayer.EndOfMedia) {
                if (!app.queue.next())
                    page.statusLine = "End of queue"
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
                onClicked: pageStack.push(Qt.resolvedUrl("SearchPage.qml"))
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

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingLarge * 2

                Button {
                    text: "Play / Pause"
                    enabled: page.track !== null
                    onClicked: {
                        if (player.playbackState === MediaPlayer.PlayingState)
                            player.pause()
                        else
                            player.play()
                    }
                }
                Button {
                    text: "Next"
                    enabled: app.queue.hasNext()
                    onClicked: app.queue.next()
                }
            }

            Label {
                width: parent.width
                text: page.statusLine + (app.queue.model.count > 0
                    ? "   (" + (app.queue.currentIndex + 1) + "/" + app.queue.model.count + ")" : "")
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
