use serde::Serialize;
use serde_json::Value;

use qbz_models::Quality;
use qbz_qobuz::QobuzClient;
use std::path::PathBuf;
use std::time::Duration;
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::TcpListener;

pub struct Core {
    client: QobuzClient,
}

#[derive(Serialize)]
pub struct FpTrack {
    pub id: u64,
    pub playlist_track_id: u64,
    pub title: String,
    pub artist: String,
    pub album: String,
    pub duration_secs: u32,
    pub cover_url: String,
}

#[derive(Serialize)]
pub struct FpStream {
    pub url: String,
    pub mime: String,
    pub sample_rate: f64,
    pub bit_depth: Option<u32>,
}

#[derive(Serialize)]
pub struct FpAlbum {
    pub id: String,
    pub title: String,
    pub artist: String,
    pub artist_id: u64,
    pub cover_url: String,
    pub year: String,
    pub track_count: u32,
    pub duration_secs: u32,
    pub label: String,
}

#[derive(Serialize)]
pub struct FpArtist {
    pub id: u64,
    pub name: String,
    pub image_url: String,
    pub bio: String,
    pub bio_full: String,
}

#[derive(Serialize)]
pub struct FpPlaylist {
    pub id: u64,
    pub name: String,
    pub image_url: String,
    pub track_count: u32,
    pub is_public: bool,
}

#[derive(Serialize)]
pub struct FavouritesPayload {
    pub tracks: Vec<FpTrack>,
    pub albums: Vec<FpAlbum>,
    pub artists: Vec<FpArtist>,
}

#[derive(Serialize)]
pub struct FpDiscoverAlbum {
    pub id: String,
    pub title: String,
    pub artist: String,
    pub artist_id: u64,
    pub cover_url: String,
    pub year: String,
}

#[derive(Serialize)]
pub struct FpDiscoverSection {
    pub key: String,
    pub title: String,
    pub endpoint: String,
    pub has_more: bool,
    pub albums: Vec<FpDiscoverAlbum>,
}

#[derive(Serialize)]
pub struct FpDiscoverPage {
    pub albums: Vec<FpDiscoverAlbum>,
    pub has_more: bool,
}

#[derive(Serialize)]
pub struct FpGenre {
    pub id: u64,
    pub name: String,
}

impl Core {
    pub async fn new() -> Result<Self, String> {
        let client = QobuzClient::new().map_err(|e| e.to_string())?;
        client.init().await.map_err(|e| e.to_string())?;
        Ok(Self { client })
    }

    pub async fn login_with_token(&self, token: &str) -> Result<(), String> {
        self.client
            .login_with_token(token)
            .await
            .map_err(|e| e.to_string())?;
        Ok(())
    }

    pub async fn search(&self, query: &str) -> Result<Vec<FpTrack>, String> {
        let page = self
            .client
            .search_tracks(query, 40, 0, None)
            .await
            .map_err(|e| e.to_string())?;

        Ok(page.items.iter().map(to_fp_track).collect())
    }

    pub async fn search_albums(&self, query: &str) -> Result<Vec<FpAlbum>, String> {
        let page = self
            .client
            .search_albums(query, 40, 0, None)
            .await
            .map_err(|e| e.to_string())?;

        Ok(page.items.iter().map(to_fp_album).collect())
    }

    pub async fn search_artists(&self, query: &str) -> Result<Vec<FpArtist>, String> {
        let page = self
            .client
            .search_artists(query, 40, 0, None)
            .await
            .map_err(|e| e.to_string())?;

        Ok(page.items.iter().map(to_fp_artist).collect())
    }

    pub async fn stream_url(&self, track_id: u64) -> Result<FpStream, String> {
        self.stream_url_quality(track_id, "lossless").await
    }

    pub async fn stream_url_quality(
        &self,
        track_id: u64,
        quality_name: &str,
    ) -> Result<FpStream, String> {
        let quality = match quality_name {
            "mp3" => Quality::Mp3,
            "lossless" | "cd" => Quality::Lossless,
            "hires" => Quality::HiRes,
            "ultrahires" => Quality::UltraHiRes,
            _ => return Err(format!(
                "unsupported stream quality: {quality_name}"
            )),
        };

        let stream = self
            .client
            .get_stream_url(track_id, quality)
            .await
            .map_err(|error| error.to_string())?;

        Ok(FpStream {
            url: stream.url,
            mime: stream.mime_type,
            sample_rate: stream.sampling_rate,
            bit_depth: stream.bit_depth,
        })
    }

