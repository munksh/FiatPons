import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0
import se.munkstolen.fiatpons 1.0
import "../components"
import ".."

// Drill-down from Search (Album pill) or ArtistPage. Order: cover, title,
// big round play button, a divider line, then release info + label right
// after it (no gap), then the track list, then a link to the artist.
Page {
    id: page
    property string albumId: ""

    property string title: ""
    property string artist: ""
    property string artistId: ""     // not returned by fp_album yet -- see note below
    property string coverUrl: ""
    property string year: ""
    property int trackCount: 0
    property int durationSecs: 0
    property string label: ""
    property bool busy: true
    property string errorText: ""

    function paint() { FiatPonsTheme.applyPalette(page) }
    Component.onCompleted: { paint(); backend.album(albumId) }
    Connections { target: FiatPonsTheme; onAmbientChanged: page.paint() }

    function fmtDuration(secs) {
        if (!secs || secs <= 0) return ""
        var m = Math.floor(secs / 60)
        var h = Math.floor(m / 60)
        m = m % 60
        return h > 0 ? (h + " hr " + m + " min") : (m + " min")
    }

    Backend {
        id: backend
        onAlbumComplete: {
            busy = false
            var data
            try { data = JSON.parse(json) }
            catch (e) { errorText = "Could not read response"; return }
            if (data.error) { errorText = data.error; return }
            var a = data.album || {}
            title = a.title || ""
            artist = a.artist || ""
            artistId = a.artist_id !== undefined ? String(a.artist_id) : ""
            coverUrl = a.cover_url || ""
            year = a.year || ""
            trackCount = a.track_count || 0
            durationSecs = a.duration_secs || 0
            label = a.label || ""
            var items = data.tracks || []
            for (var i = 0; i < items.length; i++) {
                var t = items[i]
                t.id = String(t.id)
                tracksModel.append(t)
            }
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

    SilicaListView {
        id: listView
        anchors.fill: parent
        model: ListModel { id: tracksModel }

        header: Column {
            width: listView.width
            spacing: Theme.paddingMedium

            PageHeader { title: "Album" }

            // ---- Cover ----
            Item {
                width: parent.width - Theme.horizontalPageMargin * 2
                height: width
                anchors.horizontalCenter: parent.horizontalCenter

                Rectangle { id: mask; anchors.fill: parent; radius: FiatPonsTheme.cardRadius; visible: false }
                Rectangle { anchors.fill: parent; radius: FiatPonsTheme.cardRadius; color: FiatPonsTheme.recessFill }
                Image {
                    id: art
                    anchors.fill: parent
                    source: page.coverUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    visible: false
                }
                OpacityMask { anchors.fill: parent; source: art; maskSource: mask; visible: page.coverUrl.length > 0 }
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
                    visible: page.coverUrl.length === 0
                }
            }

            // ---- Title / artist (under the cover) ----
            Column {
                width: parent.width - Theme.horizontalPageMargin * 2
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingSmall / 2
                Label {
                    width: parent.width
                    text: page.title
                    color: FiatPonsTheme.primaryText
                    font.pixelSize: Theme.fontSizeLarge
                    font.family: FiatPonsTheme.serif
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                }
                Label {
                    width: parent.width
                    text: page.artist
                    color: FiatPonsTheme.secondaryText
                    font.pixelSize: Theme.fontSizeMedium
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                }
            }

            // ---- Big round play button ----
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Theme.itemSizeLarge
                height: width
                radius: width / 2
                color: FiatPonsTheme.pillFillActive
                border.color: FiatPonsTheme.pillBorderActive
                border.width: 1
                enabled: tracksModel.count > 0
                opacity: enabled ? 1.0 : 0.4
                Icon {
                    anchors.centerIn: parent
                    source: "image://theme/icon-l-play"
                    color: FiatPonsTheme.accent
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (tracksModel.count === 0) return
                        app.queue.playNow(page.rowToTrack(tracksModel.get(0)))
                        for (var i = 1; i < tracksModel.count; i++)
                            app.queue.enqueue(page.rowToTrack(tracksModel.get(i)))
                    }
                }
            }

            // ---- Divider ----
            Rectangle {
                width: parent.width
                height: 1
                color: FiatPonsTheme.innerBorder
            }

            // ---- Release info + label, right after the divider ----
            Column {
                width: parent.width - Theme.horizontalPageMargin * 2
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingSmall / 4
                Label {
                    width: parent.width
                    visible: text.length > 0
                    text: {
                        var parts = []
                        if (page.trackCount > 0) parts.push(page.trackCount + (page.trackCount === 1 ? " track" : " tracks"))
                        var d = page.fmtDuration(page.durationSecs)
                        if (d.length > 0) parts.push(d)
                        if (page.year.length > 0) parts.push(page.year)
                        return parts.join(" \u00B7 ")
                    }
                    color: FiatPonsTheme.secondaryText
                    font.pixelSize: Theme.fontSizeExtraSmall
                    horizontalAlignment: Text.AlignHCenter
                }
                Label {
                    width: parent.width
                    visible: page.label.length > 0
                    text: page.label
                    color: FiatPonsTheme.secondaryText
                    font.pixelSize: Theme.fontSizeExtraSmall
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            Item { width: 1; height: Theme.paddingSmall }
        }

        delegate: ListItem {
            id: delegateItem
            width: listView.width
            contentHeight: Theme.itemSizeSmall

            function trackObj() { return page.rowToTrack(model) }

            onClicked: app.queue.playNow(trackObj())

            menu: ContextMenu {
                MenuItem { text: "Play now";     onClicked: app.queue.playNow(delegateItem.trackObj()) }
                MenuItem { text: "Add to queue"; onClicked: app.queue.enqueue(delegateItem.trackObj()) }
                MenuItem { text: "Play next";    onClicked: app.queue.playNext(delegateItem.trackObj()) }
            }

            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 1
                color: FiatPonsTheme.innerBorder
            }

            Row {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.horizontalPageMargin
                anchors.rightMargin: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.paddingMedium

                Label {
                    width: Theme.itemSizeExtraSmall
                    text: (index + 1)
                    color: FiatPonsTheme.secondaryText
                    font.pixelSize: Theme.fontSizeSmall
                    horizontalAlignment: Text.AlignRight
                }
                Label {
                    width: parent.width - Theme.itemSizeExtraSmall - Theme.paddingMedium
                    text: model.title === undefined ? "" : model.title
                    color: delegateItem.highlighted ? FiatPonsTheme.accent : FiatPonsTheme.primaryText
                    font.pixelSize: Theme.fontSizeMedium
                    truncationMode: TruncationMode.Fade
                }
            }
        }

        footer: Column {
            width: listView.width
            Rectangle { width: parent.width; height: 1; color: FiatPonsTheme.innerBorder }
            BackgroundItem {
                width: parent.width
                height: Theme.itemSizeSmall
                onClicked: pageStack.push(Qt.resolvedUrl("ArtistPage.qml"), { artistIdStr: page.artistId })
                enabled: page.artistId.length > 0
                Label {
                    anchors.centerIn: parent
                    text: "Discover " + page.artist
                    color: FiatPonsTheme.accent
                    font.pixelSize: Theme.fontSizeSmall
                }
            }
        }

        VerticalScrollDecorator {}
    }

    function rowToTrack(m) {
        return { id: m.id, title: m.title, artist: m.artist, album: m.album, cover_url: m.cover_url }
    }

    BusyIndicator {
        anchors.centerIn: parent
        size: BusyIndicatorSize.Large
        running: page.busy
    }

    Label {
        anchors.centerIn: parent
        visible: !page.busy && page.errorText.length > 0
        text: page.errorText
        color: FiatPonsTheme.secondaryText
        font.pixelSize: Theme.fontSizeSmall
        wrapMode: Text.Wrap
        width: parent.width - Theme.horizontalPageMargin * 4
        horizontalAlignment: Text.AlignHCenter
    }
}
