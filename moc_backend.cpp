/****************************************************************************
** Meta object code from reading C++ file 'backend.h'
**
** Created by: The Qt Meta Object Compiler version 67 (Qt 5.6.3)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "src/backend.h"
#include <QtCore/qbytearray.h>
#include <QtCore/qmetatype.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'backend.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 67
#error "This file was generated using the moc from 5.6.3. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

QT_BEGIN_MOC_NAMESPACE
struct qt_meta_stringdata_SearchWorker_t {
    QByteArrayData data[9];
    char stringdata0[71];
};
#define QT_MOC_LITERAL(idx, ofs, len) \
    Q_STATIC_BYTE_ARRAY_DATA_HEADER_INITIALIZER_WITH_OFFSET(len, \
    qptrdiff(offsetof(qt_meta_stringdata_SearchWorker_t, stringdata0) + ofs \
        - idx * sizeof(QByteArrayData)) \
    )
static const qt_meta_stringdata_SearchWorker_t qt_meta_stringdata_SearchWorker = {
    {
QT_MOC_LITERAL(0, 0, 12), // "SearchWorker"
QT_MOC_LITERAL(1, 13, 10), // "searchDone"
QT_MOC_LITERAL(2, 24, 0), // ""
QT_MOC_LITERAL(3, 25, 4), // "json"
QT_MOC_LITERAL(4, 30, 10), // "streamDone"
QT_MOC_LITERAL(5, 41, 8), // "doSearch"
QT_MOC_LITERAL(6, 50, 5), // "query"
QT_MOC_LITERAL(7, 56, 11), // "doStreamUrl"
QT_MOC_LITERAL(8, 68, 2) // "id"

    },
    "SearchWorker\0searchDone\0\0json\0streamDone\0"
    "doSearch\0query\0doStreamUrl\0id"
};
#undef QT_MOC_LITERAL

static const uint qt_meta_data_SearchWorker[] = {

 // content:
       7,       // revision
       0,       // classname
       0,    0, // classinfo
       4,   14, // methods
       0,    0, // properties
       0,    0, // enums/sets
       0,    0, // constructors
       0,       // flags
       2,       // signalCount

 // signals: name, argc, parameters, tag, flags
       1,    1,   34,    2, 0x06 /* Public */,
       4,    1,   37,    2, 0x06 /* Public */,

 // slots: name, argc, parameters, tag, flags
       5,    1,   40,    2, 0x0a /* Public */,
       7,    1,   43,    2, 0x0a /* Public */,

 // signals: parameters
    QMetaType::Void, QMetaType::QString,    3,
    QMetaType::Void, QMetaType::QString,    3,

 // slots: parameters
    QMetaType::Void, QMetaType::QString,    6,
    QMetaType::Void, QMetaType::ULongLong,    8,

       0        // eod
};

void SearchWorker::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    if (_c == QMetaObject::InvokeMetaMethod) {
        SearchWorker *_t = static_cast<SearchWorker *>(_o);
        Q_UNUSED(_t)
        switch (_id) {
        case 0: _t->searchDone((*reinterpret_cast< const QString(*)>(_a[1]))); break;
        case 1: _t->streamDone((*reinterpret_cast< const QString(*)>(_a[1]))); break;
        case 2: _t->doSearch((*reinterpret_cast< const QString(*)>(_a[1]))); break;
        case 3: _t->doStreamUrl((*reinterpret_cast< qulonglong(*)>(_a[1]))); break;
        default: ;
        }
    } else if (_c == QMetaObject::IndexOfMethod) {
        int *result = reinterpret_cast<int *>(_a[0]);
        void **func = reinterpret_cast<void **>(_a[1]);
        {
            typedef void (SearchWorker::*_t)(const QString & );
            if (*reinterpret_cast<_t *>(func) == static_cast<_t>(&SearchWorker::searchDone)) {
                *result = 0;
                return;
            }
        }
        {
            typedef void (SearchWorker::*_t)(const QString & );
            if (*reinterpret_cast<_t *>(func) == static_cast<_t>(&SearchWorker::streamDone)) {
                *result = 1;
                return;
            }
        }
    }
}