    pub async fn album(&self, album_id: &str) -> Result<(FpAlbum, Vec<FpTrack>), String> {
        let album = self
            .client
            .get_album(album_id)
            .await
            .map_err(|e| e.to_string())?;

        let fp_album = to_fp_album(&album);

        let artist = fp_album.artist.clone();
        let title = fp_album.title.clone();
        let cover = fp_album.cover_url.clone();

        let tracks = album
            .tracks
            .as_ref()
            .map(|tc| {
                tc.items
                    .iter()
                    .map(|t| track_from_album(t, &artist, &title, &cover))
                    .collect()
            })
            .unwrap_or_else(Vec::new);

        Ok((fp_album, tracks))
    }

    pub async fn artist(&self, artist_id: u64) -> Result<(FpArtist, Vec<FpAlbum>), String> {
        let artist = self
            .client
            .get_artist(artist_id, true)
            .await
            .map_err(|e| e.to_string())?;

        let value = serde_json::to_value(&artist)
            .map_err(|e| e.to_string())?;

        let fp_artist = to_fp_artist(&artist);
        let albums = value
            .get("albums")
            .and_then(|v| v.get("items"))
            .and_then(|v| v.as_array())
            .map(|items| items.iter().map(album_from_value).collect())
            .unwrap_or_else(Vec::new);

        Ok((fp_artist, albums))
    }

    pub async fn radio_artist(&self, artist_id: u64) -> Result<Vec<FpTrack>, String> {
        let r = self
            .client
            .get_radio_artist(&artist_id.to_string())
            .await
            .map_err(|e| e.to_string())?;

        Ok(r.tracks.items.iter().map(to_fp_track).collect())
    }

    pub async fn user_playlists(&self) -> Result<Vec<FpPlaylist>, String> {
        let playlists = self
            .client
            .get_user_playlists()
            .await
            .map_err(|e| e.to_string())?;

        Ok(playlists
            .iter()
            .filter_map(|p| serde_json::to_value(p).ok())
            .map(|v| playlist_from_value(&v))
            .collect())
    }

    pub async fn playlist(&self, playlist_id: u64) -> Result<(FpPlaylist, Vec<FpTrack>), String> {
        let playlist = self
            .client
            .get_playlist(playlist_id)
            .await
            .map_err(|e| e.to_string())?;

        let value = serde_json::to_value(&playlist).map_err(|e| e.to_string())?;
        let fp_playlist = playlist_from_value(&value);

        let tracks = value
            .get("tracks")
            .and_then(|v| v.get("items"))
            .and_then(|v| v.as_array())
            .map(|items| items.iter().map(track_from_value).collect())
            .unwrap_or_else(Vec::new);

        Ok((fp_playlist, tracks))
    }

    pub async fn favourites(&self, mode: &str) -> Result<FavouritesPayload, String> {
        match mode {
            "tracks" => {
                let raw = self
                    .client
                    .get_favorites("tracks", 50, 0)
                    .await
                    .map_err(|e| e.to_string())?;

                let tracks = raw
                    .get("tracks")
                    .and_then(|v| v.get("items"))
                    .and_then(|v| v.as_array())
                    .map(|items| items.iter().map(track_from_value).collect())
                    .unwrap_or_else(Vec::new);

                Ok(FavouritesPayload {
                    tracks,
                    albums: Vec::new(),
                    artists: Vec::new(),
                })
            }

            "albums" => {
                let raw = self
                    .client
                    .get_favorites("albums", 50, 0)
                    .await
                    .map_err(|e| e.to_string())?;

                let albums = raw
                    .get("albums")
                    .and_then(|v| v.get("items"))
                    .and_then(|v| v.as_array())
                    .map(|items| items.iter().map(album_from_value).collect())
                    .unwrap_or_else(Vec::new);

                Ok(FavouritesPayload {
                    tracks: Vec::new(),
                    albums,
                    artists: Vec::new(),
                })
            }

            "artists" => {
                let raw = self
                    .client
                    .get_favorites("artists", 50, 0)
                    .await
                    .map_err(|e| e.to_string())?;

                let values = raw
                    .get("artists")
                    .and_then(|v| v.get("items"))
                    .and_then(|v| v.as_array())
                    .cloned()
                    .unwrap_or_else(Vec::new);

                let mut artists = Vec::new();

                for value in values {
                    let parsed: Result<qbz_models::Artist, _> =
                        serde_json::from_value(value.clone());

                    let mut artist = match parsed {
                        Ok(parsed_artist) => to_fp_artist(&parsed_artist),
                        Err(_) => basic_artist_from_value(&value),
                    };

                    if artist.id > 0
                        && (artist.name.is_empty()
                            || artist.image_url.is_empty())
                    {
                        if let Ok(detail) =
                            self.client.get_artist(artist.id, false).await
                        {
                            let detailed = to_fp_artist(&detail);

                            if artist.name.is_empty() {
                                artist.name = detailed.name;
                            }

                            if artist.image_url.is_empty() {
                                artist.image_url = detailed.image_url;
                            }

                            if artist.bio.is_empty() {
                                artist.bio = detailed.bio;
                            }

                            if artist.bio_full.is_empty() {
                                artist.bio_full = detailed.bio_full;
                            }
                        }
                    }

                    if artist.id > 0 {
                        artists.push(artist);
                    }
                }

                Ok(FavouritesPayload {
                    tracks: Vec::new(),
                    albums: Vec::new(),
                    artists,
                })
            }
            _ => Err(format!("unknown favourites mode: {mode}")),
        }
    }


