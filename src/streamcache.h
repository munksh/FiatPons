#ifndef STREAMCACHE_H
#define STREAMCACHE_H

// Local caching proxy for track streams.
//
// GStreamer's own HTTP buffering (souphttpsrc + queue2) holds only a few
// seconds of hi-res FLAC and gives up after a short outage. Instead, the
// player is pointed at http://127.0.0.1:<port>/s/<id>, and this proxy:
//
//   * downloads the whole track to the app's cache directory as fast as the
//     link allows, so the buffer grows to minutes ahead of the playhead;
//   * resumes an interrupted download with an HTTP Range request, with
//     backoff, and treats a silent connection (no bytes for a while) as dead;
//   * serves the player from disk, holding the connection open, not
//     failing it, while waiting for data.
//
// Everything network/disk related runs in its own thread so the UI never
// waits on a write.

#include <QtCore/QObject>
#include <QtCore/QThread>
#include <QtCore/QTimer>
#include <QtCore/QFile>
#include <QtCore/QDir>
#include <QtCore/QHash>
#include <QtCore/QList>
#include <QtCore/QPointer>
#include <QtCore/QRegularExpression>
#include <QtCore/QStandardPaths>
#include <QtCore/QUrl>
#include <QtCore/QDebug>
#include <QtNetwork/QNetworkAccessManager>
#include <QtNetwork/QNetworkReply>
#include <QtNetwork/QNetworkRequest>
#include <QtNetwork/QTcpServer>
#include <QtNetwork/QTcpSocket>
#include <QtNetwork/QHostAddress>

#include <limits>

namespace StreamTuning {
// A download that delivers nothing for this long is considered dead.
static const int StallTimeoutMs = 15000;
// Reconnect backoff: 0.5 s, 1 s, 2 s, 4 s, then every 8 s.
static const int RetryMinMs = 500;
static const int RetryMaxMs = 8000;
// HTTP errors (expired URL, 403, ...) in a row before the stream is failed,
// so the player can resolve a fresh URL.
static const int MaxHttpErrors = 3;
// A reader this far ahead of the download restarts the download there
// (a seek into a part not downloaded yet).
static const qint64 SeekRestartBytes = 2 * 1024 * 1024;
static const qint64 ChunkBytes = 64 * 1024;
static const qint64 SocketHighWater = 256 * 1024;
// Tracks kept on disk: the current one and the one before it.
static const int MaxEntries = 2;
}

// ---------------------------------------------------------------------------
// One track: a sparse cache file plus the single contiguous byte range
// [validStart, validEnd) that has been downloaded into it.
// ---------------------------------------------------------------------------
class StreamEntry : public QObject
{
    Q_OBJECT

public:
    StreamEntry(int id, const QString &path, QNetworkAccessManager *nam,
                QObject *parent = nullptr)
        : QObject(parent), id(id), path(path), m_nam(nam)
    {
        m_file.setFileName(path);
        m_file.open(QIODevice::ReadWrite | QIODevice::Truncate);

        m_stallTimer.setSingleShot(true);
        m_stallTimer.setInterval(StreamTuning::StallTimeoutMs);
        connect(&m_stallTimer, &QTimer::timeout, this, [this]() {
            qWarning() << "[SC]" << this->id << "download stalled at" << validEnd;
            dropReply();
            scheduleRetry();
        });

        m_retryTimer.setSingleShot(true);
        connect(&m_retryTimer, &QTimer::timeout, this, [this]() {
            startDownload(validEnd);
        });
    }

    ~StreamEntry() override {
        dropReply();
        m_file.close();
        QFile::remove(path);
    }

    const int id;
    const QString path;
    QUrl url;
    qint64 total = -1;
    qint64 validStart = 0;
    qint64 validEnd = 0;
    QByteArray contentType;
    bool headersKnown = false;
    bool complete = false;
    bool failed = false;
    bool reconnecting = false;

    bool isActive() const { return m_active; }

    // Read-ahead limit in bytes past the reader, 0 = whole track.
    void setReadAhead(qint64 bytes) {
        m_readAhead = bytes;
        maybeResume();
    }

