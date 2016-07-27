#ifndef DISSEMINATE_H
#define DISSEMINATE_H

#include <QMainWindow>

namespace Ui {
class Disseminate;
}

class Disseminate : public QMainWindow
{
    Q_OBJECT

public:
    explicit Disseminate(QWidget *parent = 0);
    ~Disseminate();

private:
    Ui::Disseminate *ui;
};

#endif // DISSEMINATE_H
