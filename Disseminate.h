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
    void windowSelected(const QString& name, uint64_t window);

private:
    Ui::Disseminate *ui;
    WindowSelector* selector;
};

#endif // DISSEMINATE_H
