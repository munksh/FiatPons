// The play queue. Pure state + a currentChanged() signal fired exactly when the
// current track should (re)load. Track objects are stored/returned as plain
// COPIES (never live model.get references). Session-only: cleared on close.
import QtQuick 2.0

Item {
    id: queue
    property ListModel model: ListModel { }
    property int currentIndex: -1

    signal currentChanged()

    readonly property bool hasNext: currentIndex + 1 < model.count
    readonly property bool hasPrev: currentIndex > 0

    function copy(t) {
        return { id: t.id, title: t.title, artist: t.artist,
                 album: t.album, cover_url: t.cover_url }
    }

    function currentTrack() {
        if (currentIndex >= 0 && currentIndex < model.count) {
            var m = model.get(currentIndex)
            return { id: m.id, title: m.title, artist: m.artist,
                     album: m.album, cover_url: m.cover_url }
        }
        return null
    }

    function playNow(t)  { model.clear(); model.append(copy(t)); currentIndex = 0; currentChanged() }
    function enqueue(t)  { model.append(copy(t)); if (currentIndex < 0) { currentIndex = 0; currentChanged() } }
    function playNext(t) {
        if (currentIndex < 0) { model.append(copy(t)); currentIndex = 0; currentChanged() }
        else model.insert(currentIndex + 1, copy(t))
    }
    function goTo(i)     { if (i >= 0 && i < model.count) { currentIndex = i; currentChanged() } }
    function next()      { if (currentIndex + 1 < model.count) { currentIndex += 1; currentChanged(); return true } return false }
    function previous()  { if (currentIndex > 0) { currentIndex -= 1; currentChanged(); return true } return false }
    function clear()     { model.clear(); currentIndex = -1; currentChanged() }
}
