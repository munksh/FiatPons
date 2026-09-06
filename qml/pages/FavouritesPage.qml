import QtQuick 2.0
import Sailfish.Silica 1.0
import se.munkstolen.fiatpons 1.0
import "../components"
import ".."

Page {
    id: page

    property string mode: "tracks"
    property bool busy: true
    property string errorText: ""

    function paint() {
        FiatPonsTheme.applyPalette(page)
    }

    function load() {
        busy = true
        errorText = ""
        favModel.clear()
        backend.favourites(mode)
    }

    function selectMode(nextMode) {
        if (mode === nextMode && !busy)
            return

        mode = nextMode
        load()
    }

    function rowToTrack(m) {
        return {
            id: m.id,
            title: m.title,
            artist: m.artist,
            album: m.album,
            cover_url: m.cover_url === undefined ? "" : m.cover_url
        }
    }

    Component.onCompleted: {
        paint()
        load()
    }

    Connections {
        target: FiatPonsTheme
        onAmbientChanged: page.paint()
    }

    Backend {
        id: backend
    }

    Connections {
        target: backend

        onFavouritesComplete: {
            page.busy = false

            var data
            try {
                data = JSON.parse(json)
            } catch (e) {
                page.errorText = "Could not read response"
                return
            }

            if (data.error) {
                page.errorText = data.error
                return
            }

            var items = []
            if (page.mode === "tracks")
                items = data.tracks || []
            else if (page.mode === "albums")
                items = data.albums || []
            else
                items = data.artists || []

            for (var i = 0; i < items.length; i++) {
                var item = items[i]
                item.id = String(item.id)
                favModel.append(item)
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
        clip: true
        model: ListModel {
            id: favModel
        }

        PullDownMenu {
            backgroundColor: FiatPonsTheme.surface
            highlightColor: FiatPonsTheme.accent

            MenuItem {
                text: "Refresh"
                color: FiatPonsTheme.primaryText
                onClicked: page.load()
            }
        }

        header: Column {
            width: listView.width
            spacing: Theme.paddingSmall

            PageHeader {
                title: "Favourites"
            }

            Item {
                width: parent.width
                height: pillRow.height + Theme.paddingSmall

                Row {
                    id: pillRow
                    anchors.centerIn: parent
                    spacing: Theme.paddingSmall

                    Repeater {
                        model: [
                            { key: "tracks", label: "Tracks" },
                            { key: "albums", label: "Albums" },
                            { key: "artists", label: "Artists" }
                        ]

                        delegate: Rectangle {
                            property bool active: page.mode === modelData.key

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
                                onClicked: page.selectMode(modelData.key)
                            }
                        }
                    }
                }
            }
        }

        delegate: ListItem {
            id: delegateItem
            width: listView.width
            contentHeight: Theme.itemSizeMedium

            function trackObj() {
                return page.rowToTrack(model)
            }

            onClicked: {
                if (page.mode === "tracks") {
                    app.queue.playNow(trackObj())
                } else if (page.mode === "albums") {
                    pageStack.push(Qt.resolvedUrl("AlbumPage.qml"), {
                        albumId: model.id,
                        initialCover: model.cover_url === undefined ? "" : model.cover_url
                    })
                } else if (page.mode === "artists") {
                    pageStack.push(Qt.resolvedUrl("ArtistPage.qml"), {
                        artistIdStr: model.id
                    })
                }
            }

            menu: page.mode === "tracks" ? tracksMenu : null

            Component {
                id: tracksMenu

                ContextMenu {
                    MenuItem {
                        text: "Play now"
                        onClicked: app.queue.playNow(delegateItem.trackObj())
                    }

                    MenuItem {
                        text: "Add to queue"
                        onClicked: app.queue.enqueue(delegateItem.trackObj())
                    }

                    MenuItem {
                        text: "Play next"
                        onClicked: app.queue.playNext(delegateItem.trackObj())
                    }
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
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
                    radius: page.mode === "artists" ? width / 2 : Theme.paddingSmall / 2
                    color: FiatPonsTheme.recessFill
                    border.color: FiatPonsTheme.recessBorder
                    border.width: 1
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: page.mode === "artists"
                                ? ((model.image_url === undefined) ? "" : model.image_url)
                                : ((model.cover_url === undefined) ? "" : model.cover_url)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                    }

                    Label {
                        anchors.centerIn: parent
                        text: page.mode === "artists" ? "\u263A" : "\u266A"
                        color: FiatPonsTheme.secondaryText
                        font.pixelSize: Theme.fontSizeLarge
                        visible: page.mode === "artists"
                                 ? (model.image_url === undefined || model.image_url.length === 0)
                                 : (model.cover_url === undefined || model.cover_url.length === 0)
                    }
                }

                Column {
                    width: parent.width - tile.width - Theme.paddingMedium
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.paddingSmall / 2

                    Label {
                        width: parent.width
                        text: page.mode === "artists"
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
                            if (page.mode === "tracks")
                                return (model.artist === undefined ? "" : model.artist) + " \u2014 " + (model.album === undefined ? "" : model.album)

                            if (page.mode === "albums") {
                                var y = model.year === undefined || model.year.length === 0 ? "" : " \u00B7 " + model.year
                                return (model.artist === undefined ? "" : model.artist) + y
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
        running: page.busy
    }

    Column {
        anchors.centerIn: parent
        width: parent.width - Theme.horizontalPageMargin * 4
        spacing: Theme.paddingSmall
        visible: !page.busy && favModel.count === 0

        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: page.errorText.length > 0 ? "Couldn't load" : "No favourites yet"
            color: FiatPonsTheme.accent
            font.pixelSize: Theme.fontSizeLarge
            font.family: FiatPonsTheme.serif
        }

        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            text: page.errorText.length > 0 ? page.errorText : "Tap the heart on a track, album or artist to save it here"
            color: FiatPonsTheme.secondaryText
            font.pixelSize: Theme.fontSizeSmall
        }
    }
}
