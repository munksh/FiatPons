import QtQuick 2.0
import Sailfish.Silica 1.0
import se.munkstolen.fiatpons 1.0
import "../components"
import ".."

Page {
    id: page

    property string pageTitle: "Discover"
    property string endpoint: ""
    property string genreName: ""
    property string genreIdStr: ""
    property int genreId: genreIdStr.length > 0 ? parseInt(genreIdStr) : 0

    property int limit: 24
    property int offset: 0
    property bool busy: false
    property bool hasMore: false
    property string errorText: ""

    property real cardWidth: Math.floor((width - Theme.horizontalPageMargin * 3) / 2)

    function paint() {
        FiatPonsTheme.applyPalette(page)
    }

    function resetAndLoad() {
        offset = 0
        albumsModel.clear()
        loadMore()
    }

    function loadMore() {
        if (busy || endpoint.length === 0)
            return

        busy = true
        errorText = ""

        backend.discoverAlbums(
            endpoint,
            genreId,
            offset,
            limit
        )
    }

    Component.onCompleted: {
        paint()
        resetAndLoad()
    }

    Connections {
        target: FiatPonsTheme
        onAmbientChanged: page.paint()
    }

    ListModel {
        id: albumsModel
    }

    Backend {
        id: backend
    }

    Connections {
        target: backend

        onDiscoverAlbumsComplete: {
            page.busy = false

            var data

            try {
                data = JSON.parse(json)
            } catch (error) {
                page.errorText = "Could not read Discover response"
                return
            }

            if (data.error) {
                page.errorText = data.error
                return
            }

            var items = data.albums || []

            for (var i = 0; i < items.length; i++) {
                var album = items[i]
                album.id = String(album.id)
                albumsModel.append(album)
            }

            page.offset = albumsModel.count
            page.hasMore = data.has_more === true
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

    SilicaGridView {
        id: grid

        anchors.fill: parent
        clip: true
        model: albumsModel

        cellWidth: width / 2
        cellHeight: page.cardWidth + Theme.paddingLarge * 2.2 + Theme.fontSizeSmall * 2

        PullDownMenu {
            backgroundColor: FiatPonsTheme.surface
            highlightColor: FiatPonsTheme.accent

            MenuItem {
                text: "Refresh"
                color: FiatPonsTheme.primaryText
                onClicked: page.resetAndLoad()
            }
        }

        header: Column {
            width: grid.width
            spacing: Theme.paddingSmall

            PageHeader {
                title: page.pageTitle
            }

            Label {
                width: parent.width - Theme.horizontalPageMargin * 2
                anchors.horizontalCenter: parent.horizontalCenter
                visible: page.genreName.length > 0
                text: page.genreName
                color: FiatPonsTheme.secondaryText
                font.pixelSize: Theme.fontSizeSmall
                horizontalAlignment: Text.AlignHCenter
            }

            Item { width: 1; height: Theme.paddingMedium }
        }

        delegate: Item {
            id: albumCell

            width: grid.cellWidth
            height: grid.cellHeight

            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: Theme.paddingSmall

                width: page.cardWidth
                height: page.cardWidth + titleLabel.height + artistLabel.height + Theme.paddingSmall * 2

                Rectangle {
                    id: cover

                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter

                    width: page.cardWidth
                    height: width

                    radius: FiatPonsTheme.cardRadius
                    color: FiatPonsTheme.recessFill
                    border.color: albumMouse.pressed ? FiatPonsTheme.accent : FiatPonsTheme.recessBorder
                    border.width: albumMouse.pressed ? 2 : 1
                    clip: true

                    Image {
                        anchors.fill: parent
                        anchors.margins: 2
                        source: model.cover_url === undefined ? "" : model.cover_url
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                    }

                    Label {
                        anchors.centerIn: parent
                        text: "\u266B"
                        color: FiatPonsTheme.secondaryText
                        font.pixelSize: Theme.fontSizeHuge
                        font.family: FiatPonsTheme.serif
                        visible: model.cover_url === undefined || model.cover_url.length === 0
                    }
                }

                Label {
                    id: titleLabel

                    anchors.top: cover.bottom
                    anchors.topMargin: Theme.paddingSmall
                    anchors.left: parent.left
                    anchors.right: parent.right

                    text: model.title === undefined ? "" : model.title
                    color: albumMouse.pressed ? FiatPonsTheme.accent : FiatPonsTheme.primaryText
                    font.pixelSize: Theme.fontSizeSmall
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    truncationMode: TruncationMode.Fade
                }

                Label {
                    id: artistLabel

                    anchors.top: titleLabel.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right

                    text: {
                        var artist = model.artist === undefined ? "" : model.artist
                        var year = model.year === undefined ? "" : model.year
                        return year.length > 0 ? artist + " \u00B7 " + year : artist
                    }

                    color: FiatPonsTheme.secondaryText
                    font.pixelSize: Theme.fontSizeExtraSmall
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    maximumLineCount: 1
                    truncationMode: TruncationMode.Fade
                    visible: text.length > 0
                }

                MouseArea {
                    id: albumMouse
                    anchors.fill: parent
                    onClicked: pageStack.push(Qt.resolvedUrl("AlbumPage.qml"), {
                        albumId: String(model.id),
                        initialCover: model.cover_url === undefined ? "" : model.cover_url
                    })
                }

                scale: albumMouse.pressed ? 0.96 : 1.0
                opacity: albumMouse.pressed ? 0.75 : 1.0

                Behavior on scale {
                    NumberAnimation {
                        duration: 90
                        easing.type: Easing.OutQuad
                    }
                }

                Behavior on opacity {
                    NumberAnimation { duration: 90 }
                }
            }
        }

        footer: Item {
            width: grid.width
            height: Theme.itemSizeLarge

            BackgroundItem {
                anchors.centerIn: parent
                width: parent.width
                height: Theme.itemSizeMedium
                visible: page.hasMore && !page.busy
                onClicked: page.loadMore()

                Label {
                    anchors.centerIn: parent
                    text: "Show more\u2026"
                    color: highlighted ? FiatPonsTheme.accent : FiatPonsTheme.primaryText
                    font.pixelSize: Theme.fontSizeSmall
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            BusyIndicator {
                anchors.centerIn: parent
                running: page.busy
                visible: running
                size: BusyIndicatorSize.Medium
            }
        }

        VerticalScrollDecorator {}
    }

    Column {
        anchors.centerIn: parent
        width: parent.width - Theme.horizontalPageMargin * 4
        spacing: Theme.paddingSmall

        visible: !page.busy
                 && albumsModel.count === 0

        Label {
            width: parent.width
            text: page.errorText.length > 0 ? "Couldn't load" : "Nothing here"
            color: FiatPonsTheme.accent
            font.pixelSize: Theme.fontSizeLarge
            font.family: FiatPonsTheme.serif
            horizontalAlignment: Text.AlignHCenter
        }

        Label {
            width: parent.width
            text: page.errorText.length > 0 ? page.errorText : "Pull down to refresh"
            color: FiatPonsTheme.secondaryText
            font.pixelSize: Theme.fontSizeSmall
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
        }
    }
}
