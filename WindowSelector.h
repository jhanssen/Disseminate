#ifndef WINDOWSELECTOR_H
#define WINDOWSELECTOR_H

#include <QDialog>

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

signals:
    void windowSelected(const QString& name, uint64_t id);

private slots:
    void emitSelected();

private:
    Ui::WindowSelector *ui;
};

#endif // WINDOWSELECTOR_H
