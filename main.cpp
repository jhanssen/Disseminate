#include "Disseminate.h"
#include <QApplication>

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);
    Disseminate w;
    w.show();

    return a.exec();
}
