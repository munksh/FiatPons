TARGET = harbour-fiatpons
CONFIG += sailfishapp

SOURCES += src/harbour-fiatpons.cpp
HEADERS += src/backend.h
INCLUDEPATH += $$PWD/src

# ---- Rust FFI library (built on the host via build-rust.sh) ----
TARGET_TRIPLE = $$(SB2_RUST_TARGET_TRIPLE)
isEmpty(TARGET_TRIPLE): TARGET_TRIPLE = aarch64-unknown-linux-gnu
RUST_LIB_DIR = $$PWD/rust/target/$$TARGET_TRIPLE/release
RUST_LIB = $$RUST_LIB_DIR/libfiatpons_ffi.so

!exists($$RUST_LIB): error("Missing $$RUST_LIB -- build it first (build-rust.sh).")

LIBS += -L$$RUST_LIB_DIR -lfiatpons_ffi

rustlib.files = $$RUST_LIB
rustlib.path = $$[QT_INSTALL_LIBS]
INSTALLS += rustlib
# ---- end Rust FFI ----

OTHER_FILES += \
    qml/harbour-fiatpons.qml \
    qml/MainPage.qml \
    qml/Queue.qml \
    qml/Playback.qml \
    qml/FiatPonsTheme.qml \
    qml/qmldir \
    qml/sections/SearchSection.qml \
    qml/sections/NowPlayingSection.qml \
    qml/sections/LibrarySection.qml \
    qml/sections/DiscoverSection.qml \
    qml/pages/QueuePage.qml \
    qml/components/PageHead.qml \
    qml/components/EmptyNote.qml \
    qml/cover/FiatPonsCover.qml \
    harbour-fiatpons.desktop \
    rpm/harbour-fiatpons.spec

REQUIRED_FILES = \
    harbour-fiatpons.desktop \
    qml/harbour-fiatpons.qml \
    qml/MainPage.qml \
    qml/qmldir \
    qml/FiatPonsTheme.qml \
    qml/cover/FiatPonsCover.qml
for(f, REQUIRED_FILES) {
    !exists($$PWD/$$f): error("Missing $$f -- expected it at $$PWD/$$f")
}

DISTFILES += \
    qml/harbour-fiatpons.qml \
    qml/MainPage.qml \
    qml/Queue.qml \
    qml/Playback.qml \
    qml/FiatPonsTheme.qml \
    qml/qmldir \
    qml/sections/SearchSection.qml \
    qml/sections/NowPlayingSection.qml \
    qml/sections/LibrarySection.qml \
    qml/sections/DiscoverSection.qml \
    qml/pages/QueuePage.qml \
    qml/components/PageHead.qml \
    qml/components/EmptyNote.qml \
    qml/cover/FiatPonsCover.qml \
    harbour-fiatpons.desktop \
    rpm/harbour-fiatpons.spec

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172
