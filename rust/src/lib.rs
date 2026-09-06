mod facade;
use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::sync::Mutex;
use once_cell::sync::Lazy;
use tokio::runtime::Runtime;
use facade::{Core, FpTrack, FpAlbum, FpArtist, FpPlaylist, FavouritesPayload};

static RT:   Lazy<Runtime>             = Lazy::new(|| Runtime::new().expect("tokio runtime"));
static CORE: Lazy<Mutex<Option<Core>>> = Lazy::new(|| Mutex::new(None));

fn token_path() -> Option<String> {
    let home = std::env::var("HOME").ok()?;
    Some(format!("{home}/.local/share/se.munkstolen/harbour-fiatpons/token"))
}

fn ensure_core(slot: &mut Option<Core>) -> Result<(), String> {
    if slot.is_some() { return Ok(()); }
    let path = token_path().ok_or("no HOME set")?;
    let token = std::fs::read_to_string(&path)
        .map_err(|e| format!("no token file at {path}: {e}"))?
        .trim().to_string();
    if token.is_empty() { return Err("token file is empty".into()); }
    let core = RT.block_on(async {
        let c = Core::new().await?;
        c.login_with_token(&token).await?;
        Ok::<Core, String>(c)
    })?;
    *slot = Some(core);
    Ok(())
}

// ---- FFI surface ----

#[no_mangle]
pub extern "C" fn fp_search(query: *const c_char) -> *mut c_char {
    to_c(build_search(query))
}

#[no_mangle]
pub extern "C" fn fp_search_albums(query: *const c_char) -> *mut c_char {
    to_c(build_search_albums(query))
}

#[no_mangle]
pub extern "C" fn fp_search_artists(query: *const c_char) -> *mut c_char {
    to_c(build_search_artists(query))
}

#[no_mangle]
pub extern "C" fn fp_stream_url(track_id: u64) -> *mut c_char {
    to_c(build_stream(track_id))
}

#[no_mangle]
pub extern "C" fn fp_album(album_id: *const c_char) -> *mut c_char {
    to_c(build_album(album_id))
}

#[no_mangle]
pub extern "C" fn fp_artist(artist_id: u64) -> *mut c_char {
    to_c(build_artist(artist_id))
}

#[no_mangle]
pub extern "C" fn fp_radio_artist(artist_id: u64) -> *mut c_char {
    to_c(build_radio_artist(artist_id))
}

#[no_mangle]
pub extern "C" fn fp_user_playlists() -> *mut c_char {
    to_c(build_user_playlists())
}

#[no_mangle]
pub extern "C" fn fp_playlist(playlist_id: u64) -> *mut c_char {
    to_c(build_playlist(playlist_id))
}

#[no_mangle]
pub extern "C" fn fp_favourites(mode: *const c_char) -> *mut c_char {
    to_c(build_favourites(mode))
}

// ---- builders ----

fn read_cstr(p: *const c_char) -> Result<String, String> {
    if p.is_null() { return Err("null string".into()); }
    match unsafe { CStr::from_ptr(p) }.to_str() {
        Ok(s) => Ok(s.to_string()),
        Err(_) => Err("string not utf-8".into()),
    }
}

fn build_search(query: *const c_char) -> String {
    let q = match read_cstr(query) { Ok(s) => s, Err(e) => return err_json(&e) };
    let mut slot = CORE.lock().unwrap();
    if let Err(e) = ensure_core(&mut slot) { return err_json(&e); }
    match RT.block_on(slot.as_ref().unwrap().search(&q)) {
        Ok(tracks) => tracks_json(&tracks),
        Err(e) => err_json(&e),
    }
}

fn build_search_albums(query: *const c_char) -> String {
    let q = match read_cstr(query) { Ok(s) => s, Err(e) => return err_json(&e) };
    let mut slot = CORE.lock().unwrap();
    if let Err(e) = ensure_core(&mut slot) { return err_json(&e); }
    match RT.block_on(slot.as_ref().unwrap().search_albums(&q)) {
        Ok(albums) => albums_json(&albums),
        Err(e) => err_json(&e),
    }
}

fn build_search_artists(query: *const c_char) -> String {
    let q = match read_cstr(query) { Ok(s) => s, Err(e) => return err_json(&e) };
    let mut slot = CORE.lock().unwrap();
    if let Err(e) = ensure_core(&mut slot) { return err_json(&e); }
    match RT.block_on(slot.as_ref().unwrap().search_artists(&q)) {
        Ok(artists) => artists_json(&artists),
        Err(e) => err_json(&e),
    }
}

fn build_stream(track_id: u64) -> String {
    let mut slot = CORE.lock().unwrap();
    if let Err(e) = ensure_core(&mut slot) { return err_json(&e); }
    match RT.block_on(slot.as_ref().unwrap().stream_url(track_id)) {
        Ok(s) => serde_json::to_string(&s).unwrap_or_else(|e| err_json(&e.to_string())),
        Err(e) => err_json(&e),
    }
}

fn build_album(album_id: *const c_char) -> String {
    let id = match read_cstr(album_id) { Ok(s) => s, Err(e) => return err_json(&e) };
    let mut slot = CORE.lock().unwrap();
    if let Err(e) = ensure_core(&mut slot) { return err_json(&e); }
    match RT.block_on(slot.as_ref().unwrap().album(&id)) {
        Ok((album, tracks)) => album_json(&album, &tracks),
        Err(e) => err_json(&e),
    }
}

