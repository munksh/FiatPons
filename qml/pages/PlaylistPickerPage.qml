import QtQuick 2.0
import Sailfish.Silica 1.0
import se.munkstolen.fiatpons 1.0
import ".."

Page {
    id: page

    property string trackIdStr: ""
    property bool busy: true
    property string errorText: ""

    function trackId() {
        var value = parseInt(trackIdStr)
        return isNaN(value) ? 0 : value
    }

    function load() {
        busy = true
        errorText = ""
        playlistModel.clear()
        backend.userPlaylists()
    }

    function addToPlaylist(playlistId) {
        var id = trackId()

        if (id <= 0) {
            errorText = "No track selected"
            return
        }

        busy = true
        errorText = ""
        backend.addTrackToPlaylist(
            parseInt(playlistId),
            id
        )
    }

    Component.onCompleted: load()

    ListModel {
        id: playlistModel
    }

    Backend {
        id: backend
    }

    Connections {
        target: backend

        onUserPlaylistsComplete: {
            page.busy = false

            var data

            try {
                data = JSON.parse(json)
            } catch (error) {
                page.errorText = "Could not read playlists"
                return
            }

            if (data.error) {
                page.errorText = data.error
                return
            }

            var items = data.playlists || []

            for (var i = 0; i < items.length; i++) {
                var item = items[i]
                item.id = String(item.id)
                playlistModel.append(item)
            }
        }

        onAddTrackToPlaylistComplete: {
            page.busy = false

            var data

            try {
                data = JSON.parse(json)
            } catch (error) {
                page.errorText = "Could not read the response"
                return
            }

            if (data.error) {
                page.errorText = data.error
                return
            }

            pageStack.pop()
        }
    }

    SilicaListView {
        anchors.fill: parent
        model: playlistModel

        PullDownMenu {
            MenuItem {
                text: "New playlist"
                onClicked: pageStack.push(
                    Qt.resolvedUrl("NewPlaylistDialog.qml"),
                    { trackIdStr: page.trackIdStr }
                )
            }

            MenuItem {
                text: "Refresh"
                onClicked: page.load()
            }
        }

        header: PageHeader {
            title: "Add to playlist"
        }

        delegate: ListItem {
            width: parent.width
            contentHeight: Theme.itemSizeMedium
            enabled: !page.busy

            onClicked: page.addToPlaylist(model.id)

            Row {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.horizontalPageMargin
                anchors.rightMargin: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.paddingMedium

                Rectangle {
                    width: Theme.itemSizeSmall
                    height: width
                    radius: FiatPonsTheme.cardRadius
                    color: FiatPonsTheme.recessFill
                    border.color: FiatPonsTheme.recessBorder
                    border.width: 1
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: model.image_url === undefined
                                ? ""
                                : model.image_url
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                    }

                    Label {
                        anchors.centerIn: parent
                        text: "\u266B"
                        color: FiatPonsTheme.secondaryText
                        visible: model.image_url === undefined
                                 || model.image_url.length === 0
                    }
                }

                Column {
                    width: parent.width - Theme.itemSizeSmall - Theme.paddingMedium
                    anchors.verticalCenter: parent.verticalCenter

                    Label {
                        width: parent.width
                        text: model.name === undefined ? "" : model.name
                        color: highlighted
                               ? FiatPonsTheme.accent
                               : FiatPonsTheme.primaryText
                        font.pixelSize: Theme.fontSizeMedium
                        font.family: FiatPonsTheme.serif
                        truncationMode: TruncationMode.Fade
                    }

                    Label {
                        width: parent.width
                        text: {
                            var count = model.track_count === undefined
                                        ? 0
                                        : model.track_count
                            return count === 1
                                   ? "1 track"
                                   : count + " tracks"
                        }
                        color: FiatPonsTheme.secondaryText
                        font.pixelSize: Theme.fontSizeExtraSmall
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
        visible: running
    }

    Label {
        anchors.centerIn: parent
        width: parent.width - Theme.horizontalPageMargin * 4

        visible: !page.busy
                 && (
                     page.errorText.length > 0
                     || playlistModel.count === 0
                 )

        text: page.errorText.length > 0
              ? page.errorText
              : "No playlists yet"
        color: page.errorText.length > 0
               ? Theme.errorColor
               : FiatPonsTheme.secondaryText
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
    }
}
