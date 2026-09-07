import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0
import se.munkstolen.fiatpons 1.0
import "../components"
import ".."

Page {
    id: page

    property string playlistIdStr: ""
    property var playlistId:
        playlistIdStr.length > 0
        ? parseInt(playlistIdStr)
        : 0

    property string initialName: ""
    property string initialCover: ""

    property string name: initialName
    property string coverUrl: initialCover
    property int trackCount: 0
    property bool isPublic: false

    property bool busy: true
    property bool wired: false
    property bool editMode: false
    property bool savingOrder: false
    property bool changingPublic: false

    property string errorText: ""
    property string statusText: ""
    property var originalOrder: []

    function paint() {
        FiatPonsTheme.applyPalette(page)
    }

    function loadPlaylist() {
        if (playlistId <= 0) {
            busy = false
            return
        }

        busy = true
        errorText = ""
        statusText = ""
        tracksModel.clear()
        backend.playlist(playlistId)
    }

    Component.onCompleted: {
        paint()
        wired = playlistId > 0
        loadPlaylist()
    }

    Connections {
        target: FiatPonsTheme
        onAmbientChanged: page.paint()
    }

    function rowToTrack(m) {
        return {
            id: m.id,
            title: m.title,
            artist: m.artist,
            album: m.album,
            cover_url: m.cover_url
        }
    }

    function copyRow(m) {
        return {
            id: m.id,
            playlist_track_id:
                m.playlist_track_id === undefined
                ? 0
                : m.playlist_track_id,
            title: m.title === undefined ? "" : m.title,
            artist: m.artist === undefined ? "" : m.artist,
            album: m.album === undefined ? "" : m.album,
            cover_url:
                m.cover_url === undefined
                ? ""
                : m.cover_url
        }
    }

    function playAll() {
        if (tracksModel.count === 0)
            return

        app.queue.playNow(
            rowToTrack(tracksModel.get(0))
        )

        for (var i = 1; i < tracksModel.count; i++)
            app.queue.enqueue(
                rowToTrack(tracksModel.get(i))
            )
    }

    function beginEdit() {
        originalOrder = []

        for (var i = 0; i < tracksModel.count; i++)
            originalOrder.push(copyRow(tracksModel.get(i)))

        editMode = true
        statusText = "Drag the handles to reorder"
    }

    function discardOrder() {
        tracksModel.clear()

        for (var i = 0; i < originalOrder.length; i++)
            tracksModel.append(originalOrder[i])

        originalOrder = []
        editMode = false
        statusText = ""
    }

    function orderedTrackIds() {
        var ids = []

        for (var i = 0; i < tracksModel.count; i++)
            ids.push(String(tracksModel.get(i).id))

        return ids.join(",")
    }

    function requestSaveOrder() {
        pageStack.push(saveOrderDialog)
    }

    function commitOrder() {
        if (savingOrder || playlistId <= 0)
            return

        savingOrder = true
        statusText = "Saving order…"

        backend.savePlaylistOrder(
            playlistId,
            orderedTrackIds()
        )
    }

    function togglePublic() {
        if (changingPublic || playlistId <= 0)
            return

        changingPublic = true
        statusText = isPublic
                     ? "Making playlist private…"
                     : "Making playlist public…"

        backend.setPlaylistPublic(
            playlistId,
            !isPublic
        )
    }

    function requestRemove(rowItem) {
        var playlistTrackId =
            rowItem.playlist_track_id === undefined
            ? 0
            : parseInt(rowItem.playlist_track_id)

        if (!playlistTrackId) {
            errorText = "This track cannot be removed"
            return
        }

        remorse.execute(
            "Removing track",
            function() {
                page.busy = true
                backend.removePlaylistTrack(
                    playlistId,
                    playlistTrackId
                )
            }
        )
    }

    Backend {
        id: backend
    }

    Connections {
        target: backend

        onPlaylistComplete: {
            page.busy = false
            tracksModel.clear()

            var data

            try {
                data = JSON.parse(json)
            } catch (error) {
                page.errorText = "Could not read response"
                return
            }

            if (data.error) {
                page.errorText = data.error
                return
            }

            var playlist = data.playlist || {}

            if ((playlist.name || "").length > 0)
                page.name = playlist.name

            if ((playlist.image_url || "").length > 0)
                page.coverUrl = playlist.image_url

            page.trackCount = playlist.track_count || 0
            page.isPublic = playlist.is_public === true

            var items = data.tracks || []

            for (var i = 0; i < items.length; i++) {
                var track = items[i]
                track.id = String(track.id)
                track.playlist_track_id =
                    track.playlist_track_id || 0
                tracksModel.append(track)
            }
        }

        onRemovePlaylistTrackComplete: {
            page.busy = false

            var data

            try {
                data = JSON.parse(json)
            } catch (error) {
                page.errorText = "Could not read response"
                return
            }

            if (data.error) {
                page.errorText = data.error
                return
            }

            page.statusText = "Track removed"
            page.loadPlaylist()
        }

        onSetPlaylistPublicComplete: {
            page.changingPublic = false

            var data

            try {
                data = JSON.parse(json)
            } catch (error) {
                page.errorText = "Could not read response"
                return
            }

            if (data.error) {
                page.errorText = data.error
                return
            }

            var playlist = data.playlist || {}
            page.isPublic = playlist.is_public === true
            page.statusText = page.isPublic
                              ? "Playlist is public"
                              : "Playlist is private"
        }

        onSavePlaylistOrderComplete: {
            page.savingOrder = false

            var data

            try {
                data = JSON.parse(json)
            } catch (error) {
                page.errorText = "Could not read response"
                return
            }

            if (data.error) {
                page.errorText = data.error
                page.statusText = ""
                return
            }

            page.editMode = false
            page.originalOrder = []
            page.statusText = "Order saved"
            page.loadPlaylist()
        }
    }

    Component {
        id: saveOrderDialog

        Dialog {
            canAccept: !page.savingOrder

            onAccepted:
                page.commitOrder()

            Column {
                width: parent.width

                DialogHeader {
                    acceptText: "Save"
                    cancelText: "Cancel"
                }

                Label {
                    width: parent.width
                           - Theme.horizontalPageMargin * 2
                    anchors.horizontalCenter: parent.horizontalCenter

                    text: "Save this order to Qobuz?"
                    color: FiatPonsTheme.primaryText
                    font.pixelSize: Theme.fontSizeLarge
                    font.family: FiatPonsTheme.serif
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                }

                Label {
                    width: parent.width
                           - Theme.horizontalPageMargin * 2
                    anchors.horizontalCenter: parent.horizontalCenter

                    text: "The playlist will be rebuilt. "
                          + "If saving fails, FiatPons will "
                          + "attempt to restore the original order."

                    color: FiatPonsTheme.secondaryText
                    font.pixelSize: Theme.fontSizeSmall
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                }
            }
        }
    }

    RemorsePopup {
        id: remorse
    }

    Rectangle {
        anchors.fill: parent
        visible: !FiatPonsTheme.ambient

        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: FiatPonsTheme.backgroundHigh
            }

            GradientStop {
                position: 1.0
                color: FiatPonsTheme.backgroundLow
            }
        }
    }

    SilicaListView {
        id: listView

        anchors.fill: parent
        model: ListModel { id: tracksModel }
        clip: true

        PullDownMenu {
            backgroundColor: FiatPonsTheme.surface
            highlightColor: FiatPonsTheme.accent

            MenuItem {
                text: page.editMode
                      ? "Save order to Qobuz"
                      : "Edit order"
                color: FiatPonsTheme.primaryText
                enabled: tracksModel.count > 1
                         && !page.savingOrder

                onClicked: {
                    if (page.editMode)
                        page.requestSaveOrder()
                    else
                        page.beginEdit()
                }
            }

            MenuItem {
                visible: page.editMode
                text: "Discard changes"
                color: FiatPonsTheme.primaryText
                onClicked: page.discardOrder()
            }

            MenuItem {
                visible: !page.editMode
                text: page.isPublic
                      ? "Make private"
                      : "Make public"
                color: FiatPonsTheme.primaryText
                enabled: !page.changingPublic
                onClicked: page.togglePublic()
            }

            MenuItem {
                visible: !page.editMode
                text: "Refresh"
                color: FiatPonsTheme.primaryText
                onClicked: page.loadPlaylist()
            }
        }

        header: Column {
            width: listView.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: page.editMode
                       ? "Reorder playlist"
                       : "Playlist"
            }

            Item {
                width: parent.width
                       - Theme.horizontalPageMargin * 2
                height: width
                anchors.horizontalCenter: parent.horizontalCenter

                Rectangle {
                    id: mask
                    anchors.fill: parent
                    radius: FiatPonsTheme.cardRadius
                    visible: false
                }

                Rectangle {
                    anchors.fill: parent
                    radius: FiatPonsTheme.cardRadius
                    color: FiatPonsTheme.recessFill
                }

                Image {
                    id: art

                    anchors.fill: parent
                    source: page.coverUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    visible: false
                }

                OpacityMask {
                    anchors.fill: parent
                    source: art
                    maskSource: mask
                    visible: page.coverUrl.length > 0
                }

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

            Label {
                width: parent.width
                       - Theme.horizontalPageMargin * 2
                anchors.horizontalCenter: parent.horizontalCenter

                text: page.name
                color: FiatPonsTheme.primaryText
                font.pixelSize: Theme.fontSizeLarge
                font.family: FiatPonsTheme.serif
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
            }

            Label {
                width: parent.width
                       - Theme.horizontalPageMargin * 2
                anchors.horizontalCenter: parent.horizontalCenter

                text: page.isPublic
                      ? "Public playlist"
                      : "Private playlist"
                color: FiatPonsTheme.secondaryText
                font.pixelSize: Theme.fontSizeExtraSmall
                horizontalAlignment: Text.AlignHCenter
            }

            Item {
                width: parent.width
                height: page.editMode
                        ? editHint.height + Theme.paddingSmall
                        : playButton.height

                Label {
                    id: editHint
                    anchors.centerIn: parent
                    visible: page.editMode

                    text: "Drag the handles to reorder"
                    color: FiatPonsTheme.secondaryText
                    font.pixelSize: Theme.fontSizeExtraSmall
                }

                IconButton {
                    id: playButton
                    anchors.centerIn: parent
                    visible: !page.editMode

                    icon.source: "image://theme/icon-l-play"
                    icon.color: FiatPonsTheme.primaryText
                    enabled: tracksModel.count > 0
                    onClicked: page.playAll()
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: FiatPonsTheme.innerBorder
            }
        }

        delegate: ListItem {
            id: delegateItem

            property int dragTarget: -1

            width: listView.width
            contentHeight: Theme.itemSizeMedium

            function trackObj() {
                return page.rowToTrack(model)
            }

            onClicked: {
                if (!page.editMode)
                    app.queue.playNow(trackObj())
            }

            menu: page.editMode ? null : trackMenu

            Component {
                id: trackMenu

                ContextMenu {
                    MenuItem {
                        text: "Play now"
                        onClicked:
                            app.queue.playNow(delegateItem.trackObj())
                    }

                    MenuItem {
                        text: "Add to queue"
                        onClicked:
                            app.queue.enqueue(delegateItem.trackObj())
                    }

                    MenuItem {
                        text: "Play next"
                        onClicked:
                            app.queue.playNext(delegateItem.trackObj())
                    }

                    MenuItem {
                        text: "Remove from playlist"
                        onClicked:
                            page.requestRemove(
                                page.copyRow(model)
                            )
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

                    width: Theme.itemSizeMedium
                           - Theme.paddingMedium
                    height: width
                    anchors.verticalCenter: parent.verticalCenter

                    radius: Theme.paddingSmall / 2
                    color: FiatPonsTheme.recessFill
                    border.color: FiatPonsTheme.recessBorder
                    border.width: 1
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: model.cover_url === undefined
                                ? ""
                                : model.cover_url
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                    }

                    Label {
                        anchors.centerIn: parent
                        text: "\u266A"
                        color: FiatPonsTheme.secondaryText
                        font.pixelSize: Theme.fontSizeLarge
                        visible: model.cover_url === undefined
                                 || model.cover_url.length === 0
                    }
                }

                Column {
                    width: parent.width
                           - tile.width
                           - dragHandle.width
                           - Theme.paddingMedium * 2
                    anchors.verticalCenter: parent.verticalCenter

                    spacing: Theme.paddingSmall / 2

                    Label {
                        width: parent.width

                        text: model.title === undefined
                              ? ""
                              : model.title
                        color: delegateItem.highlighted
                               ? FiatPonsTheme.accent
                               : FiatPonsTheme.primaryText
                        font.pixelSize: Theme.fontSizeMedium
                        truncationMode: TruncationMode.Fade
                    }

                    Label {
                        width: parent.width
                        visible: text.length > 0

                        text: model.artist === undefined
                              ? ""
                              : model.artist
                        color: FiatPonsTheme.secondaryText
                        font.pixelSize: Theme.fontSizeExtraSmall
                        truncationMode: TruncationMode.Fade
                    }
                }

                Item {
                    id: dragHandle

                    width: page.editMode
                           ? Theme.itemSizeSmall
                           : 0
                    height: Theme.itemSizeMedium
                    visible: page.editMode
                    clip: true

                    Label {
                        anchors.centerIn: parent

                        text: "\u2261"
                        color: handleMouse.pressed
                               ? FiatPonsTheme.accent
                               : FiatPonsTheme.secondaryText
                        font.pixelSize: Theme.fontSizeLarge
                    }

                    MouseArea {
                        id: handleMouse

                        anchors.fill: parent
                        enabled: page.editMode
                        preventStealing: true

                        onPressed:
                            delegateItem.dragTarget = index

                        onPositionChanged: {
                            if (!pressed)
                                return

                            var point = mapToItem(
                                listView.contentItem,
                                mouse.x,
                                mouse.y
                            )

                            var target = listView.indexAt(
                                listView.width / 2,
                                point.y
                            )

                            if (target >= 0
                                    && target !== index
                                    && target !== delegateItem.dragTarget) {
                                tracksModel.move(index, target, 1)
                                delegateItem.dragTarget = target
                            }
                        }

                        onReleased:
                            delegateItem.dragTarget = -1

                        onCanceled:
                            delegateItem.dragTarget = -1
                    }
                }
            }
        }

        VerticalScrollDecorator {}
    }

    BusyIndicator {
        anchors.centerIn: parent
        size: BusyIndicatorSize.Large
        running: page.busy || page.savingOrder
        visible: running
    }

    Label {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: Theme.horizontalPageMargin
        anchors.rightMargin: Theme.horizontalPageMargin
        anchors.bottomMargin: Theme.paddingMedium

        visible: page.statusText.length > 0
                 && !page.busy
        text: page.statusText
        color: FiatPonsTheme.accent
        font.pixelSize: Theme.fontSizeExtraSmall
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
    }

    Label {
        anchors.centerIn: parent
        width: parent.width - Theme.horizontalPageMargin * 4

        visible: !page.busy
                 && (
                     page.errorText.length > 0
                     || tracksModel.count === 0
                 )

        text: page.errorText.length > 0
              ? page.errorText
              : "This playlist is empty"
        color: page.errorText.length > 0
               ? Theme.errorColor
               : FiatPonsTheme.secondaryText
        font.pixelSize: Theme.fontSizeSmall
        wrapMode: Text.Wrap
        horizontalAlignment: Text.AlignHCenter
    }
}
