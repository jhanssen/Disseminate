#ifndef WINDOWSELECTOR_H
#define WINDOWSELECTOR_H

#include <QDialog>
#include <QList>
#include <QString>

namespace Ui {
class WindowSelector;
}

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
        uint64_t id;

        bool operator==(const Window& other) const
        {
            return name == other.name && id == other.id;
        }
    };
    static QList<Window> getWindowList();

signals:
    void windowSelected(const QString& name, uint64_t id);

private slots:
    void emitSelected();

private:
    Ui::WindowSelector *ui;
};

#endif // WINDOWSELECTOR_H
