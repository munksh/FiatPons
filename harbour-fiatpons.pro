TARGET = harbour-fiatpons
CONFIG += sailfishapp

SOURCES += src/harbour-fiatpons.cpp
HEADERS += src/backend.h
INCLUDEPATH += $$PWD/src

# ---- Rust FFI library (built on the host — see the cargo step below) ----
# Inside `sfdk build` the sb2 env sets SB2_RUST_TARGET_TRIPLE; on the host it's
# empty, so we fall back to the aarch64 triple we build for. Both point at the
# same directory, so the host-built .so is found either way.
TARGET_TRIPLE = $$(SB2_RUST_TARGET_TRIPLE)
isEmpty(TARGET_TRIPLE): TARGET_TRIPLE = aarch64-unknown-linux-gnu
RUST_LIB_DIR = $$PWD/rust/target/$$TARGET_TRIPLE/release
RUST_LIB = $$RUST_LIB_DIR/libfiatpons_ffi.so

!exists($$RUST_LIB): error("Missing $$RUST_LIB -- build it first (the cargo step).")

LIBS += -L$$RUST_LIB_DIR -lfiatpons_ffi

rustlib.files = $$RUST_LIB
rustlib.path = $$[QT_INSTALL_LIBS]
INSTALLS += rustlib
# ---- end Rust FFI ----

OTHER_FILES += \
    qml/harbour-fiatpons.qml \
    qml/qmldir \
    qml/FiatPonsTheme.qml \
    qml/pages/NowPlayingPage.qml \
    qml/pages/SearchPage.qml \
    qml/pages/PingPage.qml \
    qml/components/PageHead.qml \
    qml/components/EmptyNote.qml \
    qml/cover/FiatPonsCover.qml \
    harbour-fiatpons.desktop \
    rpm/harbour-fiatpons.spec

REQUIRED_FILES = \
    harbour-fiatpons.desktop \
    qml/harbour-fiatpons.qml \
    qml/qmldir \
    qml/FiatPonsTheme.qml \
    qml/pages/NowPlayingPage.qml \
    qml/cover/FiatPonsCover.qml
for(f, REQUIRED_FILES) {
    !exists($$PWD/$$f): error("Missing $$f -- expected it at $$PWD/$$f")
}

DISTFILES += \
    qml/Queue.qml \
    qml/harbour-fiatpons.qml \
    qml/pages/PlayProbe.qml \
    qml/pages/SearchPage.qml \
    qml/pages/PingPage.qml \
    qml/qmldir \
    qml/FiatPonsTheme.qml \
    qml/pages/NowPlayingPage.qml \
    qml/components/PageHead.qml \
    qml/components/EmptyNote.qml \
    qml/cover/FiatPonsCover.qml \
    harbour-fiatpons.desktop \
    rpm/harbour-fiatpons.spec

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172
