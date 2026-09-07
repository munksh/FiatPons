import QtQuick 2.0
import Sailfish.Silica 1.0
import se.munkstolen.fiatpons 1.0
import ".."

Dialog {
    id: dialog

    property string trackIdStr: ""
    property bool saving: false
    property string errorText: ""

    canAccept: playlistName.text.trim().length > 0 && !saving

    function paint() {
        FiatPonsTheme.applyPalette(dialog)
    }

    Component.onCompleted: paint()

    Connections {
        target: FiatPonsTheme
        onAmbientChanged: dialog.paint()
    }

    Backend {
        id: backend
    }

    Connections {
        target: backend

        onCreatePlaylistComplete: {
            dialog.saving = false

            var data

            try {
                data = JSON.parse(json)
            } catch (error) {
                dialog.errorText = "Could not read the response"
                return
            }

            if (data.error) {
                dialog.errorText = data.error
                return
            }

            dialog.accept()
        }
    }

    onAccepted: {
        if (saving)
            return

        saving = true
        errorText = ""

        var trackId = parseInt(trackIdStr)

        if (isNaN(trackId))
            trackId = 0

        backend.createPlaylist(
            playlistName.text.trim(),
            trackId
        )
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height

        Column {
            id: content
            width: parent.width

            DialogHeader {
                acceptText: saving ? "Creating…" : "Create"
                cancelText: "Cancel"
            }

            TextField {
                id: playlistName
                width: parent.width
                label: "Playlist name"
                placeholderText: "Playlist name"
                color: FiatPonsTheme.primaryText
                focus: true
                EnterKey.enabled: dialog.canAccept
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.onClicked: dialog.accept()
            }

            TextSwitch {
                width: parent.width
                text: "Public playlist"
                description: "Coming later"
                enabled: false
                checked: false
            }

            Label {
                width: parent.width - Theme.horizontalPageMargin * 2
                anchors.horizontalCenter: parent.horizontalCenter

                visible: dialog.errorText.length > 0
                text: dialog.errorText
                color: Theme.errorColor
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.Wrap
            }

            BusyIndicator {
                anchors.horizontalCenter: parent.horizontalCenter
                size: BusyIndicatorSize.Medium
                running: dialog.saving
                visible: running
            }
        }

        VerticalScrollDecorator {}
    }
}
