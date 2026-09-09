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

    property string probeStatus: ""

    function paint() { FiatPonsTheme.applyPalette(page) }
    Component.onCompleted: { paint(); backend.isLoggedIn() }
    Connections { target: FiatPonsTheme; onAmbientChanged: page.paint() }

    Backend {
        id: backend
    }

    Connections {
        target: backend
        onLoginProbeComplete: {
            page.probeStatus = json
        }

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

            SectionHeader { text: "Login probe" }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Test browser open"
                onClicked: Qt.openUrlExternally("https://www.qobuz.com/")
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Test localhost callback"
                onClicked: backend.loginProbeStart()
            }

            Label {
                width: parent.width - Theme.horizontalPageMargin * 2
                anchors.horizontalCenter: parent.horizontalCenter
                text: probeStatus
                color: FiatPonsTheme.secondaryText
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                visible: text.length > 0
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
                description: app.playback.preferredQuality === "mp3"
                             ? "MP3 320 kbps"
                             : "Lossless CD quality"
                currentIndex:
                    app.playback.preferredQuality === "mp3"
                    ? 1
                    : 0

                menu: ContextMenu {
                    MenuItem {
                        text: "CD (FLAC 16/44.1)"
                        onClicked:
                            app.playback.setPreferredQuality(
                                "lossless"
                            )
                    }

                    MenuItem {
                        text: "MP3 320"
                        onClicked:
                            app.playback.setPreferredQuality(
                                "mp3"
                            )
                    }
                }
            }
        }

        VerticalScrollDecorator {}
    }
}
