#include "Disseminate.h"
#include "KeyInput.h"
#include "Item.h"
#include "Utils.h"
#include "ui_Disseminate.h"
#include <QMessageBox>

Disseminate::Disseminate(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::Disseminate),
    selector(0)
{
    ui->setupUi(this);

    connect(ui->actionAdd, &QAction::triggered, this, &Disseminate::addWindow);
    connect(ui->actionRemove, &QAction::triggered, this, &Disseminate::removeWindow);
    connect(ui->actionStart, &QAction::triggered, this, &Disseminate::startBroadcast);
    connect(ui->actionStop, &QAction::triggered, this, &Disseminate::stopBroadcast);

    connect(ui->addKey, &QPushButton::clicked, this, &Disseminate::addKey);
    connect(ui->removeKey, &QPushButton::clicked, this, &Disseminate::removeKey);
}

Disseminate::~Disseminate()
{
    capture::stop();
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
    if (ui->windowList->findItems(name, Qt::MatchFixedString).isEmpty())
        ui->windowList->addItem(new Item(name, window));
    capture::addWindow(window);
}

void Disseminate::removeWindow()
{
    const auto& items = ui->windowList->selectedItems();
    for (auto& item : items) {
        capture::removeWindow(static_cast<Item*>(item)->wid);
        delete item;
    }
}

void Disseminate::startBroadcast()
{
    if (!capture::start()) {
        QMessageBox::critical(this, "Unable to capture", "Unable to capture, ensure that the app is allowed to control your computer");
        return;
    }
    ui->actionStart->setEnabled(false);
    ui->actionStop->setEnabled(true);
}

void Disseminate::stopBroadcast()
{
    ui->actionStart->setEnabled(true);
    ui->actionStop->setEnabled(false);
    capture::stop();
}

void Disseminate::addKey()
{
    KeyInput readKey(this);
    if (readKey.valid()) {
        readKey.exec();
    } else {
        QMessageBox::critical(this, "Unable to capture", "Unable to capture, ensure that the app is allowed to control your computer");
    }
}

void Disseminate::removeKey()
{
}
