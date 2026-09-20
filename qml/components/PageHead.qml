import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

// The house page header. Left-aligned title, optional line under it.
//
// Not Silica's PageHeader, which draws its title in Theme.highlightColor --
// light text on light paper under Fiat colours plus a dark ambience.
//
// The title HANGS FROM THE TOP of the band, it is not centred in it and it is
// not aligned from the bottom. With bottom alignment a page that has a second
// line pushes its title up, so every page sits at a slightly different height.
// Anchored to the top, every title in the app is on the same line whether or
// not anything follows it, and the header is only as tall as what it holds.
Item {
    id: root

    property string title: ""
    property string subtitle: ""
    property alias titleItem: titleLabel

    width: parent ? parent.width : 0
    height: FiatPonsTheme.headerTopInset + col.height + Theme.paddingMedium

    Column {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Theme.horizontalPageMargin
        anchors.rightMargin: Theme.horizontalPageMargin
        anchors.top: parent.top
        anchors.topMargin: FiatPonsTheme.headerTopInset

        Label {
            id: titleLabel
            width: parent.width
            text: root.title
            color: FiatPonsTheme.primaryText
            font.pixelSize: Theme.fontSizeExtraLarge
            truncationMode: TruncationMode.Fade
            maximumLineCount: 1
        }

        Label {
            width: parent.width
            visible: root.subtitle !== ""
            text: root.subtitle
            color: FiatPonsTheme.secondaryText
            font.pixelSize: Theme.fontSizeExtraSmall
            truncationMode: TruncationMode.Fade
            maximumLineCount: 1
        }
    }
}