    // The player has read up to pos. Resumes a download paused by the
    // read-ahead limit once the lead shrinks to two thirds of it.
    void noteReader(qint64 pos) {
        m_readerPos = pos;
        maybeResume();
    }

    void setUrl(const QString &u) {
        url = QUrl(u);
        failed = false;
        m_httpErrors = 0;
    }

    void setActive(bool active) {
        m_active = active;

        if (!active) {
            dropReply();
            m_retryTimer.stop();
            setReconnecting(false);
            return;
        }

        if (!complete && !m_reply && !m_retryTimer.isActive() && !m_throttled)
            startDownload(validEnd);
    }

    // A reader needs the byte at pos. Restarts the download there when pos
    // is outside of what is, or soon will be, downloaded.
    void ensureCovers(qint64 pos) {
        if (failed || !m_active)
            return;

        bool covered = pos >= validStart && pos < validEnd;
        bool soon = pos >= validStart
                    && pos <= validEnd + StreamTuning::SeekRestartBytes
                    && !complete;

        if (covered)
            return;

        if (soon) {
            if (!m_reply && !m_retryTimer.isActive())
                startDownload(validEnd);
            return;
        }

        if (complete && total >= 0 && pos >= total)
            return;

        qDebug() << "[SC]" << id << "seek outside cache, restart at" << pos;
        complete = false;
        m_retryTimer.stop();
        startDownload(pos);
    }

    bool readAt(qint64 pos, qint64 n, QByteArray &out) {
        if (!m_file.seek(pos))
            return false;
        out = m_file.read(n);
        return !out.isEmpty();
    }

signals:
    void dataAvailable();
    void headersReady();
    void streamFailed();
    void reconnectingChanged(bool reconnecting);

private:
    qint64 lead() const {
        return validEnd - qMax(m_readerPos, validStart);
    }

    void maybeResume() {
        if (!m_throttled)
            return;

        if (m_readAhead > 0 && lead() >= m_readAhead * 2 / 3)
            return;

        m_throttled = false;
        if (m_active && !failed && !complete && !m_reply && !m_retryTimer.isActive()) {
            qDebug() << "[SC]" << id << "read-ahead resumed at" << validEnd;
            startDownload(validEnd);
        }
    }

    void startDownload(qint64 offset) {
        dropReply();
        m_throttled = false;

        if (!m_active || failed)
            return;

        // Continue the current range, or begin a new one elsewhere.
        if (offset != validEnd || offset < validStart) {
            validStart = offset;
            validEnd = offset;
        }

        QNetworkRequest request(url);
        request.setAttribute(QNetworkRequest::FollowRedirectsAttribute, true);
        request.setRawHeader("Range", "bytes=" + QByteArray::number(offset) + "-");

        // Qt 5.6 can flag the network as inaccessible while switching
        // between Wi-Fi and mobile data and then refuse every request.
        m_nam->setNetworkAccessible(QNetworkAccessManager::Accessible);

        m_reply = m_nam->get(request);
        m_replyOffset = offset;
        m_replyChecked = false;

        connect(m_reply, &QNetworkReply::readyRead, this, &StreamEntry::onReadyRead);
        connect(m_reply, &QNetworkReply::finished, this, &StreamEntry::onFinished);

        m_stallTimer.start();
    }

    // Detach first so abort() cannot re-enter onFinished().
    void dropReply() {
        m_stallTimer.stop();

        if (!m_reply)
            return;

        QNetworkReply *reply = m_reply;
        m_reply = nullptr;
        disconnect(reply, nullptr, this, nullptr);
        reply->abort();
        reply->deleteLater();
    }

    int httpStatus() const {
        return m_reply
            ? m_reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt()
            : 0;
    }

