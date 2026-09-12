import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

// Reached from Settings. A quiet word on why this app exists, plus a real
// acknowledgement of the work it's built on -- qbz-qobuz did the hard,
// unglamorous job of talking to Qobuz's actual API so this app didn't have
// to reverse-engineer it from scratch.
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
        contentHeight: col.height + Theme.paddingLarge

        Column {
            id: col
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader { title: "About" }

            // ---- Wordmark ----
            Label {
                width: parent.width - Theme.horizontalPageMargin * 2
                anchors.horizontalCenter: parent.horizontalCenter
                text: "fiat pons"
                horizontalAlignment: Text.AlignHCenter
                color: FiatPonsTheme.primaryText
                font.pixelSize: Theme.fontSizeExtraLarge
                font.family: FiatPonsTheme.serif
                font.italic: true
            }

            // ---- The idea ----
            Column {
                width: parent.width - Theme.horizontalPageMargin * 2
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingMedium

                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    color: FiatPonsTheme.secondaryText
                    font.pixelSize: Theme.fontSizeSmall
                    text: "\u201CFiat pons\u201D — let there be a bridge. This app doesn't try to " +
                          "be Qobuz's web player squeezed onto a phone; it tries to be what a " +
                          "music player looks like when it's built for Sailfish's own hands and " +
                          "eyes, and left there quietly to just work."
                }

                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    color: FiatPonsTheme.secondaryText
                    font.pixelSize: Theme.fontSizeSmall
                    text: "It's part of Munkstolen's small family of Fiat apps for Sailfish OS " +
                          "— each one a bridge of its own kind, built the same unhurried way: " +
                          "read the platform closely, keep the interface calm, and let the " +
                          "thing do one job well."
                }
            }

            Rectangle { width: parent.width; height: 1; color: FiatPonsTheme.innerBorder }

            // ---- Acknowledgement ----
            Column {
                width: parent.width - Theme.horizontalPageMargin * 2
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingSmall

                SectionHeader { text: "Built on" }

                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    color: FiatPonsTheme.primaryText
                    font.pixelSize: Theme.fontSizeSmall
                    text: "Fiat Pons owes its entire connection to Qobuz to " +
                          "<b>qbz-qobuz</b>, the Rust library at the heart of " +
                          "<b>blitzkriegfc</b>'s QBZ project (MIT licensed). Search, " +
                          "streaming, favourites, playlists and login all run on that " +
                          "work — this app is the Silica face put on top of it. " +
                          "A genuine thank-you for building and sharing it."
                }

                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    color: FiatPonsTheme.accent
                    font.pixelSize: Theme.fontSizeExtraSmall
                    text: "github.com/vicrodh/qbz"
                }
            }

            Rectangle { width: parent.width; height: 1; color: FiatPonsTheme.innerBorder }

            // ---- Fine print ----
            Column {
                width: parent.width - Theme.horizontalPageMargin * 2
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingSmall / 2

                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    color: FiatPonsTheme.secondaryText
                    font.pixelSize: Theme.fontSizeExtraSmall
                    text: "Fiat Pons is an unofficial, independent client. It is not made, " +
                          "endorsed, or supported by Qobuz. A Qobuz subscription of your " +
                          "own is required to use it."
                }
                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    color: FiatPonsTheme.secondaryText
                    font.pixelSize: Theme.fontSizeExtraSmall
                    text: "github.com/munksh/FiatPons"
                }
            }
        }

        VerticalScrollDecorator {}
    }
}