    fn token_file() -> Result<PathBuf, String> {
        let home = std::env::var("HOME")
            .map_err(|_| "HOME is not set".to_string())?;

        Ok(PathBuf::from(home)
            .join(".local/share/se.munkstolen/harbour-fiatpons/token"))
    }

    fn write_token(token: &str) -> Result<(), String> {
        let path = Self::token_file()?;

        if let Some(parent) = path.parent() {
            std::fs::create_dir_all(parent)
                .map_err(|e| e.to_string())?;
        }

        std::fs::write(&path, token)
            .map_err(|e| e.to_string())?;

        #[cfg(unix)]
        {
            use std::os::unix::fs::PermissionsExt;

            std::fs::set_permissions(
                &path,
                std::fs::Permissions::from_mode(0o600),
            )
            .map_err(|e| e.to_string())?;
        }

        Ok(())
    }

    pub fn logout() -> Result<(), String> {
        let path = Self::token_file()?;

        match std::fs::remove_file(&path) {
            Ok(()) => Ok(()),
            Err(error) if error.kind() == std::io::ErrorKind::NotFound => Ok(()),
            Err(error) => Err(error.to_string()),
        }
    }

    pub fn has_token_file() -> bool {
        Self::token_file()
            .map(|path| path.exists())
            .unwrap_or(false)
    }

    pub async fn oauth_url(
        &self,
        port: u16,
    ) -> Result<String, String> {
        let app_id = self
            .client
            .app_id()
            .await
            .map_err(|error| {
                format!("app_id unavailable: {error}")
            })?;

        let redirect = format!(
            "http://localhost:{port}"
        );

        Ok(format!(
            "https://www.qobuz.com/signin/oauth?ext_app_id={}&redirect_url={}",
            app_id,
            urlencoding::encode(&redirect),
        ))
    }

    pub async fn login_with_code_and_save(
        &self,
        code: &str,
    ) -> Result<String, String> {
        let code = code.trim();

        if code.is_empty() {
            return Err(
                "empty OAuth authorization code".into()
            );
        }

        let session = self
            .client
            .login_with_oauth_code(code)
            .await
            .map_err(|error| {
                format!("token exchange failed: {error}")
            })?;

        Self::write_token(
            &session.user_auth_token
        )?;

        if session.display_name.is_empty() {
            Ok("Qobuz".to_string())
        } else {
            Ok(session.display_name)
        }
    }

    pub async fn login_browser_and_save(&self) -> Result<String, String> {
        let app_id = self
            .client
            .app_id()
            .await
            .map_err(|e| format!("app_id unavailable: {e}"))?;

        let listener = TcpListener::bind("127.0.0.1:0")
            .await
            .map_err(|e| format!("could not bind localhost: {e}"))?;

        let port = listener
            .local_addr()
            .map_err(|e| e.to_string())?
            .port();

        let redirect = format!("http://localhost:{port}");

        let oauth_url = format!(
            "https://www.qobuz.com/signin/oauth?ext_app_id={}&redirect_url={}",
            app_id,
            urlencoding::encode(&redirect),
        );

        open::that(&oauth_url)
            .map_err(|e| format!("could not open browser: {e}"))?;

        let code = tokio::time::timeout(
            Duration::from_secs(180),
            capture_oauth_code(listener),
        )
        .await
        .map_err(|_| "OAuth login timed out".to_string())?
        .ok_or_else(|| "OAuth login cancelled or no code received".to_string())?;

        let session = self
            .client
            .login_with_oauth_code(&code)
            .await
            .map_err(|e| format!("token exchange failed: {e}"))?;

        Self::write_token(&session.user_auth_token)?;

        Ok(if session.display_name.is_empty() { "Qobuz".to_string() } else { session.display_name })
    }

