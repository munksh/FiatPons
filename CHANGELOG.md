# Changelog

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
