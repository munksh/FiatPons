# fiat pons — an unofficial Qobuz client for Sailfish OS.
#
# The Rust playback core (libfiatpons_ffi.so) is built SEPARATELY via
# build-rust.sh before packaging, and shipped as a prebuilt binary inside the
# source tarball -- this spec does NOT invoke cargo. A generic RPM build
# environment has no aarch64 Rust cross-toolchain configured (the toolchain
# setup that produces that .so is a whole SDK-side procedure of its own; see
# build-rust.sh and the project README). This mirrors how most OpenRepos
# packages with compiled dependencies are done.
#
# Before building a release tarball, always run:
#   ./build-rust.sh
# so rust/target/aarch64-unknown-linux-gnu/release/libfiatpons_ffi.so exists
# and is current, THEN create the tarball (see tools/make-tarball.sh).

Name:       harbour-fiatpons
Summary:    Fiat Pons
Version:    0.3
Release:    1
License:    MIT
URL:        https://github.com/munksh/FiatPons
Source0:    %{name}-%{version}.tar.bz2

Requires:   sailfishsilica-qt5 >= 0.10.9
Requires:   qt5-qtdeclarative-import-multimedia
Requires:   amber-qml-plugin-mpris

BuildRequires:  pkgconfig(sailfishapp) >= 1.0.2
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  pkgconfig(Qt5Network)
BuildRequires:  desktop-file-utils

%description
An unofficial Sailfish OS client for Qobuz. Search, browse albums and
artists, build a queue, keep favourites and playlists, and play music --
all native Silica, all yours, no web view. Requires your own Qobuz
subscription; log in from Settings.

Built on the qbz-qobuz Rust library (MIT), which does the heavy lifting
of talking to Qobuz's API.

%prep
%setup -q -n %{name}-%{version}

%build
%qmake5
make %{?_smp_mflags}

%install
rm -rf %{buildroot}
make install INSTALL_ROOT=%{buildroot}

desktop-file-install --delete-original \
  --dir %{buildroot}%{_datadir}/applications \
  %{buildroot}%{_datadir}/applications/*.desktop

%files
%defattr(-,root,root,-)
%{_bindir}/%{name}
%{_libdir}/libfiatpons_ffi.so
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/86x86/apps/%{name}.png
%{_datadir}/icons/hicolor/108x108/apps/%{name}.png
%{_datadir}/icons/hicolor/128x128/apps/%{name}.png
%{_datadir}/icons/hicolor/172x172/apps/%{name}.png

%changelog
* Sat Sep 12 2026 Caesar <caesar@munkstolen.se> - 0.3-1
- Add MP3, CD, Hi-Res and Hi-Res Max quality options
- Show the audio quality actually delivered by the stream
- Preserve playback position and play/pause state when changing quality
- Improve track switching and asynchronous GStreamer stream changes
- Add Sailjail audio permission
- Fix initial album cover handling

* Fri Sep 11 2026 Caesar <caesar@munkstolen.se> - 0.2-1
- Add MPRIS integration for lock-screen and remote media controls

* Wed Sep 09 2026 Caesar <caesar@munkstolen.se> - 0.2-1
- On-device Qobuz login (browser OAuth)
- Library: favourites, playlists (create/edit), queue
- Discover section
- Streaming quality setting (Lossless / MP3 320)
- Album and artist pages with unified design
- About page

* Sat Sep 05 2026 Caesar <caesar@munkstolen.se> - 0.1-1
- Initial release: search, playback, queue
