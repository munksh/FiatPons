import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

// Full-biography drill-down, reached from "Read more" on ArtistPage. A plain
// text page -- the calm, Silica-native alternative to expanding text inline
// (which was causing the whole page above it to jump around).
Page {
    id: page
    property string artistName: ""
    property string bio: ""

    function paint() { FiatPonsTheme.applyPalette(page) }
    Component.onCompleted: paint()
    Connections { target: FiatPonsTheme; onAmbientChanged: page.paint() }

    Rectangle {
        anchors.fill: parent
        visible: !FiatPonsTheme.ambient
        gradient: Gradient {
            GradientStop { position: 0.0; color: FiatPonsTheme.backgroundHigh }
            GradientStop { position: 1.0; color: FiatPonsTheme.backgroundLow }
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: col.height + Theme.paddingLarge

        Column {
            id: col
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader { title: page.artistName }

            Label {
                width: parent.width - Theme.horizontalPageMargin * 2
                anchors.horizontalCenter: parent.horizontalCenter
                text: page.bio
                color: FiatPonsTheme.primaryText
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.Wrap
            }
        }

        VerticalScrollDecorator {}
    }
}
