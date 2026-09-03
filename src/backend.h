#ifndef FIATPONS_BACKEND_H
#define FIATPONS_BACKEND_H

#include <QObject>
#include <QThread>
#include <QString>

extern "C" {
    char *fp_search(const char *query);
    char *fp_stream_url(unsigned long long track_id);
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
    void doStreamUrl(qulonglong id) {
        char *raw = fp_stream_url(id);
        QString out = QString::fromUtf8(raw);
        fp_free(raw);
        emit streamDone(out);
    }
signals:
    void searchDone(const QString &json);
    void streamDone(const QString &json);
};

class Backend : public QObject
{
    Q_OBJECT
public:
    explicit Backend(QObject *parent = nullptr) : QObject(parent) {
        SearchWorker *worker = new SearchWorker;
        worker->moveToThread(&m_thread);
        connect(&m_thread, &QThread::finished, worker, &QObject::deleteLater);
        connect(this, &Backend::requestSearch, worker, &SearchWorker::doSearch);
        connect(this, &Backend::requestStream, worker, &SearchWorker::doStreamUrl);
        connect(worker, &SearchWorker::searchDone, this, &Backend::searchComplete);
        connect(worker, &SearchWorker::streamDone, this, &Backend::streamReady);
        m_thread.start();
    }
    ~Backend() override { m_thread.quit(); m_thread.wait(); }

    Q_INVOKABLE void search(const QString &query) { emit requestSearch(query); }
    Q_INVOKABLE void streamUrl(qulonglong id) { emit requestStream(id); }

signals:
    void requestSearch(const QString &query);
    void requestStream(qulonglong id);
    void searchComplete(const QString &json);
    void streamReady(const QString &json);

private:
    QThread m_thread;
};

#endif // FIATPONS_BACKEND_H
