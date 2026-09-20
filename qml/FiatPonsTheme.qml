pragma Singleton
import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0

QtObject {
    // ---- the switch, remembered between runs ----
    property ConfigurationValue ambientConfig: ConfigurationValue {
        key: "/apps/fiatpons/ambient"
        defaultValue: true
    }
    readonly property bool ambient: ambientConfig.value
    function setAmbient(on) { ambientConfig.value = on }

    // Fiat colours are a light scheme, so dark is false there.
    readonly property bool dark: ambient ? (Theme.colorScheme === Theme.LightOnDark) : false

    readonly property string serif: "Georgia"

    readonly property color primaryText:   ambient ? Theme.primaryColor   : "#1A1A1A"
    readonly property color secondaryText: ambient ? Theme.secondaryColor : Qt.rgba(0.10, 0.10, 0.10, 0.55)
    readonly property color accent:        ambient ? Theme.highlightColor : "#4165BA"

    function mixColor(a, b, t) {
        return Qt.rgba(
            a.r * (1.0 - t) + b.r * t,
            a.g * (1.0 - t) + b.g * t,
            a.b * (1.0 - t) + b.b * t,
            1.0
        )
    }

    // A muted variant of the accent, for the Silica chrome that draws with
    // palette.highlightColor directly -- the pull-down menu's revealed label
    // chief among them. Found on Fiat Mos: a saturated accent used raw there
    // reads far louder as a large glowing fill than it does as a button or a
    // mark. This mutes only that role; everything the app draws itself still
    // uses the full accent above.
    readonly property color chromeAccent: mixColor(accent, primaryText, 0.35)

    readonly property color backgroundHigh: "#F2EFE8"
    readonly property color backgroundLow:  "#D8D2C6"

    readonly property color card: ambient
        ? (dark ? Qt.rgba(0.08, 0.08, 0.08, 1.0) : Qt.rgba(0.96, 0.96, 0.96, 1.0))
        : "#F5F5F5"
    readonly property color surface: card
    readonly property color cardBorder:   Theme.rgba(primaryText, 0.45)
    readonly property color innerBorder:  Theme.rgba(primaryText, 0.22)
    readonly property color recessFill:   Theme.rgba(primaryText, 0.05)
    readonly property color recessBorder: Theme.rgba(primaryText, 0.16)
    readonly property real cardRadius: Theme.paddingLarge * 2
    readonly property int cardBorderWidth: 2

    readonly property color pillFill:         Theme.rgba(primaryText, 0.15)
    readonly property color pillBorder:       Theme.rgba(primaryText, 0.55)
    readonly property color pillFillActive:   Theme.rgba(accent, 0.15)
    readonly property color pillBorderActive: Theme.rgba(accent, 0.45)

    // No semantic colours: nothing in a player is a verdict rather than a state.
    // Errors (e.g. a failed stream) use accent + wording, not a dedicated red.

    // The wash under a pressed row or menu item.
    readonly property color highlightWash: Theme.rgba(accent, 0.15)

    // Taupe, and fixed: Munkstolen's colour, not the app's, so it does not
    // follow the ambience.
    readonly property color makerMark: "#7E7566"

    // ---- header notch handling ----
    function cutoutHeight() {
        if (typeof Screen === "undefined" || Screen === null) return -1
        var c = Screen.topCutout
        if (c === undefined || c === null) return -1
        if (typeof c === "number") return c
        if (c.height !== undefined) return c.height
        return -1
    }

    readonly property real headerTopInsetFallback: Theme.paddingLarge * 1.5
    readonly property real headerTopInset: {
        var c = cutoutHeight()
        return c >= 0 ? c + Theme.paddingMedium : headerTopInsetFallback
    }

    readonly property real statusRowCenter: Theme.itemSizeLarge / 2

    // ---- Silica chrome palette ----
    function applyPalette(item) {
        if (item === null || item === undefined) return
        var p = item.palette
        if (p === undefined || p === null) return
        try { p.colorScheme = ambient ? Theme.colorScheme : Theme.DarkOnLight } catch (e) { }
        try { p.primaryColor = primaryText } catch (e) { }
        try { p.secondaryColor = secondaryText } catch (e) { }
        try { p.highlightColor = chromeAccent } catch (e) { }
        try { p.secondaryHighlightColor = Theme.rgba(chromeAccent, 0.6) } catch (e) { }
        // A neutral wash for in-app selection/highlight surfaces. NOT the
        // virtual keyboard -- that turned out to be a separate surface
        // (Maliit/FutoKeyboard) that reads Theme.*, the system ambience,
        // directly. It cannot be reached from an app's palette at all, so
        // this project does not try; it follows the ambience.
        try { p.highlightBackgroundColor = Theme.rgba(primaryText, 0.12) } catch (e) { }
        try { p.errorColor = "#8A2B25" } catch (e) { }
        try { p.highlightDimmerColor = ambient ? Theme.highlightDimmerColor : backgroundLow } catch (e) { }
        try { p.overlayBackgroundColor = ambient ? Theme.overlayBackgroundColor : backgroundHigh } catch (e) { }
    }

    // Cover layout
    //
    // The whole block was missing — CoverPage.qml already read all five of
    // these, so it was running on undefined. This alone would give Pons the
    // same "strange cover" as Margo/Cor/Glossa, not the "won't start" you
    // reported; something else is layered on top (see the note below, and
    // the request for the actual build/run output).
    readonly property real coverWordmarkTop: Theme.paddingLarge
    readonly property real coverSideMargin: Theme.paddingLarge
    // Pons's figure is the album art, a shape, not a line of text.
    readonly property real coverFigureFractionShape: 0.20
    readonly property real coverArtFraction: 0.5
    readonly property int coverFigureSize: Theme.fontSizeHuge
}
