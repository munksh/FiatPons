import QtQuick 2.0
import Sailfish.Silica 1.0
import se.munkstolen.fiatpons 1.0
import ".."

Page {
    id: page
    Backend { id: backend }

    Column {
        anchors.centerIn: parent
        spacing: Theme.paddingMedium
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Rust says"
            color: FiatPonsTheme.secondaryText
            font.pixelSize: Theme.fontSizeSmall
        }
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: backend.ping()
            color: FiatPonsTheme.accent
            font.pixelSize: Theme.fontSizeHuge
            font.family: FiatPonsTheme.serif
        }
    }
}