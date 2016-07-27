#ifndef DISSEMINATE_H
#define DISSEMINATE_H

#include <QMainWindow>
#include "WindowSelector.h"
#include "Preferences.h"

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

    void windowSelected(const QString& name, uint64_t psn, uint64_t winid, const QPixmap& image);
    void keyAdded(int64_t key, uint64_t mask);
    void preferencesChanged(const Preferences::Config& cfg);

    void startBroadcast();
    void stopBroadcast();

    void addKey();
    void removeKey();

    void whiteListChanged();
    void blackListChanged();

    void preferences();

    void reloadWindows();

private:
    void saveConfig();
    void loadConfig();
    void applyConfig();

private:
    Ui::Disseminate *ui;
    WindowSelector* selector;
    bool broadcasting;

    Preferences::Config prefs;
};

#endif // DISSEMINATE_H