    pub async fn discover_featured(
        &self,
    ) -> Result<Vec<FpDiscoverSection>, String> {
        let response = self
            .client
            .get_discover_index(None)
            .await
            .map_err(|error| error.to_string())?;

        let containers = response.containers;
        let mut sections = Vec::new();

        if let Some(container) = containers.album_of_the_week {
            sections.push(discover_section(
                "albumOfTheWeek",
                "Albums of the Week",
                "/discover/albumOfTheWeek",
                container,
                2,
            ));
        }

        if let Some(container) = containers.new_releases {
            sections.push(discover_section(
                "newReleases",
                "New Releases",
                "/discover/newReleases",
                container,
                2,
            ));
        }

        if let Some(container) = containers.qobuzissims {
            sections.push(discover_section(
                "qobuzissims",
                "Qobuzissimes",
                "/discover/qobuzissims",
                container,
                2,
            ));
        }

        if let Some(container) = containers.press_awards {
            sections.push(discover_section(
                "pressAward",
                "Press Accolades",
                "/discover/pressAward",
                container,
                2,
            ));
        }

        if let Some(container) = containers.most_streamed {
            sections.push(discover_section(
                "mostStreamed",
                "Most Streamed",
                "/discover/mostStreamed",
                container,
                2,
            ));
        }

        if let Some(container) = containers.ideal_discography {
            sections.push(discover_section(
                "idealDiscography",
                "Ideal Discography",
                "/discover/idealDiscography",
                container,
                2,
            ));
        }

        sections.retain(|section| !section.albums.is_empty());
        Ok(sections)
    }

    pub async fn discover_albums(
        &self,
        endpoint: &str,
        genre_id: u64,
        offset: u32,
        limit: u32,
    ) -> Result<FpDiscoverPage, String> {
        let genres = if genre_id == 0 {
            None
        } else {
            Some(vec![genre_id])
        };

        let response = self
            .client
            .get_discover_albums(
                endpoint,
                genres,
                offset,
                limit,
            )
            .await
            .map_err(|error| error.to_string())?;

        Ok(FpDiscoverPage {
            albums: response
                .items
                .into_iter()
                .map(to_fp_discover_album)
                .collect(),
            has_more: response.has_more,
        })
    }

    pub async fn discover_genres(
        &self,
    ) -> Result<Vec<FpGenre>, String> {
        let mut genres: Vec<FpGenre> = self
            .client
            .get_genres(None)
            .await
            .map_err(|error| error.to_string())?
            .into_iter()
            .map(|genre| FpGenre {
                id: genre.id,
                name: genre.name,
            })
            .collect();

        genres.sort_by(|left, right| {
            left.name
                .to_lowercase()
                .cmp(&right.name.to_lowercase())
        });

        Ok(genres)
    }

    pub async fn create_playlist(
        &self,
        name: &str,
        initial_track_id: Option<u64>,
    ) -> Result<FpPlaylist, String> {
        let name = name.trim();

        if name.is_empty() {
            return Err("playlist name cannot be empty".into());
        }

        let playlist = self
            .client
            .create_playlist(name, None, false)
            .await
            .map_err(|e| e.to_string())?;

        if let Some(track_id) = initial_track_id {
            self.client
                .add_tracks_to_playlist(playlist.id, &[track_id])
                .await
                .map_err(|e| e.to_string())?;
        }

        let value = serde_json::to_value(&playlist)
            .map_err(|e| e.to_string())?;

        Ok(playlist_from_value(&value))
    }

    pub async fn add_track_to_playlist(
        &self,
        playlist_id: u64,
        track_id: u64,
    ) -> Result<(), String> {
        self.client
            .add_tracks_to_playlist(playlist_id, &[track_id])
            .await
            .map_err(|e| e.to_string())
    }

    pub async fn create_playlist_visible(
        &self,
        name: &str,
        initial_track_id: Option<u64>,
        is_public: bool,
    ) -> Result<FpPlaylist, String> {
        let name = name.trim();

        if name.is_empty() {
            return Err("playlist name cannot be empty".into());
        }

        let playlist = self
            .client
            .create_playlist(name, None, is_public)
            .await
            .map_err(|error| error.to_string())?;

        if let Some(track_id) = initial_track_id {
            self.client
                .add_tracks_to_playlist(playlist.id, &[track_id])
                .await
                .map_err(|error| error.to_string())?;
        }

        let value = serde_json::to_value(&playlist)
            .map_err(|error| error.to_string())?;

        Ok(playlist_from_value(&value))
    }

    pub async fn remove_playlist_track(
        &self,
        playlist_id: u64,
        playlist_track_id: u64,
    ) -> Result<(), String> {
        if playlist_track_id == 0 {
            return Err("missing playlist track id".into());
        }

        self.client
            .remove_tracks_from_playlist(
                playlist_id,
                &[playlist_track_id],
            )
            .await
            .map_err(|error| error.to_string())
    }

