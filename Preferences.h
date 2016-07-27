#ifndef PREFERENCES_H
#define PREFERENCES_H

#include <QDialog>
#include <QStringList>

namespace Ui {
class Preferences;
}

class Preferences : public QDialog
{
    Q_OBJECT

public:
    struct Config
    {
        QStringList automaticWindows;
    };

    explicit Preferences(QWidget *parent, const Config& cfg);
    ~Preferences();

signals:
    void configChanged(const Config& cfg);

private slots:
    void emitConfigChanged();
    void addWindow();
    void removeWindow();

private:
    Ui::Preferences *ui;
};

#endif // PREFERENCES_H