    bool checkResponse() {
        m_replyChecked = true;
        int status = httpStatus();

        if (status == 206) {
            static const QRegularExpression re(
                QStringLiteral("bytes\\s+(\\d+)-(\\d+)/(\\d+|\\*)"));
            QRegularExpressionMatch m =
                re.match(QString::fromLatin1(m_reply->rawHeader("Content-Range")));

            if (m.hasMatch()) {
                qint64 start = m.captured(1).toLongLong();
                if (m.captured(3) != QLatin1String("*"))
                    total = m.captured(3).toLongLong();
                if (start != m_replyOffset) {
                    validStart = start;
                    validEnd = start;
                }
            }
        } else if (status == 200) {
            // The server ignored the range: the body starts at byte 0.
            bool ok = false;
            qint64 length =
                m_reply->header(QNetworkRequest::ContentLengthHeader).toLongLong(&ok);
            if (ok)
                total = length;
            validStart = 0;
            validEnd = 0;
        } else {
            return false;
        }

        if (contentType.isEmpty())
            contentType =
                m_reply->header(QNetworkRequest::ContentTypeHeader).toByteArray();

        if (!headersKnown) {
            headersKnown = true;
            emit headersReady();
        }

        return true;
    }

    void onReadyRead() {
        if (!m_reply)
            return;

        if (!m_replyChecked && !checkResponse()) {
            handleHttpError();
            return;
        }

        QByteArray data = m_reply->readAll();
        if (data.isEmpty())
            return;

        if (!m_file.seek(validEnd) || m_file.write(data) != data.size()) {
            qWarning() << "[SC]" << id << "cache write failed:" << m_file.errorString();
            dropReply();
            fail();
            return;
        }
        m_file.flush();
        validEnd += data.size();

        m_stallTimer.start();
        m_retries = 0;
        m_httpErrors = 0;
        setReconnecting(false);

        // Far enough ahead of the player: stop until it catches up.
        if (m_readAhead > 0 && lead() >= m_readAhead
                && (total < 0 || validEnd < total)) {
            qDebug() << "[SC]" << id << "read-ahead limit reached at" << validEnd;
            dropReply();
            m_throttled = true;
        }

        emit dataAvailable();
    }

    void onFinished() {
        if (!m_reply)
            return;

        if (m_reply->error() == QNetworkReply::NoError
                || m_reply->bytesAvailable() > 0)
            onReadyRead();

        if (!m_reply)   // onReadyRead() may have dropped it
            return;

        int status = httpStatus();
        QNetworkReply::NetworkError error = m_reply->error();
        QString errorString = m_reply->errorString();
        dropReply();

        if (total >= 0 && validEnd >= total) {
            complete = true;
            setReconnecting(false);
            qDebug() << "[SC]" << id << "download complete," << total << "bytes";
            emit dataAvailable();
            return;
        }

        if (total < 0 && error == QNetworkReply::NoError && status >= 200 && status < 300) {
            // No length was ever announced; the end of the body is the end.
            total = validEnd;
            complete = true;
            emit dataAvailable();
            return;
        }

        if (status >= 400) {
            handleHttpError(status);
            return;
        }

        qWarning() << "[SC]" << id << "download interrupted at" << validEnd
                   << "of" << total << ":" << errorString;
        scheduleRetry();
    }

    void handleHttpError(int status = -1) {
        if (status < 0)
            status = httpStatus();

        dropReply();
        ++m_httpErrors;
        qWarning() << "[SC]" << id << "HTTP" << status << "attempt" << m_httpErrors;

        if (m_httpErrors >= StreamTuning::MaxHttpErrors) {
            fail();
            return;
        }

        scheduleRetry();
    }

    void scheduleRetry() {
        if (!m_active || failed || complete)
            return;

        int delay = qMin(StreamTuning::RetryMaxMs,
                         StreamTuning::RetryMinMs << qMin(m_retries, 5));
        ++m_retries;

        // A single blip is not worth telling the user about.
        if (m_retries >= 2)
            setReconnecting(true);

        m_retryTimer.start(delay);
    }

    void fail() {
        failed = true;
        m_retryTimer.stop();
        setReconnecting(false);
        qWarning() << "[SC]" << id << "stream failed";
        emit streamFailed();
    }

    void setReconnecting(bool value) {
        if (reconnecting == value)
            return;
        reconnecting = value;
        emit reconnectingChanged(value);
    }

