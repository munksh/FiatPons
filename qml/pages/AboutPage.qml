import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."
import "../components"

// Reached from Settings, not the pull-down -- Pons has no pull-down menu of
// its own. Everything else follows the family template.
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
        contentHeight: content.height + Theme.paddingLarge

        Column {
            id: content
            width: parent.width
            spacing: Theme.paddingMedium

            PageHead {
                title: qsTr("about")
                subtitle: "fiat pons"
            }

            // -- What it is -----------------------------------------------

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeMedium
                font.family: FiatPonsTheme.serif
                color: FiatPonsTheme.primaryText
                text: qsTr("This app doesn't try to be Qobuz's web player squeezed onto a phone. It tries to be what a music player looks like when it's built for Sailfish's own hands and eyes, and left there quietly to just work.")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: FiatPonsTheme.secondaryText
                text: qsTr("It's part of Munkstolen's small family of Fiat apps for Sailfish OS — each one a bridge of its own kind, built the same unhurried way: read the platform closely, keep the interface calm, and let the thing do one job well.")
            }

            // -- The name --------------------------------------------------

            SectionLabel {
                x: Theme.horizontalPageMargin
                text: qsTr("The name")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: FiatPonsTheme.secondaryText
                textFormat: Text.StyledText
                text: qsTr("<b>fiat</b> — Latin, <i>let there be</i>. From <i>fiat lux</i> in the Vulgate: let there be light, and there was light. The first app took the phrase. The rest of the family kept the verb.")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: FiatPonsTheme.secondaryText
                textFormat: Text.StyledText
                text: qsTr("<b>pons</b> — Latin, <i>bridge</i>. This app is a bridge to Qobuz, not a replica of it.")
            }

            Item { width: 1; height: Theme.paddingLarge }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Theme.itemSizeSmall
                height: 1
                color: FiatPonsTheme.innerBorder
            }

            Item { width: 1; height: Theme.paddingMedium }

            Column {
                x: Theme.horizontalPageMargin
                width: content.width - Theme.horizontalPageMargin * 2
                spacing: Theme.paddingSmall

                Label {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Theme.fontSizeSmall
                    font.family: FiatPonsTheme.serif
                    font.italic: true
                    color: FiatPonsTheme.primaryText
                    text: qsTr("Music is the universal language of mankind.")
                }

                Label {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: FiatPonsTheme.secondaryText
                    text: "Henry Wadsworth Longfellow, Outre-Mer"
                }
            }

            Item { width: 1; height: Theme.paddingMedium }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Theme.itemSizeSmall
                height: 1
                color: FiatPonsTheme.innerBorder
            }

            // -- Built on ----------------------------------------------------

            SectionLabel {
                x: Theme.horizontalPageMargin
                text: qsTr("Built on")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: FiatPonsTheme.primaryText
                textFormat: Text.StyledText
                text: qsTr("Fiat Pons owes its entire connection to Qobuz to <b>qbz-qobuz</b>, the Rust library at the heart of <b>blitzkriegfc</b>'s QBZ project (MIT licensed). Search, streaming, favourites, playlists and login all run on that work — this app is the Silica face put on top of it. A genuine thank-you for building and sharing it.")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                font.pixelSize: Theme.fontSizeExtraSmall
                color: FiatPonsTheme.accent
                text: "github.com/vicrodh/qbz"
            }

            // -- Privacy ---------------------------------------------------

            SectionLabel {
                x: Theme.horizontalPageMargin
                text: qsTr("Your data")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: FiatPonsTheme.secondaryText
                text: qsTr("Fiat Pons talks to one server: Qobuz, using your own Qobuz account. There is no Munkstolen server in between and nothing is measured or reported.")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: FiatPonsTheme.secondaryText
                text: qsTr("Fiat Pons is an unofficial, independent client. It is not made, endorsed, or supported by Qobuz. A Qobuz subscription of your own is required to use it.")
            }

            // -- Who ---------------------------------------------------------

            SectionLabel {
                x: Theme.horizontalPageMargin
                text: qsTr("Made by")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                font.pixelSize: Theme.fontSizeMedium
                font.family: FiatPonsTheme.serif
                color: FiatPonsTheme.primaryText
                text: "Munkstolen"
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                font.pixelSize: Theme.fontSizeExtraSmall
                color: FiatPonsTheme.secondaryText
                text: "Caesar Prometheus Ivarsson"
            }

            BackgroundItem {
                width: parent.width
                height: Theme.itemSizeSmall
                highlightedColor: FiatPonsTheme.highlightWash
                onClicked: Qt.openUrlExternally("https://munkstolen.se")

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    x: Theme.horizontalPageMargin
                    width: parent.width - Theme.horizontalPageMargin * 2

                    Label {
                        width: parent.width
                        truncationMode: TruncationMode.Fade
                        color: FiatPonsTheme.accent
                        font.pixelSize: Theme.fontSizeSmall
                        text: "munkstolen.se"
                    }

                    Label {
                        width: parent.width
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: FiatPonsTheme.secondaryText
                        text: qsTr("Everything else I make")
                    }
                }
            }

            BackgroundItem {
                width: parent.width
                height: Theme.itemSizeSmall
                highlightedColor: FiatPonsTheme.highlightWash
                onClicked: Qt.openUrlExternally("https://github.com/munksh/FiatPons")

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    x: Theme.horizontalPageMargin
                    width: parent.width - Theme.horizontalPageMargin * 2

                    Label {
                        width: parent.width
                        truncationMode: TruncationMode.Fade
                        color: FiatPonsTheme.accent
                        font.pixelSize: Theme.fontSizeSmall
                        text: "github.com/munksh/FiatPons"
                    }

                    Label {
                        width: parent.width
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: FiatPonsTheme.secondaryText
                        text: qsTr("Source and issues · MIT licence")
                    }
                }
            }

            // -- The family ---------------------------------------------------

            SectionLabel {
                x: Theme.horizontalPageMargin
                text: qsTr("The fiat family")
            }

            Repeater {
                model: [
                    { name: "fiat agenda", what: qsTr("let there be doing — a task list"), icon: "images/family/harbour-fiatagenda.png", url: "https://openrepos.net/content/munkstolen/fiat-agenda-task-list" },
                    { name: "fiat margo", what: qsTr("let there be edge — keeps edges"), icon: "images/family/harbour-fiatmargo.png", url: "https://openrepos.net/content/munkstolen/fiat-margo-keeps-edges" },
                    { name: "fiat glossa", what: qsTr("let there be tongue — a translator"), icon: "images/family/harbour-fiatglossa.png", url: "https://openrepos.net/content/munkstolen/fiat-glossa-a-deepl-translator" },
                    { name: "fiat vox", what: qsTr("let there be voice — a chromatic tuner"), icon: "images/family/harbour-fiatvox.png", url: "https://openrepos.net/content/munkstolen/fiat-vox-chromatic-tuner" },
                    { name: "fiat pons", what: qsTr("let there be bridge — this one"), icon: "images/family/harbour-fiatpons.png", url: "" },
                    { name: "fiat lux", what: qsTr("let there be light — a light meter for film - Coming soon"), icon: "images/family/harbour-fiatlux.png", url: "" },
                    { name: "fiat cor", what: qsTr("let there be heart — a metronome"), icon: "images/family/harbour-fiatcor.png", url: "https://openrepos.net/content/munkstolen/fiat-cor-a-metronome" },
                    { name: "fiat passus", what: qsTr("let there be step — a step counter - Coming soon"), icon: "images/family/harbour-fiatpassus.png", url: "" },
                    { name: "fiat mos", what: qsTr("let there be habit — a habit tracker"), icon: "images/family/harbour-fiatmos.png", url: "https://openrepos.net/content/munkstolen/fiat-mos-habit-tracker" }
                ]

                delegate: BackgroundItem {
                    id: familyRow
                    x: Theme.horizontalPageMargin
                    width: content.width - Theme.horizontalPageMargin * 2
                    height: familyText.height
                    enabled: modelData.url !== ""
                    highlightedColor: FiatPonsTheme.highlightWash
                    onClicked: Qt.openUrlExternally(modelData.url)

                    // A cap, not a measurement of familyText: sizing the icon
                    // from the text's height while the text's width comes
                    // from the icon's width would make each depend on the
                    // other, and QML gives no guarantee a loop like that
                    // settles. Every "what" line here is one short sentence,
                    // so in practice this cap and the real name+what height
                    // match; if one ever wraps past it the icon just stops
                    // growing with it instead of the layout misbehaving.
                    readonly property real iconSlot: Theme.itemSizeSmall

                    Image {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(familyText.height, familyRow.iconSlot)
                        height: width
                        source: Qt.resolvedUrl(modelData.icon)
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        opacity: modelData.url !== "" ? 1.0 : 0.55
                    }

                    Column {
                        id: familyText
                        anchors.left: parent.left
                        anchors.leftMargin: familyRow.iconSlot + Theme.paddingMedium
                        anchors.right: parent.right

                        Label {
                            width: parent.width
                            font.pixelSize: Theme.fontSizeSmall
                            font.family: FiatPonsTheme.serif
                            color: modelData.url !== "" ? FiatPonsTheme.accent : FiatPonsTheme.primaryText
                            text: modelData.name
                        }

                        Label {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: FiatPonsTheme.secondaryText
                            text: modelData.what
                        }
                    }
                }
            }

            Item { width: 1; height: Theme.paddingMedium }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeTiny
                color: FiatPonsTheme.secondaryText
                text: qsTr("Small instruments that each do one thing and leave the rest alone. They share a look, a palette and a stubbornness about staying on your own phone.")
            }

            // -- Version ---------------------------------------------------
            //
            // Last, because it is support and not identity. The number comes
            // from the rpm spec by way of qmake, so it is the one the package
            // was actually built with rather than one written down twice.

            SectionLabel {
                x: Theme.horizontalPageMargin
                text: qsTr("Version")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin * 2
                font.pixelSize: Theme.fontSizeSmall
                color: FiatPonsTheme.primaryText
                text: typeof appVersion !== "undefined" ? appVersion : qsTr("unknown")
            }

            // -- Colophon --------------------------------------------------

            Item { width: 1; height: Theme.itemSizeExtraSmall }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Theme.itemSizeSmall
                height: 1
                color: FiatPonsTheme.innerBorder
            }

            Item { width: 1; height: Theme.paddingLarge }

            MunkstolenMark {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Theme.itemSizeMedium
                frame: "ring"
                color: FiatPonsTheme.makerMark
            }

            Item { width: 1; height: Theme.paddingSmall }

            Label {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: "munkstolen"
                font.pixelSize: Theme.fontSizeSmall
                font.family: FiatPonsTheme.serif
                font.italic: true
                color: FiatPonsTheme.makerMark
            }
        }

        VerticalScrollDecorator { }
    }
}
