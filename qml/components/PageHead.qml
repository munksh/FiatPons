import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

Item {
    id: root
    property string title: ""
    property alias titleItem: titleLabel

    width: parent ? parent.width : 0
    height: FiatPonsTheme.headerTopInset + titleLabel.height + Theme.paddingMedium

    Label {
        id: titleLabel
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Theme.horizontalPageMargin
        anchors.rightMargin: Theme.horizontalPageMargin
        anchors.top: parent.top
        anchors.topMargin: FiatPonsTheme.headerTopInset
        text: root.title
        color: FiatPonsTheme.primaryText
        font.pixelSize: Theme.fontSizeExtraLarge
        truncationMode: TruncationMode.Fade
        maximumLineCount: 1
    }
}