    pub async fn set_playlist_public(
        &self,
        playlist_id: u64,
        is_public: bool,
    ) -> Result<FpPlaylist, String> {
        let playlist = self
            .client
            .update_playlist(
                playlist_id,
                None,
                None,
                Some(is_public),
            )
            .await
            .map_err(|error| error.to_string())?;

        let value = serde_json::to_value(&playlist)
            .map_err(|error| error.to_string())?;

        Ok(playlist_from_value(&value))
    }

    async fn restore_playlist_tracks(
        &self,
        playlist_id: u64,
        original_track_ids: &[u64],
    ) -> Result<(), String> {
        let current = self
            .client
            .get_playlist(playlist_id)
            .await
            .map_err(|error| error.to_string())?;

        let current_playlist_track_ids: Vec<u64> = current
            .tracks
            .as_ref()
            .map(|container| {
                container
                    .items
                    .iter()
                    .filter_map(|track| track.playlist_track_id)
                    .collect()
            })
            .unwrap_or_default();

        if !current_playlist_track_ids.is_empty() {
            self.client
                .remove_tracks_from_playlist(
                    playlist_id,
                    &current_playlist_track_ids,
                )
                .await
                .map_err(|error| error.to_string())?;
        }

        if !original_track_ids.is_empty() {
            self.client
                .add_tracks_to_playlist(
                    playlist_id,
                    original_track_ids,
                )
                .await
                .map_err(|error| error.to_string())?;
        }

        Ok(())
    }

    pub async fn save_playlist_order(
        &self,
        playlist_id: u64,
        ordered_track_ids: &[u64],
    ) -> Result<(), String> {
        let current = self
            .client
            .get_playlist(playlist_id)
            .await
            .map_err(|error| error.to_string())?;

        let current_tracks = current
            .tracks
            .as_ref()
            .map(|container| container.items.as_slice())
            .unwrap_or(&[]);

        let original_track_ids: Vec<u64> = current_tracks
            .iter()
            .map(|track| track.id)
            .collect();

        let playlist_track_ids: Vec<u64> = current_tracks
            .iter()
            .filter_map(|track| track.playlist_track_id)
            .collect();

        if original_track_ids.len() != playlist_track_ids.len() {
            return Err(
                "one or more tracks lack playlist_track_id".into()
            );
        }

        let mut expected = original_track_ids.clone();
        let mut requested = ordered_track_ids.to_vec();

        expected.sort_unstable();
        requested.sort_unstable();

        if expected != requested {
            return Err(
                "new order does not contain the same tracks".into()
            );
        }

        self.client
            .remove_tracks_from_playlist(
                playlist_id,
                &playlist_track_ids,
            )
            .await
            .map_err(|error| error.to_string())?;

        if let Err(error) = self
            .client
            .add_tracks_to_playlist(
                playlist_id,
                ordered_track_ids,
            )
            .await
        {
            let restore = self
                .restore_playlist_tracks(
                    playlist_id,
                    &original_track_ids,
                )
                .await;

            return match restore {
                Ok(()) => Err(format!(
                    "could not save order; original restored: {error}"
                )),
                Err(restore_error) => Err(format!(
                    "could not save order and restore failed:                      {error}; restore: {restore_error}"
                )),
            };
        }

        let verification = self
            .client
            .get_playlist_track_ids(playlist_id)
            .await
            .map_err(|error| error.to_string())?;

        if verification.track_ids != ordered_track_ids {
            let restore = self
                .restore_playlist_tracks(
                    playlist_id,
                    &original_track_ids,
                )
                .await;

            return match restore {
                Ok(()) => Err(
                    "Qobuz returned a different order;                      original restored"
                        .into()
                ),
                Err(error) => Err(format!(
                    "order verification failed and restore failed:                      {error}"
                )),
            };
        }

        Ok(())
    }

    pub async fn item_favourite_state(
        &self,
        item_type: &str,
        item_id: &str,
    ) -> Result<bool, String> {
        let branch = match item_type {
            "track" => "tracks",
            "album" => "albums",
            "artist" => "artists",
            _ => return Err(format!(
                "unsupported favourite type: {item_type}"
            )),
        };

        let raw = self
            .client
            .get_favorites(branch, 500, 0)
            .await
            .map_err(|e| e.to_string())?;

        let items = raw
            .get(branch)
            .and_then(|value| value.get("items"))
            .and_then(|value| value.as_array());

        Ok(items
            .map(|items| {
                items.iter().any(|item| {
                    item.get("id")
                        .map(|id| {
                            if let Some(value) = id.as_str() {
                                value == item_id
                            } else if let Some(value) = id.as_u64() {
                                value.to_string() == item_id
                            } else {
                                false
                            }
                        })
                        .unwrap_or(false)
                })
            })
            .unwrap_or(false))
    }