    QNetworkAccessManager *m_nam;
    QFile m_file;
    QNetworkReply *m_reply = nullptr;
    qint64 m_replyOffset = 0;
    bool m_replyChecked = false;
    bool m_active = false;
    int m_retries = 0;
    int m_httpErrors = 0;
    qint64 m_readAhead = 0;
    qint64 m_readerPos = 0;
    bool m_throttled = false;
    QTimer m_stallTimer;
    QTimer m_retryTimer;
};

// ---------------------------------------------------------------------------
// One HTTP connection from the player.
// ---------------------------------------------------------------------------
class StreamProxyEngine;

class ProxyClient : public QObject
{
    Q_OBJECT

public:
    ProxyClient(QTcpSocket *socket, StreamProxyEngine *engine);

private:
    void onReadyRead();
    void sendSimple(const QByteArray &status);
    void sendHeaders();
    void pump();
    void finish();

    QTcpSocket *m_socket;
    StreamProxyEngine *m_engine;
    QPointer<StreamEntry> m_entry;
    QByteArray m_request;
    bool m_parsed = false;
    bool m_headersSent = false;
    bool m_done = false;
    bool m_head = false;
    bool m_rangeRequested = false;
    bool m_suffixRange = false;
    qint64 m_pos = 0;
    qint64 m_end = -1;        // requested last byte, -1 = to the end
    qint64 m_limit = -1;      // one past the last byte to send, -1 = unknown
};

// ---------------------------------------------------------------------------
// Lives in the worker thread: owns the server, the downloads and the files.
// ---------------------------------------------------------------------------
class StreamProxyEngine : public QObject
{
    Q_OBJECT

public:
    explicit StreamProxyEngine(const QString &cacheDir)
        : m_cacheDir(cacheDir) {}

    StreamEntry *entry(int id) const { return m_entries.value(id, nullptr); }

public slots:
    int start() {
        QDir dir(m_cacheDir);
        dir.removeRecursively();   // leftovers from a previous run
        dir.mkpath(QStringLiteral("."));

        m_nam = new QNetworkAccessManager(this);
        m_server = new QTcpServer(this);

        m_progressTimer = new QTimer(this);
        m_progressTimer->setInterval(500);
        connect(m_progressTimer, &QTimer::timeout, this, [this]() {
            reportProgress(false);
        });
        m_progressTimer->start();

        connect(m_server, &QTcpServer::newConnection, this, [this]() {
            while (QTcpSocket *socket = m_server->nextPendingConnection())
                new ProxyClient(socket, this);
        });

        if (!m_server->listen(QHostAddress::LocalHost, 0)) {
            qWarning() << "[SC] proxy listen failed:" << m_server->errorString();
            return 0;
        }

        qDebug() << "[SC] proxy on port" << m_server->serverPort()
                 << "cache" << m_cacheDir;
        return m_server->serverPort();
    }

    void open(int id, const QString &url) {
        StreamEntry *e = m_entries.value(id, nullptr);

        if (!e) {
            e = new StreamEntry(
                id, m_cacheDir + QStringLiteral("/%1.part").arg(id), m_nam, this);
            m_entries.insert(id, e);
            e->setReadAhead(m_readAhead);
            connect(e, &StreamEntry::reconnectingChanged, this, [this, e](bool value) {
                if (m_current == e->id)
                    emit reconnectingChanged(value);
            });
        }

        // Only the current track downloads: on a weak link it needs all of it.
        for (StreamEntry *other : m_entries) {
            if (other != e)
                other->setActive(false);
        }

        m_order.removeAll(id);
        m_order.append(id);
        m_current = id;

        e->setUrl(url);   // a freshly signed URL each time
        e->setActive(true);
        emit reconnectingChanged(e->reconnecting);
        reportProgress(true);

        while (m_order.size() > StreamTuning::MaxEntries) {
            int old = m_order.takeFirst();
            emit entryDropped(old);
            delete m_entries.take(old);
        }
    }

    void setReadAhead(double bytes) {
        m_readAhead = qint64(bytes);
        for (StreamEntry *e : m_entries)
            e->setReadAhead(m_readAhead);
    }

