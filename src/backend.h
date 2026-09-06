#ifndef FIATPONS_BACKEND_H
#define FIATPONS_BACKEND_H

#include <QObject></Q>
#include <QThread></Q>
#include <QString></Q>

extern "C" {
    char *fp_search(const char *query);
    char *fp_search_albums(const char *query);
    char *fp_search_artists(const char *query);
    char *fp_stream_url(unsigned long long track_id);
    char *fp_album(const char *album_id);
    char *fp_artist(unsigned long long artist_id);
    char *fp_radio_artist(unsigned long long artist_id);
    char *fp_user_playlists();
    char *fp_playlist(unsigned long long playlist_id);
    char *fp_favourites(const char *mode);
    void  fp_free(char *s);
}

class SearchWorker : public QObject
{
    Q_OBJECT

public slots:
    void doSearch(const QString &query) {
        QByteArray q = query.toUtf8();
        char *raw = fp_search(q.constData());
        QString out = QString::fromUtf8(raw);
        fp_free(raw);
        emit searchDone(out);
    }

    void doSearchAlbums(const QString &query) {
        QByteArray q = query.toUtf8();
        char *raw = fp_search_albums(q.constData());
        QString out = QString::fromUtf8(raw);
        fp_free(raw);
        emit albumsDone(out);
    }

    void doSearchArtists(const QString &query) {
        QByteArray q = query.toUtf8();
        char *raw = fp_search_artists(q.constData());
        QString out = QString::fromUtf8(raw);
        fp_free(raw);
        emit artistsDone(out);
    }

    void doStreamUrl(qulonglong id) {
        char *raw = fp_stream_url(id);
        QString out = QString::fromUtf8(raw);
        fp_free(raw);
        emit streamDone(out);
    }

    void doAlbum(const QString &albumId) {
        QByteArray a = albumId.toUtf8();
        char *raw = fp_album(a.constData());
        QString out = QString::fromUtf8(raw);
        fp_free(raw);
        emit albumDone(out);
    }

    void doArtist(qulonglong id) {
        char *raw = fp_artist(id);
        QString out = QString::fromUtf8(raw);
        fp_free(raw);
        emit artistDone(out);
    }

    void doRadioArtist(qulonglong id) {
        char *raw = fp_radio_artist(id);
        QString out = QString::fromUtf8(raw);
        fp_free(raw);
        emit radioArtistDone(out);
    }

    void doUserPlaylists() {
        char *raw = fp_user_playlists();
        QString out = QString::fromUtf8(raw);
        fp_free(raw);
        emit userPlaylistsDone(out);
    }

    void doPlaylist(qulonglong id) {
        char *raw = fp_playlist(id);
        QString out = QString::fromUtf8(raw);
        fp_free(raw);
        emit playlistDone(out);
    }

    void doFavourites(const QString &mode) {
        QByteArray m = mode.toUtf8();
        char *raw = fp_favourites(m.constData());
        QString out = QString::fromUtf8(raw);
        fp_free(raw);
        emit favouritesDone(out);
    }

signals:
    void searchDone(const QString &json);
    void albumsDone(const QString &json);
    void artistsDone(const QString &json);
    void streamDone(const QString &json);
    void albumDone(const QString &json);
    void artistDone(const QString &json);
    void radioArtistDone(const QString &json);
    void userPlaylistsDone(const QString &json);
    void playlistDone(const QString &json);
    void favouritesDone(const QString &json);
};

class Backend : public QObject
{
    Q_OBJECT

public:
    explicit Backend(QObject *parent = nullptr) : QObject(parent) {
        SearchWorker *worker = new SearchWorker;
        worker->moveToThread(&m_thread);

        connect(&m_thread, &QThread::finished, worker, &QObject::deleteLater);

        connect(this, &Backend::requestSearch,        worker, &SearchWorker::doSearch);
        connect(this, &Backend::requestSearchAlbums,  worker, &SearchWorker::doSearchAlbums);
        connect(this, &Backend::requestSearchArtists, worker, &SearchWorker::doSearchArtists);
        connect(this, &Backend::requestStream,        worker, &SearchWorker::doStreamUrl);
        connect(this, &Backend::requestAlbum,         worker, &SearchWorker::doAlbum);
        connect(this, &Backend::requestArtist,        worker, &SearchWorker::doArtist);
        connect(this, &Backend::requestRadioArtist,   worker, &SearchWorker::doRadioArtist);
        connect(this, &Backend::requestUserPlaylists, worker, &SearchWorker::doUserPlaylists);
        connect(this, &Backend::requestPlaylist,      worker, &SearchWorker::doPlaylist);
        connect(this, &Backend::requestFavourites,    worker, &SearchWorker::doFavourites);

        connect(worker, &SearchWorker::searchDone,        this, &Backend::searchComplete);
        connect(worker, &SearchWorker::albumsDone,        this, &Backend::albumsComplete);
        connect(worker, &SearchWorker::artistsDone,       this, &Backend::artistsComplete);
        connect(worker, &SearchWorker::streamDone,        this, &Backend::streamReady);
        connect(worker, &SearchWorker::albumDone,         this, &Backend::albumComplete);
        connect(worker, &SearchWorker::artistDone,        this, &Backend::artistComplete);
        connect(worker, &SearchWorker::radioArtistDone,   this, &Backend::radioArtistComplete);
        connect(worker, &SearchWorker::userPlaylistsDone, this, &Backend::userPlaylistsComplete);
        connect(worker, &SearchWorker::playlistDone,      this, &Backend::playlistComplete);
        connect(worker, &SearchWorker::favouritesDone,    this, &Backend::favouritesComplete);

        m_thread.start();
    }

    ~Backend() override {
        m_thread.quit();
        m_thread.wait();
    }

    Q_INVOKABLE void search(const QString &query)        { emit requestSearch(query); }
    Q_INVOKABLE void searchAlbums(const QString &query)  { emit requestSearchAlbums(query); }
    Q_INVOKABLE void searchArtists(const QString &query) { emit requestSearchArtists(query); }
    Q_INVOKABLE void streamUrl(qulonglong id)            { emit requestStream(id); }
    Q_INVOKABLE void album(const QString &albumId)       { emit requestAlbum(albumId); }
    Q_INVOKABLE void artist(qulonglong id)               { emit requestArtist(id); }
    Q_INVOKABLE void radioArtist(qulonglong id)          { emit requestRadioArtist(id); }
    Q_INVOKABLE void userPlaylists()                     { emit requestUserPlaylists(); }
    Q_INVOKABLE void playlist(qulonglong id)              { emit requestPlaylist(id); }
    Q_INVOKABLE void favourites(const QString &mode)      { emit requestFavourites(mode); }

signals:
    void requestSearch(const QString &query);
    void requestSearchAlbums(const QString &query);
    void requestSearchArtists(const QString &query);
    void requestStream(qulonglong id);
    void requestAlbum(const QString &albumId);
    void requestArtist(qulonglong id);
    void requestRadioArtist(qulonglong id);
    void requestUserPlaylists();
    void requestPlaylist(qulonglong id);
    void requestFavourites(const QString &mode);

    void searchComplete(const QString &json);
    void albumsComplete(const QString &json);
    void artistsComplete(const QString &json);
    void streamReady(const QString &json);
    void albumComplete(const QString &json);
    void artistComplete(const QString &json);
    void radioArtistComplete(const QString &json);
    void userPlaylistsComplete(const QString &json);
    void playlistComplete(const QString &json);
    void favouritesComplete(const QString &json);

private:
    QThread m_thread;
};

#endif // FIATPONS_BACKEND_H
