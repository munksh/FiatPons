import QtQuick 2.0
import Sailfish.Silica 1.0
import se.munkstolen.fiatpons 1.0
import "../components"
import ".."

// The user's playlists. Backend wiring is optional: the call and its signal
// are guarded (ignoreUnknownSignals + a function-exists check), so this page
// renders cleanly whether or not the backend verb exists yet, and lights up
// automatically once backend.userPlaylists()/userPlaylistsComplete are added.
Page {
    id: page
    property bool busy: true
    property bool wired: false
    property string errorText: ""

    function paint() { FiatPonsTheme.applyPalette(page) }
    Component.onCompleted: {
        paint()
        if (backend.userPlaylists) { wired = true; backend.userPlaylists() }
        else busy = false
    }
    Connections { target: FiatPonsTheme; onAmbientChanged: page.paint() }

    Backend { id: backend }
    Connections {
        target: backend
        ignoreUnknownSignals: true
        onUserPlaylistsComplete: {
            page.busy = false
            var data
            try { data = JSON.parse(json) } catch (e) { page.errorText = "Could not read response"; return }
            if (data.error) { page.errorText = data.error; return }
            var items = data.playlists || []
            for (var i = 0; i < items.length; i++) {
                var p = items[i]; p.id = String(p.id)
                playlistsModel.append(p)
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
        model: ListModel { id: playlistsModel }
        header: PageHeader { title: "Playlists" }

        delegate: ListItem {
            id: delegateItem
            width: listView.width
            contentHeight: Theme.itemSizeMedium
            onClicked: pageStack.push(Qt.resolvedUrl("PlaylistPage.qml"),
                { playlistIdStr: model.id, initialName: model.name === undefined ? "" : model.name,
                  initialCover: (model.image_url === undefined) ? "" : model.image_url })

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
                    radius: Theme.paddingSmall / 2
                    color: FiatPonsTheme.recessFill
                    border.color: FiatPonsTheme.recessBorder
                    border.width: 1
                    clip: true
                    Image {
                        anchors.fill: parent
                        source: (model.image_url === undefined) ? "" : model.image_url
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                    }
                    Label {
                        anchors.centerIn: parent
                        text: "\u266B"
                        color: FiatPonsTheme.secondaryText
                        font.pixelSize: Theme.fontSizeLarge
                        visible: (model.image_url === undefined || model.image_url.length === 0)
                    }
                }
                Column {
                    width: parent.width - tile.width - Theme.paddingMedium
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.paddingSmall / 2
                    Label {
                        width: parent.width
                        text: model.name === undefined ? "" : model.name
                        color: delegateItem.highlighted ? FiatPonsTheme.accent : FiatPonsTheme.primaryText
                        font.pixelSize: Theme.fontSizeMedium
                        truncationMode: TruncationMode.Fade
                    }
                    Label {
                        width: parent.width
                        visible: (model.track_count !== undefined && model.track_count > 0)
                        text: (model.track_count === undefined ? 0 : model.track_count) + " tracks"
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
    }

    Column {
        anchors.centerIn: parent
        width: parent.width - Theme.horizontalPageMargin * 4
        spacing: Theme.paddingSmall
        visible: !page.busy && playlistsModel.count === 0
        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: page.errorText.length > 0 ? "Couldn't load"
                 : (page.wired ? "No playlists yet" : "Playlists")
            color: FiatPonsTheme.accent
            font.pixelSize: Theme.fontSizeLarge
            font.family: FiatPonsTheme.serif
        }
        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            text: page.errorText.length > 0 ? page.errorText
                 : (page.wired ? "Your saved playlists will appear here"
                              : "Playlist data will appear once the backend is wired")
            color: FiatPonsTheme.secondaryText
            font.pixelSize: Theme.fontSizeSmall
        }
    }
}