    pub async fn set_item_favourite(
        &self,
        item_type: &str,
        item_id: &str,
        favourite: bool,
    ) -> Result<(), String> {
        match item_type {
            "track" | "album" | "artist" => {}
            _ => return Err(format!(
                "unsupported favourite type: {item_type}"
            )),
        }

        if favourite {
            self.client
                .add_favorite(item_type, item_id)
                .await
                .map_err(|e| e.to_string())
        } else {
            self.client
                .remove_favorite(item_type, item_id)
                .await
                .map_err(|e| e.to_string())
        }
    }

    pub async fn track_favourite_state(
        &self,
        track_id: u64,
    ) -> Result<bool, String> {
        let raw = self
            .client
            .get_favorites("tracks", 500, 0)
            .await
            .map_err(|e| e.to_string())?;

        let items = raw
            .get("tracks")
            .and_then(|value| value.get("items"))
            .and_then(|value| value.as_array());

        Ok(items
            .map(|tracks| {
                tracks.iter().any(|track| {
                    track.get("id")
                        .and_then(|id| {
                            id.as_u64().or_else(|| {
                                id.as_str()
                                    .and_then(|value| value.parse::<u64>().ok())
                            })
                        })
                        == Some(track_id)
                })
            })
            .unwrap_or(false))
    }

    pub async fn set_track_favourite(
        &self,
        track_id: u64,
        favourite: bool,
    ) -> Result<(), String> {
        let track_id = track_id.to_string();

        if favourite {
            self.client
                .add_favorite("track", &track_id)
                .await
                .map_err(|e| e.to_string())
        } else {
            self.client
                .remove_favorite("track", &track_id)
                .await
                .map_err(|e| e.to_string())
        }
    }
}


async fn capture_oauth_code(listener: TcpListener) -> Option<String> {
    loop {
        let (mut stream, _) = listener.accept().await.ok()?;

        let mut buf = [0u8; 8192];
        let n = stream.read(&mut buf).await.ok()?;

        let request = String::from_utf8_lossy(&buf[..n]);

        let target = request
            .lines()
            .next()
            .and_then(|line| line.split_whitespace().nth(1))
            .unwrap_or("");

        let code = query_param(target, "code_autorisation")
            .or_else(|| query_param(target, "code"));

        let body = if code.is_some() {
            "<html><body><h1>FiatPons login complete</h1><p>You can return to FiatPons.</p></body></html>"
        } else {
            "<html><body><h1>FiatPons</h1><p>No OAuth code found.</p></body></html>"
        };

        let response = format!(
            "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{}",
            body.as_bytes().len(),
            body,
        );

        let _ = stream.write_all(response.as_bytes()).await;
        let _ = stream.shutdown().await;

        if code.is_some() {
            return code;
        }
    }
}

fn query_param(target: &str, key: &str) -> Option<String> {
    let query = target.split('?').nth(1)?;

    for part in query.split('&') {
        let mut pieces = part.splitn(2, '=');
        let k = pieces.next().unwrap_or("");
        let v = pieces.next().unwrap_or("");

        if k == key {
            return urlencoding::decode(v)
                .ok()
                .map(|decoded| decoded.to_string());
        }
    }

    None
}

fn discover_section(
    key: &str,
    title: &str,
    endpoint: &str,
    container: qbz_models::DiscoverContainer<
        qbz_models::DiscoverAlbum
    >,
    preview_count: usize,
) -> FpDiscoverSection {
    let has_more =
        container.data.has_more
        || container.data.items.len() > preview_count;

    let albums = container
        .data
        .items
        .into_iter()
        .take(preview_count)
        .map(to_fp_discover_album)
        .collect();

    FpDiscoverSection {
        key: key.to_string(),
        title: title.to_string(),
        endpoint: endpoint.to_string(),
        has_more,
        albums,
    }
}

fn to_fp_discover_album(
    album: qbz_models::DiscoverAlbum,
) -> FpDiscoverAlbum {
    let artist = album
        .artists
        .first()
        .map(|artist| artist.name.clone())
        .unwrap_or_default();

    let artist_id = album
        .artists
        .first()
        .map(|artist| artist.id)
        .unwrap_or_default();

    let cover_url = album
        .image
        .large
        .or(album.image.thumbnail)
        .or(album.image.small)
        .unwrap_or_default();

    let year = album
        .dates
        .as_ref()
        .and_then(|dates| {
            dates
                .original
                .as_ref()
                .or(dates.download.as_ref())
                .or(dates.stream.as_ref())
        })
        .and_then(|date| date.get(0..4))
        .unwrap_or_default()
        .to_string();

    FpDiscoverAlbum {
        id: album.id,
        title: album.title,
        artist,
        artist_id,
        cover_url,
        year,
    }
}

