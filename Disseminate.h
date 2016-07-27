#ifndef DISSEMINATE_H
#define DISSEMINATE_H

#include <QMainWindow>
#include "WindowSelector.h"

namespace Ui {
class Disseminate;
}

class Disseminate : public QMainWindow
{
    Q_OBJECT

public:
    explicit Disseminate(QWidget *parent = 0);
    ~Disseminate();

private slots:
    void addWindow();
    void removeWindow();

    void windowSelected(const QString& name, uint64_t window);
    void keyAdded(int64_t key, uint64_t mask);

    void startBroadcast();
    void stopBroadcast();

    void addKey();
    void removeKey();

    void whiteListChanged();
    void blackListChanged();

    void preferences();

private:
    Ui::Disseminate *ui;
    WindowSelector* selector;
};

#endif // DISSEMINATE_H
