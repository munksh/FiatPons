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

    // Play t now, queueing the rest of the given list after it.
    function playNowRange(t, rest) {
        model.clear()
        model.append(copy(t))
        if (rest) {
            for (var i = 0; i < rest.length; i++)
                model.append(copy(rest[i]))
        }
        currentIndex = 0
        currentChanged()
    }
    function enqueue(t)  { model.append(copy(t)); if (currentIndex < 0) { currentIndex = 0; currentChanged() } }
    function playNext(t) {
        if (currentIndex < 0) { model.append(copy(t)); currentIndex = 0; currentChanged() }
        else model.insert(currentIndex + 1, copy(t))
    }
    function goTo(i)     { if (i >= 0 && i < model.count) { currentIndex = i; currentChanged() } }
    function next()      { if (currentIndex + 1 < model.count) { currentIndex += 1; currentChanged(); return true } return false }
    function previous()  { if (currentIndex > 0) { currentIndex -= 1; currentChanged(); return true } return false }

    function move(fromIndex, toIndex) {
        if (fromIndex < 0 || toIndex < 0
                || fromIndex >= model.count
                || toIndex >= model.count
                || fromIndex === toIndex)
            return

        var oldCurrent = currentIndex

        model.move(fromIndex, toIndex, 1)

        if (fromIndex === oldCurrent) {
            currentIndex = toIndex
        } else if (fromIndex < oldCurrent && toIndex >= oldCurrent) {
            currentIndex = oldCurrent - 1
        } else if (fromIndex > oldCurrent && toIndex <= oldCurrent) {
            currentIndex = oldCurrent + 1
        }
    }

    function removeAt(index) {
        if (index < 0 || index >= model.count)
            return

        var oldCurrent = currentIndex

        model.remove(index)

        if (model.count === 0) {
            currentIndex = -1
            currentChanged()
            return
        }

        if (index === oldCurrent) {
            currentIndex = Math.min(index, model.count - 1)
            currentChanged()
        } else if (index < oldCurrent) {
            currentIndex = oldCurrent - 1
        }
    }

    function persist() {
        // Queue remains session-local for now.
    }

    function clear() {
        model.clear()
        currentIndex = -1
        currentChanged()
    }
}