fn to_fp_track(t: &qbz_models::Track) -> FpTrack {
    let album = t.album.as_ref();

    let artist = t
        .performer
        .as_ref()
        .map(|a| a.name.clone())
        .filter(|n| !n.is_empty())
        .unwrap_or_default();

    FpTrack {
        id: t.id,
        playlist_track_id: t.playlist_track_id.unwrap_or_default(),
        title: t.title.clone(),
        artist,
        album: album.map(|a| a.title.clone()).unwrap_or_default(),
        duration_secs: t.duration,
        cover_url: album
            .and_then(|a| a.image.large.clone().or_else(|| a.image.small.clone()))
            .unwrap_or_default(),
    }
}

fn track_from_album(
    t: &qbz_models::Track,
    artist: &str,
    album_title: &str,
    cover: &str,
) -> FpTrack {
    let own_artist = t
        .performer
        .as_ref()
        .map(|a| a.name.clone())
        .filter(|n| !n.is_empty())
        .unwrap_or_else(|| artist.to_string());

    FpTrack {
        id: t.id,
        playlist_track_id: t.playlist_track_id.unwrap_or_default(),
        title: t.title.clone(),
        artist: own_artist,
        album: album_title.to_string(),
        duration_secs: t.duration,
        cover_url: cover.to_string(),
    }
}

fn to_fp_album(a: &qbz_models::Album) -> FpAlbum {
    FpAlbum {
        id: a.id.clone(),
        title: a.title.clone(),
        artist: a.artist.name.clone(),
        artist_id: a.artist.id,
        cover_url: a.image.large.clone().or_else(|| a.image.small.clone()).unwrap_or_default(),
        year: a
            .release_date_original
            .as_ref()
            .map(|d| d.chars().take(4).collect())
            .unwrap_or_default(),
        track_count: a.tracks_count.unwrap_or_default(),
        duration_secs: a.duration.unwrap_or_default(),
        label: a.label.as_ref().map(|l| l.name.clone()).unwrap_or_default(),
    }
}

fn to_fp_artist(a: &qbz_models::Artist) -> FpArtist {
    FpArtist {
        id: a.id,
        name: a.name.clone(),
        image_url: a
            .image
            .as_ref()
            .and_then(|i| i.large.clone().or_else(|| i.small.clone()))
            .unwrap_or_default(),
        bio: a
            .biography
            .as_ref()
            .and_then(|b| b.summary.clone())
            .unwrap_or_default(),
        bio_full: a
            .biography
            .as_ref()
            .and_then(|b| b.content.clone())
            .or_else(|| {
                a.biography
                    .as_ref()
                    .and_then(|b| b.summary.clone())
            })
            .unwrap_or_default(),
    }
}

fn s(v: &Value, key: &str) -> String {
    v.get(key)
        .and_then(|x| x.as_str())
        .unwrap_or_default()
        .to_string()
}

fn u(v: &Value, key: &str) -> u64 {
    v.get(key).and_then(|x| x.as_u64()).unwrap_or_default()
}

fn u32v(v: &Value, key: &str) -> u32 {
    v.get(key)
        .and_then(|x| x.as_u64())
        .map(|x| x as u32)
        .unwrap_or_default()
}

fn image_url(v: &Value) -> String {
    v.get("image")
        .and_then(|i| {
            i.get("large")
                .and_then(|x| x.as_str())
                .or_else(|| i.get("small").and_then(|x| x.as_str()))
                .or_else(|| i.as_str())
        })
        .or_else(|| {
            v.get("images")
                .and_then(|i| i.as_array())
                .and_then(|a| a.first())
                .and_then(|x| x.as_str())
        })
        .unwrap_or_default()
        .to_string()
}

fn track_from_value(v: &Value) -> FpTrack {
    let album = v.get("album");
    let performer = v.get("performer");

    let artist = performer
        .and_then(|p| p.get("name"))
        .and_then(|x| x.as_str())
        .or_else(|| v.get("artist").and_then(|a| a.get("name")).and_then(|x| x.as_str()))
        .unwrap_or_default()
        .to_string();

    let album_title = album
        .and_then(|a| a.get("title"))
        .and_then(|x| x.as_str())
        .unwrap_or_default()
        .to_string();

    let cover_url = album.map(image_url).unwrap_or_default();

    FpTrack {
        id: u(v, "id"),
        playlist_track_id: u(v, "playlist_track_id"),
        title: s(v, "title"),
        artist,
        album: album_title,
        duration_secs: u32v(v, "duration"),
        cover_url,
    }
}

