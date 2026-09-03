import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

Column {
    id: root
    property string title: ""
    property string hint: ""

    anchors.centerIn: parent
    width: parent ? parent.width - Theme.horizontalPageMargin * 4 : 0
    spacing: Theme.paddingSmall
    visible: title.length > 0 || hint.length > 0

    Label {
        width: parent.width
        text: root.title
        color: FiatPonsTheme.accent
        font.pixelSize: Theme.fontSizeLarge
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
    }

    Label {
        width: parent.width
        text: root.hint
        color: FiatPonsTheme.secondaryText
        font.pixelSize: Theme.fontSizeSmall
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        visible: text.length > 0
    }
}
