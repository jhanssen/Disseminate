#include "Disseminate.h"
#include "ui_Disseminate.h"

Disseminate::Disseminate(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::Disseminate),
    selector(0)
{
    ui->setupUi(this);

    connect(ui->actionAdd, &QAction::triggered, this, &Disseminate::addWindow);
}

Disseminate::~Disseminate()
{
    delete ui;
}

void Disseminate::addWindow()
{
    if (!selector) {
        selector = new WindowSelector(this);
        connect(selector, &WindowSelector::windowSelected, this, &Disseminate::windowSelected);
    }
    selector->init();
    selector->exec();
}

void Disseminate::windowSelected(const QString& name, uint64_t window)
{
}
