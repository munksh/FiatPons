import QtQuick 2.0
import Sailfish.Silica 1.0
import se.munkstolen.fiatpons 1.0
import "../components"
import ".."

// Drill-down from Search (Artist pill). Portrait, two-line bio ("Read more"
// drills to BioPage -- keeps this page's layout stable), Radio (the real
// "play this artist" primitive), then Albums. Deliberately simple: only one
// list (albums) lives in the ListView, nothing else competes with its layout.
Page {
    id: page
    property string artistIdStr: ""
    property var artistId: artistIdStr.length > 0 ? parseInt(artistIdStr) : 0

    property string name: ""
    property string imageUrl: ""
    property string bio: ""
    property bool busy: true
    property string errorText: ""

    function paint() { FiatPonsTheme.applyPalette(page) }
    Component.onCompleted: { paint(); if (artistId > 0) backend.artist(artistId) }
    Connections { target: FiatPonsTheme; onAmbientChanged: page.paint() }

    Backend {
        id: backend
        onArtistComplete: {
            busy = false
            var data
            try { data = JSON.parse(json) }
            catch (e) { errorText = "Could not read response"; return }
            if (data.error) { errorText = data.error; return }
            var a = data.artist || {}
            name = a.name || ""
            imageUrl = a.image_url || ""
            bio = a.bio || ""
            var items = data.albums || []
            for (var i = 0; i < items.length; i++) {
                var al = items[i]
                al.id = String(al.id)
                albumsModel.append(al)
            }
        }
        onRadioArtistComplete: {
            var data
            try { data = JSON.parse(json) } catch (e) { return }
            if (data.error) return
            var items = data.tracks || []
            if (items.length === 0) return
            var first = items[0]; first.id = String(first.id)
            app.queue.playNow(first)
            for (var i = 1; i < items.length; i++) {
                var t = items[i]; t.id = String(t.id)
                app.queue.enqueue(t)
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
        model: ListModel { id: albumsModel }

        header: Column {
            width: listView.width
            spacing: Theme.paddingMedium

            PageHeader { title: "Artist" }

            Rectangle {
                width: Theme.itemSizeLarge * 1.6
                height: width
                radius: width / 2
                anchors.horizontalCenter: parent.horizontalCenter
                color: FiatPonsTheme.recessFill
                border.color: FiatPonsTheme.recessBorder
                border.width: 1
                clip: true
                Image {
                    anchors.fill: parent
                    source: page.imageUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                }
                Label {
                    anchors.centerIn: parent
                    text: "\u263A"
                    color: FiatPonsTheme.secondaryText
                    font.pixelSize: Theme.fontSizeHuge
                    visible: page.imageUrl.length === 0
                }
            }

            Label {
                width: parent.width - Theme.horizontalPageMargin * 2
                anchors.horizontalCenter: parent.horizontalCenter
                text: page.name
                color: FiatPonsTheme.primaryText
                font.pixelSize: Theme.fontSizeLarge
                font.family: FiatPonsTheme.serif
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
            }

            // ---- Bio: fixed two lines, "Read more" drills to BioPage. Fixed
            // height means this block never resizes and never pushes the
            // portrait/name around. ----
            Column {
                width: parent.width - Theme.horizontalPageMargin * 2
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingSmall / 2
                visible: page.bio.length > 0
                Label {
                    width: parent.width
                    text: page.bio
                    color: FiatPonsTheme.secondaryText
                    font.pixelSize: Theme.fontSizeSmall
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
                Label {
                    width: parent.width
                    text: "Read more\u2026"
                    color: FiatPonsTheme.accent
                    font.pixelSize: Theme.fontSizeExtraSmall
                    horizontalAlignment: Text.AlignHCenter
                    MouseArea {
                        anchors.fill: parent
                        onClicked: pageStack.push(Qt.resolvedUrl("BioPage.qml"),
                            { artistName: page.name, bio: page.bio })
                    }
                }
            }

            // ---- Radio: the real "play this artist" action ----
            Item {
                width: parent.width
                height: radioButton.height + Theme.paddingSmall
                IconButton {
                    id: radioButton
                    anchors.horizontalCenter: parent.horizontalCenter
                    icon.source: "image://theme/icon-l-play"
                    icon.color: FiatPonsTheme.primaryText
                    onClicked: backend.radioArtist(page.artistId)
                }
            }

            SectionHeader { text: "Albums"; color: FiatPonsTheme.secondaryText }
            Item { width: 1; height: Theme.paddingSmall }
        }

        delegate: ListItem {
            id: delegateItem
            width: listView.width
            contentHeight: Theme.itemSizeMedium

            onClicked: pageStack.push(Qt.resolvedUrl("AlbumPage.qml"), { albumId: model.id })

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
                    width: parent.width - tile.width - Theme.paddingMedium
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
                        visible: text.length > 0
                        text: (model.year === undefined || model.year.length === 0) ? "" : model.year
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

    Label {
        anchors.centerIn: parent
        visible: !page.busy && page.errorText.length > 0
        text: page.errorText
        color: FiatPonsTheme.secondaryText
        font.pixelSize: Theme.fontSizeSmall
        wrapMode: Text.Wrap
        width: parent.width - Theme.horizontalPageMargin * 4
        horizontalAlignment: Text.AlignHCenter
    }
}
