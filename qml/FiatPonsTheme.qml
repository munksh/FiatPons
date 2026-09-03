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
    readonly property color accent:        ambient ? Theme.highlightColor : "#417B84"

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
        try { p.highlightColor = accent } catch (e) { }
        try { p.secondaryHighlightColor = Theme.rgba(accent, 0.6) } catch (e) { }
        try { p.highlightBackgroundColor = Theme.rgba(primaryText, 0.12) } catch (e) { }
        try { p.errorColor = "#8A2B25" } catch (e) { }
        try { p.highlightDimmerColor = ambient ? Theme.highlightDimmerColor : backgroundLow } catch (e) { }
        try { p.overlayBackgroundColor = ambient ? Theme.overlayBackgroundColor : backgroundHigh } catch (e) { }
    }
}