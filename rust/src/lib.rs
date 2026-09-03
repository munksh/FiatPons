mod facade;

use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::sync::Mutex;

use once_cell::sync::Lazy;
use tokio::runtime::Runtime;

use facade::{Core, FpTrack};

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

#[no_mangle]
pub extern "C" fn fp_search(query: *const c_char) -> *mut c_char {
    to_c(build_search(query))
}

#[no_mangle]
pub extern "C" fn fp_stream_url(track_id: u64) -> *mut c_char {
    to_c(build_stream(track_id))
}

fn build_search(query: *const c_char) -> String {
    if query.is_null() { return err_json("null query"); }
    let q = match unsafe { CStr::from_ptr(query) }.to_str() {
        Ok(s) => s.to_string(),
        Err(_) => return err_json("query not utf-8"),
    };
    let mut slot = CORE.lock().unwrap();
    if let Err(e) = ensure_core(&mut slot) { return err_json(&e); }
    match RT.block_on(slot.as_ref().unwrap().search(&q)) {
        Ok(tracks) => tracks_json(&tracks),
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

fn tracks_json(tracks: &[FpTrack]) -> String {
    #[derive(serde::Serialize)]
    struct Out<'a> { tracks: &'a [FpTrack] }
    serde_json::to_string(&Out { tracks }).unwrap_or_else(|e| err_json(&e.to_string()))
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