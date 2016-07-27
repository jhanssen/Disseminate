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

    connect(ui->actionPreferences, &QAction::triggered, this, &Disseminate::preferences);

    connect(ui->addKey, &QPushButton::clicked, this, &Disseminate::addKey);
    connect(ui->removeKey, &QPushButton::clicked, this, &Disseminate::removeKey);

    connect(ui->whitelistRadio, &QRadioButton::toggled, this, &Disseminate::whiteListChanged);
    connect(ui->blacklistRadio, &QRadioButton::toggled, this, &Disseminate::blackListChanged);
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
    if (ui->windowList->findItems(name, Qt::MatchFixedString).isEmpty()) {
        ui->windowList->addItem(new WindowItem(name, window));
        capture::addWindow(window);
    }
}

void Disseminate::removeWindow()
{
    const auto& items = ui->windowList->selectedItems();
    for (auto& item : items) {
        capture::removeWindow(static_cast<WindowItem*>(item)->wid);
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
        connect(&readKey, &KeyInput::keyAdded, this, &Disseminate::keyAdded);
        readKey.exec();
    } else {
        QMessageBox::critical(this, "Unable to capture", "Unable to capture, ensure that the app is allowed to control your computer");
    }
}

void Disseminate::removeKey()
{
    const auto& items = ui->keyList->selectedItems();
    for (auto& item : items) {
        const KeyItem* kitem = static_cast<const KeyItem*>(item);
        capture::removeKey(kitem->key, kitem->mask);
        delete item;
    }
}

void Disseminate::keyAdded(int64_t key, uint64_t mask)
{
    QString name = QString::number(key) + " (" + QString::number(mask) + ")";
    if (ui->keyList->findItems(name, Qt::MatchFixedString).isEmpty()) {
        ui->keyList->addItem(new KeyItem(name, key, mask));
        capture::addKey(key, mask);
    }
}

void Disseminate::whiteListChanged()
{
    if (ui->whitelistRadio->isChecked()) {
        capture::setKeyType(capture::WhiteList);
    }
}

void Disseminate::blackListChanged()
{
    if (ui->blacklistRadio->isChecked()) {
        capture::setKeyType(capture::BlackList);
    }
}

void Disseminate::preferences()
{
#warning preferences, but I cant remember what to put here
}
