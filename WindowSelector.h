#ifndef WINDOWSELECTOR_H
#define WINDOWSELECTOR_H

#include <QDialog>
#include <QList>
#include <QString>
#include <QListWidgetItem>
#include <QVBoxLayout>

namespace Ui {
class WindowSelector;
}

class ScreenShotWidget;

class WindowSelector : public QDialog
{
    Q_OBJECT

public:
    explicit WindowSelector(QWidget *parent = 0);
    ~WindowSelector();

    void init();

    struct Window
    {
        QString name;
        uint64_t psn, winid;
        QPixmap icon;

        bool operator==(const Window& other) const
        {
            return name == other.name && psn == other.psn;
        }
    };
    static QList<Window> getWindowList();

signals:
    void windowSelected(const QString& name, uint64_t psn, uint64_t id, const QPixmap& image);

private slots:
    void emitSelected();
    void itemChanged(const QListWidgetItem* item);

private:
    Ui::WindowSelector *ui;
    ScreenShotWidget* screenShot;
    QVBoxLayout* screenShotLayout;
};

#endif // WINDOWSELECTOR_H
