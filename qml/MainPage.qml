import QtQuick 2.0
import Sailfish.Silica 1.0
import "sections"
import "."

// Host page: wordmark + settings tucked into the status row, a tab row, and a
// horizontally-swiped pager holding the four top-level sections.
Page {
    id: mainPage
    allowedOrientations: defaultAllowedOrientations

    function paint() { FiatPonsTheme.applyPalette(mainPage) }
    Component.onCompleted: {
        paint()
        pager.positionViewAtIndex(1, ListView.SnapPosition)
    }
    Connections { target: FiatPonsTheme; onAmbientChanged: mainPage.paint() }

    Rectangle {
        anchors.fill: parent
        visible: !FiatPonsTheme.ambient
        gradient: Gradient {
            GradientStop { position: 0.0; color: FiatPonsTheme.backgroundHigh }
            GradientStop { position: 1.0; color: FiatPonsTheme.backgroundLow }
        }
    }

    // ---- Top bar: wordmark + settings, raised into the status row ----
    Item {
        id: topBar
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: FiatPonsTheme.statusRowCenter + wordmark.height / 2 + Theme.paddingSmall
        z: 10

        Label {
            id: wordmark
            anchors.left: parent.left
            anchors.leftMargin: Theme.horizontalPageMargin
            anchors.top: parent.top
            anchors.topMargin: Math.max(0, FiatPonsTheme.statusRowCenter - height / 2)
            text: "fiat pons"
            color: FiatPonsTheme.primaryText
            font.pixelSize: Theme.fontSizeLarge
            font.family: FiatPonsTheme.serif
            font.italic: true
        }
        IconButton {
            anchors.right: parent.right
            anchors.rightMargin: Theme.horizontalPageMargin
            anchors.verticalCenter: wordmark.verticalCenter
            icon.source: "image://theme/icon-m-menu"
            onClicked: pageStack.push(Qt.resolvedUrl("pages/SettingsPage.qml"))
        }
    }

    // ---- Tab bar ----
    Item {
        id: tabBar
        anchors { top: topBar.bottom; left: parent.left; right: parent.right }
        height: Theme.itemSizeSmall
        z: 10

        Row {
            anchors.fill: parent
            Repeater {
                model: ["Search", "Now Playing", "Library", "Discover"]
                delegate: Item {
                    width: tabBar.width / 4
                    height: tabBar.height
                    Label {
                        anchors.centerIn: parent
                        text: modelData
                        font.pixelSize: Theme.fontSizeExtraSmall
                        font.family: FiatPonsTheme.serif
                        color: index === pager.currentIndex
                            ? FiatPonsTheme.accent : FiatPonsTheme.secondaryText
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: pager.currentIndex = index
                    }
                }
            }
        }
        Rectangle {
            width: tabBar.width / 4
            height: 2
            color: FiatPonsTheme.accent
            anchors.bottom: parent.bottom
            x: pager.currentIndex * width
            Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
        }
    }

    ListView {
        id: pager
        anchors { top: tabBar.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
        clip: true
        orientation: ListView.Horizontal
        snapMode: ListView.SnapOneItem
        highlightRangeMode: ListView.StrictlyEnforceRange
        highlightMoveDuration: 200
        boundsBehavior: Flickable.StopAtBounds
        cacheBuffer: width * 4
        model: 4
        delegate: Loader {
            width: pager.width
            height: pager.height
            sourceComponent: index === 0 ? searchComp
                          : index === 1 ? nowComp
                          : index === 2 ? libComp
                          : discComp
        }
    }

    Component { id: searchComp; SearchSection { } }
    Component { id: nowComp;    NowPlayingSection { } }
    Component { id: libComp;    LibrarySection { } }
    Component { id: discComp;   DiscoverSection { } }
}