fn album_from_value(v: &Value) -> FpAlbum {
    let artist = v.get("artist");

    let release = s(v, "release_date_original");
    let year = release.chars().take(4).collect();

    FpAlbum {
        id: s(v, "id"),
        title: s(v, "title"),
        artist: artist
            .and_then(|a| a.get("name"))
            .and_then(|x| x.as_str())
            .unwrap_or_default()
            .to_string(),
        artist_id: artist
            .and_then(|a| a.get("id"))
            .and_then(|x| x.as_u64())
            .unwrap_or_default(),
        cover_url: image_url(v),
        year,
        track_count: u32v(v, "tracks_count"),
        duration_secs: u32v(v, "duration"),
        label: v
            .get("label")
            .and_then(|l| l.get("name"))
            .and_then(|x| x.as_str())
            .unwrap_or_default()
            .to_string(),
    }
}

fn value_as_string(v: &Value, key: &str) -> String {
    v.get(key)
        .and_then(|value| {
            if let Some(text) = value.as_str() {
                Some(text.to_string())
            } else {
                value.as_u64().map(|number| number.to_string())
            }
        })
        .unwrap_or_default()
}

fn artist_id_from_value(v: &Value) -> u64 {
    let source = v.get("artist").unwrap_or(v);

    source
        .get("id")
        .and_then(|value| {
            if let Some(number) = value.as_u64() {
                Some(number)
            } else {
                value
                    .as_str()
                    .and_then(|text| text.parse().ok())
            }
        })
        .unwrap_or_default()
}

fn artist_image_from_value(v: &Value) -> String {
    let source = v.get("artist").unwrap_or(v);

    source
        .get("image")
        .and_then(|image| {
            image
                .as_str()
                .or_else(|| image.get("mega").and_then(|x| x.as_str()))
                .or_else(|| image.get("extralarge").and_then(|x| x.as_str()))
                .or_else(|| image.get("large").and_then(|x| x.as_str()))
                .or_else(|| image.get("medium").and_then(|x| x.as_str()))
                .or_else(|| image.get("small").and_then(|x| x.as_str()))
                .or_else(|| image.get("thumbnail").and_then(|x| x.as_str()))
        })
        .or_else(|| {
            source
                .get("picture")
                .and_then(|value| value.as_str())
        })
        .or_else(|| {
            source
                .get("image_url")
                .and_then(|value| value.as_str())
        })
        .unwrap_or_default()
        .to_string()
}

fn basic_artist_from_value(v: &Value) -> FpArtist {
    let source = v.get("artist").unwrap_or(v);

    FpArtist {
        id: artist_id_from_value(v),
        name: value_as_string(source, "name"),
        image_url: artist_image_from_value(v),
        bio: String::new(),
        bio_full: String::new(),
    }
}

fn image_size_hint(url: &str) -> u32 {
    let filename = url
        .rsplit('/')
        .next()
        .unwrap_or(url);

    let stem = filename
        .split('.')
        .next()
        .unwrap_or(filename);

    stem
        .rsplit('_')
        .next()
        .and_then(|part| part.parse().ok())
        .unwrap_or_default()
}

fn playlist_image_url(v: &Value) -> String {
    let mut best = String::new();
    let mut best_score = 0;

    let mut consider = |url: &str| {
        if url.is_empty() {
            return;
        }

        let score = image_size_hint(url);

        if best.is_empty() || score > best_score {
            best = url.to_string();
            best_score = score;
        }
    };

    if let Some(images) = v.get("images") {
        if let Some(rectangle) = images.get("rectangle") {
            if let Some(url) = rectangle.as_str() {
                consider(url);
            }

            if let Some(urls) = rectangle.as_array() {
                for value in urls {
                    if let Some(url) = value.as_str() {
                        consider(url);
                    }
                }
            }
        }

        if let Some(covers) = images.get("covers") {
            if let Some(url) = covers.as_str() {
                consider(url);
            }

            if let Some(urls) = covers.as_array() {
                for value in urls {
                    if let Some(url) = value.as_str() {
                        consider(url);
                    }
                }
            }
        }

        for key in [
            "mega",
            "extralarge",
            "large",
            "medium",
            "small",
            "thumbnail",
        ] {
            if let Some(url) = images
                .get(key)
                .and_then(|value| value.as_str())
            {
                consider(url);
            }
        }
    }

    if best.is_empty() {
        image_url(v)
    } else {
        best
    }
}

fn playlist_from_value(v: &Value) -> FpPlaylist {
    FpPlaylist {
        id: u(v, "id"),
        name: s(v, "name"),
        image_url: playlist_image_url(v),
        track_count: u32v(v, "tracks_count"),
        is_public: v
            .get("is_public")
            .and_then(|value| value.as_bool())
            .unwrap_or(false),
    }
}
