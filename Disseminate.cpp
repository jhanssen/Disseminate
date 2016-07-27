#include "Disseminate.h"
#include "ui_Disseminate.h"

Disseminate::Disseminate(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::Disseminate)
{
    ui->setupUi(this);
}

Disseminate::~Disseminate()
{
    delete ui;
}
