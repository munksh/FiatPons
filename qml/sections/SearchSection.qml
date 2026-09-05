import QtQuick 2.0
import Sailfish.Silica 1.0
import se.munkstolen.fiatpons 1.0
import "../components"
import ".."

Item {
    id: section
    clip: true
    property bool busy: false
    property string errorText: ""

    // Apply the Fiat palette to this section's chrome (SearchField etc.) so it
    // matches the theme like everything else, regardless of ambience.
    function paint() { FiatPonsTheme.applyPalette(section) }
    Component.onCompleted: paint()
    Connections { target: FiatPonsTheme; onAmbientChanged: section.paint() }

    Backend {
        id: backend
        onSearchComplete: {
            section.busy = false
            resultsModel.clear()
            var data
            try { data = JSON.parse(json) }
            catch (e) { section.errorText = "Could not read response"; return }
            if (data.error) { section.errorText = data.error; return }
            section.errorText = ""
            var items = data.tracks || []
            for (var i = 0; i < items.length; i++) resultsModel.append(items[i])
        }
    }

    SilicaListView {
        id: listView
        anchors.fill: parent
        clip: true
        currentIndex: -1

        header: Item {
            width: listView.width
            height: searchField.height + Theme.paddingMedium
            SearchField {
                id: searchField
                width: parent.width
                placeholderText: "Track, artist, or album"
                color: FiatPonsTheme.primaryText
                inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
                EnterKey.iconSource: "image://theme/icon-m-enter-close"
                EnterKey.onClicked: {
                    focus = false
                    if (text.length > 0) {
                        section.busy = true
                        section.errorText = ""
                        resultsModel.clear()
                        backend.search(text)
                    }
                }
            }
        }
        model: ListModel { id: resultsModel }

        delegate: ListItem {
            id: delegateItem
            width: listView.width
            contentHeight: Theme.itemSizeMedium

            function trackObj() {
                return {
                    id: model.id,
                    title: model.title,
                    artist: model.artist,
                    album: model.album,
                    cover_url: (model.cover_url === undefined) ? "" : model.cover_url
                }
            }

            onClicked: app.queue.playNow(trackObj())

            menu: ContextMenu {
                MenuItem { text: "Play now";     onClicked: app.queue.playNow(delegateItem.trackObj()) }
                MenuItem { text: "Add to queue"; onClicked: app.queue.enqueue(delegateItem.trackObj()) }
                MenuItem { text: "Play next";    onClicked: app.queue.playNext(delegateItem.trackObj()) }
            }

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
                    id: coverTile
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
                        source: (model.cover_url === undefined) ? "" : model.cover_url
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                    }
                    Label {
                        anchors.centerIn: parent
                        text: "\u266A"
                        color: FiatPonsTheme.secondaryText
                        font.pixelSize: Theme.fontSizeLarge
                        visible: (model.cover_url === undefined || model.cover_url.length === 0)
                    }
                }

                Column {
                    width: parent.width - coverTile.width - Theme.paddingMedium
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
        }

        VerticalScrollDecorator {}
    }

    BusyIndicator {
        anchors.centerIn: parent
        size: BusyIndicatorSize.Large
        running: section.busy
    }

    Column {
        anchors.centerIn: parent
        width: parent.width - Theme.horizontalPageMargin * 4
        spacing: Theme.paddingSmall
        visible: !section.busy && resultsModel.count === 0
        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: section.errorText.length > 0 ? "Search failed" : "Search Qobuz"
            color: FiatPonsTheme.accent
            font.pixelSize: Theme.fontSizeLarge
            font.family: FiatPonsTheme.serif
        }
        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            text: section.errorText.length > 0 ? section.errorText
                                               : "Find a track, artist, or album"
            color: FiatPonsTheme.secondaryText
            font.pixelSize: Theme.fontSizeSmall
        }
    }
}
