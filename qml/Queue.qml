// The play queue: a list of track objects and a current index. Pure state,
// no UI. Lives on the ApplicationWindow so it persists across pages.
import QtQuick 2.0

Item {
    id: queue

    property ListModel model: ListModel { }
    property int currentIndex: -1

    readonly property var currentTrack:
        (currentIndex >= 0 && currentIndex < model.count) ? model.get(currentIndex) : null

    // Replace the queue with one track and play it (tapping a search result).
    function playNow(track) {
        model.clear()
        model.append(track)
        currentIndex = 0
    }

    // Add to the end without disturbing what's playing.
    function enqueue(track) {
        model.append(track)
    }

    // Advance; returns false if there's nothing after the current track.
    function next() {
        if (currentIndex + 1 < model.count) {
            currentIndex = currentIndex + 1
            return true
        }
        return false
    }

    function hasNext() { return currentIndex + 1 < model.count }
    function clear() { model.clear(); currentIndex = -1 }
}
