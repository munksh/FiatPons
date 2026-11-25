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

            ComboBox {
                id: precacheBox

                // Seconds; index matches the menu below.
                property var values: [0, 10, 30, 60, 120]

                width: parent.width
                label: "Precache before playing"
                description:
                    "Audio to download before a track starts, and before "
                    + "it continues if the connection falls behind. More "
                    + "means fewer interruptions but a slower start."

                currentIndex: {
                    var i = values.indexOf(app.playback.precacheSeconds)
                    return i >= 0 ? i : 2
                }

                menu: ContextMenu {
                    MenuItem {
                        text: "Off"
                        onClicked: app.playback.setPrecacheSeconds(0)
                    }
                    MenuItem {
                        text: "10 seconds"
                        onClicked: app.playback.setPrecacheSeconds(10)
                    }
                    MenuItem {
                        text: "30 seconds"
                        onClicked: app.playback.setPrecacheSeconds(30)
                    }
                    MenuItem {
                        text: "1 minute"
                        onClicked: app.playback.setPrecacheSeconds(60)
                    }
                    MenuItem {
                        text: "2 minutes"
                        onClicked: app.playback.setPrecacheSeconds(120)
                    }
                }
            }

            TextSwitch {
                text: "Show cache status"
                description: "Show precaching progress on the Now Playing page"
                automaticCheck: false
                checked: app.playback.showCacheStatus
                onClicked: app.playback.setShowCacheStatus(!app.playback.showCacheStatus)
            }

            ComboBox {
                id: readAheadBox

                // Seconds; index matches the menu below. 0 = whole track.
                property var values: [60, 180, 300, 0]

                width: parent.width
                label: "Download ahead"
                description:
                    "How far ahead of what is playing to download. The "
                    + "whole track rides out the longest outages; a limit "
                    + "saves data when skipping songs. Always at least "
                    + "30 s more than the precache."

                currentIndex: {
                    var i = values.indexOf(app.playback.readAheadSeconds)
                    return i >= 0 ? i : 3
                }

                menu: ContextMenu {
                    MenuItem {
                        text: "1 minute"
                        onClicked: app.playback.setReadAheadSeconds(60)
                    }
                    MenuItem {
                        text: "3 minutes"
                        onClicked: app.playback.setReadAheadSeconds(180)
                    }
                    MenuItem {
                        text: "5 minutes"
                        onClicked: app.playback.setReadAheadSeconds(300)
                    }
                    MenuItem {
                        text: "Whole track"
                        onClicked: app.playback.setReadAheadSeconds(0)
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
