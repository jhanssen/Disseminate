/*
  Disseminate, keyboard broadcaster
  Copyright (C) 2016  Jan Erik Hanssen

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include "Disseminate.h"
#include "KeyInput.h"
#include "Item.h"
#include "Utils.h"
#include "Helpers.h"
#include "TemplateChooser.h"
#include "ui_Disseminate.h"
#include <QMessageBox>
#include <QSettings>

Disseminate::Disseminate(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::Disseminate),
    selector(0),
    broadcasting(false)
{
    ui->setupUi(this);

    loadConfig();
    applyConfig();

    connect(ui->windowList, &QListWidget::itemDoubleClicked, this, &Disseminate::windowDoubleClicked);

    connect(ui->addWindow, &QPushButton::clicked, this, &Disseminate::addWindow);
    connect(ui->removeWindow, &QPushButton::clicked, this, &Disseminate::removeWindow);

    connect(ui->actionStart, &QAction::triggered, this, &Disseminate::startBroadcast);
    connect(ui->actionStop, &QAction::triggered, this, &Disseminate::stopBroadcast);
    connect(ui->actionTemplates, &QAction::triggered, this, &Disseminate::templates);

    connect(ui->actionPreferences, &QAction::triggered, this, &Disseminate::preferences);

    connect(ui->addKey, &QPushButton::clicked, this, &Disseminate::addKey);
    connect(ui->removeKey, &QPushButton::clicked, this, &Disseminate::removeKey);

    connect(ui->whitelistRadio, &QRadioButton::toggled, this, &Disseminate::whiteListChanged);
    connect(ui->blacklistRadio, &QRadioButton::toggled, this, &Disseminate::blackListChanged);

    connect(ui->reloadWindows, &QPushButton::clicked, this, &Disseminate::reloadWindows);
}

Disseminate::~Disseminate()
{
    broadcast::stop();
    delete selector;
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

void Disseminate::windowSelected(const QString& name, uint64_t psn, uint64_t winid, const QPixmap& image)
{
    if (!helpers::contains(ui->windowList, name)) {
        const bool bc = broadcasting;
        if (bc)
            stopBroadcast();
        const QString str = name + " (" + QString::number(psn) + ")";
        ui->windowList->addItem(new WindowItem(str, name, psn, winid, image));
        broadcast::addWindow(psn);
        if (bc)
            startBroadcast();
    }
}

void Disseminate::removeWindow()
{
    if (broadcasting)
        stopBroadcast();

    const auto& items = ui->windowList->selectedItems();
    for (auto& item : items) {
        broadcast::removeWindow(static_cast<WindowItem*>(item)->wpsn);
        delete item;
    }
}

void Disseminate::startBroadcast()
{
    if (broadcasting)
        return;
    if (ui->windowList->count() < 2) {
        QMessageBox::information(this, "No windows to broadcast", "Add at least two windows before broadcasting");
        return;
    }
    if (!broadcast::start()) {
        QMessageBox::critical(this, "Unable to broadcast", "Unable to broadcast, ensure that the app is allowed to control your computer");
        return;
    }
    broadcasting = true;
    ui->actionStart->setEnabled(false);
    ui->actionStop->setEnabled(true);
}

void Disseminate::stopBroadcast()
{
    if (!broadcasting)
        return;
    ui->actionStart->setEnabled(true);
    ui->actionStop->setEnabled(false);
    broadcast::stop();
    broadcasting = false;
}

void Disseminate::addKey()
{
    KeyInput readKey(this);
    if (readKey.valid()) {
        connect(&readKey, &KeyInput::keyAdded, this, &Disseminate::keyAdded);
        readKey.exec();
    } else {
        QMessageBox::critical(this, "Unable to capture key", "Unable to capture key, ensure that the app is allowed to control your computer");
    }
}

void Disseminate::removeKey()
{
    const auto& items = ui->keyList->selectedItems();
    for (auto& item : items) {
        const KeyItem* kitem = static_cast<const KeyItem*>(item);
        broadcast::removeKey(kitem->key, kitem->mask);
        delete item;
    }

    saveConfig();
}

void Disseminate::keyAdded(int64_t key, uint64_t mask)
{
    const QString name = helpers::keyToQString(key, mask);
    if (!helpers::contains(ui->keyList, name)) {
        ui->keyList->addItem(new KeyItem(name, key, mask));
        broadcast::addKey(key, mask);

        saveConfig();
    }
}

void Disseminate::whiteListChanged()
{
    if (ui->whitelistRadio->isChecked()) {
        broadcast::setKeyType(broadcast::WhiteList);
        saveConfig();
    }
}

void Disseminate::blackListChanged()
{
    if (ui->blacklistRadio->isChecked()) {
        broadcast::setKeyType(broadcast::BlackList);
        saveConfig();
    }
}

void Disseminate::templates()
{
    Templates templates(this, temps);
    connect(&templates, &Templates::configChanged, this, &Disseminate::templatesChanged);

    templates.exec();
}

void Disseminate::templatesChanged(const Templates::Config& cfg)
{
    temps = cfg;
    saveConfig();
    applyConfig();
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

    broadcast::clearKeys();
    ui->keyList->clear();

    const QList<QVariant> keys = settings.value("keys").toList();
    for (const auto& elem : keys) {
        QVariantMap key = elem.toMap();
        if (key.contains("key") && key.contains("mask")) {
            const int64_t k = key["key"].toLongLong();
            const uint64_t m = key["mask"].toULongLong();

            if (k || m) {
                const QString name = helpers::keyToQString(k, m);
                if (!helpers::contains(ui->keyList, name)) {
                    ui->keyList->addItem(new KeyItem(name, k, m));
                    broadcast::addKey(k, m);
                }
            }
        }
    }

    if (settings.value("keyType").toString() != "blacklist") {
        ui->whitelistRadio->setChecked(true);
        ui->blacklistRadio->setChecked(false);
        broadcast::setKeyType(broadcast::WhiteList);
    } else {
        ui->whitelistRadio->setChecked(false);
        ui->blacklistRadio->setChecked(true);
        broadcast::setKeyType(broadcast::BlackList);
    }

    temps.clear();
    const QVariantMap templates = settings.value("templates").toMap();
    // uhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
    QVariantMap::const_iterator it = templates.begin();
    const QVariantMap::const_iterator end = templates.end();
    while (it != end) {
        const QVariantMap ventry = it.value().toMap();
        if (ventry.contains("whitelist") && ventry.contains("keys")) {
            Templates::ConfigItem titem;
            const QList<QVariant> vkeys = ventry["keys"].toList();
            QVector<QPair<int64_t, uint64_t> >& tkeys = titem.keys;
            for (const auto& k : vkeys) {
                const QVariantMap km = k.toMap();
                if (km.contains("key") && km.contains("mask")) {
                    QPair<int64_t, uint64_t> tkey;
                    tkey.first = km["key"].toLongLong();
                    tkey.second = km["mask"].toULongLong();
                    tkeys.append(tkey);
                }
            }
            titem.whitelist = ventry["whitelist"].toBool();
            temps[it.key()] = titem;
        }
        ++it;
    }
}

void Disseminate::saveConfig()
{
    QSettings settings("jhanssen", "Disseminate");
    settings.setValue("preferences/automaticWindows", prefs.automaticWindows);

    QList<QVariant> keys;
    {
        const int keyCount = ui->keyList->count();
        for (int i = 0; i < keyCount; ++i) {
            KeyItem* item = static_cast<KeyItem*>(ui->keyList->item(i));
            QVariantMap k;
            k["key"] = item->key;
            k["mask"] = item->mask;
            keys.append(k);
        }
    }
    settings.setValue("keys", keys);

    if (ui->whitelistRadio->isChecked()) {
        settings.setValue("keyType", "whitelist");
    } else {
        settings.setValue("keyType", "blacklist");
    }

    QVariantMap templates;
    {
        Templates::Config::const_iterator it = temps.begin();
        const Templates::Config::const_iterator end = temps.end();
        while (it != end) {
            QList<QVariant> tkeys;
            for (const auto& k : it.value().keys) {
                QVariantMap tkey;
                tkey["key"] = k.first;
                tkey["mask"] = k.second;
                tkeys.append(tkey);
            }
            QVariantMap kentry;
            kentry["whitelist"] = it.value().whitelist;
            kentry["keys"] = tkeys;
            templates[it.key()] = kentry;
            ++it;
        }
    }
    settings.setValue("templates", templates);
}

void Disseminate::applyConfig()
{
    reloadWindows();
}

void Disseminate::reloadWindows()
{
    const bool cap = broadcasting;
    if (cap)
        stopBroadcast();

    const QList<WindowSelector::Window> windows = WindowSelector::getWindowList();
    broadcast::clearWindows();

    QList<WindowSelector::Window> current;
    const int windowCount = ui->windowList->count();
    for (int i = 0; i < windowCount; ++i) {
        WindowItem* item = static_cast<WindowItem*>(ui->windowList->item(i));
        current.append({ item->wname, item->wpsn, item->wid, item->wicon });
    }
    ui->windowList->clear();

    // readd existing windows
    for (const auto& c : current) {
        if (windows.contains(c)) {
            const QString str = c.name + " (" + QString::number(c.psn) + ")";
            ui->windowList->addItem(new WindowItem(str, c.name, c.psn, c.winid, c.icon));
            broadcast::addWindow(c.psn);
        }
    }
    // then readd automatic windows
    const QList<WindowSelector::Window> autoWindows = WindowSelector::getWindowList();
    for (const auto& str : prefs.automaticWindows) {
        QRegExp rx(str, Qt::CaseInsensitive);
        for (const auto& win : autoWindows) {
            if (rx.indexIn(win.name) != -1) {
                const QString str = win.name + " (" + QString::number(win.psn) + ")";
                if (!helpers::contains(ui->windowList, str)) {
                    ui->windowList->addItem(new WindowItem(str, win.name, win.psn, win.winid, win.icon));
                    broadcast::addWindow(win.psn);
                }
            }
        }
    }

    if (cap)
        startBroadcast();
}

void Disseminate::windowDoubleClicked(QListWidgetItem* item)
{
    if (!item)
        return;
    WindowItem* witem = static_cast<WindowItem*>(item);
    TemplateChooser chooser(this, chosenTemplates[witem->wpsn], temps.keys(), witem->wpsn, witem->wid);
    connect(&chooser, &TemplateChooser::chosen, this, &Disseminate::templateChosen);

    chooser.exec();
}

void Disseminate::templateChosen(uint64_t psn, const QString& name)
{
    chosenTemplates[psn] = name;
    broadcast::clearKeysForWindow(psn);
    if (name.isEmpty())
        return;
    const auto& item = temps[name];
    broadcast::setKeyTypeForWindow(psn, item.whitelist ? broadcast::WhiteList : broadcast::BlackList);
    const auto& keys = item.keys;
    for (const auto& key : keys) {
        broadcast::addKeyForWindow(psn, key.first, key.second);
    }
}
