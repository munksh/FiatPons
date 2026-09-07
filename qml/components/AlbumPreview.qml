import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

Item {
    id: root

    property var album
    property real cardWidth: 100

    width: cardWidth
    height: cardWidth + titleLabel.height + artistLabel.height + Theme.paddingSmall * 2

    Rectangle {
        id: cover

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        width: root.cardWidth
        height: width
        radius: FiatPonsTheme.cardRadius
        color: FiatPonsTheme.recessFill
        border.color: albumMouse.pressed ? FiatPonsTheme.accent : FiatPonsTheme.recessBorder
        border.width: albumMouse.pressed ? 2 : 1
        clip: true

        Image {
            anchors.fill: parent
            anchors.margins: 2
            source: root.album && root.album.cover_url !== undefined ? root.album.cover_url : ""
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
            visible: !root.album || root.album.cover_url === undefined || root.album.cover_url.length === 0
        }
    }

    Label {
        id: titleLabel

        anchors.top: cover.bottom
        anchors.topMargin: Theme.paddingSmall
        anchors.left: parent.left
        anchors.right: parent.right

        text: root.album && root.album.title !== undefined ? root.album.title : ""
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
            if (!root.album)
                return ""

            var artist = root.album.artist === undefined ? "" : root.album.artist
            var year = root.album.year === undefined ? "" : root.album.year

            return year.length > 0 ? artist + " \u00B7 " + year : artist
        }

        color: FiatPonsTheme.secondaryText
        font.pixelSize: Theme.fontSizeExtraSmall
        horizontalAlignment: Text.AlignHCenter
        maximumLineCount: 1
        truncationMode: TruncationMode.Fade
        visible: text.length > 0
    }

    MouseArea {
        id: albumMouse
        anchors.fill: parent

        onClicked: {
            if (!root.album)
                return

            pageStack.push(Qt.resolvedUrl("../pages/AlbumPage.qml"), {
                albumId: String(root.album.id),
                initialCover: root.album.cover_url === undefined ? "" : root.album.cover_url
            })
        }
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
