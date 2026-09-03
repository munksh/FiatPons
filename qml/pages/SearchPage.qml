import QtQuick 2.0
import Sailfish.Silica 1.0
import se.munkstolen.fiatpons 1.0
import "../components"
import ".."

Page {
    id: page
    property var onTrackSelected: null
    property bool busy: false
    property string errorText: ""

    function paint() { FiatPonsTheme.applyPalette(page) }
    Component.onCompleted: paint()
    Connections {
        target: FiatPonsTheme
        onAmbientChanged: page.paint()
    }

    Backend {
        id: backend
        onSearchComplete: {
            page.busy = false
            resultsModel.clear()
            var data
            try { data = JSON.parse(json) }
            catch (e) { page.errorText = "Could not read response"; return }
            if (data.error) { page.errorText = data.error; return }
            page.errorText = ""
            var items = data.tracks || []
            for (var i = 0; i < items.length; i++) resultsModel.append(items[i])
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
        currentIndex: -1
        header: Column {
            width: listView.width
            PageHead { title: "Search" }
            SearchField {
                id: searchField
                width: parent.width
                placeholderText: "Track, artist, or album"
                inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
                EnterKey.iconSource: "image://theme/icon-m-enter-close"
                EnterKey.onClicked: {
                    focus = false
                    if (text.length > 0) {
                        page.busy = true
                        page.errorText = ""
                        resultsModel.clear()
                        backend.search(text)
                    }
                }
            }
        }
        model: ListModel { id: resultsModel }
        delegate: BackgroundItem {
            id: delegateItem
            width: listView.width
            contentHeight: Theme.itemSizeMedium
            onClicked: {
                app.queue.enqueue({
                    id: model.id,
                    title: model.title,
                    artist: model.artist,
                    album: model.album
                })
                // If nothing is playing yet, start at the one just added.
                if (app.queue.currentIndex < 0)
                    app.queue.currentIndex = app.queue.model.count - 1
                pageStack.pop()
            }
            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.horizontalPageMargin
                anchors.rightMargin: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.paddingSmall / 2
                Label {
                    width: parent.width
                    text: model.title === undefined ? "" : model.title
                    color: delegateItem.highlighted ? FiatPonsTheme.accent : FiatPonsTheme.primaryText
                    font.pixelSize: Theme.fontSizeMedium
                    truncationMode: TruncationMode.Fade
                }
                Label {
                    width: parent.width
                    text: (model.artist === undefined ? "" : model.artist)
                        + " \u2014 " + (model.album === undefined ? "" : model.album)
                    color: FiatPonsTheme.secondaryText
                    font.pixelSize: Theme.fontSizeExtraSmall
                    truncationMode: TruncationMode.Fade
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

    EmptyNote {
        anchors.fill: parent
        anchors.topMargin: Theme.itemSizeLarge * 2
        visible: !page.busy && resultsModel.count === 0
                 && (page.errorText.length > 0 || searchField.text.length > 0)
        title: page.errorText.length > 0 ? "Search failed" : "No matches"
        hint:  page.errorText.length > 0 ? page.errorText
                                         : "Try a different title, artist, or album."
    }
}
