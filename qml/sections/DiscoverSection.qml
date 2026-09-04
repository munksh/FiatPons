import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

// Top-level DISCOVER tab — placeholder (Phase 4: editorial, new releases).
Item {
    id: section
    clip: true
    Column {
        anchors.centerIn: parent
        width: parent.width - Theme.horizontalPageMargin * 4
        spacing: Theme.paddingSmall
        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "Discover"
            color: FiatPonsTheme.accent
            font.pixelSize: Theme.fontSizeLarge
            font.family: FiatPonsTheme.serif
        }
        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            text: "Editor's picks, new releases and genres will live here"
            color: FiatPonsTheme.secondaryText
            font.pixelSize: Theme.fontSizeSmall
        }
    }
}
