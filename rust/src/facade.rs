use serde::Serialize;
use qbz_models::Quality;
use qbz_qobuz::QobuzClient;

pub struct Core { client: QobuzClient }

#[derive(Serialize)]
pub struct FpTrack {
    pub id: u64,
    pub title: String,
    pub artist: String,
    pub album: String,
    pub duration_secs: u32,
    pub cover_url: String,
}

impl Core {
    pub async fn new() -> Result<Self, String> {
        let client = QobuzClient::new().map_err(|e| e.to_string())?;
        client.init().await.map_err(|e| e.to_string())?;
        Ok(Self { client })
    }

    pub async fn login_with_token(&self, token: &str) -> Result<(), String> {
        self.client.login_with_token(token).await.map_err(|e| e.to_string())?;
        Ok(())
    }

    pub async fn search(&self, query: &str) -> Result<Vec<FpTrack>, String> {
        let page = self.client.search_tracks(query, 40, 0, None)
            .await.map_err(|e| e.to_string())?;
        Ok(page.items.iter().map(to_fp_track).collect())
    }
}

fn to_fp_track(t: &qbz_models::Track) -> FpTrack {
    let album = t.album.as_ref();
    FpTrack {
        id: t.id,
        title: t.title.clone(),
        artist: t.performer.as_ref().map(|a| a.name.clone()).unwrap_or_default(),
        album: album.map(|a| a.title.clone()).unwrap_or_default(),
        duration_secs: t.duration,
        cover_url: album
            .and_then(|a| a.image.large.clone().or_else(|| a.image.small.clone()))
            .unwrap_or_default(),
    }
}