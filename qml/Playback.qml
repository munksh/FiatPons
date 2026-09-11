// App-level playback. FIFO pending-count keeps picture/audio in sync and
// next/prev correct. Session-only; nothing restored on launch.
import QtQuick 2.0
import QtMultimedia 5.0
import Amber.Mpris 1.0
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
    property string preferredQuality: "lossless"
    property bool playWhenResolved: true
    property bool shuffle: false
    property int repeatMode: 0
    property bool explicitlyStopped: false

    readonly property bool playing:
        player.playbackState === MediaPlayer.PlayingState

    readonly property int position: player.position
    readonly property int duration: player.duration

    function log(m) {
        console.log("[PB] " + m)
    }

    function preferredQualityLabel() {
        return preferredQuality === "mp3"
               ? "MP3 320"
               : "CD (FLAC 16/44.1)"
    }

    function setPreferredQuality(value) {
        if (value !== "mp3")
            value = "lossless"

        if (preferredQuality === value)
            return

        var resume =
            player.playbackState === MediaPlayer.PlayingState

        preferredQuality = value
        backend.setStreamQualityPreference(value)

        if (queue && queue.currentTrack())
            playback.load(resume)
    }

    Connections {
        target: queue
        onCurrentChanged: playback.load(true)
    }

    function load(playAfterResolve) {
        if (playAfterResolve === undefined)
            playAfterResolve = true

        var t = queue ? queue.currentTrack() : null

        inflightTrack = t
        playWhenResolved = playAfterResolve
        shouldPlay = false
        explicitlyStopped = false
        pending += 1

        log(
            "load pending=" + pending
            + " id=" + (t ? t.id : 0)
            + " idx=" + (queue ? queue.currentIndex : -1)
        )

        if (t) {
            statusLine = "Resolving\u2026"

            log(
                "request quality="
                + preferredQuality
                + " id="
                + t.id
            )

            backend.streamUrlQuality(
                t.id,
                preferredQuality
            )
        } else {
            player.stop()
            player.source = ""
            nowTrack = null
            statusLine = ""
        }
    }

    function play() {
        if (!nowTrack)
            return

        explicitlyStopped = false

        if (player.playbackState !== MediaPlayer.PlayingState)
            player.play()
    }

    function pause() {
        if (player.playbackState === MediaPlayer.PlayingState)
            player.pause()
    }

    function stop() {
        shouldPlay = false
        explicitlyStopped = true
        player.stop()
    }

    function toggle() {
        if (player.playbackState === MediaPlayer.PlayingState)
            pause()
        else
            play()
    }

    function next() {
        advance()
    }

    function previous() {
        if (queue)
            queue.previous()
    }

    function seek(ms) {
        if (!nowTrack || duration <= 0)
            return

        var target = Math.max(
            0,
            Math.min(Math.round(ms), duration)
        )

        player.seek(target)
        mpris.seeked(target)
    }

    function mprisTrackId() {
        if (!nowTrack
                || nowTrack.id === undefined
                || nowTrack.id === null) {
            return "/org/mpris/MediaPlayer2/TrackList/NoTrack"
        }

        var safeId =
            String(nowTrack.id).replace(/[^A-Za-z0-9_]/g, "_")

        if (safeId.length === 0)
            safeId = "unknown"

        return "/se/munkstolen/fiatpons/track/" + safeId
    }

    function advance() {
        if (repeatMode === 2) {
            seek(0)
            play()
            return
        }

        if (shuffle && queue && queue.model.count > 1) {
            var n = Math.floor(
                Math.random() * queue.model.count
            )

            if (n === queue.currentIndex)
                n = (n + 1) % queue.model.count

            queue.goTo(n)
            return
        }

        if (queue && !queue.next()) {
            if (repeatMode === 1 && queue.model.count > 0)
                queue.goTo(0)
            else
                statusLine = "End of queue"
        }
    }

    Component.onCompleted: {
        preferredQuality =
            backend.streamQualityPreference()
    }

    Backend {
        id: backend
        onStreamReady: playback.onStream(json)
    }

    function onStream(json) {
        pending -= 1

        if (pending < 0)
            pending = 0

        if (pending > 0) {
            log("onStream superseded, ignore")
            return
        }

        var data

        try {
            data = JSON.parse(json)
        } catch (e) {
            statusLine = "Bad response"
            return
        }

        if (data.error) {
            log("onStream error: " + data.error)
            statusLine = "Error: " + data.error
            return
        }

        statusLine = ""

        var mime = data.mime
                   ? data.mime.toLowerCase()
                   : ""

        if (preferredQuality === "mp3"
                || mime.indexOf("mpeg") !== -1
                || mime.indexOf("mp3") !== -1) {
            quality = "MP3 320"
        } else if (data.bit_depth && data.sample_rate) {
            quality =
                data.bit_depth
                + "-bit \u00B7 "
                + data.sample_rate
                + " kHz"
        } else if (mime.indexOf("flac") !== -1) {
            quality = "FLAC"
        } else {
            quality = preferredQualityLabel()
        }

        log(
            "resolved requested=" + preferredQuality
            + " mime=" + mime
            + " displayed=" + quality
        )

        nowTrack = inflightTrack
        explicitlyStopped = false
        shouldPlay = playWhenResolved

        log(
            "source set id="
            + (nowTrack ? nowTrack.id : 0)
        )

        player.source = data.url
    }

    MprisPlayer {
        id: mpris

        serviceName: "harbour-fiatpons"
        identity: "Fiat Pons"
        desktopEntry: "harbour-fiatpons"

        canControl: true
        canQuit: false
        canRaise: false
        canSetFullscreen: false

        // These must not change during this object's lifetime.
        hasShuffle: true
        hasLoopStatus: true

        canPlay:
            playback.nowTrack !== null
            && !playback.playing

        canPause:
            playback.nowTrack !== null

        canSeek:
            playback.nowTrack !== null
            && playback.duration > 0

        canGoNext:
            playback.queue !== null
            && playback.queue.model.count > 0
            && (playback.queue.hasNext
                || playback.shuffle
                || playback.repeatMode > 0)

        canGoPrevious:
            playback.queue !== null
            && playback.queue.hasPrev

        playbackStatus:
            playback.explicitlyStopped
            || playback.nowTrack === null
            ? Mpris.Stopped
            : (playback.playing
               ? Mpris.Playing
               : Mpris.Paused)

        shuffle: playback.shuffle

        loopStatus:
            playback.repeatMode === 2
            ? Mpris.LoopTrack
            : (playback.repeatMode === 1
               ? Mpris.LoopTrackList
               : Mpris.LoopNone)

        metaData.title:
            playback.nowTrack
            ? playback.nowTrack.title
            : undefined

        metaData.contributingArtist:
            playback.nowTrack
            && playback.nowTrack.artist
            ? [playback.nowTrack.artist]
            : undefined

        metaData.albumTitle:
            playback.nowTrack
            && playback.nowTrack.album
            ? playback.nowTrack.album
            : undefined

        metaData.artUrl:
            playback.nowTrack
            && playback.nowTrack.cover_url
            ? playback.nowTrack.cover_url
            : undefined

        metaData.duration:
            playback.nowTrack
            && playback.duration > 0
            ? playback.duration
            : undefined

        metaData.trackId:
            playback.mprisTrackId()

        onPositionRequested: {
            position = playback.position
        }

        onPlayRequested: {
            playback.play()
        }

        onPauseRequested: {
            playback.pause()
        }

        onPlayPauseRequested: {
            playback.toggle()
        }

        onNextRequested: {
            playback.next()
        }

        onPreviousRequested: {
            playback.previous()
        }

        onStopRequested: {
            playback.stop()
        }

        onSeekRequested: {
            playback.seek(
                playback.position + offset
            )
        }

        onSetPositionRequested: {
            if (trackId === playback.mprisTrackId())
                playback.seek(position)
        }

        onShuffleRequested: {
            playback.shuffle = shuffle
        }

        onLoopStatusRequested: {
            if (loopStatus === Mpris.LoopTrack)
                playback.repeatMode = 2
            else if (loopStatus === Mpris.LoopTrackList)
                playback.repeatMode = 1
            else
                playback.repeatMode = 0
        }
    }

    MediaPlayer {
        id: player
        autoPlay: false

        onError: {
            log("ERR " + errorString)
            playback.statusLine =
                "Playback error: " + errorString
            playback.shouldPlay = false
        }

        onStatusChanged: {
            if (playback.shouldPlay
                    && (status === MediaPlayer.Loaded
                        || status === MediaPlayer.Buffered
                        || status === MediaPlayer.Buffering)) {
                playback.shouldPlay = false

                playback.log(
                    "play id="
                    + (playback.nowTrack
                       ? playback.nowTrack.id
                       : 0)
                )

                playback.play()
            }
        }

        onStopped: {
            if (status === MediaPlayer.EndOfMedia) {
                playback.log(
                    "EndOfMedia -> advance"
                )
                playback.advance()
            }
        }
    }
}
