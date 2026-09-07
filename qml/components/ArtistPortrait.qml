import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0
import ".."

Item {
    id: root

    property string artistId: ""
    property string imageUrl: ""
    property bool pressed: false

    width: Theme.itemSizeHuge * 1.35
    height: width

    function placeholder(id) {
        var n = parseInt(id)

        if (isNaN(n))
            n = 0

        var slot = Math.abs(n % 6) + 1
        var tone = FiatPonsTheme.ambient ? "dark" : "light"

        return "../images/artist-placeholders/artist_placeholder_"
                + tone + "_" + slot + ".svg"
    }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: FiatPonsTheme.recessFill
    }

    Image {
        id: portraitImage

        anchors.fill: parent
        anchors.margins: 2

        source: root.imageUrl.length > 0
                ? root.imageUrl
                : root.placeholder(root.artistId)

        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        visible: false
    }

    Rectangle {
        id: portraitMask

        anchors.fill: portraitImage
        radius: width / 2
        visible: false
    }

    OpacityMask {
        anchors.fill: portraitImage
        source: portraitImage
        maskSource: portraitMask
    }

    Rectangle {
        anchors.fill: parent

        radius: width / 2
        color: "transparent"
        border.color: root.pressed
                      ? FiatPonsTheme.accent
                      : FiatPonsTheme.recessBorder
        border.width: root.pressed ? 2 : 1

        Behavior on border.color {
            ColorAnimation { duration: 100 }
        }
    }

    scale: root.pressed ? 0.94 : 1.0
    opacity: root.pressed ? 0.76 : 1.0

    Behavior on scale {
        NumberAnimation {
            duration: 100
            easing.type: Easing.OutQuad
        }
    }

    Behavior on opacity {
        NumberAnimation { duration: 100 }
    }
}
