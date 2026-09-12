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

    // Transient state used when replacing a stream without losing position.
    property int resumePosition: -1
    property bool resumePending: false
    property int resumeAttempts: 0
    property int resumeConfirmations: 0

    // Verifies that a newly selected track really remains in PlayingState.
    property bool trackStartIssued: false
    property int trackStartAttempts: 0
    property int trackStartConfirmations: 0

    readonly property bool playing:
        player.playbackState === MediaPlayer.PlayingState

    readonly property int position: player.position
    readonly property int duration: player.duration

    function log(m) {
        console.log("[PB] " + m)
    }

    function normalizeQuality(value) {
        if (value === "mp3"
                || value === "lossless"
                || value === "hires"
                || value === "ultrahires")
            return value

        return "lossless"
    }

    function preferredQualityLabel() {
        if (preferredQuality === "mp3")
            return "MP3 320"

        if (preferredQuality === "hires")
            return "Hi-Res (up to 24/96)"

        if (preferredQuality === "ultrahires")
            return "Hi-Res Max (up to 24/192)"

        return "CD (FLAC 16/44.1)"
    }

    function setPreferredQuality(value) {
        value = normalizeQuality(value)

        if (preferredQuality === value)
            return

        var resumePlayback =
            player.playbackState === MediaPlayer.PlayingState

        var savedPosition =
            nowTrack ? player.position : -1

        preferredQuality = value
        backend.setStreamQualityPreference(value)

        if (queue && queue.currentTrack())
            playback.load(resumePlayback, savedPosition)
    }

    Connections {
        target: queue
        onCurrentChanged: playback.load(true)
    }

    function load(playAfterResolve, positionAfterResolve) {
        if (playAfterResolve === undefined)
            playAfterResolve = true

        if (positionAfterResolve === undefined)
            positionAfterResolve = -1

        var t = queue ? queue.currentTrack() : null

        inflightTrack = t
        playWhenResolved = playAfterResolve
        resumeTimer.stop()
        trackStartTimer.stop()
        trackStartIssued = false
        trackStartAttempts = 0
        trackStartConfirmations = 0
        resumeAttempts = 0
        resumeConfirmations = 0
        resumePosition =
            Math.max(-1, Math.round(positionAfterResolve))
        resumePending = resumePosition > 0
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
            resumeTimer.stop()
            trackStartTimer.stop()
            trackStartIssued = false
            trackStartAttempts = 0
            trackStartConfirmations = 0
            resumePosition = -1
            resumePending = false
            resumeAttempts = 0
            resumeConfirmations = 0
            statusLine = ""
        }
    }

    function play() {
        if (!nowTrack)
            return

        explicitlyStopped = false
        playWhenResolved = true
        player.play()
    }

    function pause() {
        playWhenResolved = false
        shouldPlay = false
        trackStartTimer.stop()

        if (player.playbackState === MediaPlayer.PlayingState)
            player.pause()
    }

    function stop() {
        playWhenResolved = false
        shouldPlay = false
        trackStartTimer.stop()
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

    function finishPendingLoad() {
        var ready =
            player.status === MediaPlayer.Loaded
            || player.status === MediaPlayer.Buffered
            || player.status === MediaPlayer.Buffering

        if (!ready)
            return

        if (resumePending) {
            // Start the replacement stream first if the old stream was
            // playing. Actual seeking is delayed until GStreamer has finished
            // replacing its internal stream collection.
            if (shouldPlay) {
                shouldPlay = false

                log(
                    "starting replacement stream before delayed resume"
                )

                play()
            }

            if (!resumeTimer.running) {
                resumeAttempts = 0
                resumeConfirmations = 0
                resumeTimer.start()
            }

            return
        }

        if (shouldPlay
                && !trackStartTimer.running) {
            trackStartIssued = false
            trackStartAttempts = 0
            trackStartConfirmations = 0

            log(
                "scheduling verified start id="
                + (nowTrack ? nowTrack.id : 0)
            )

            trackStartTimer.start()
        }
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
        preferredQuality = normalizeQuality(
            backend.streamQualityPreference()
        )
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

    Timer {
        id: trackStartTimer

        interval: 650
        repeat: true
        running: false

        onTriggered: {
            if (!playback.shouldPlay
                    || !playback.playWhenResolved
                    || !playback.nowTrack) {
                playback.trackStartIssued = false
                playback.trackStartAttempts = 0
                playback.trackStartConfirmations = 0
                stop()
                return
            }

            if (!playback.trackStartIssued) {
                playback.trackStartIssued = true
                playback.trackStartAttempts = 1
                playback.trackStartConfirmations = 0

                playback.log(
                    "verified start attempt 1 id="
                    + playback.nowTrack.id
                )

                player.play()
                return
            }

            if (player.playbackState
                    === MediaPlayer.PlayingState) {
                playback.trackStartConfirmations += 1

                if (playback.trackStartConfirmations >= 2) {
                    playback.log(
                        "track start confirmed id="
                        + playback.nowTrack.id
                    )

                    playback.shouldPlay = false
                    playback.trackStartIssued = false
                    playback.trackStartAttempts = 0
                    playback.trackStartConfirmations = 0
                    stop()
                }

                return
            }

            playback.trackStartConfirmations = 0
            playback.trackStartAttempts += 1

            if (playback.trackStartAttempts > 10) {
                playback.log(
                    "track start failed id="
                    + playback.nowTrack.id
                    + " state="
                    + player.playbackState
                    + " status="
                    + player.status
                )

                playback.shouldPlay = false
                playback.trackStartIssued = false
                playback.trackStartAttempts = 0
                playback.statusLine =
                    "Could not start playback"
                stop()
                return
            }

            playback.log(
                "verified start retry "
                + playback.trackStartAttempts
                + " id="
                + playback.nowTrack.id
                + " state="
                + player.playbackState
                + " status="
                + player.status
            )

            player.play()
        }
    }

    Timer {
        id: resumeTimer

        // Waiting avoids seeking before GStreamer has replaced the old
        // internal stream collection. Repeating also lets us verify that the
        // backend did not subsequently reset the position to zero.
        interval: 650
        repeat: true
        running: false

        onTriggered: {
            if (!playback.resumePending) {
                stop()
                return
            }

            if (player.duration <= 0) {
                playback.resumeAttempts += 1

                if (playback.resumeAttempts >= 12) {
                    playback.log(
                        "resume failed: duration never became available"
                    )

                    playback.resumePending = false
                    playback.resumePosition = -1
                    stop()
                }

                return
            }

            var target = Math.max(
                0,
                Math.min(
                    playback.resumePosition,
                    player.duration
                )
            )

            var difference =
                Math.abs(player.position - target)

            if (difference <= 1500) {
                playback.resumeConfirmations += 1

                // Require two confirmations on separate timer ticks. A seek
                // can appear successful briefly and then be reset by
                // GStreamer while the new stream is still being installed.
                if (playback.resumeConfirmations >= 2) {
                    playback.log(
                        "resume confirmed at "
                        + player.position
                        + " ms (target "
                        + target
                        + " ms)"
                    )

                    playback.resumePending = false
                    playback.resumePosition = -1
                    playback.resumeAttempts = 0
                    playback.resumeConfirmations = 0

                    mpris.seeked(player.position)

                    // Seeking a newly replaced GStreamer stream can leave
                    // MediaPlayer paused. Restore the state that existed
                    // before the quality change.
                    if (playback.playWhenResolved) {
                        playback.log(
                            "continuing playback after confirmed resume"
                        )
                        playback.play()
                    }

                    stop()
                }

                return
            }

            playback.resumeConfirmations = 0
            playback.resumeAttempts += 1

            if (playback.resumeAttempts > 12) {
                playback.log(
                    "resume failed after retries; target="
                    + target
                    + " actual="
                    + player.position
                )

                playback.resumePending = false
                playback.resumePosition = -1
                playback.resumeAttempts = 0
                stop()
                return
            }

            playback.log(
                "resume attempt "
                + playback.resumeAttempts
                + " target="
                + target
                + " actual="
                + player.position
            )

            player.seek(target)
            mpris.seeked(target)
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

        onStatusChanged:
            playback.finishPendingLoad()

        onSeekableChanged:
            playback.finishPendingLoad()

        onDurationChanged:
            playback.finishPendingLoad()

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