const QMetaObject SearchWorker::staticMetaObject = {
    { &QObject::staticMetaObject, qt_meta_stringdata_SearchWorker.data,
      qt_meta_data_SearchWorker,  qt_static_metacall, Q_NULLPTR, Q_NULLPTR}
};


const QMetaObject *SearchWorker::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *SearchWorker::qt_metacast(const char *_clname)
{
    if (!_clname) return Q_NULLPTR;
    if (!strcmp(_clname, qt_meta_stringdata_SearchWorker.stringdata0))
        return static_cast<void*>(const_cast< SearchWorker*>(this));
    return QObject::qt_metacast(_clname);
}

int SearchWorker::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 4)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 4;
    } else if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 4)
            *reinterpret_cast<int*>(_a[0]) = -1;
        _id -= 4;
    }
    return _id;
}

// SIGNAL 0
void SearchWorker::searchDone(const QString & _t1)
{
    void *_a[] = { Q_NULLPTR, const_cast<void*>(reinterpret_cast<const void*>(&_t1)) };
    QMetaObject::activate(this, &staticMetaObject, 0, _a);
}

// SIGNAL 1
void SearchWorker::streamDone(const QString & _t1)
{
    void *_a[] = { Q_NULLPTR, const_cast<void*>(reinterpret_cast<const void*>(&_t1)) };
    QMetaObject::activate(this, &staticMetaObject, 1, _a);
}
struct qt_meta_stringdata_Backend_t {
    QByteArrayData data[11];
    char stringdata0[95];
};
#define QT_MOC_LITERAL(idx, ofs, len) \
    Q_STATIC_BYTE_ARRAY_DATA_HEADER_INITIALIZER_WITH_OFFSET(len, \
    qptrdiff(offsetof(qt_meta_stringdata_Backend_t, stringdata0) + ofs \
        - idx * sizeof(QByteArrayData)) \
    )
static const qt_meta_stringdata_Backend_t qt_meta_stringdata_Backend = {
    {
QT_MOC_LITERAL(0, 0, 7), // "Backend"
QT_MOC_LITERAL(1, 8, 13), // "requestSearch"
QT_MOC_LITERAL(2, 22, 0), // ""
QT_MOC_LITERAL(3, 23, 5), // "query"
QT_MOC_LITERAL(4, 29, 13), // "requestStream"
QT_MOC_LITERAL(5, 43, 2), // "id"
QT_MOC_LITERAL(6, 46, 14), // "searchComplete"
QT_MOC_LITERAL(7, 61, 4), // "json"
QT_MOC_LITERAL(8, 66, 11), // "streamReady"
QT_MOC_LITERAL(9, 78, 6), // "search"
QT_MOC_LITERAL(10, 85, 9) // "streamUrl"

    },
    "Backend\0requestSearch\0\0query\0requestStream\0"
    "id\0searchComplete\0json\0streamReady\0"
    "search\0streamUrl"
};
#undef QT_MOC_LITERAL

static const uint qt_meta_data_Backend[] = {

 // content:
       7,       // revision
       0,       // classname
       0,    0, // classinfo
       6,   14, // methods
       0,    0, // properties
       0,    0, // enums/sets
       0,    0, // constructors
       0,       // flags
       4,       // signalCount

 // signals: name, argc, parameters, tag, flags
       1,    1,   44,    2, 0x06 /* Public */,
       4,    1,   47,    2, 0x06 /* Public */,
       6,    1,   50,    2, 0x06 /* Public */,
       8,    1,   53,    2, 0x06 /* Public */,

 // methods: name, argc, parameters, tag, flags
       9,    1,   56,    2, 0x02 /* Public */,
      10,    1,   59,    2, 0x02 /* Public */,

 // signals: parameters
    QMetaType::Void, QMetaType::QString,    3,
    QMetaType::Void, QMetaType::ULongLong,    5,
    QMetaType::Void, QMetaType::QString,    7,
    QMetaType::Void, QMetaType::QString,    7,

 // methods: parameters
    QMetaType::Void, QMetaType::QString,    3,
    QMetaType::Void, QMetaType::ULongLong,    5,

       0        // eod
};

