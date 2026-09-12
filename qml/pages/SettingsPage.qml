import QtQuick 2.0
import Sailfish.Silica 1.0
import se.munkstolen.fiatpons 1.0
import ".."

// Settings — pushed from the top bar. Home for preferences: theme now,
// login + default quality (disabled placeholders) later.
Page {
    id: page

    property bool loggedIn: false
    property bool authBusy: false
    property string authStatus: ""


    function paint() { FiatPonsTheme.applyPalette(page) }
    Component.onCompleted: { paint(); backend.isLoggedIn() }
    Connections { target: FiatPonsTheme; onAmbientChanged: page.paint() }

    Backend {
        id: backend
    }

    Connections {
        target: backend
        onLoginComplete: {
            page.authBusy = false

            var data
            try {
                data = JSON.parse(json)
            } catch (error) {
                page.authStatus = "Could not read login response"
                return
            }

            if (data.error) {
                page.authStatus = data.error
                return
            }

            page.loggedIn = true
            page.authStatus = "Logged in as " + (data.display_name || "Qobuz")
        }

        onLogoutComplete: {
            page.authBusy = false
            page.loggedIn = false
            page.authStatus = "Logged out"
        }

        onIsLoggedInComplete: {
            var data
            try {
                data = JSON.parse(json)
            } catch (error) {
                return
            }

            page.loggedIn = data.logged_in === true
        }
    }

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

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: page.loggedIn ? "Log out of Qobuz" : "Log in to Qobuz"
                enabled: !page.authBusy

                onClicked: {
                    page.authBusy = true
                    page.authStatus = page.loggedIn
                                      ? "Logging out…"
                                      : "Opening browser…"

                    if (page.loggedIn)
                        backend.logout()
                    else
                        backend.loginBrowser()
                }
            }

            Label {
                width: parent.width - Theme.horizontalPageMargin * 2
                anchors.horizontalCenter: parent.horizontalCenter
                text: page.authStatus
                visible: text.length > 0
                color: FiatPonsTheme.secondaryText
                font.pixelSize: Theme.fontSizeSmall
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
            }

            SectionHeader { text: "Playback" }
            ComboBox {
                id: qualityBox

                width: parent.width
                label: "Streaming quality"
                description:
                    app.playback.preferredQualityLabel()

                currentIndex:
                    app.playback.preferredQuality === "mp3" ? 0
                    : app.playback.preferredQuality === "lossless" ? 1
                    : app.playback.preferredQuality === "hires" ? 2
                    : 3

                menu: ContextMenu {
                    MenuItem {
                        text: "MP3 320"
                        onClicked:
                            app.playback.setPreferredQuality("mp3")
                    }

                    MenuItem {
                        text: "CD (FLAC 16/44.1)"
                        onClicked:
                            app.playback.setPreferredQuality("lossless")
                    }

                    MenuItem {
                        text: "Hi-Res (up to 24/96)"
                        onClicked:
                            app.playback.setPreferredQuality("hires")
                    }

                    MenuItem {
                        text: "Hi-Res Max (up to 24/192)"
                        onClicked:
                            app.playback.setPreferredQuality("ultrahires")
                    }
                }
            }

            SectionHeader { text: "" }
            BackgroundItem {
                width: parent.width
                height: Theme.itemSizeSmall
                onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
                Label {
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.horizontalPageMargin
                    anchors.verticalCenter: parent.verticalCenter
                    text: "About Fiat Pons"
                    color: FiatPonsTheme.primaryText
                    font.pixelSize: Theme.fontSizeMedium
                }
            }
        }

        VerticalScrollDecorator {}
    }
}
