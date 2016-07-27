#include "Disseminate.h"
#include "KeyInput.h"
#include "Item.h"
#include "Utils.h"
#include "Preferences.h"
#include "Helpers.h"
#include "ui_Disseminate.h"
#include <QMessageBox>
#include <QSettings>

Disseminate::Disseminate(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::Disseminate),
    selector(0),
    capturing(false)
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

    connect(ui->reloadWindows, &QPushButton::clicked, this, &Disseminate::reloadWindows);

    loadConfig();
    applyConfig();
}

Disseminate::~Disseminate()
{
    capture::stop();
    delete ui;
}

void Disseminate::addWindow()
{
    if (capturing)
        stopBroadcast();

    if (!selector) {
        selector = new WindowSelector(this);
        connect(selector, &WindowSelector::windowSelected, this, &Disseminate::windowSelected);
    }
    selector->init();
    selector->exec();
}

void Disseminate::windowSelected(const QString& name, uint64_t window)
{
    if (!helpers::contains(ui->windowList, name)) {
        const QString str = name + " (" + QString::number(window) + ")";
        ui->windowList->addItem(new WindowItem(str, name, window));
        capture::addWindow(window);
    }
}

void Disseminate::removeWindow()
{
    if (capturing)
        stopBroadcast();

    const auto& items = ui->windowList->selectedItems();
    for (auto& item : items) {
        capture::removeWindow(static_cast<WindowItem*>(item)->wid);
        delete item;
    }
}

void Disseminate::startBroadcast()
{
    if (capturing)
        return;
    if (!capture::start()) {
        QMessageBox::critical(this, "Unable to capture", "Unable to capture, ensure that the app is allowed to control your computer");
        return;
    }
    capturing = true;
    ui->actionStart->setEnabled(false);
    ui->actionStop->setEnabled(true);
}

void Disseminate::stopBroadcast()
{
    if (!capturing)
        return;
    ui->actionStart->setEnabled(true);
    ui->actionStop->setEnabled(false);
    capture::stop();
    capturing = false;
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
    if (!helpers::contains(ui->keyList, name)) {
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
    Preferences preferences(this, prefs);
    connect(&preferences, &Preferences::configChanged, this, &Disseminate::preferencesChanged);

    preferences.exec();
}

void Disseminate::preferencesChanged(const Preferences::Config& cfg)
{
    prefs = cfg;
    saveConfig();
    applyConfig();
}

void Disseminate::loadConfig()
{
    QSettings settings("jhanssen", "Disseminate");
    QVariant windows = settings.value("preferences/automaticWindows");
    prefs.automaticWindows.clear();
    QStringList list = windows.toStringList();
    for (const auto& str : list) {
        prefs.automaticWindows.append(str);
    }
}

void Disseminate::saveConfig()
{
    QSettings settings("jhanssen", "Disseminate");
    settings.setValue("preferences/automaticWindows", prefs.automaticWindows);
}

void Disseminate::applyConfig()
{
    if (capturing)
        stopBroadcast();
    const QList<WindowSelector::Window> windows = WindowSelector::getWindowList();
    for (const auto& str : prefs.automaticWindows) {
        QRegExp rx(str, Qt::CaseInsensitive);
        for (const auto& win : windows) {
            if (rx.indexIn(win.name) != -1) {
                const QString str = win.name + " (" + QString::number(win.id) + ")";
                if (!helpers::contains(ui->windowList, str)) {
                    ui->windowList->addItem(new WindowItem(str, win.name, win.id));
                    capture::addWindow(win.id);
                }
            }
        }
    }
}

void Disseminate::reloadWindows()
{
    const bool cap = capturing;
    if (cap)
        stopBroadcast();

    const QList<WindowSelector::Window> windows = WindowSelector::getWindowList();
    capture::clearWindows();

    QList<WindowSelector::Window> current;
    const int windowCount = ui->windowList->count();
    for (int i = 0; i < windowCount; ++i) {
        WindowItem* item = static_cast<WindowItem*>(ui->windowList->item(i));
        current.append({ item->wname, item->wid });
    }
    ui->windowList->clear();

    // readd existing windows
    for (const auto& c : current) {
        if (windows.contains(c)) {
            const QString str = c.name + " (" + QString::number(c.id) + ")";
            ui->windowList->addItem(new WindowItem(str, c.name, c.id));
            capture::addWindow(c.id);
        }
    }
    // then readd automatic windows
    applyConfig();

    if (cap)
        startBroadcast();
}
