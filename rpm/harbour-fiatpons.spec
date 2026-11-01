# fiat pons — an unofficial Qobuz client for Sailfish OS.
#
# The Rust core, libfiatpons_ffi.so, is built by build-rust.sh before
# packaging. This spec does not run cargo.

# The Rust library is private to the app: neither provided nor required
# system-wide (Harbour rule).
%define __provides_exclude_from ^%{_datadir}/.*$
%define __requires_exclude ^libfiatpons_ffi.*$

Name:       harbour-fiatpons
Summary:    Fiat Pons
Version:    1.2
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

%if 0%{?_chum}
Title: Fiat Pons
Type: desktop-application
DeveloperName: Munkstolen
Categories:
 - AudioVideo
 - Audio
AIRating: V
AINote: Claude is my typist - I cross review with Mistral, and add the code once it looks good. Architecture, design, on-device testing, releases and maintenance by me; issues and input welcome.
PackageIcon: https://munkstolen.se/SFOS/harbour-fiatpons.png
Screenshots:
 - https://munkstolen.se/SFOS/fiatpons1.png
 - https://munkstolen.se/SFOS/fiatpons2.png
 - https://munkstolen.se/SFOS/fiatpons3.png
 - https://munkstolen.se/SFOS/fiatpons4.png
 - https://munkstolen.se/SFOS/fiatpons5.png
 - https://munkstolen.se/SFOS/fiatpons6.png
Custom:
  Repo: https://github.com/munksh/FiatPons
Links:
  Homepage: https://github.com/munksh/FiatPons
  Bugtracker: https://github.com/munksh/FiatPons/issues
%endif

%prep
%setup -q -n %{name}-%{version}

%build
%qmake5 APP_VERSION=%{version}
make %{?_smp_mflags}

%install
rm -rf %{buildroot}
make install INSTALL_ROOT=%{buildroot}

chmod 644 %{buildroot}%{_datadir}/%{name}/lib/libfiatpons_ffi.so

desktop-file-install --delete-original \
  --dir %{buildroot}%{_datadir}/applications \
  %{buildroot}%{_datadir}/applications/*.desktop

%files
%defattr(-,root,root,-)
%{_bindir}/%{name}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/86x86/apps/%{name}.png
%{_datadir}/icons/hicolor/108x108/apps/%{name}.png
%{_datadir}/icons/hicolor/128x128/apps/%{name}.png
%{_datadir}/icons/hicolor/172x172/apps/%{name}.png

%changelog
* Sun Nov 01 2026 Caesar <caesar@munkstolen.se> - 1.2-1
- fiat penus and fiat tessera added to the family list on the About page
- Family links lead to munkstolen.se

* Mon Oct 26 2026 Caesar <caesar@munkstolen.se> - 1.1-1
- Tapping a track plays it and queues the rest of the list; the context
  menu's Play now still plays a single track
- Play button on albums, playlists and favourite tracks shows pause while
  that list is playing
- Streaming quality is remembered between restarts
- Ready for the Jolla Store: private library location, plain launcher Exec
- Thanks to ozzi- for the code and AngusOfStockholm for the report

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