    void stopAll() {
        qDeleteAll(m_entries);
        m_entries.clear();
        m_order.clear();
        if (m_server)
            m_server->close();
        QDir(m_cacheDir).removeRecursively();
    }

signals:
    void reconnectingChanged(bool reconnecting);
    void entryDropped(int id);
    // Byte range of the current track on disk. Doubles: no metatype fuss
    // across threads, and exact far beyond any track size.
    void progress(double start, double end, double total, bool complete);

private:
    void reportProgress(bool force) {
        StreamEntry *e = m_entries.value(m_current, nullptr);
        double start = e ? e->validStart : 0;
        double end = e ? e->validEnd : 0;
        double total = e ? e->total : -1;
        bool complete = e && e->complete;

        if (!force && start == m_lastStart && end == m_lastEnd
                && total == m_lastTotal && complete == m_lastComplete)
            return;

        m_lastStart = start;
        m_lastEnd = end;
        m_lastTotal = total;
        m_lastComplete = complete;
        emit progress(start, end, total, complete);
    }

    qint64 m_readAhead = 0;
    QTimer *m_progressTimer = nullptr;
    double m_lastStart = 0;
    double m_lastEnd = 0;
    double m_lastTotal = -1;
    bool m_lastComplete = false;
    QString m_cacheDir;
    QNetworkAccessManager *m_nam = nullptr;
    QTcpServer *m_server = nullptr;
    QHash<int, StreamEntry *> m_entries;
    QList<int> m_order;
    int m_current = 0;
};

inline ProxyClient::ProxyClient(QTcpSocket *socket, StreamProxyEngine *engine)
    : QObject(engine), m_socket(socket), m_engine(engine)
{
    socket->setParent(this);
    connect(socket, &QTcpSocket::readyRead, this, &ProxyClient::onReadyRead);
    connect(socket, &QTcpSocket::bytesWritten, this, &ProxyClient::pump);
    connect(socket, &QTcpSocket::disconnected, this, &QObject::deleteLater);
}

inline void ProxyClient::onReadyRead() {
    if (m_parsed) {
        m_socket->readAll();
        return;
    }

    m_request += m_socket->readAll();

    if (m_request.size() > 16 * 1024) {
        sendSimple("400 Bad Request");
        return;
    }

    if (!m_request.contains("\r\n\r\n"))
        return;

    m_parsed = true;

    QList<QByteArray> lines = m_request.split('\n');
    QList<QByteArray> first = lines.value(0).trimmed().split(' ');
    QByteArray method = first.value(0);
    QByteArray target = first.value(1);

    if (method != "GET" && method != "HEAD") {
        sendSimple("405 Method Not Allowed");
        return;
    }
    m_head = method == "HEAD";

    static const QRegularExpression pathRe(QStringLiteral("^/s/(\\d+)"));
    QRegularExpressionMatch pm = pathRe.match(QString::fromLatin1(target));
    if (pm.hasMatch())
        m_entry = m_engine->entry(pm.captured(1).toInt());

    if (!m_entry || m_entry->failed) {
        sendSimple("404 Not Found");
        return;
    }

    for (const QByteArray &raw : lines) {
        QByteArray line = raw.trimmed();
        if (!line.toLower().startsWith("range:"))
            continue;

        static const QRegularExpression rangeRe(
            QStringLiteral("bytes\\s*=\\s*(\\d*)\\s*-\\s*(\\d*)"));
        QRegularExpressionMatch rm =
            rangeRe.match(QString::fromLatin1(line.mid(6)));
        if (!rm.hasMatch())
            break;

        m_rangeRequested = true;
        if (rm.captured(1).isEmpty()) {
            // "bytes=-N": the last N bytes; resolved once the size is known.
            m_suffixRange = true;
            m_end = rm.captured(2).toLongLong();
        } else {
            m_pos = rm.captured(1).toLongLong();
            if (!rm.captured(2).isEmpty())
                m_end = rm.captured(2).toLongLong();
        }
        break;
    }

    StreamEntry *e = m_entry;
    connect(e, &StreamEntry::dataAvailable, this, &ProxyClient::pump);
    connect(e, &StreamEntry::streamFailed, m_socket, &QTcpSocket::abort);
    connect(e, &QObject::destroyed, m_socket, &QTcpSocket::abort);

    if (e->headersKnown) {
        sendHeaders();
    } else {
        connect(e, &StreamEntry::headersReady, this, &ProxyClient::sendHeaders);
        if (!m_suffixRange)
            e->ensureCovers(m_pos);
    }
}