void Backend::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    if (_c == QMetaObject::InvokeMetaMethod) {
        Backend *_t = static_cast<Backend *>(_o);
        Q_UNUSED(_t)
        switch (_id) {
        case 0: _t->requestSearch((*reinterpret_cast< const QString(*)>(_a[1]))); break;
        case 1: _t->requestStream((*reinterpret_cast< qulonglong(*)>(_a[1]))); break;
        case 2: _t->searchComplete((*reinterpret_cast< const QString(*)>(_a[1]))); break;
        case 3: _t->streamReady((*reinterpret_cast< const QString(*)>(_a[1]))); break;
        case 4: _t->search((*reinterpret_cast< const QString(*)>(_a[1]))); break;
        case 5: _t->streamUrl((*reinterpret_cast< qulonglong(*)>(_a[1]))); break;
        default: ;
        }
    } else if (_c == QMetaObject::IndexOfMethod) {
        int *result = reinterpret_cast<int *>(_a[0]);
        void **func = reinterpret_cast<void **>(_a[1]);
        {
            typedef void (Backend::*_t)(const QString & );
            if (*reinterpret_cast<_t *>(func) == static_cast<_t>(&Backend::requestSearch)) {
                *result = 0;
                return;
            }
        }
        {
            typedef void (Backend::*_t)(qulonglong );
            if (*reinterpret_cast<_t *>(func) == static_cast<_t>(&Backend::requestStream)) {
                *result = 1;
                return;
            }
        }
        {
            typedef void (Backend::*_t)(const QString & );
            if (*reinterpret_cast<_t *>(func) == static_cast<_t>(&Backend::searchComplete)) {
                *result = 2;
                return;
            }
        }
        {
            typedef void (Backend::*_t)(const QString & );
            if (*reinterpret_cast<_t *>(func) == static_cast<_t>(&Backend::streamReady)) {
                *result = 3;
                return;
            }
        }
    }
}

const QMetaObject Backend::staticMetaObject = {
    { &QObject::staticMetaObject, qt_meta_stringdata_Backend.data,
      qt_meta_data_Backend,  qt_static_metacall, Q_NULLPTR, Q_NULLPTR}
};


const QMetaObject *Backend::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *Backend::qt_metacast(const char *_clname)
{
    if (!_clname) return Q_NULLPTR;
    if (!strcmp(_clname, qt_meta_stringdata_Backend.stringdata0))
        return static_cast<void*>(const_cast< Backend*>(this));
    return QObject::qt_metacast(_clname);
}

int Backend::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 6)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 6;
    } else if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 6)
            *reinterpret_cast<int*>(_a[0]) = -1;
        _id -= 6;
    }
    return _id;
}

// SIGNAL 0
void Backend::requestSearch(const QString & _t1)
{
    void *_a[] = { Q_NULLPTR, const_cast<void*>(reinterpret_cast<const void*>(&_t1)) };
    QMetaObject::activate(this, &staticMetaObject, 0, _a);
}

// SIGNAL 1
void Backend::requestStream(qulonglong _t1)
{
    void *_a[] = { Q_NULLPTR, const_cast<void*>(reinterpret_cast<const void*>(&_t1)) };
    QMetaObject::activate(this, &staticMetaObject, 1, _a);
}

// SIGNAL 2
void Backend::searchComplete(const QString & _t1)
{
    void *_a[] = { Q_NULLPTR, const_cast<void*>(reinterpret_cast<const void*>(&_t1)) };
    QMetaObject::activate(this, &staticMetaObject, 2, _a);
}

// SIGNAL 3
void Backend::streamReady(const QString & _t1)
{
    void *_a[] = { Q_NULLPTR, const_cast<void*>(reinterpret_cast<const void*>(&_t1)) };
    QMetaObject::activate(this, &staticMetaObject, 3, _a);
}
QT_END_MOC_NAMESPACE
