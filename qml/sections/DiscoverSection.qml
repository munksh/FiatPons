import QtQuick 2.0
import Sailfish.Silica 1.0
import se.munkstolen.fiatpons 1.0
import "../components"
import ".."

Item {
    id: section
    clip: true

    property string mode: "featured"
    property bool busy: false
    property string errorText: ""

    property real cardWidth: Math.floor((width - Theme.horizontalPageMargin * 3) / 2)

    function paint() {
        FiatPonsTheme.applyPalette(section)
    }

    function selectMode(nextMode) {
        if (mode === nextMode)
            return

        mode = nextMode

        if (mode === "featured")
            loadFeatured()
        else if (mode === "new")
            loadNew()
        else
            loadGenres()
    }

    function loadFeatured() {
        busy = true
        errorText = ""
        featuredModel.clear()
        backend.discoverFeatured()
    }

    function loadNew() {
        busy = true
        errorText = ""
        newAlbumsModel.clear()
        backend.discoverAlbums("/discover/newReleases", 0, 0, 24)
    }

    function loadGenres() {
        busy = true
        errorText = ""
        genresModel.clear()
        backend.discoverGenres()
    }

    function refresh() {
        if (mode === "featured")
            loadFeatured()
        else if (mode === "new")
            loadNew()
        else
            loadGenres()
    }

    function openSection(title, endpoint) {
        pageStack.push(Qt.resolvedUrl("../pages/DiscoverListPage.qml"), {
            pageTitle: title,
            endpoint: endpoint,
            genreName: "",
            genreIdStr: ""
        })
    }

    function openGenre(id, name) {
        pageStack.push(Qt.resolvedUrl("../pages/DiscoverListPage.qml"), {
            pageTitle: "Discover",
            endpoint: "/discover/newReleases",
            genreName: name,
            genreIdStr: String(id)
        })
    }

    Component.onCompleted: {
        paint()
        loadFeatured()
    }

    Connections {
        target: FiatPonsTheme
        onAmbientChanged: section.paint()
    }

    ListModel { id: featuredModel }
    ListModel { id: newAlbumsModel }
    ListModel { id: genresModel }

    Backend {
        id: backend
    }

    Connections {
        target: backend

        onDiscoverFeaturedComplete: {
            section.busy = false
            featuredModel.clear()

            var data

            try {
                data = JSON.parse(json)
            } catch (error) {
                section.errorText = "Could not read Discover response"
                return
            }

            if (data.error) {
                section.errorText = data.error
                return
            }

            var sections = data.sections || []

            for (var i = 0; i < sections.length; i++) {
                var item = sections[i]
                item.albums_json = JSON.stringify(item.albums || [])
                featuredModel.append(item)
            }
        }

        onDiscoverAlbumsComplete: {
            section.busy = false

            if (section.mode !== "new")
                return

            newAlbumsModel.clear()

            var data

            try {
                data = JSON.parse(json)
            } catch (error) {
                section.errorText = "Could not read Discover response"
                return
            }

            if (data.error) {
                section.errorText = data.error
                return
            }

            var albums = data.albums || []

            for (var i = 0; i < albums.length; i++) {
                var album = albums[i]
                album.id = String(album.id)
                newAlbumsModel.append(album)
            }
        }

        onDiscoverGenresComplete: {
            section.busy = false
            genresModel.clear()

            var data

            try {
                data = JSON.parse(json)
            } catch (error) {
                section.errorText = "Could not read genres"
                return
            }

            if (data.error) {
                section.errorText = data.error
                return
            }

            var genres = data.genres || []

            for (var i = 0; i < genres.length; i++)
                genresModel.append(genres[i])
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

    Column {
        id: discoverHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        Item {
            width: parent.width
            height: Theme.itemSizeMedium

            Label {
                anchors.centerIn: parent
                text: "Discover"
                color: FiatPonsTheme.primaryText
                font.pixelSize: Theme.fontSizeLarge
                font.family: FiatPonsTheme.serif
            }
        }

        Item {
            width: parent.width
            height: Theme.itemSizeExtraSmall

            Row {
                anchors.fill: parent
                anchors.leftMargin: Theme.horizontalPageMargin
                anchors.rightMargin: Theme.horizontalPageMargin

                Repeater {
                    model: [
                        { key: "featured", label: "Featured" },
                        { key: "new", label: "New" },
                        { key: "genres", label: "Genres" }
                    ]

                    delegate: Item {
                        id: tab

                        property bool selected: section.mode === modelData.key

                        width: parent.width / 3
                        height: parent.height

                        Label {
                            anchors.centerIn: parent
                            text: modelData.label
                            color: tab.selected ? FiatPonsTheme.accent : FiatPonsTheme.secondaryText
                            font.pixelSize: Theme.fontSizeSmall
                            font.family: FiatPonsTheme.serif
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width * 0.55
                            height: 1
                            radius: 1
                            color: FiatPonsTheme.accent
                            opacity: tab.selected ? 1.0 : 0.0
                        }

                        MouseArea {
                            id: tabMouse
                            anchors.fill: parent
                            onClicked: section.selectMode(modelData.key)
                        }

                        scale: tabMouse.pressed ? 0.96 : 1.0
                        opacity: tabMouse.pressed ? 0.68 : 1.0

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
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: FiatPonsTheme.innerBorder
        }
    }

    Item {
        anchors.top: discoverHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        SilicaListView {
            id: featuredList
            anchors.fill: parent
            visible: section.mode === "featured"
            model: featuredModel
            clip: true

            PullDownMenu {
                backgroundColor: FiatPonsTheme.surface
                highlightColor: FiatPonsTheme.accent

                MenuItem {
                    text: "Refresh"
                    color: FiatPonsTheme.primaryText
                    onClicked: section.loadFeatured()
                }
            }

            delegate: Column {
                width: featuredList.width
                spacing: Theme.paddingSmall

                property var albums: JSON.parse(model.albums_json || "[]")

                BackgroundItem {
                    width: parent.width
                    height: Theme.itemSizeSmall
                    onClicked: section.openSection(model.title, model.endpoint)

                    Label {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.horizontalPageMargin
                        anchors.verticalCenter: parent.verticalCenter
                        text: model.title
                        color: highlighted ? FiatPonsTheme.accent : FiatPonsTheme.primaryText
                        font.pixelSize: Theme.fontSizeMedium
                        font.family: FiatPonsTheme.serif
                    }

                    Label {
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.horizontalPageMargin
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Show more\u2026"
                        color: highlighted ? FiatPonsTheme.accent : FiatPonsTheme.secondaryText
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                }

                Row {
                    width: parent.width
                    spacing: Theme.horizontalPageMargin
                    anchors.horizontalCenter: parent.horizontalCenter

                    Repeater {
                        model: albums.length > 2 ? 2 : albums.length

                        delegate: AlbumPreview {
                            album: albums[index]
                            cardWidth: section.cardWidth
                        }
                    }
                }

                Item {
                    width: 1
                    height: Theme.paddingMedium
                }
            }

            VerticalScrollDecorator {}
        }

        SilicaGridView {
            id: newGrid
            anchors.fill: parent
            visible: section.mode === "new"
            model: newAlbumsModel
            clip: true

            cellWidth: width / 2
            cellHeight: section.cardWidth + Theme.paddingLarge * 2.2 + Theme.fontSizeSmall * 2
            topMargin: Theme.itemSizeSmall

            PullDownMenu {
                backgroundColor: FiatPonsTheme.surface
                highlightColor: FiatPonsTheme.accent

                MenuItem {
                    text: "Refresh"
                    color: FiatPonsTheme.primaryText
                    onClicked: section.loadNew()
                }
            }

            delegate: AlbumPreview {
                cardWidth: section.cardWidth
                album: {
                    return {
                        id: model.id,
                        title: model.title,
                        artist: model.artist,
                        year: model.year,
                        cover_url: model.cover_url
                    }
                }
            }

            VerticalScrollDecorator {}
        }

        SilicaListView {
            id: genresList
            anchors.fill: parent
            visible: section.mode === "genres"
            model: genresModel
            clip: true

            PullDownMenu {
                backgroundColor: FiatPonsTheme.surface
                highlightColor: FiatPonsTheme.accent

                MenuItem {
                    text: "Refresh"
                    color: FiatPonsTheme.primaryText
                    onClicked: section.loadGenres()
                }
            }

            delegate: ListItem {
                width: genresList.width
                contentHeight: Theme.itemSizeMedium

                onClicked: section.openGenre(model.id, model.name)

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 1
                    color: FiatPonsTheme.innerBorder
                }

                Label {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: Theme.horizontalPageMargin
                    anchors.rightMargin: Theme.horizontalPageMargin
                    anchors.verticalCenter: parent.verticalCenter

                    text: model.name
                    color: highlighted ? FiatPonsTheme.accent : FiatPonsTheme.primaryText
                    font.pixelSize: Theme.fontSizeMedium
                    truncationMode: TruncationMode.Fade
                }
            }

            VerticalScrollDecorator {}
        }

        BusyIndicator {
            anchors.centerIn: parent
            size: BusyIndicatorSize.Large
            running: section.busy
            visible: running
        }

        Column {
            anchors.centerIn: parent
            width: parent.width - Theme.horizontalPageMargin * 4
            spacing: Theme.paddingSmall

            visible: !section.busy
                     && section.errorText.length > 0

            Label {
                width: parent.width
                text: "Couldn't load"
                color: FiatPonsTheme.accent
                font.pixelSize: Theme.fontSizeLarge
                font.family: FiatPonsTheme.serif
                horizontalAlignment: Text.AlignHCenter
            }

            Label {
                width: parent.width
                text: section.errorText
                color: FiatPonsTheme.secondaryText
                font.pixelSize: Theme.fontSizeSmall
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
            }
        }
    }


}
