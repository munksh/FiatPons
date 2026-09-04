import QtQuick 2.0
import Sailfish.Silica 1.0
import "."
import "pages"

ApplicationWindow {
    id: app

    // Shared, app-level state — every tab is just a view over these.
    property alias queue: theQueue
    property alias playback: thePlayback
    Queue { id: theQueue }
    Playback { id: thePlayback; queue: theQueue }

    initialPage: Component { MainPage { } }
    cover: Qt.resolvedUrl("cover/FiatPonsCover.qml")
    allowedOrientations: defaultAllowedOrientations
    Component.onCompleted: FiatPonsTheme.applyPalette(app)
    Connections {
        target: FiatPonsTheme
        onAmbientChanged: FiatPonsTheme.applyPalette(app)
    }
}
