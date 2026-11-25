# Changelog

## 1.3

This release focuses on smooth playback over weak or unstable connections, especially at high bitrates.

### Added

- Tracks are streamed through a local cache: the track is downloaded to the device ahead of playback, as fast as the connection allows, instead of relying on GStreamer's few seconds of network buffer.
- Interrupted downloads resume where they stopped (HTTP range requests), with automatic reconnects; a connection that goes silent for 15 seconds is dropped and reopened.
- Precache setting: how much audio to download before a track starts, and before it continues after the buffer runs dry (off, 10 s, 30 s, 1 min, 2 min; default 30 s). One longer pause replaces repeated stutters.
- Download-ahead setting: how far ahead of playback to download (1, 3 or 5 minutes, or the whole track; default whole track). A limit saves data when skipping songs; the download also stops at the limit while paused.
- Cache status on the Now Playing page, e.g. "Precaching 42% · 1:23 ahead" or "Fully cached". It can be hidden in Settings.
- "Buffering…" and "Weak connection, reconnecting…" status messages.

### Improved

- After a playback error the track is reloaded automatically with a fresh stream URL, resuming at the last position played.
- Starting playback and resuming at a position now wait longer for data on slow connections before reporting a failure.

### Fixed

- A dropped connection could end a track early and skip to the next one.

## 0.3

This release focuses on playback stability, audio quality controls, and improved Sailfish OS integration.

### Added

- MPRIS integration and lock-screen media controls.
- Play, pause, previous, and next controls from the lock screen.
- Four selectable streaming quality levels:
  - MP3 320 kbps
  - CD quality, 16-bit / 44.1 kHz
  - Hi-Res, up to 24-bit / 96 kHz
  - Hi-Res Max, up to 24-bit / 192 kHz
- Display of the audio quality actually delivered by the stream.
- Required Sailjail audio permission.
- An About page with project information and acknowledgements.

### Improved

- Audio quality changes now preserve the playback position.
- Audio quality changes now preserve the current play or pause state.
- More reliable switching to another track while playback is active.
- Delayed and verified playback startup after asynchronous GStreamer stream changes.

### Fixed

- Fixed playback sometimes failing after selecting another track.
- Fixed initial album cover handling on the album page.

### Notes

Track information and detailed credits are not included in this release. They are planned for a future version.
