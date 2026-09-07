import QtQuick 2.0
import Sailfish.Silica 1.0
import se.munkstolen.fiatpons 1.0
import "../components"
import ".."

// Top-level SEARCH tab. Three modes via pills: Album (default) / Tracks / Artist.
// IMPORTANT: album ids are strings, track/artist ids are numbers. Reusing one
// ListModel across modes made QML's role-type inference collide ("Number ->
// String"), which silently broke bindings. Fix: every id is normalised to a
// STRING the moment it enters the model, and the model is fully torn down
// (not just cleared) on every mode switch so no stale role types remain.
Item {
    id: section
    clip: true
    property bool busy: false
    property string errorText: ""
    property string lastQuery: ""
    property string mode: "albums"   // "albums" | "tracks" | "artists"

    function paint() { FiatPonsTheme.applyPalette(section) }
    Component.onCompleted: paint()
    Connections { target: FiatPonsTheme; onAmbientChanged: section.paint() }

    function runSearch() {
        if (lastQuery.length === 0) return
        busy = true
        errorText = ""
        resetModel()
        if (mode === "albums") backend.searchAlbums(lastQuery)
        else if (mode === "artists") backend.searchArtists(lastQuery)
        else backend.search(lastQuery)
    }

    function selectMode(m) {
        if (mode === m) return
        mode = m
        resetModel()
        runSearch()
    }

    // Fully rebuild the model component so no role types survive a mode switch.
    function resetModel() {
        listView.model = null
        modelComp.createObject(section)
    }
    Component {
        id: modelComp
        ListModel { id: freshModel; Component.onCompleted: listView.model = freshModel }
    }

    Backend {
        id: backend
        onSearchComplete: section.handle(json, "tracks")
        onAlbumsComplete: section.handle(json, "albums")
        onArtistsComplete: section.handle(json, "artists")
    }

    function handle(json, kind) {
        busy = false
        var data
        try { data = JSON.parse(json) }
        catch (e) { errorText = "Could not read response"; return }
        if (data.error) { errorText = data.error; return }
        errorText = ""
        var items = data[kind] || []
        for (var i = 0; i < items.length; i++) {
            var it = items[i]
            // Normalise id to a string unconditionally -- this is the fix for
            // the Number->String role collision when switching pills.
            it.id = String(it.id)
            if (listView.model) listView.model.append(it)
        }
    }

    SilicaListView {
        id: listView
        anchors.fill: parent
        clip: true
        currentIndex: -1
        model: ListModel { }

        header: Column {
            width: listView.width
            spacing: Theme.paddingSmall

            SearchField {
                id: searchField
                width: parent.width
                placeholderText: "Track, artist, or album"
                color: FiatPonsTheme.primaryText
                inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
                EnterKey.iconSource: "image://theme/icon-m-enter-close"
                EnterKey.onClicked: {
                    focus = false
                    if (text.length > 0) { section.lastQuery = text; section.runSearch() }
                }
            }

            // ---- Pills, wrapped in a fixed-height Item for clean top/bottom padding ----
            Item {
                width: parent.width
                height: pillRow.height + Theme.paddingSmall * 2

                Row {
                    id: pillRow
                    anchors.centerIn: parent
                    spacing: Theme.paddingSmall

                    Repeater {
                        model: [
                            { key: "albums",  label: "Album" },
                            { key: "tracks",  label: "Tracks" },
                            { key: "artists", label: "Artist" }
                        ]
                        delegate: Rectangle {
                            property bool active: section.mode === modelData.key
                            width: pillLabel.width + Theme.paddingLarge
                            height: Theme.itemSizeExtraSmall * 0.7
                            radius: height / 2
                            color: active ? FiatPonsTheme.pillFillActive : FiatPonsTheme.pillFill
                            border.color: active ? FiatPonsTheme.pillBorderActive : FiatPonsTheme.pillBorder
                            border.width: 1
                            Label {
                                id: pillLabel
                                anchors.centerIn: parent
                                text: modelData.label
                                font.pixelSize: Theme.fontSizeExtraSmall
                                color: active ? FiatPonsTheme.accent : FiatPonsTheme.primaryText
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: section.selectMode(modelData.key)
                            }
                        }
                    }
                }
            }
        }

        // One delegate, three layouts by section.mode.
        delegate: ListItem {
            id: delegateItem
            width: listView.width
            contentHeight: Theme.itemSizeMedium

            function trackObj() {
                return {
                    id: model.id, title: model.title, artist: model.artist,
                    album: model.album, cover_url: (model.cover_url === undefined) ? "" : model.cover_url
                }
            }

            onClicked: {
                if (section.mode === "tracks") app.queue.playNow(trackObj())
                else if (section.mode === "albums") pageStack.push(Qt.resolvedUrl("../pages/AlbumPage.qml"), { albumId: model.id })
                else if (section.mode === "artists") pageStack.push(Qt.resolvedUrl("../pages/ArtistPage.qml"), { artistIdStr: model.id })
            }

            menu: section.mode === "tracks" ? tracksMenu : null
            Component {
                id: tracksMenu
                ContextMenu {
                    MenuItem { text: "Play now";     onClicked: app.queue.playNow(delegateItem.trackObj()) }
                    MenuItem { text: "Add to queue"; onClicked: app.queue.enqueue(delegateItem.trackObj()) }
                    MenuItem { text: "Play next";    onClicked: app.queue.playNext(delegateItem.trackObj()) }
                }
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

                Rectangle {
                    id: tile
                    width: Theme.itemSizeMedium - Theme.paddingMedium
                    height: width
                    anchors.verticalCenter: parent.verticalCenter
                    radius: section.mode === "artists" ? width / 2 : Theme.paddingSmall / 2
                    color: FiatPonsTheme.recessFill
                    border.color: FiatPonsTheme.recessBorder
                    border.width: 1
                    clip: true
                    Image {
                        anchors.fill: parent
                        source: {
                            if (section.mode === "artists") return (model.image_url === undefined) ? "" : model.image_url
                            return (model.cover_url === undefined) ? "" : model.cover_url
                        }
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                    }
                    Label {
                        anchors.centerIn: parent
                        text: section.mode === "artists" ? "\u263A" : "\u266A"
                        color: FiatPonsTheme.secondaryText
                        font.pixelSize: Theme.fontSizeLarge
                        visible: {
                            if (section.mode === "artists") return (model.image_url === undefined || model.image_url.length === 0)
                            return (model.cover_url === undefined || model.cover_url.length === 0)
                        }
                    }
                }

                Column {
                    width: parent.width - tile.width - Theme.paddingMedium
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.paddingSmall / 2

                    Label {
                        width: parent.width
                        text: section.mode === "artists"
                            ? (model.name === undefined ? "" : model.name)
                            : (model.title === undefined ? "" : model.title)
                        color: delegateItem.highlighted ? FiatPonsTheme.accent : FiatPonsTheme.primaryText
                        font.pixelSize: Theme.fontSizeMedium
                        truncationMode: TruncationMode.Fade
                    }

                    Label {
                        width: parent.width
                        visible: text.length > 0
                        color: FiatPonsTheme.secondaryText
                        font.pixelSize: Theme.fontSizeExtraSmall
                        truncationMode: TruncationMode.Fade
                        text: {
                            if (section.mode === "tracks")
                                return (model.artist === undefined ? "" : model.artist)
                                    + " \u2014 " + (model.album === undefined ? "" : model.album)
                            if (section.mode === "albums") {
                                var year = (model.year === undefined || model.year.length === 0) ? "" : " \u00B7 " + model.year
                                return (model.artist === undefined ? "" : model.artist) + year
                            }
                            return ""
                        }
                    }
                }
            }
        }

        VerticalScrollDecorator {}
    }

    BusyIndicator {
        anchors.centerIn: parent
        size: BusyIndicatorSize.Large
        running: section.busy
    }

    Column {
        anchors.centerIn: parent
        width: parent.width - Theme.horizontalPageMargin * 4
        spacing: Theme.paddingSmall
        visible: !section.busy && listView.count === 0
        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: section.errorText.length > 0 ? "Search failed" : "Search Qobuz"
            color: FiatPonsTheme.accent
            font.pixelSize: Theme.fontSizeLarge
            font.family: FiatPonsTheme.serif
        }
        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            text: section.errorText.length > 0 ? section.errorText
                                               : "Find an album, track, or artist"
            color: FiatPonsTheme.secondaryText
            font.pixelSize: Theme.fontSizeSmall
        }
    }
}
