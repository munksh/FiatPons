// App-level playback. FIFO pending-count keeps picture/audio in sync and
// next/prev correct. Session-only; nothing restored on launch.
import QtQuick 2.0
import QtMultimedia 5.0
import se.munkstolen.fiatpons 1.0

Item {
    id: playback
    property var queue

    property int pending: 0
    property bool shouldPlay: false
    property var inflightTrack: null
    property var nowTrack: null

    property string statusLine: ""
    property string quality: ""
    property bool shuffle: false
    property int repeatMode: 0

    readonly property bool playing: player.playbackState === MediaPlayer.PlayingState
    readonly property int position: player.position
    readonly property int duration: player.duration

    function log(m) { console.log("[PB] " + m) }

    Connections { target: queue; onCurrentChanged: playback.load() }

    function load() {
        var t = queue ? queue.currentTrack() : null
        inflightTrack = t
        shouldPlay = false
        pending += 1
        log("load pending=" + pending + " id=" + (t ? t.id : 0) + " idx=" + (queue ? queue.currentIndex : -1))
        if (t) { statusLine = "Resolving\u2026"; backend.streamUrl(t.id) }
        else { player.stop(); player.source = ""; nowTrack = null; statusLine = "" }
    }

    function toggle() { if (player.playbackState === MediaPlayer.PlayingState) player.pause(); else player.play() }
    function next() { advance() }
    function previous() { if (queue) queue.previous() }
    function seek(ms) { player.seek(ms) }
    function advance() {
        if (repeatMode === 2) { player.seek(0); player.play(); return }
        if (shuffle && queue && queue.model.count > 1) {
            var n = Math.floor(Math.random() * queue.model.count)
            if (n === queue.currentIndex) n = (n + 1) % queue.model.count
            queue.goTo(n); return
        }
        if (queue && !queue.next()) {
            if (repeatMode === 1 && queue.model.count > 0) queue.goTo(0)
            else statusLine = "End of queue"
        }
    }

    Backend { id: backend; onStreamReady: playback.onStream(json) }
    function onStream(json) {
        pending -= 1
        if (pending < 0) pending = 0
        if (pending > 0) { log("onStream superseded, ignore"); return }
        var data
        try { data = JSON.parse(json) } catch (e) { statusLine = "Bad response"; return }
        if (data.error) { log("onStream error: " + data.error); statusLine = "Error: " + data.error; return }
        statusLine = ""
        if (data.bit_depth && data.sample_rate) quality = data.bit_depth + "-bit \u00B7 " + data.sample_rate + " kHz"
        else if (data.mime) quality = (data.mime.indexOf("flac") !== -1) ? "FLAC" : "MP3"
        else quality = ""
        nowTrack = inflightTrack
        shouldPlay = true
        log("source set id=" + (nowTrack ? nowTrack.id : 0))
        player.source = data.url
    }

    MediaPlayer {
        id: player
        autoPlay: false
        onError: { log("ERR " + errorString); playback.statusLine = "Playback error: " + errorString; playback.shouldPlay = false }
        onStatusChanged: {
            if (playback.shouldPlay &&
                (status === MediaPlayer.Loaded || status === MediaPlayer.Buffered || status === MediaPlayer.Buffering)) {
                playback.shouldPlay = false
                playback.log("play id=" + (playback.nowTrack ? playback.nowTrack.id : 0))
                play()
            }
        }
        onStopped: {
            if (status === MediaPlayer.EndOfMedia) { playback.log("EndOfMedia -> advance"); playback.advance() }
        }
    }
}
