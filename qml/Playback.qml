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
    // Ticks spent waiting on the network during a verified start; these do
    // not count as failed attempts.
    property int trackStartWaitTicks: 0

    // Automatic recovery after a network error: reload the same track and
    // resume at the last position that actually played.
    property int lastGoodPosition: -1
    property int recoveryAttempts: 0
    property bool recoveryLoad: false
    readonly property int maxRecoveryAttempts: 8

    readonly property string bufferingText: "Buffering\u2026"
    readonly property string reconnectingText: "Weak connection, reconnecting\u2026"

    // Precache status for the Now Playing page, e.g.
    // "Precaching 42% \u00B7 1:23 ahead" or "Fully cached".
    readonly property bool cacheAvailable:
        typeof streamCache !== "undefined" && streamCache !== null
    // Seconds of audio to cache before playing (setting, 0 = off).
    property int precacheSeconds: 30
    // True while playback is held back until enough is cached.
    property bool precaching: false
    property int precacheWaitTicks: 0

    // Show cacheText on the Now Playing page (setting).
    property bool showCacheStatus: true

    function setShowCacheStatus(value) {
        showCacheStatus = value
        backend.setShowCacheStatus(value)
    }

    // Seconds to download ahead of the player (setting, 0 = whole track).
    property int readAheadSeconds: 0

    // The limit in bytes for the current track, from its average bitrate.
    // Never below the precache amount plus a margin, or precaching could
    // wait for data the limit forbids.
    readonly property real readAheadBytes: {
        if (!cacheAvailable || readAheadSeconds <= 0)
            return 0

        var total = streamCache.totalBytes
        if (total <= 0 || knownDuration <= 0)
            return 0

        var seconds = Math.max(readAheadSeconds, precacheSeconds + 30)
        return Math.round(total * seconds * 1000 / knownDuration)
    }

    onReadAheadBytesChanged: {
        if (cacheAvailable)
            streamCache.setReadAheadBytes(readAheadBytes)
    }

    function setReadAheadSeconds(value) {
        readAheadSeconds = Math.max(0, Math.min(3600, Math.round(value)))
        backend.setReadAheadSeconds(readAheadSeconds)
    }

    // Track length: from the player once known, else from the catalogue.
    readonly property int knownDuration:
        duration > 0 ? duration
        : (nowTrack && nowTrack.duration_secs
           ? nowTrack.duration_secs * 1000 : 0)

    readonly property string cacheText: {
        if (!cacheAvailable || !nowTrack || streamCache.totalBytes <= 0)
            return ""

        var total = streamCache.totalBytes
        var start = streamCache.cachedStart
        var end = streamCache.cachedEnd
        var ahead = cacheAheadMs()

        if (precaching) {
            return "Precaching " + fmtTime(Math.max(0, ahead))
                    + " / " + fmtTime(precacheTargetMs())
                    + " before playing"
        }

        if (streamCache.cacheComplete && start <= 0)
            return "Fully cached"

        var text = "Precaching " + Math.floor(100 * (end - start) / total) + "%"

        if (ahead >= 0)
            text += " \u00B7 " + fmtTime(ahead) + " ahead"

        return text
    }

    function fmtTime(ms) {
        var s = Math.floor(Math.max(0, ms) / 1000)
        var sec = s % 60
        return Math.floor(s / 60) + ":" + (sec < 10 ? "0" : "") + sec
    }

    // Milliseconds of audio cached past the playhead, -1 if unknown.
    // FLAC is variable bitrate, so bytes to time is an estimate.
    function cacheAheadMs() {
        if (!cacheAvailable || streamCache.totalBytes <= 0 || knownDuration <= 0)
            return -1

        if (streamCache.cacheComplete && streamCache.cachedStart <= 0)
            return Math.max(0, knownDuration - position)

        return Math.max(
            0,
            streamCache.cachedEnd / streamCache.totalBytes * knownDuration
            - position
        )
    }

    // Never ask for more than what is left of the track.
    function precacheTargetMs() {
        return Math.min(
            precacheSeconds * 1000,
            Math.max(0, knownDuration - position - 1000)
        )
    }

    function enoughCached() {
        if (precacheSeconds <= 0 || !cacheAvailable)
            return true

        // Playing straight from Qobuz (proxy unavailable): nothing to wait on.
        if (String(player.source).indexOf("http://127.0.0.1:") !== 0)
            return true

        if (streamCache.cacheComplete)
            return true

        var ahead = cacheAheadMs()
        return ahead >= 0 && ahead >= precacheTargetMs()
    }

    function setPrecacheSeconds(value) {
        precacheSeconds = Math.max(0, Math.min(300, Math.round(value)))
        backend.setPrecacheSeconds(precacheSeconds)
    }

    function stopPrecaching() {
        precaching = false
        precacheWaitTicks = 0
        rebufferTimer.stop()
    }

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

    function load(playAfterResolve, positionAfterResolve, isRecovery) {
        if (playAfterResolve === undefined)
            playAfterResolve = true

        if (positionAfterResolve === undefined)
            positionAfterResolve = -1

        recoveryLoad = isRecovery === true
        recoveryTimer.stop()

        if (!recoveryLoad) {
            recoveryAttempts = 0
            lastGoodPosition =
                positionAfterResolve > 0 ? Math.round(positionAfterResolve) : -1
        }

        var t = queue ? queue.currentTrack() : null

        inflightTrack = t
        playWhenResolved = playAfterResolve
        resumeTimer.stop()
        trackStartTimer.stop()
        trackStartIssued = false
        trackStartAttempts = 0
        trackStartConfirmations = 0
        trackStartWaitTicks = 0
        stopPrecaching()
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
            if (!recoveryLoad)
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

        // Pressing play after recovery gave up: start over from where it was.
        if (player.status === MediaPlayer.InvalidMedia
                || player.status === MediaPlayer.NoMedia) {
            load(true, lastGoodPosition)
            return
        }

        player.play()
    }

    // Called on a player error or a premature end of stream.
    function recover(reason) {
        if (!nowTrack || explicitlyStopped)
            return

        if (recoveryAttempts >= maxRecoveryAttempts) {
            log("recovery gave up: " + reason)
            statusLine = "Playback error: " + reason
            shouldPlay = false
            return
        }

        recoveryAttempts += 1

        // 2 s, 4 s, 6 s ... capped at 10 s.
        recoveryTimer.interval =
            Math.min(2000 * recoveryAttempts, 10000)

        log(
            "recover attempt " + recoveryAttempts
            + " in " + recoveryTimer.interval + " ms"
            + " at " + lastGoodPosition + " ms: " + reason
        )

        statusLine = reconnectingText
        recoveryTimer.restart()
    }

    function pause() {
        playWhenResolved = false
        shouldPlay = false
        trackStartTimer.stop()
        recoveryTimer.stop()
        stopPrecaching()

        if (player.playbackState === MediaPlayer.PlayingState)
            player.pause()
    }

    function stop() {
        playWhenResolved = false
        shouldPlay = false
        trackStartTimer.stop()
        recoveryTimer.stop()
        stopPrecaching()
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
        precacheSeconds = backend.precacheSeconds()
        readAheadSeconds = backend.readAheadSeconds()
        showCacheStatus = backend.showCacheStatus()
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

            // Resolving the URL needs the network too.
            if (recoveryLoad) {
                recover(data.error)
                return
            }

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

        // Play through the local caching proxy (see src/streamcache.h). The
        // key ties the cache to track and quality, so a reload after an error
        // keeps what was already downloaded.
        var source = data.url

        if (typeof streamCache !== "undefined" && streamCache) {
            source = streamCache.proxy(
                String(nowTrack ? nowTrack.id : 0) + ":" + preferredQuality,
                data.url
            )
        }

        player.source = source
    }

    Connections {
        target: typeof streamCache !== "undefined" ? streamCache : null

        onReconnectingChanged: {
            if (streamCache.reconnecting) {
                if (playback.statusLine === ""
                        || playback.statusLine === playback.bufferingText)
                    playback.statusLine = playback.reconnectingText
            } else if (playback.statusLine === playback.reconnectingText
                       && !recoveryTimer.running) {
                playback.statusLine = ""
            }
        }
    }

    Timer {
        id: recoveryTimer

        repeat: false
        running: false

        onTriggered: {
            if (!playback.nowTrack || playback.explicitlyStopped)
                return

            playback.load(
                playback.playWhenResolved,
                playback.lastGoodPosition,
                true
            )
        }
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

            // Hold the first play until enough is cached; give up holding
            // after about two minutes and play anyway.
            if (!playback.trackStartIssued
                    && !playback.enoughCached()
                    && playback.precacheWaitTicks < 185) {
                playback.precacheWaitTicks += 1
                playback.precaching = true
                return
            }

            playback.precaching = false

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
                    playback.recoveryAttempts = 0
                    playback.clearTransientStatus()
                    stop()
                }

                return
            }

            playback.trackStartConfirmations = 0

            // Still waiting for data is not a failed start. Allow about 45 s
            // of that before giving up.
            if (playback.waitingForData()
                    && playback.trackStartWaitTicks < 70) {
                playback.trackStartWaitTicks += 1
                player.play()
                return
            }

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

                // ~20 s: on a weak link the header can take a while.
                if (playback.resumeAttempts >= 30) {
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
                    playback.recoveryAttempts = 0
                    playback.clearTransientStatus()

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

            // A seek into a part not downloaded yet waits for the download.
            // Do not seek again while it does.
            if (playback.waitingForData()
                    && playback.resumeAttempts < 30) {
                playback.resumeAttempts += 1
                return
            }

            playback.resumeAttempts += 1

            if (playback.resumeAttempts > 30) {
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

    // The playhead caught up with the download: pause, refill the
    // precache amount, then continue. One longer pause instead of many
    // short stutters.
    Timer {
        id: rebufferTimer

        interval: 500
        repeat: true
        running: false

        onTriggered: {
            if (!playback.playWhenResolved || !playback.nowTrack) {
                playback.stopPrecaching()
                return
            }

            playback.precacheWaitTicks += 1

            if (playback.enoughCached()
                    || playback.precacheWaitTicks > 240) {
                playback.log(
                    "rebuffer done after "
                    + playback.precacheWaitTicks * 500 + " ms"
                )
                playback.stopPrecaching()
                player.play()
            }
        }
    }

    function waitingForData() {
        return player.status === MediaPlayer.Loading
            || player.status === MediaPlayer.Stalled
            || player.status === MediaPlayer.Buffering
    }

    function clearTransientStatus() {
        if (statusLine === bufferingText
                || statusLine === reconnectingText)
            statusLine = ""
    }

    MediaPlayer {
        id: player
        autoPlay: false

        onError: {
            log("ERR " + errorString)
            playback.shouldPlay = false
            trackStartTimer.stop()
            playback.recover(errorString)
        }

        onPositionChanged: {
            // Not while a new track is being resolved: the old one is
            // still playing then.
            if (position > 0
                    && playback.nowTrack
                    && playback.pending === 0
                    && !playback.resumePending)
                playback.lastGoodPosition = position
        }

        onStatusChanged: {
            if (status === MediaPlayer.Stalled
                    && playback.playWhenResolved
                    && playback.precacheSeconds > 0
                    && playbackState === MediaPlayer.PlayingState
                    && !playback.resumePending
                    && !trackStartTimer.running
                    && !rebufferTimer.running
                    && !playback.enoughCached()) {
                playback.log("buffer ran dry, rebuffering")
                player.pause()
                playback.precaching = true
                playback.precacheWaitTicks = 0
                rebufferTimer.start()
            } else if (status === MediaPlayer.Stalled
                    && playback.playWhenResolved
                    && !playback.precaching) {
                if (playback.statusLine === "")
                    playback.statusLine = playback.bufferingText
            } else if (status === MediaPlayer.Buffered
                       && playback.statusLine === playback.bufferingText) {
                playback.statusLine = ""
            }

            playback.finishPendingLoad()
        }

        onSeekableChanged:
            playback.finishPendingLoad()

        onDurationChanged:
            playback.finishPendingLoad()

        onStopped: {
            if (status === MediaPlayer.EndOfMedia) {
                // A broken connection can look like the end of the track.
                // Do not skip ahead when we were nowhere near the end.
                if (playback.duration > 0
                        && playback.lastGoodPosition >= 0
                        && playback.lastGoodPosition
                           < playback.duration - 5000) {
                    playback.log(
                        "EndOfMedia at " + playback.lastGoodPosition
                        + " of " + playback.duration + " -> recover"
                    )
                    playback.recover("stream ended early")
                    return
                }

                playback.log(
                    "EndOfMedia -> advance"
                )
                playback.advance()
            }
        }
    }
}
