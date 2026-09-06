import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0
import se.munkstolen.fiatpons 1.0
import "../components"
import ".."

// A single playlist's tracks. Guarded backend call so it renders whether or
// not backend.playlist()/playlistComplete exist yet.
Page {
    id: page
    property string playlistIdStr: ""
    property var playlistId: playlistIdStr.length > 0 ? parseInt(playlistIdStr) : 0
    property string initialName: ""
    property string initialCover: ""

    property string name: initialName
    property string coverUrl: initialCover
    property int trackCount: 0
    property bool busy: true
    property bool wired: false
    property string errorText: ""

    function paint() { FiatPonsTheme.applyPalette(page) }
    Component.onCompleted: {
        paint()
        if (playlistId > 0 && backend.playlist) { wired = true; backend.playlist(playlistId) }
        else busy = false
    }
    Connections { target: FiatPonsTheme; onAmbientChanged: page.paint() }

    function rowToTrack(m) { return { id: m.id, title: m.title, artist: m.artist, album: m.album, cover_url: m.cover_url } }
    function playAll() {
        if (tracksModel.count === 0) return
        app.queue.playNow(rowToTrack(tracksModel.get(0)))
        for (var i = 1; i < tracksModel.count; i++) app.queue.enqueue(rowToTrack(tracksModel.get(i)))
    }

    Backend { id: backend }
    Connections {
        target: backend
        ignoreUnknownSignals: true
        onPlaylistComplete: {
            page.busy = false
            var data
            try { data = JSON.parse(json) } catch (e) { page.errorText = "Could not read response"; return }
            if (data.error) { page.errorText = data.error; return }
            var pl = data.playlist || {}
            if ((pl.name || "").length > 0) page.name = pl.name
            if ((pl.image_url || "").length > 0) page.coverUrl = pl.image_url
            page.trackCount = pl.track_count || 0
            var items = data.tracks || []
            for (var i = 0; i < items.length; i++) { var t = items[i]; t.id = String(t.id); tracksModel.append(t) }
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

            PageHeader { title: "Playlist" }

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
                    asynchronous: true; cache: true; visible: false
                }
                OpacityMask { anchors.fill: parent; source: art; maskSource: mask; visible: page.coverUrl.length > 0 }
                Rectangle {
                    anchors.fill: parent; radius: FiatPonsTheme.cardRadius; color: "transparent"
                    border.color: FiatPonsTheme.cardBorder; border.width: FiatPonsTheme.cardBorderWidth
                }
                Label {
                    anchors.centerIn: parent; text: "\u266B"; color: FiatPonsTheme.secondaryText
                    font.pixelSize: Theme.fontSizeHuge * 2; font.family: FiatPonsTheme.serif
                    visible: page.coverUrl.length === 0
                }
            }

            Label {
                width: parent.width - Theme.horizontalPageMargin * 2
                anchors.horizontalCenter: parent.horizontalCenter
                text: page.name
                color: FiatPonsTheme.primaryText
                font.pixelSize: Theme.fontSizeLarge
                font.family: FiatPonsTheme.serif
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
            }

            Item {
                width: parent.width
                height: playButton.height
                IconButton {
                    id: playButton
                    anchors.horizontalCenter: parent.horizontalCenter
                    icon.source: "image://theme/icon-l-play"
                    icon.color: FiatPonsTheme.primaryText
                    enabled: tracksModel.count > 0
                    onClicked: page.playAll()
                }
            }

            Rectangle { width: parent.width; height: 1; color: FiatPonsTheme.innerBorder }
            Item { width: 1; height: Theme.paddingSmall }
        }

        delegate: ListItem {
            id: delegateItem
            width: listView.width
            contentHeight: Theme.itemSizeMedium
            function trackObj() { return page.rowToTrack(model) }
            onClicked: app.queue.playNow(trackObj())
            menu: ContextMenu {
                MenuItem { text: "Play now";     onClicked: app.queue.playNow(delegateItem.trackObj()) }
                MenuItem { text: "Add to queue"; onClicked: app.queue.enqueue(delegateItem.trackObj()) }
                MenuItem { text: "Play next";    onClicked: app.queue.playNext(delegateItem.trackObj()) }
            }
            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 1; color: FiatPonsTheme.innerBorder
            }
            Row {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.horizontalPageMargin
                anchors.rightMargin: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.paddingMedium
                Rectangle {
                    id: tile
                    width: Theme.itemSizeMedium - Theme.paddingMedium
                    height: width
                    anchors.verticalCenter: parent.verticalCenter
                    radius: Theme.paddingSmall / 2
                    color: FiatPonsTheme.recessFill
                    border.color: FiatPonsTheme.recessBorder
                    border.width: 1
                    clip: true
                    Image {
                        anchors.fill: parent
                        source: (model.cover_url === undefined) ? "" : model.cover_url
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true; cache: true
                    }
                    Label {
                        anchors.centerIn: parent; text: "\u266A"; color: FiatPonsTheme.secondaryText
                        font.pixelSize: Theme.fontSizeLarge
                        visible: (model.cover_url === undefined || model.cover_url.length === 0)
                    }
                }
                Column {
                    width: parent.width - tile.width - Theme.paddingMedium
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.paddingSmall / 2
                    Label {
                        width: parent.width
                        text: model.title === undefined ? "" : model.title
                        color: delegateItem.highlighted ? FiatPonsTheme.accent : FiatPonsTheme.primaryText
                        font.pixelSize: Theme.fontSizeMedium
                        truncationMode: TruncationMode.Fade
                    }
                    Label {
                        width: parent.width
                        visible: text.length > 0
                        text: model.artist === undefined ? "" : model.artist
                        color: FiatPonsTheme.secondaryText
                        font.pixelSize: Theme.fontSizeExtraSmall
                        truncationMode: TruncationMode.Fade
                    }
                }
            }
        }

        VerticalScrollDecorator {}
    }

    BusyIndicator {
        anchors.centerIn: parent
        size: BusyIndicatorSize.Large
        running: page.busy
    }

    Label {
        anchors.centerIn: parent
        visible: !page.busy && tracksModel.count === 0
        text: page.errorText.length > 0 ? page.errorText
             : (page.wired ? "This playlist is empty" : "Playlist tracks will appear once wired")
        color: FiatPonsTheme.secondaryText
        font.pixelSize: Theme.fontSizeSmall
        wrapMode: Text.Wrap
        width: parent.width - Theme.horizontalPageMargin * 4
        horizontalAlignment: Text.AlignHCenter
    }
}
