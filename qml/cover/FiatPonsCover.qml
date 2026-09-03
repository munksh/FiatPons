import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

CoverBackground {
    id: cover

    Rectangle {
        anchors.fill: parent
        visible: !FiatPonsTheme.ambient
        gradient: Gradient {
            GradientStop { position: 0.0; color: FiatPonsTheme.backgroundHigh }
            GradientStop { position: 1.0; color: FiatPonsTheme.backgroundLow }
        }
    }

    Column {
        anchors.centerIn: parent
        width: parent.width - Theme.paddingLarge * 2
        spacing: Theme.paddingSmall

        Label {
            width: parent.width
            text: "\u266B"   // eighth-note glyph as the cover figure
            color: FiatPonsTheme.accent
            font.pixelSize: Theme.fontSizeHuge
            font.family: FiatPonsTheme.serif
            horizontalAlignment: Text.AlignHCenter
        }

        Label {
            width: parent.width
            text: "not playing"
            color: FiatPonsTheme.secondaryText
            font.pixelSize: Theme.fontSizeExtraSmall
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
        }
    }

    Label {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.paddingMedium
        anchors.horizontalCenter: parent.horizontalCenter
        text: "fiat pons"
        color: FiatPonsTheme.secondaryText
        font.pixelSize: Theme.fontSizeTiny
        font.family: FiatPonsTheme.serif
        font.italic: true
    }

    CoverActionList {
        iconBackground: true

        CoverAction {
            iconSource: "image://theme/icon-cover-play"
        }
    }
}
