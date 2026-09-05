import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0
import ".."

CoverBackground {
    id: cover

    readonly property var track: app.playback.nowTrack
    readonly property string coverUrl: (track && track.cover_url) ? track.cover_url : ""
    readonly property string title: track ? track.title : ""
    readonly property string artist: track ? track.artist : ""

    // Fiat background (only when not following ambience).
    Rectangle {
        anchors.fill: parent
        visible: !FiatPonsTheme.ambient
        gradient: Gradient {
            GradientStop { position: 0.0; color: FiatPonsTheme.backgroundHigh }
            GradientStop { position: 1.0; color: FiatPonsTheme.backgroundLow }
        }
    }

    Column {
        anchors {
            top: parent.top; left: parent.left; right: parent.right
            topMargin: Theme.paddingLarge
            leftMargin: Theme.paddingMedium
            rightMargin: Theme.paddingMedium
        }
        spacing: Theme.paddingMedium

        // ---- Rounded album art ----
        Item {
            width: parent.width
            height: width

            Rectangle { id: mask; anchors.fill: parent; radius: Theme.paddingLarge; visible: false }
            Rectangle { anchors.fill: parent; radius: Theme.paddingLarge; color: FiatPonsTheme.recessFill }
            Image {
                id: art
                anchors.fill: parent
                source: cover.coverUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                visible: false
            }
            OpacityMask {
                anchors.fill: parent
                source: art
                maskSource: mask
                visible: cover.coverUrl.length > 0
            }
            Rectangle {
                anchors.fill: parent
                radius: Theme.paddingLarge
                color: "transparent"
                border.color: FiatPonsTheme.cardBorder
                border.width: 2
            }
            Label {
                anchors.centerIn: parent
                text: "\u266B"
                color: FiatPonsTheme.secondaryText
                font.pixelSize: Theme.fontSizeHuge
                font.family: FiatPonsTheme.serif
                visible: cover.coverUrl.length === 0
            }
        }

        // ---- Title / artist ----
        Label {
            width: parent.width
            text: cover.title.length > 0 ? cover.title : "fiat pons"
            color: FiatPonsTheme.primaryText
            font.pixelSize: Theme.fontSizeSmall
            font.family: FiatPonsTheme.serif
            font.italic: cover.title.length === 0
            truncationMode: TruncationMode.Fade
            maximumLineCount: 1
        }
        Label {
            width: parent.width
            text: cover.artist
            color: FiatPonsTheme.secondaryText
            font.pixelSize: Theme.fontSizeExtraSmall
            truncationMode: TruncationMode.Fade
            maximumLineCount: 1
            visible: text.length > 0
        }
    }

    // ---- One play/pause cover action ----
    CoverActionList {
        id: actions
        CoverAction {
            iconSource: app.playback.playing
                ? "image://theme/icon-cover-pause" : "image://theme/icon-cover-play"
            onTriggered: app.playback.toggle()
        }
    }
}
