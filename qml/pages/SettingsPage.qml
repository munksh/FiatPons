import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

// Settings — pushed from the top bar. Home for preferences: theme now,
// login + default quality (disabled placeholders) later.
Page {
    id: page

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
        contentHeight: col.height

        Column {
            id: col
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader { title: "Settings" }

            SectionHeader { text: "Appearance" }
            TextSwitch {
                text: "Fiat colours"
                description: "Use the Fiat light palette instead of following the system ambience"
                automaticCheck: false
                checked: !FiatPonsTheme.ambient
                onClicked: FiatPonsTheme.setAmbient(!FiatPonsTheme.ambient)
            }

            SectionHeader { text: "Account" }
            TextSwitch {
                text: "Log in to Qobuz"
                description: "Coming soon \u2014 on-device login"
                enabled: false
                automaticCheck: false
            }

            SectionHeader { text: "Playback" }
            ComboBox {
                width: parent.width
                label: "Default quality"
                enabled: false
                description: "Coming soon"
                menu: ContextMenu {
                    MenuItem { text: "CD (FLAC 16/44)" }
                    MenuItem { text: "MP3 320" }
                }
            }
        }

        VerticalScrollDecorator {}
    }
}
