import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.0
import QtGraphicalEffects 1.0
import "../components"
import ".."

Item {
    id: section

    readonly property var track: app.playback.nowTrack
    readonly property string trackTitle:  track ? track.title  : "Nothing playing"
    readonly property string trackArtist: track ? track.artist : ""
    readonly property string trackAlbum:  track ? track.album  : ""
    readonly property string coverUrl:    (track && track.cover_url) ? track.cover_url : ""

    function fmt(ms) {
        if (!ms || ms < 0) return "0:00"
        var s = Math.floor(ms / 1000), m = Math.floor(s / 60), sec = s % 60
        return m + ":" + (sec < 10 ? "0" + sec : sec)
    }

    property bool favourite: false

    SilicaFlickable {
        id: flick
        anchors.fill: parent
        contentHeight: content.height + Theme.paddingLarge

        Column {
            id: content
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: Theme.paddingMedium
            anchors.leftMargin: Theme.horizontalPageMargin
            anchors.rightMargin: Theme.horizontalPageMargin
            spacing: Theme.paddingMedium

            // ---- Cover ----
            Item {
                width: parent.width
                height: width

                Rectangle { id: coverMask; anchors.fill: parent; radius: FiatPonsTheme.cardRadius; visible: false }
                Rectangle { anchors.fill: parent; radius: FiatPonsTheme.cardRadius; color: FiatPonsTheme.recessFill }
                Image {
                    id: coverImage
                    anchors.fill: parent
                    source: section.coverUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    visible: false
                }
                OpacityMask { anchors.fill: parent; source: coverImage; maskSource: coverMask; visible: section.coverUrl.length > 0 }
                Rectangle {
                    anchors.fill: parent
                    radius: FiatPonsTheme.cardRadius
                    color: "transparent"
                    border.color: FiatPonsTheme.cardBorder
                    border.width: FiatPonsTheme.cardBorderWidth
                }
                Label {
                    anchors.centerIn: parent
                    text: "\u266B"
                    color: FiatPonsTheme.secondaryText
                    font.pixelSize: Theme.fontSizeHuge * 2
                    font.family: FiatPonsTheme.serif
                    visible: section.coverUrl.length === 0
                }
                IconButton {
                    anchors { top: parent.top; right: parent.right; margins: Theme.paddingMedium }
                    icon.source: "image://theme/icon-m-about"
                    icon.color: FiatPonsTheme.primaryText
                    onClicked: { /* TODO: track info / credits */ }
                }
            }

            // ---- Title / artist / album (+ quality) ----
            Column {
                width: parent.width
                spacing: Theme.paddingSmall / 2
                Label {
                    width: parent.width
                    text: section.trackTitle
                    color: FiatPonsTheme.primaryText
                    font.pixelSize: Theme.fontSizeLarge
                    font.family: FiatPonsTheme.serif
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                }
                Label {
                    width: parent.width
                    text: section.trackArtist
                    color: FiatPonsTheme.secondaryText
                    font.pixelSize: Theme.fontSizeMedium
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    visible: text.length > 0
                }
                Label {
                    width: parent.width
                    text: section.trackAlbum + (app.playback.quality.length > 0
                        ? "   \u00B7   " + app.playback.quality : "")
                    color: FiatPonsTheme.secondaryText
                    font.pixelSize: Theme.fontSizeExtraSmall
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    visible: text.length > 0
                }
            }

            // ---- Progress: elapsed | slider | total ----
            Row {
                width: parent.width
                spacing: Theme.paddingSmall
                Label {
                    id: elapsed
                    anchors.verticalCenter: parent.verticalCenter
                    text: section.fmt(app.playback.position)
                    color: FiatPonsTheme.secondaryText
                    font.pixelSize: Theme.fontSizeExtraSmall
                }
                Slider {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - elapsed.width - total.width - Theme.paddingSmall * 2
                    minimumValue: 0
                    maximumValue: app.playback.duration > 0 ? app.playback.duration : 1
                    enabled: app.playback.duration > 0
                    value: app.playback.position
                    color: FiatPonsTheme.accent
                    highlightColor: FiatPonsTheme.accent
                    onReleased: app.playback.seek(value)
                }
                Label {
                    id: total
                    anchors.verticalCenter: parent.verticalCenter
                    text: section.fmt(app.playback.duration)
                    color: FiatPonsTheme.secondaryText
                    font.pixelSize: Theme.fontSizeExtraSmall
                }
            }

            // ---- Primary transport ----
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingLarge
                IconButton {
                    icon.source: "image://theme/icon-m-previous"
                    icon.color: FiatPonsTheme.primaryText
                    enabled: app.queue.hasPrev
                    onClicked: app.playback.previous()
                }
                IconButton {
                    icon.source: app.playback.playing
                        ? "image://theme/icon-l-pause" : "image://theme/icon-l-play"
                    icon.color: FiatPonsTheme.primaryText
                    enabled: section.track !== null
                    onClicked: app.playback.toggle()
                }
                IconButton {
                    icon.source: "image://theme/icon-m-next"
                    icon.color: FiatPonsTheme.primaryText
                    enabled: app.queue.hasNext || app.playback.repeatMode > 0 || app.playback.shuffle
                    onClicked: app.playback.next()
                }
            }

            // ---- Secondary: favourite / shuffle / repeat / Q ----
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingLarge * 1.5
                BackgroundItem {
                    width: Theme.iconSizeMedium
                    height: Theme.iconSizeMedium
                    anchors.verticalCenter: parent.verticalCenter

                    onClicked: section.favourite = !section.favourite

                    Label {
                        anchors.centerIn: parent
                        text: section.favourite ? "\u2665" : "\u2661"
                        color: section.favourite ? FiatPonsTheme.accent : FiatPonsTheme.primaryText
                        font.pixelSize: Theme.fontSizeLarge
                        font.family: FiatPonsTheme.serif
                    }
                }
                IconButton {
                    icon.source: "image://theme/icon-m-shuffle"
                    icon.color: app.playback.shuffle ? FiatPonsTheme.accent : FiatPonsTheme.primaryText
                    onClicked: app.playback.shuffle = !app.playback.shuffle
                }
                IconButton {
                    icon.source: app.playback.repeatMode === 2
                        ? "image://theme/icon-m-repeat-single" : "image://theme/icon-m-repeat"
                    icon.color: app.playback.repeatMode > 0 ? FiatPonsTheme.accent : FiatPonsTheme.primaryText
                    onClicked: app.playback.repeatMode = (app.playback.repeatMode + 1) % 3
                }
                BackgroundItem {
                    width: Theme.iconSizeMedium
                    height: Theme.iconSizeMedium
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: pageStack.push(Qt.resolvedUrl("../pages/QueuePage.qml"))
                    Label {
                        anchors.centerIn: parent
                        text: "Q"
                        font.pixelSize: Theme.fontSizeLarge
                        font.family: FiatPonsTheme.serif
                        color: highlighted ? FiatPonsTheme.accent : FiatPonsTheme.primaryText
                    }
                    Label {
                        anchors { bottom: parent.bottom; right: parent.right }
                        visible: app.queue.model.count > 0
                        text: app.queue.model.count
                        font.pixelSize: Theme.fontSizeTiny
                        color: FiatPonsTheme.accent
                    }
                }
            }

            Label {
                width: parent.width
                text: app.playback.statusLine
                color: FiatPonsTheme.accent
                font.pixelSize: Theme.fontSizeExtraSmall
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                visible: text.length > 0
            }
        }

        VerticalScrollDecorator { flickable: flick }
    }
}