inline void ProxyClient::sendSimple(const QByteArray &status) {
    m_done = true;
    m_socket->write("HTTP/1.1 " + status
                    + "\r\nContent-Length: 0\r\nConnection: close\r\n\r\n");
    m_socket->disconnectFromHost();
}

inline void ProxyClient::sendHeaders() {
    if (m_headersSent || m_done || !m_entry)
        return;
    m_headersSent = true;

    StreamEntry *e = m_entry;
    qint64 total = e->total;

    if (m_suffixRange && total >= 0) {
        m_pos = qMax<qint64>(0, total - m_end);
        m_end = -1;
    }

    if (total >= 0 && m_pos >= total) {
        m_done = true;
        m_socket->write("HTTP/1.1 416 Range Not Satisfiable\r\n"
                        "Content-Range: bytes */" + QByteArray::number(total)
                        + "\r\nContent-Length: 0\r\nConnection: close\r\n\r\n");
        m_socket->disconnectFromHost();
        return;
    }

    QByteArray type = e->contentType.isEmpty()
        ? QByteArray("application/octet-stream") : e->contentType;

    QByteArray head;
    if (total >= 0) {
        qint64 last = m_end >= 0 ? qMin(m_end, total - 1) : total - 1;
        m_limit = last + 1;

        bool partial = m_rangeRequested;
        head = partial ? "HTTP/1.1 206 Partial Content\r\n" : "HTTP/1.1 200 OK\r\n";
        head += "Content-Length: " + QByteArray::number(m_limit - m_pos) + "\r\n";
        if (partial)
            head += "Content-Range: bytes " + QByteArray::number(m_pos) + "-"
                    + QByteArray::number(last) + "/" + QByteArray::number(total) + "\r\n";
    } else {
        head = "HTTP/1.1 200 OK\r\n";
    }
    head += "Content-Type: " + type + "\r\n"
            "Accept-Ranges: bytes\r\n"
            "Cache-Control: no-cache\r\n"
            "Connection: close\r\n\r\n";
    m_socket->write(head);

    if (m_head) {
        finish();
        return;
    }

    e->ensureCovers(m_pos);
    pump();
}

inline void ProxyClient::pump() {
    if (!m_headersSent || m_done)
        return;

    StreamEntry *e = m_entry;
    if (!e) {
        m_socket->abort();
        return;
    }

    while (m_socket->bytesToWrite() < StreamTuning::SocketHighWater) {
        qint64 limit = m_limit >= 0 ? m_limit : std::numeric_limits<qint64>::max();

        if (m_pos >= limit || (e->complete && m_pos >= e->total)) {
            finish();
            return;
        }

        if (m_pos < e->validStart || m_pos >= e->validEnd) {
            // Not downloaded yet: keep the connection open and wait.
            e->ensureCovers(m_pos);
            return;
        }

        qint64 n = qMin(qMin(e->validEnd, limit) - m_pos, StreamTuning::ChunkBytes);
        QByteArray chunk;
        if (!e->readAt(m_pos, n, chunk)) {
            m_socket->abort();
            return;
        }

        m_socket->write(chunk);
        m_pos += chunk.size();
        e->noteReader(m_pos);
    }
}

inline void ProxyClient::finish() {
    m_done = true;
    m_socket->disconnectFromHost();
}

