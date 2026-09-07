use serde::Serialize;
use serde_json::Value;

use qbz_models::Quality;
use qbz_qobuz::QobuzClient;

pub struct Core {
    client: QobuzClient,
}

#[derive(Serialize)]
pub struct FpTrack {
    pub id: u64,
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
}

#[derive(Serialize)]
pub struct FpPlaylist {
    pub id: u64,
    pub name: String,
    pub image_url: String,
    pub track_count: u32,
}

#[derive(Serialize)]
pub struct FavouritesPayload {
    pub tracks: Vec<FpTrack>,
    pub albums: Vec<FpAlbum>,
    pub artists: Vec<FpArtist>,
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
        let s = self
            .client
            .get_stream_url(track_id, Quality::Lossless)
            .await
            .map_err(|e| e.to_string())?;

        Ok(FpStream {
            url: s.url,
            mime: s.mime_type,
            sample_rate: s.sampling_rate,
            bit_depth: s.bit_depth,
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

        let fp_artist = to_fp_artist(&artist);

        let value = serde_json::to_value(&artist).map_err(|e| e.to_string())?;
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

                let artists = raw
                    .get("artists")
                    .and_then(|v| v.get("items"))
                    .and_then(|v| v.as_array())
                    .map(|items| items.iter().map(artist_from_value).collect())
                    .unwrap_or_else(Vec::new);

                Ok(FavouritesPayload {
                    tracks: Vec::new(),
                    albums: Vec::new(),
                    artists,
                })
            }

            _ => Err(format!("unknown favourites mode: {mode}")),
        }
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

fn artist_from_value(v: &Value) -> FpArtist {
    FpArtist {
        id: u(v, "id"),
        name: s(v, "name"),
        image_url: image_url(v),
        bio: v
            .get("biography")
            .and_then(|b| b.get("summary"))
            .and_then(|x| x.as_str())
            .unwrap_or_default()
            .to_string(),
    }
}

fn playlist_from_value(v: &Value) -> FpPlaylist {
    FpPlaylist {
        id: u(v, "id"),
        name: s(v, "name"),
        image_url: image_url(v),
        track_count: u32v(v, "tracks_count"),
    }
}
