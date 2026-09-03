#ifdef QT_QML_DEBUG
#include <QtQuick>
#endif

#include <QtQml>                 // added
#include <sailfishapp.h>
#include "backend.h"            // added

int main(int argc, char *argv[])
{
    // added: expose Backend to QML as `import se.munkstolen.fiatpons 1.0`
    qmlRegisterType<Backend>("se.munkstolen.fiatpons", 1, 0, "Backend");

    return SailfishApp::main(argc, argv);
}
