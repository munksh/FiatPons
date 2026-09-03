import QtQuick 2.0
import Sailfish.Silica 1.0
import "."
import "pages"

ApplicationWindow {
    id: app

    initialPage: Component { NowPlayingPage { } }
    cover: Qt.resolvedUrl("cover/FiatPonsCover.qml")
    allowedOrientations: defaultAllowedOrientations

    Component.onCompleted: FiatPonsTheme.applyPalette(app)

    Connections {
        target: FiatPonsTheme
        onAmbientChanged: FiatPonsTheme.applyPalette(app)
    }
}
