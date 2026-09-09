#ifndef FIATPONS_BACKEND_H
#define FIATPONS_BACKEND_H

#include <QObject>
#include <QThread>
#include <QString>
#include <QSettings>
#include <QtNetwork/QTcpServer>
#include <QtNetwork/QTcpSocket>
#include <QtNetwork/QHostAddress>
#include <QtGui/QDesktopServices>
#include <QtCore/QUrl>
#include <QtCore/QUrlQuery>
#include <QtCore/QJsonDocument>
#include <QtCore/QJsonObject>

extern "C" {
    char *fp_search(const char *query);
    char *fp_search_albums(const char *query);
    char *fp_search_artists(const char *query);
    char *fp_stream_url(unsigned long long track_id);
    char *fp_stream_url_quality(
        unsigned long long track_id,
        const char *quality
    );
    char *fp_album(const char *album_id);
    char *fp_artist(unsigned long long artist_id);
    char *fp_radio_artist(unsigned long long artist_id);
    char *fp_user_playlists();
    char *fp_playlist(unsigned long long playlist_id);
    char *fp_favourites(const char *mode);
    char *fp_oauth_url(
        unsigned short port
    );
    char *fp_login_code(
        const char *code
    );
    char *fp_login_browser();
    char *fp_logout();
    char *fp_is_logged_in();
    char *fp_discover_featured();
    char *fp_discover_albums(
        const char *endpoint,
        unsigned long long genre_id,
        unsigned int offset,
        unsigned int limit
    );
    char *fp_discover_genres();
    char *fp_create_playlist(
        const char *name,
        unsigned long long initial_track_id
    );
    char *fp_add_track_to_playlist(
        unsigned long long playlist_id,
        unsigned long long track_id
    );
    char *fp_create_playlist_visible(
        const char *name,
        unsigned long long initial_track_id,
        bool is_public
    );
    char *fp_remove_playlist_track(
        unsigned long long playlist_id,
        unsigned long long playlist_track_id
    );
    char *fp_set_playlist_public(
        unsigned long long playlist_id,
        bool is_public
    );
    char *fp_save_playlist_order(
        unsigned long long playlist_id,
        const char *ordered_track_ids
    );
    char *fp_item_favourite_state(
        const char *item_type,
        const char *item_id
    );
    char *fp_set_item_favourite(
        const char *item_type,
        const char *item_id,
        bool favourite
    );
    char *fp_track_favourite_state(
        unsigned long long track_id
    );
    char *fp_set_track_favourite(
        unsigned long long track_id,
        bool favourite
    );
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

    void doStreamUrlQuality(
        qulonglong id,
        const QString &quality
    ) {
        QByteArray encoded = quality.toUtf8();

        char *raw = fp_stream_url_quality(
            id,
            encoded.constData()
        );

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

    void doOAuthUrl(quint16 port) {
        char *raw = fp_oauth_url(port);
        QString out = QString::fromUtf8(raw);
        fp_free(raw);
        emit oauthUrlDone(out);
    }

    void doLoginCode(const QString &code) {
        QByteArray encoded = code.toUtf8();

        char *raw = fp_login_code(
            encoded.constData()
        );

        QString out = QString::fromUtf8(raw);
        fp_free(raw);
        emit loginCodeDone(out);
    }

    void doLoginBrowser() {
        char *raw = fp_login_browser();
        QString out = QString::fromUtf8(raw);
        fp_free(raw);
        emit loginComplete(out);
    }

    void doLogout() {
        char *raw = fp_logout();
        QString out = QString::fromUtf8(raw);
        fp_free(raw);
        emit logoutComplete(out);
    }

    void doIsLoggedIn() {
        char *raw = fp_is_logged_in();
        QString out = QString::fromUtf8(raw);
        fp_free(raw);
        emit isLoggedInComplete(out);
    }

    void doDiscoverFeatured() {
        char *raw = fp_discover_featured();
        QString out = QString::fromUtf8(raw);
        fp_free(raw);
        emit discoverFeaturedDone(out);
    }

    void doDiscoverAlbums(
        const QString &endpoint,
        qulonglong genreId,
        uint offset,
        uint limit
    ) {
        QByteArray encoded = endpoint.toUtf8();

        char *raw = fp_discover_albums(
            encoded.constData(),
            genreId,
            offset,
            limit
        );

        QString out = QString::fromUtf8(raw);
        fp_free(raw);
        emit discoverAlbumsDone(out);
    }

    void doDiscoverGenres() {
        char *raw = fp_discover_genres();
        QString out = QString::fromUtf8(raw);
        fp_free(raw);
        emit discoverGenresDone(out);
    }

    void doCreatePlaylist(
        const QString &name,
        qulonglong initialTrackId
    ) {
        QByteArray encoded = name.toUtf8();
        char *raw = fp_create_playlist(
            encoded.constData(),
            initialTrackId
        );
        QString out = QString::fromUtf8(raw);
        fp_free(raw);
        emit createPlaylistDone(out);
    }

    void doAddTrackToPlaylist(
        qulonglong playlistId,
        qulonglong trackId
    ) {
        char *raw = fp_add_track_to_playlist(
            playlistId,
            trackId
        );
        QString out = QString::fromUtf8(raw);
        fp_free(raw);
        emit addTrackToPlaylistDone(out);
    }

    void doCreatePlaylistVisible(
        const QString &name,
        qulonglong initialTrackId,
        bool isPublic
    ) {
        QByteArray encoded = name.toUtf8();
        char *raw = fp_create_playlist_visible(
            encoded.constData(),
            initialTrackId,
            isPublic
        );
        QString out = QString::fromUtf8(raw);
        fp_free(raw);
        emit createPlaylistVisibleDone(out);
    }

    void doRemovePlaylistTrack(
        qulonglong playlistId,
        qulonglong playlistTrackId
    ) {
        char *raw = fp_remove_playlist_track(
            playlistId,
            playlistTrackId
        );
        QString out = QString::fromUtf8(raw);
        fp_free(raw);
        emit removePlaylistTrackDone(out);
    }

    void doSetPlaylistPublic(
        qulonglong playlistId,
        bool isPublic
    ) {
        char *raw = fp_set_playlist_public(
            playlistId,
            isPublic
        );
        QString out = QString::fromUtf8(raw);
        fp_free(raw);
        emit setPlaylistPublicDone(out);
    }

    void doSavePlaylistOrder(
        qulonglong playlistId,
        const QString &orderedTrackIds
    ) {
        QByteArray encoded = orderedTrackIds.toUtf8();
        char *raw = fp_save_playlist_order(
            playlistId,
            encoded.constData()
        );
        QString out = QString::fromUtf8(raw);
        fp_free(raw);
        emit savePlaylistOrderDone(out);
    }

    void doItemFavouriteState(
        const QString &itemType,
        const QString &itemId
    ) {
        QByteArray type = itemType.toUtf8();
        QByteArray id = itemId.toUtf8();

        char *raw = fp_item_favourite_state(
            type.constData(),
            id.constData()
        );

        QString out = QString::fromUtf8(raw);
        fp_free(raw);
        emit itemFavouriteStateDone(out);
    }

    void doSetItemFavourite(
        const QString &itemType,
        const QString &itemId,
        bool favourite
    ) {
        QByteArray type = itemType.toUtf8();
        QByteArray id = itemId.toUtf8();

        char *raw = fp_set_item_favourite(
            type.constData(),
            id.constData(),
            favourite
        );

        QString out = QString::fromUtf8(raw);
        fp_free(raw);
        emit setItemFavouriteDone(out);
    }

    void doTrackFavouriteState(qulonglong trackId) {
        char *raw = fp_track_favourite_state(trackId);
        QString out = QString::fromUtf8(raw);
        fp_free(raw);
        emit trackFavouriteStateDone(out);
    }

    void doSetTrackFavourite(
        qulonglong trackId,
        bool favourite
    ) {
        char *raw = fp_set_track_favourite(
            trackId,
            favourite
        );
        QString out = QString::fromUtf8(raw);
        fp_free(raw);
        emit setTrackFavouriteDone(out);
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
    void oauthUrlDone(const QString &url);
    void loginCodeDone(const QString &json);
    void loginComplete(const QString &json);
    void logoutComplete(const QString &json);
    void isLoggedInComplete(const QString &json);
    void discoverFeaturedDone(const QString &json);
    void discoverAlbumsDone(const QString &json);
    void discoverGenresDone(const QString &json);
    void createPlaylistDone(const QString &json);
    void addTrackToPlaylistDone(const QString &json);
    void createPlaylistVisibleDone(const QString &json);
    void removePlaylistTrackDone(const QString &json);
    void setPlaylistPublicDone(const QString &json);
    void savePlaylistOrderDone(const QString &json);
    void itemFavouriteStateDone(const QString &json);
    void setItemFavouriteDone(const QString &json);
    void trackFavouriteStateDone(const QString &json);
    void setTrackFavouriteDone(const QString &json);
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
        connect(this, &Backend::requestStreamQuality, worker, &SearchWorker::doStreamUrlQuality);
        connect(this, &Backend::requestAlbum,         worker, &SearchWorker::doAlbum);
        connect(this, &Backend::requestArtist,        worker, &SearchWorker::doArtist);
        connect(this, &Backend::requestRadioArtist,   worker, &SearchWorker::doRadioArtist);
        connect(this, &Backend::requestUserPlaylists, worker, &SearchWorker::doUserPlaylists);
        connect(this, &Backend::requestPlaylist,      worker, &SearchWorker::doPlaylist);
        connect(this, &Backend::requestFavourites,    worker, &SearchWorker::doFavourites);
        connect(this, &Backend::requestOAuthUrl, worker, &SearchWorker::doOAuthUrl);
        connect(this, &Backend::requestLoginCode, worker, &SearchWorker::doLoginCode);
        connect(this, &Backend::requestLogout, worker, &SearchWorker::doLogout);
        connect(this, &Backend::requestIsLoggedIn, worker, &SearchWorker::doIsLoggedIn);
        connect(this, &Backend::requestDiscoverFeatured, worker, &SearchWorker::doDiscoverFeatured);
        connect(this, &Backend::requestDiscoverAlbums, worker, &SearchWorker::doDiscoverAlbums);
        connect(this, &Backend::requestDiscoverGenres, worker, &SearchWorker::doDiscoverGenres);
        connect(this, &Backend::requestCreatePlaylist, worker, &SearchWorker::doCreatePlaylist);
        connect(this, &Backend::requestAddTrackToPlaylist, worker, &SearchWorker::doAddTrackToPlaylist);
        connect(this, &Backend::requestCreatePlaylistVisible, worker, &SearchWorker::doCreatePlaylistVisible);
        connect(this, &Backend::requestRemovePlaylistTrack, worker, &SearchWorker::doRemovePlaylistTrack);
        connect(this, &Backend::requestSetPlaylistPublic, worker, &SearchWorker::doSetPlaylistPublic);
        connect(this, &Backend::requestSavePlaylistOrder, worker, &SearchWorker::doSavePlaylistOrder);
        connect(this, &Backend::requestItemFavouriteState, worker, &SearchWorker::doItemFavouriteState);
        connect(this, &Backend::requestSetItemFavourite, worker, &SearchWorker::doSetItemFavourite);
        connect(this, &Backend::requestTrackFavouriteState, worker, &SearchWorker::doTrackFavouriteState);
        connect(this, &Backend::requestSetTrackFavourite, worker, &SearchWorker::doSetTrackFavourite);

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
        connect(
            worker,
            &SearchWorker::oauthUrlDone,
            this,
            [this](const QString &result) {
                handleOAuthUrl(result);
            }
        );

        connect(
            worker,
            &SearchWorker::loginCodeDone,
            this,
            &Backend::loginComplete
        );

        connect(worker, &SearchWorker::logoutComplete, this, &Backend::logoutComplete);
        connect(worker, &SearchWorker::isLoggedInComplete, this, &Backend::isLoggedInComplete);
        connect(worker, &SearchWorker::discoverFeaturedDone, this, &Backend::discoverFeaturedComplete);
        connect(worker, &SearchWorker::discoverAlbumsDone, this, &Backend::discoverAlbumsComplete);
        connect(worker, &SearchWorker::discoverGenresDone, this, &Backend::discoverGenresComplete);
        connect(worker, &SearchWorker::createPlaylistDone, this, &Backend::createPlaylistComplete);
        connect(worker, &SearchWorker::addTrackToPlaylistDone, this, &Backend::addTrackToPlaylistComplete);
        connect(worker, &SearchWorker::createPlaylistVisibleDone, this, &Backend::createPlaylistVisibleComplete);
        connect(worker, &SearchWorker::removePlaylistTrackDone, this, &Backend::removePlaylistTrackComplete);
        connect(worker, &SearchWorker::setPlaylistPublicDone, this, &Backend::setPlaylistPublicComplete);
        connect(worker, &SearchWorker::savePlaylistOrderDone, this, &Backend::savePlaylistOrderComplete);
        connect(worker, &SearchWorker::itemFavouriteStateDone, this, &Backend::itemFavouriteStateComplete);
        connect(worker, &SearchWorker::setItemFavouriteDone, this, &Backend::setItemFavouriteComplete);
        connect(worker, &SearchWorker::trackFavouriteStateDone, this, &Backend::trackFavouriteStateComplete);
        connect(worker, &SearchWorker::setTrackFavouriteDone, this, &Backend::setTrackFavouriteComplete);

        m_thread.start();
    }

    ~Backend() override {
        m_thread.quit();
        m_thread.wait();
    }

    Q_INVOKABLE void loginProbeStart() {
        QTcpServer *server = new QTcpServer(this);

        connect(
            server,
            &QTcpServer::newConnection,
            this,
            [this, server]() {
                QTcpSocket *socket =
                    server->nextPendingConnection();

                connect(
                    socket,
                    &QTcpSocket::readyRead,
                    this,
                    [this, server, socket]() {
                        QByteArray request =
                            socket->readAll();

                        QByteArray body =
                            "<!doctype html>"
                            "<html>"
                            "<head>"
                            "<meta charset=\"utf-8\">"
                            "<meta name=\"viewport\" "
                            "content=\"width=device-width,"
                            "initial-scale=1\">"
                            "<title>FiatPons</title>"
                            "</head>"
                            "<body style=\"font-family:sans-serif;"
                            "text-align:center;padding:3rem\">"
                            "<h1>FiatPons callback OK</h1>"
                            "<p>You can return to FiatPons.</p>"
                            "</body>"
                            "</html>";

                        QByteArray response =
                            "HTTP/1.1 200 OK\r\n"
                            "Content-Type: text/html; "
                            "charset=utf-8\r\n"
                            "Content-Length: "
                            + QByteArray::number(body.size())
                            + "\r\n"
                            "Connection: close\r\n"
                            "Cache-Control: no-store\r\n"
                            "\r\n"
                            + body;

                        connect(
                            socket,
                            &QTcpSocket::disconnected,
                            server,
                            &QObject::deleteLater
                        );

                        socket->write(response);
                        socket->flush();

                        emit loginProbeComplete(
                            QString(
                                "OK: browser reached the "
                                "localhost callback. "
                                "Request: "
                            )
                            + QString::fromUtf8(
                                request.left(120)
                            )
                        );

                        server->close();
                        socket->disconnectFromHost();
                    }
                );
            }
        );

        if (!server->listen(
                QHostAddress::LocalHost,
                0
        )) {
            emit loginProbeComplete(
                "FAIL: could not bind localhost: "
                + server->errorString()
            );

            server->deleteLater();
            return;
        }

        quint16 port = server->serverPort();

        QUrl url(
            QString(
                "http://localhost:%1/"
                "?code_autorisation=test-code"
            ).arg(port)
        );

        bool opened =
            QDesktopServices::openUrl(url);

        emit loginProbeComplete(
            QString(
                "Waiting on 127.0.0.1:%1. "
                "Browser open: %2"
            )
            .arg(port)
            .arg(opened ? "yes" : "no")
        );
    }

    Q_INVOKABLE QString streamQualityPreference() const {
        QSettings settings(
            "se.munkstolen",
            "harbour-fiatpons"
        );

        QString value = settings.value(
            "playback/streamQuality",
            "lossless"
        ).toString();

        return value == "mp3" ? "mp3" : "lossless";
    }

    Q_INVOKABLE void setStreamQualityPreference(
        const QString &quality
    ) {
        QSettings settings(
            "se.munkstolen",
            "harbour-fiatpons"
        );

        settings.setValue(
            "playback/streamQuality",
            quality == "mp3" ? "mp3" : "lossless"
        );

        settings.sync();
    }

    Q_INVOKABLE void search(const QString &query)        { emit requestSearch(query); }
    Q_INVOKABLE void searchAlbums(const QString &query)  { emit requestSearchAlbums(query); }
    Q_INVOKABLE void searchArtists(const QString &query) { emit requestSearchArtists(query); }
    Q_INVOKABLE void streamUrl(qulonglong id)            { emit requestStream(id); }
    Q_INVOKABLE void streamUrlQuality(
        qulonglong id,
        const QString &quality
    ) {
        emit requestStreamQuality(id, quality);
    }

    Q_INVOKABLE void album(const QString &albumId)       { emit requestAlbum(albumId); }
    Q_INVOKABLE void artist(qulonglong id)               { emit requestArtist(id); }
    Q_INVOKABLE void radioArtist(qulonglong id)          { emit requestRadioArtist(id); }
    Q_INVOKABLE void userPlaylists()                     { emit requestUserPlaylists(); }
    Q_INVOKABLE void playlist(qulonglong id)              { emit requestPlaylist(id); }
    Q_INVOKABLE void favourites(const QString &mode)      { emit requestFavourites(mode); }

    Q_INVOKABLE void loginBrowser() {
        startOAuthBrowser();
    }

    Q_INVOKABLE void logout() {
        emit requestLogout();
    }

    Q_INVOKABLE void isLoggedIn() {
        emit requestIsLoggedIn();
    }

    Q_INVOKABLE void discoverFeatured() {
        emit requestDiscoverFeatured();
    }

    Q_INVOKABLE void discoverAlbums(
        const QString &endpoint,
        qulonglong genreId,
        uint offset,
        uint limit
    ) {
        emit requestDiscoverAlbums(
            endpoint,
            genreId,
            offset,
            limit
        );
    }

    Q_INVOKABLE void discoverGenres() {
        emit requestDiscoverGenres();
    }

    Q_INVOKABLE void createPlaylist(
        const QString &name,
        qulonglong initialTrackId
    ) {
        emit requestCreatePlaylist(name, initialTrackId);
    }

    Q_INVOKABLE void addTrackToPlaylist(
        qulonglong playlistId,
        qulonglong trackId
    ) {
        emit requestAddTrackToPlaylist(playlistId, trackId);
    }

    Q_INVOKABLE void createPlaylistVisible(
        const QString &name,
        qulonglong initialTrackId,
        bool isPublic
    ) {
        emit requestCreatePlaylistVisible(
            name,
            initialTrackId,
            isPublic
        );
    }

    Q_INVOKABLE void removePlaylistTrack(
        qulonglong playlistId,
        qulonglong playlistTrackId
    ) {
        emit requestRemovePlaylistTrack(
            playlistId,
            playlistTrackId
        );
    }

    Q_INVOKABLE void setPlaylistPublic(
        qulonglong playlistId,
        bool isPublic
    ) {
        emit requestSetPlaylistPublic(
            playlistId,
            isPublic
        );
    }

    Q_INVOKABLE void savePlaylistOrder(
        qulonglong playlistId,
        const QString &orderedTrackIds
    ) {
        emit requestSavePlaylistOrder(
            playlistId,
            orderedTrackIds
        );
    }

    Q_INVOKABLE void itemFavouriteState(
        const QString &itemType,
        const QString &itemId
    ) {
        emit requestItemFavouriteState(itemType, itemId);
    }

    Q_INVOKABLE void setItemFavourite(
        const QString &itemType,
        const QString &itemId,
        bool favourite
    ) {
        emit requestSetItemFavourite(
            itemType,
            itemId,
            favourite
        );
    }

    Q_INVOKABLE void trackFavouriteState(
        qulonglong trackId
    ) {
        emit requestTrackFavouriteState(trackId);
    }

    Q_INVOKABLE void setTrackFavourite(
        qulonglong trackId,
        bool favourite
    ) {
        emit requestSetTrackFavourite(trackId, favourite);
    }

signals:
    void requestSearch(const QString &query);
    void requestSearchAlbums(const QString &query);
    void requestSearchArtists(const QString &query);
    void requestStream(qulonglong id);
    void requestStreamQuality(
        qulonglong id,
        const QString &quality
    );
    void requestAlbum(const QString &albumId);
    void requestArtist(qulonglong id);
    void requestRadioArtist(qulonglong id);
    void requestUserPlaylists();
    void requestPlaylist(qulonglong id);
    void requestFavourites(const QString &mode);
    void requestOAuthUrl(quint16 port);
    void requestLoginCode(const QString &code);
    void requestLoginBrowser();
    void requestLogout();
    void requestIsLoggedIn();
    void requestDiscoverFeatured();
    void requestDiscoverAlbums(
        const QString &endpoint,
        qulonglong genreId,
        uint offset,
        uint limit
    );
    void requestDiscoverGenres();
    void requestCreatePlaylist(
        const QString &name,
        qulonglong initialTrackId
    );
    void requestAddTrackToPlaylist(
        qulonglong playlistId,
        qulonglong trackId
    );
    void requestCreatePlaylistVisible(
        const QString &name,
        qulonglong initialTrackId,
        bool isPublic
    );
    void requestRemovePlaylistTrack(
        qulonglong playlistId,
        qulonglong playlistTrackId
    );
    void requestSetPlaylistPublic(
        qulonglong playlistId,
        bool isPublic
    );
    void requestSavePlaylistOrder(
        qulonglong playlistId,
        const QString &orderedTrackIds
    );
    void requestItemFavouriteState(
        const QString &itemType,
        const QString &itemId
    );
    void requestSetItemFavourite(
        const QString &itemType,
        const QString &itemId,
        bool favourite
    );
    void requestTrackFavouriteState(qulonglong trackId);
    void requestSetTrackFavourite(
        qulonglong trackId,
        bool favourite
    );

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
    void loginComplete(const QString &json);
    void logoutComplete(const QString &json);
    void isLoggedInComplete(const QString &json);
    void discoverFeaturedComplete(const QString &json);
    void discoverAlbumsComplete(const QString &json);
    void discoverGenresComplete(const QString &json);
    void createPlaylistComplete(const QString &json);
    void addTrackToPlaylistComplete(const QString &json);
    void createPlaylistVisibleComplete(const QString &json);
    void removePlaylistTrackComplete(const QString &json);
    void setPlaylistPublicComplete(const QString &json);
    void savePlaylistOrderComplete(const QString &json);
    void itemFavouriteStateComplete(const QString &json);
    void setItemFavouriteComplete(const QString &json);
    void trackFavouriteStateComplete(const QString &json);
    void setTrackFavouriteComplete(const QString &json);
    void loginProbeComplete(const QString &json);

private:
    QString loginErrorJson(
        const QString &message
    ) const {
        QJsonObject object;
        object.insert("error", message);

        return QString::fromUtf8(
            QJsonDocument(object)
                .toJson(QJsonDocument::Compact)
        );
    }

    void cleanupOAuthServer() {
        if (!m_oauthServer)
            return;

        m_oauthServer->close();
        m_oauthServer->deleteLater();
        m_oauthServer = nullptr;
    }

    void startOAuthBrowser() {
        cleanupOAuthServer();

        m_oauthServer = new QTcpServer(this);

        connect(
            m_oauthServer,
            &QTcpServer::newConnection,
            this,
            [this]() {
                if (!m_oauthServer)
                    return;

                QTcpSocket *socket =
                    m_oauthServer
                        ->nextPendingConnection();

                connect(
                    socket,
                    &QTcpSocket::readyRead,
                    this,
                    [this, socket]() {
                        QByteArray request =
                            socket->readAll();

                        QString firstLine =
                            QString::fromUtf8(request)
                                .section('\n', 0, 0)
                                .trimmed();

                        QString target =
                            firstLine.section(' ', 1, 1);

                        QUrl callbackUrl(target);
                        QUrlQuery query(callbackUrl);

                        QString code =
                            query.queryItemValue(
                                "code_autorisation"
                            );

                        if (code.isEmpty()) {
                            code = query.queryItemValue(
                                "code"
                            );
                        }

                        bool success = !code.isEmpty();

                        QByteArray body = success
                            ? QByteArray(
                                "<!doctype html>"
                                "<html><body style=\""
                                "font-family:sans-serif;"
                                "text-align:center;"
                                "padding:3rem\">"
                                "<h1>FiatPons login complete"
                                "</h1>"
                                "<p>You can return to "
                                "FiatPons.</p>"
                                "</body></html>"
                            )
                            : QByteArray(
                                "<!doctype html>"
                                "<html><body style=\""
                                "font-family:sans-serif;"
                                "text-align:center;"
                                "padding:3rem\">"
                                "<h1>Login failed</h1>"
                                "<p>No authorization code "
                                "was received.</p>"
                                "</body></html>"
                            );

                        QByteArray response =
                            "HTTP/1.1 200 OK\r\n"
                            "Content-Type: text/html; "
                            "charset=utf-8\r\n"
                            "Content-Length: "
                            + QByteArray::number(
                                body.size()
                            )
                            + "\r\n"
                            "Connection: close\r\n"
                            "Cache-Control: no-store\r\n"
                            "\r\n"
                            + body;

                        socket->write(response);
                        socket->flush();
                        socket->disconnectFromHost();

                        cleanupOAuthServer();

                        if (success) {
                            emit requestLoginCode(code);
                        } else {
                            emit loginComplete(
                                loginErrorJson(
                                    "No OAuth code received"
                                )
                            );
                        }
                    }
                );
            }
        );

        if (!m_oauthServer->listen(
                QHostAddress::LocalHost,
                0
        )) {
            QString error =
                m_oauthServer->errorString();

            cleanupOAuthServer();

            emit loginComplete(
                loginErrorJson(
                    "Could not start callback: "
                    + error
                )
            );
            return;
        }

        emit requestOAuthUrl(
            m_oauthServer->serverPort()
        );
    }

    void handleOAuthUrl(
        const QString &result
    ) {
        if (result.startsWith("ERROR:")) {
            cleanupOAuthServer();

            emit loginComplete(
                loginErrorJson(
                    result.mid(6)
                )
            );
            return;
        }

        if (!QDesktopServices::openUrl(
                QUrl(result)
        )) {
            cleanupOAuthServer();

            emit loginComplete(
                loginErrorJson(
                    "Could not open system browser"
                )
            );
        }
    }

    QTcpServer *m_oauthServer = nullptr;
    QThread m_thread;
};

#endif // FIATPONS_BACKEND_H
