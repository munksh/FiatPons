#ifndef FIATPONS_BACKEND_H
#define FIATPONS_BACKEND_H

#include <QObject>
#include <QThread>
#include <QString>

extern "C" {
    char *fp_search(const char *query);
    void  fp_free(char *s);
}

// Runs the blocking Rust call on its own thread so the UI never stalls.
class SearchWorker : public QObject
{
    Q_OBJECT
public slots:
    void doSearch(const QString &query) {
        QByteArray q = query.toUtf8();
        char *raw = fp_search(q.constData());
        QString out = QString::fromUtf8(raw);
        fp_free(raw);
        emit done(out);
    }
signals:
    void done(const QString &json);
};

// The object QML talks to. search() hands the query to the worker thread;
// searchComplete fires back on the UI thread when the JSON is ready.
class Backend : public QObject
{
    Q_OBJECT
public:
    explicit Backend(QObject *parent = nullptr) : QObject(parent) {
        SearchWorker *worker = new SearchWorker;
        worker->moveToThread(&m_thread);
        connect(&m_thread, &QThread::finished, worker, &QObject::deleteLater);
        connect(this, &Backend::requestSearch, worker, &SearchWorker::doSearch);
        connect(worker, &SearchWorker::done, this, &Backend::searchComplete);
        m_thread.start();
    }
    ~Backend() override { m_thread.quit(); m_thread.wait(); }

    Q_INVOKABLE void search(const QString &query) { emit requestSearch(query); }

signals:
    void requestSearch(const QString &query);
    void searchComplete(const QString &json);

private:
    QThread m_thread;
};

#endif // FIATPONS_BACKEND_H