fn build_artist(artist_id: u64) -> String {
    let mut slot = CORE.lock().unwrap();
    if let Err(e) = ensure_core(&mut slot) { return err_json(&e); }
    match RT.block_on(slot.as_ref().unwrap().artist(artist_id)) {
        Ok((artist, albums)) => artist_json(&artist, &albums),
        Err(e) => err_json(&e),
    }
}

fn build_radio_artist(artist_id: u64) -> String {
    let mut slot = CORE.lock().unwrap();
    if let Err(e) = ensure_core(&mut slot) { return err_json(&e); }
    match RT.block_on(slot.as_ref().unwrap().radio_artist(artist_id)) {
        Ok(tracks) => tracks_json(&tracks),
        Err(e) => err_json(&e),
    }
}


fn build_user_playlists() -> String {
    let mut slot = CORE.lock().unwrap();

    if let Err(e) = ensure_core(&mut slot) {
        return err_json(&e);
    }

    match RT.block_on(slot.as_ref().unwrap().user_playlists()) {
        Ok(playlists) => playlists_json(&playlists),
        Err(e) => err_json(&e),
    }
}

fn build_playlist(playlist_id: u64) -> String {
    let mut slot = CORE.lock().unwrap();

    if let Err(e) = ensure_core(&mut slot) {
        return err_json(&e);
    }

    match RT.block_on(slot.as_ref().unwrap().playlist(playlist_id)) {
        Ok((playlist, tracks)) => playlist_json(&playlist, &tracks),
        Err(e) => err_json(&e),
    }
}

fn build_favourites(mode: *const c_char) -> String {
    let mode = match read_cstr(mode) {
        Ok(s) => s,
        Err(e) => return err_json(&e),
    };

    let mut slot = CORE.lock().unwrap();

    if let Err(e) = ensure_core(&mut slot) {
        return err_json(&e);
    }

    match RT.block_on(slot.as_ref().unwrap().favourites(&mode)) {
        Ok(payload) => favourites_json(&payload),
        Err(e) => err_json(&e),
    }
}

// ---- JSON envelopes ----

fn tracks_json(tracks: &[FpTrack]) -> String {
    #[derive(serde::Serialize)]
    struct Out<'a> { tracks: &'a [FpTrack] }
    serde_json::to_string(&Out { tracks }).unwrap_or_else(|e| err_json(&e.to_string()))
}

fn albums_json(albums: &[FpAlbum]) -> String {
    #[derive(serde::Serialize)]
    struct Out<'a> { albums: &'a [FpAlbum] }
    serde_json::to_string(&Out { albums }).unwrap_or_else(|e| err_json(&e.to_string()))
}

fn artists_json(artists: &[FpArtist]) -> String {
    #[derive(serde::Serialize)]
    struct Out<'a> { artists: &'a [FpArtist] }
    serde_json::to_string(&Out { artists }).unwrap_or_else(|e| err_json(&e.to_string()))
}

fn album_json(album: &FpAlbum, tracks: &[FpTrack]) -> String {
    #[derive(serde::Serialize)]
    struct Out<'a> { album: &'a FpAlbum, tracks: &'a [FpTrack] }
    serde_json::to_string(&Out { album, tracks }).unwrap_or_else(|e| err_json(&e.to_string()))
}

fn artist_json(artist: &FpArtist, albums: &[FpAlbum]) -> String {
    #[derive(serde::Serialize)]
    struct Out<'a> { artist: &'a FpArtist, albums: &'a [FpAlbum] }
    serde_json::to_string(&Out { artist, albums }).unwrap_or_else(|e| err_json(&e.to_string()))
}


fn playlists_json(playlists: &[FpPlaylist]) -> String {
    #[derive(serde::Serialize)]
    struct Out<'a> {
        playlists: &'a [FpPlaylist],
    }

    serde_json::to_string(&Out { playlists })
        .unwrap_or_else(|e| err_json(&e.to_string()))
}

fn playlist_json(playlist: &FpPlaylist, tracks: &[FpTrack]) -> String {
    #[derive(serde::Serialize)]
    struct Out<'a> {
        playlist: &'a FpPlaylist,
        tracks: &'a [FpTrack],
    }

    serde_json::to_string(&Out { playlist, tracks })
        .unwrap_or_else(|e| err_json(&e.to_string()))
}

fn favourites_json(payload: &FavouritesPayload) -> String {
    serde_json::to_string(payload)
        .unwrap_or_else(|e| err_json(&e.to_string()))
}

fn err_json(msg: &str) -> String {
    format!(r#"{{"error":{}}}"#, serde_json::to_string(msg).unwrap_or_else(|_| "\"error\"".into()))
}

fn to_c(s: String) -> *mut c_char {
    CString::new(s)
        .unwrap_or_else(|_| CString::new(r#"{"error":"nul in output"}"#).unwrap())
        .into_raw()
}

#[no_mangle]
pub extern "C" fn fp_free(s: *mut c_char) {
    if s.is_null() { return; }
    unsafe { drop(CString::from_raw(s)); }
}
