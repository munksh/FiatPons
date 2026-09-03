import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.0
import ".."

Page {
    id: page
    property string status: "constructed"

    MediaPlayer {
        id: player
        autoPlay: false
        source: "https://munkstolen.se/RECORDINGS/ISRC-SE2FP2002101-314-ack-saliga-dag-1644.wav"
        onError: page.status = "ERROR: " + errorString
        onStatusChanged: page.status = "mediaStatus=" + status
        onPlaybackStateChanged: page.status = "state=" + playbackState
    }

    Column {
        anchors.centerIn: parent
        width: parent.width - Theme.horizontalPageMargin * 2
        spacing: Theme.paddingLarge

        Label {
            width: parent.width
            text: page.status
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            color: FiatPonsTheme.accent
            font.pixelSize: Theme.fontSizeSmall
        }
        Button {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Play"
            onClicked: player.play()
        }
    }
}
