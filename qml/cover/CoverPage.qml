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

    Rectangle {
        anchors.fill: parent
        visible: !FiatPonsTheme.ambient
        gradient: Gradient {
            GradientStop { position: 0.0; color: FiatPonsTheme.backgroundHigh }
            GradientStop { position: 1.0; color: FiatPonsTheme.backgroundLow }
        }
    }

    Label {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: FiatPonsTheme.coverWordmarkTop
        text: "fiat pons"
        color: FiatPonsTheme.secondaryText
        font.pixelSize: Theme.fontSizeTiny
        font.family: FiatPonsTheme.serif
        font.italic: true
    }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: FiatPonsTheme.coverSideMargin
        anchors.rightMargin: FiatPonsTheme.coverSideMargin
        anchors.topMargin: cover.height * FiatPonsTheme.coverFigureFractionShape
        spacing: Theme.paddingMedium

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: cover.width * FiatPonsTheme.coverArtFraction
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
                text: "♫"
                color: FiatPonsTheme.secondaryText
                font.pixelSize: FiatPonsTheme.coverFigureSize
                font.family: FiatPonsTheme.serif
                visible: cover.coverUrl.length === 0
            }
        }

        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: cover.title.length > 0 ? cover.title : qsTr("nothing playing")
            color: FiatPonsTheme.accent
            font.pixelSize: Theme.fontSizeSmall
            font.family: FiatPonsTheme.serif
            font.italic: cover.title.length === 0
            truncationMode: TruncationMode.Fade
            maximumLineCount: 1
        }

        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: cover.artist
            color: Theme.rgba(FiatPonsTheme.accent, 0.75)
            font.pixelSize: Theme.fontSizeExtraSmall
            truncationMode: TruncationMode.Fade
            maximumLineCount: 1
            visible: text.length > 0
        }
    }

    CoverActionList {
        id: actions

        CoverAction {
            iconSource: app.playback.playing
                        ? "image://theme/icon-cover-pause"
                        : "image://theme/icon-cover-play"
            onTriggered: app.playback.toggle()
        }
    }
}