// ---------------------------------------------------------------------------
// QML-facing side, in the GUI thread. Exposed as the context property
// "streamCache".
// ---------------------------------------------------------------------------
class StreamCache : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool reconnecting READ reconnecting NOTIFY reconnectingChanged)
    // Current track: bytes [cachedStart, cachedEnd) of totalBytes are on disk.
    Q_PROPERTY(double cachedStart READ cachedStart NOTIFY cacheChanged)
    Q_PROPERTY(double cachedEnd READ cachedEnd NOTIFY cacheChanged)
    Q_PROPERTY(double totalBytes READ totalBytes NOTIFY cacheChanged)
    Q_PROPERTY(bool cacheComplete READ cacheComplete NOTIFY cacheChanged)

public:
    explicit StreamCache(QObject *parent = nullptr) : QObject(parent) {
        // Sailjail grants ~/.cache/<OrganizationName>/<ApplicationName>.
        QString dir =
            QStandardPaths::writableLocation(QStandardPaths::GenericCacheLocation)
            + QStringLiteral("/se.munkstolen/harbour-fiatpons/streams");

        m_engine = new StreamProxyEngine(dir);
        m_engine->moveToThread(&m_thread);
        connect(&m_thread, &QThread::finished, m_engine, &QObject::deleteLater);
        connect(m_engine, &StreamProxyEngine::reconnectingChanged,
                this, &StreamCache::setReconnecting);
        connect(m_engine, &StreamProxyEngine::progress, this,
                [this](double start, double end, double total, bool complete) {
            m_cachedStart = start;
            m_cachedEnd = end;
            m_totalBytes = total;
            m_cacheComplete = complete;
            emit cacheChanged();
        });
        connect(m_engine, &StreamProxyEngine::entryDropped, this, [this](int id) {
            QString key = m_ids.key(id);
            if (!key.isEmpty())
                m_ids.remove(key);
        });
        m_thread.start();

        QMetaObject::invokeMethod(m_engine, "start", Qt::BlockingQueuedConnection,
                                  Q_RETURN_ARG(int, m_port));
    }

    ~StreamCache() override {
        QMetaObject::invokeMethod(m_engine, "stopAll", Qt::BlockingQueuedConnection);
        m_thread.quit();
        m_thread.wait();
    }

    bool reconnecting() const { return m_reconnecting; }
    double cachedStart() const { return m_cachedStart; }
    double cachedEnd() const { return m_cachedEnd; }
    double totalBytes() const { return m_totalBytes; }
    bool cacheComplete() const { return m_cacheComplete; }

    // Returns the URL the player should open for this track. key identifies
    // the track and quality: the same key reuses what is already downloaded.
    // Falls back to the remote URL if the proxy could not start.
    Q_INVOKABLE QString proxy(const QString &key, const QString &remoteUrl) {
        if (m_port == 0 || remoteUrl.isEmpty())
            return remoteUrl;

        int id = m_ids.value(key, 0);
        if (id == 0) {
            id = ++m_nextId;
            m_ids.insert(key, id);
        }

        QMetaObject::invokeMethod(m_engine, "open", Qt::QueuedConnection,
                                  Q_ARG(int, id), Q_ARG(QString, remoteUrl));

        // The serial makes every call a new source, so MediaPlayer reloads
        // even when the same track is reopened after an error.
        return QStringLiteral("http://127.0.0.1:%1/s/%2?r=%3")
            .arg(m_port).arg(id).arg(++m_serial);
    }

    // Bytes to download ahead of the player, 0 = whole track.
    Q_INVOKABLE void setReadAheadBytes(double bytes) {
        QMetaObject::invokeMethod(m_engine, "setReadAhead", Qt::QueuedConnection,
                                  Q_ARG(double, qMax(0.0, bytes)));
    }

signals:
    void reconnectingChanged();
    void cacheChanged();

private:
    void setReconnecting(bool value) {
        if (m_reconnecting == value)
            return;
        m_reconnecting = value;
        emit reconnectingChanged();
    }

    QThread m_thread;
    StreamProxyEngine *m_engine = nullptr;
    QHash<QString, int> m_ids;
    int m_port = 0;
    int m_nextId = 0;
    int m_serial = 0;
    bool m_reconnecting = false;
    double m_cachedStart = 0;
    double m_cachedEnd = 0;
    double m_totalBytes = -1;
    bool m_cacheComplete = false;
};

#endif // STREAMCACHE_H
