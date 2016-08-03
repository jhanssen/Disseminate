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

#include "MainWindow.h"
#include "KeyInput.h"
#include "Item.h"
#include "Utils.h"
#include "Helpers.h"
#include "TemplateChooser.h"
#include "ui_MainWindow.h"
#include <memory>
#include <FlatbufferTypes.h>
#include <Settings_generated.h>
#include <QMessageBox>
#include <QSettings>
#include <QTimer>

MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::Disseminate),
    broadcasting(false),
    messagePort("jhanssen.disseminate.server")
{
    ui->setupUi(this);

    loadConfig();
    applyConfig();

    connect(ui->clientList, &QListWidget::itemDoubleClicked, this, &MainWindow::clientDoubleClicked);

    connect(ui->actionStart, &QAction::triggered, this, &MainWindow::startBroadcast);
    connect(ui->actionStop, &QAction::triggered, this, &MainWindow::stopBroadcast);
    connect(ui->actionTemplates, &QAction::triggered, this, &MainWindow::templates);

    connect(ui->actionPreferences, &QAction::triggered, this, &MainWindow::preferences);

    connect(ui->addKey, &QPushButton::clicked, this, &MainWindow::addKey);
    connect(ui->removeKey, &QPushButton::clicked, this, &MainWindow::removeKey);

    connect(ui->whitelistRadio, &QRadioButton::toggled, this, &MainWindow::whiteListChanged);
    connect(ui->blacklistRadio, &QRadioButton::toggled, this, &MainWindow::blackListChanged);

    connect(ui->pushSettings, &QPushButton::clicked, this, &MainWindow::pushSettings);

    QTimer::singleShot(50, [this]() {
            if (broadcast::checkAllowsAccessibility() == broadcast::Unknown) {
                QMessageBox::warning(this, "Accessibility permissions required",
                                     "Disemminate requires accessibility permissions, you might need to enable this in system preferences");
            }
        });

    messagePort.onMessage([this](int32_t id, const std::vector<uint8_t>& msg) {
            const std::string name(reinterpret_cast<const char*>(&msg[0]), msg.size());
            printf("got message %d -> %s\n", id, name.c_str());

            auto remote = std::make_shared<MessagePortRemote>(name);
            // std::weak_ptr<MessagePortRemote> weak = remote;
            remote->onInvalidated([this, id/*, weak*/]() {
                    // if (auto shared = weak.lock()) {
                    // }
                    printf("invalidated port\n");
                    remotePorts.erase(id);
                    reloadClients();
                });
            remotePorts[id] = remote;
            reloadClients();
        });
}

MainWindow::~MainWindow()
{
    //broadcast::stop();
    broadcast::cleanup();
    delete ui;
}

void MainWindow::startBroadcast()
{
    if (broadcasting)
        return;
    if (ui->clientList->count() < 2) {
        QMessageBox::information(this, "No windows to broadcast", "Add at least two windows before broadcasting");
        return;
    }
#warning implement me
    // if (!broadcast::start()) {
    //     QMessageBox::critical(this, "Unable to broadcast", "Unable to broadcast, ensure that the app is allowed to control your computer");
    //     return;
    // }
    broadcasting = true;
    ui->actionStart->setEnabled(false);
    ui->actionStop->setEnabled(true);
}

void MainWindow::stopBroadcast()
{
    if (!broadcasting)
        return;
    ui->actionStart->setEnabled(true);
    ui->actionStop->setEnabled(false);
#warning implement me
    //broadcast::stop();
    broadcasting = false;
}

void MainWindow::pushSettings()
{
    Disseminate::Settings::GlobalT global;
    if (ui->whitelistRadio->isChecked())
        global.type = Disseminate::Settings::Type_WhiteList;
    else
        global.type = Disseminate::Settings::Type_BlackList;

    const int keyCount = ui->keyList->count();
    for (int i = 0; i < keyCount; ++i) {
        KeyItem* item = static_cast<KeyItem*>(ui->keyList->item(i));
        global.keys.push_back({ item->key, item->mask });
    }

    global.toggleKeyboard = std::make_unique<Disseminate::Settings::Key>(prefs.globalKey.first, prefs.globalKey.second);
    global.toggleMouse = std::make_unique<Disseminate::Settings::Key>(prefs.globalMouse.first, prefs.globalMouse.second);

    for (auto ex : prefs.exclusions) {
        global.activeExclusions.push_back({ ex.first, ex.second });
    }

    flatbuffers::FlatBufferBuilder builder;
    auto buffer = Disseminate::Settings::CreateGlobal(builder, &global);
    builder.Finish(buffer);

    std::vector<uint8_t> message(builder.GetBufferPointer(),
                                 builder.GetBufferPointer() + builder.GetSize());
    for (auto r : remotePorts) {
        r.second->send(Disseminate::FlatbufferTypes::Settings, message);
    }
}

void MainWindow::addKey()
{
    KeyInput readKey(this);
    if (readKey.valid()) {
        connect(&readKey, &KeyInput::keyAdded, this, &MainWindow::keyAdded);
        readKey.exec();
    } else {
        QMessageBox::critical(this, "Unable to capture key", "Unable to capture key, ensure that the app is allowed to control your computer");
    }
}

void MainWindow::removeKey()
{
    const auto& items = ui->keyList->selectedItems();
    for (auto& item : items) {
        const KeyItem* kitem = static_cast<const KeyItem*>(item);
        //broadcast::removeKey(kitem->key, kitem->mask);
#warning implement me
        delete item;
    }

    saveConfig();
}

void MainWindow::keyAdded(int64_t key, uint64_t mask)
{
    const QString name = helpers::keyToQString(key, mask);
    if (!helpers::contains(ui->keyList, name)) {
        ui->keyList->addItem(new KeyItem(name, key, mask));
        //broadcast::addKey(key, mask);
#warning implement me

        saveConfig();
    }
}

void MainWindow::whiteListChanged()
{
    if (ui->whitelistRadio->isChecked()) {
        //broadcast::setKeyType(broadcast::WhiteList);
#warning implement me

        saveConfig();
    }
}

void MainWindow::blackListChanged()
{
    if (ui->blacklistRadio->isChecked()) {
        //broadcast::setKeyType(broadcast::BlackList);
#warning implement me

        saveConfig();
    }
}

void MainWindow::templates()
{
    Templates templates(this, temps);
    connect(&templates, &Templates::configChanged, this, &MainWindow::templatesChanged);

    templates.exec();
}

void MainWindow::templatesChanged(const Templates::Config& cfg)
{
    temps = cfg;
    saveConfig();
    applyConfig();
}

void MainWindow::preferences()
{
    Preferences preferences(this, prefs);
    connect(&preferences, &Preferences::configChanged, this, &MainWindow::preferencesChanged);

    preferences.exec();
}

void MainWindow::preferencesChanged(const Preferences::Config& cfg)
{
    prefs = cfg;
    saveConfig();
    applyConfig();
}

void MainWindow::loadConfig()
{
    QSettings settings("jhanssen", "Disseminate");
    QVariant windows = settings.value("preferences/automaticWindows");
    prefs.automaticWindows.clear();
    QStringList list = windows.toStringList();
    for (const auto& str : list) {
        prefs.automaticWindows.append(str);
    }

    //broadcast::clearKeys();
#warning implement me

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
                    //broadcast::addKey(k, m);
#warning implement me

                }
            }
        }
    }

    if (settings.value("keyType").toString() != "blacklist") {
        ui->whitelistRadio->setChecked(true);
        ui->blacklistRadio->setChecked(false);
        //broadcast::setKeyType(broadcast::WhiteList);
#warning implement me

    } else {
        ui->whitelistRadio->setChecked(false);
        ui->blacklistRadio->setChecked(true);
        //broadcast::setKeyType(broadcast::BlackList);
#warning implement me

    }

    temps.clear();
    const QVariantMap templates = settings.value("templates").toMap();
    // uhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
    QVariantMap::const_iterator tempit = templates.begin();
    const QVariantMap::const_iterator tempend = templates.end();
    while (tempit != tempend) {
        const QVariantMap ventry = tempit.value().toMap();
        if (ventry.contains("whitelist") && ventry.contains("keys")) {
            Templates::ConfigItem titem;
            const QList<QVariant> vkeys = ventry["keys"].toList();
            QVector<KeyCode>& tkeys = titem.keys;
            for (const auto& k : vkeys) {
                const QVariantMap km = k.toMap();
                if (km.contains("key") && km.contains("mask")) {
                    KeyCode tkey;
                    tkey.first = km["key"].toLongLong();
                    tkey.second = km["mask"].toULongLong();
                    tkeys.append(tkey);
                }
            }
            titem.whitelist = ventry["whitelist"].toBool();
            temps[tempit.key()] = titem;
        }
        ++tempit;
    }

    prefs.globalKey = { 0, 0 };
    prefs.globalMouse = { 0, 0 };
    QVariantMap bindings = settings.value("bindings").toMap();
    if (bindings.contains("keyboard") && bindings.contains("mouse")) {
        QVariantMap v = bindings.value("keyboard").toMap();
        if (v.contains("key") && v.contains("mask")) {
            prefs.globalKey.first = v["key"].toLongLong();
            prefs.globalKey.second = v["mask"].toULongLong();
        }
        v = bindings.value("mouse").toMap();
        if (v.contains("key") && v.contains("mask")) {
            prefs.globalMouse.first = v["key"].toLongLong();
            prefs.globalMouse.second = v["mask"].toULongLong();
        }
    }

    prefs.exclusions.clear();
    QList<QVariant> exclusions = settings.value("exclusions").toList();
    for (const auto& exclusion : exclusions) {
        const QVariantMap km = exclusion.toMap();
        if (km.contains("key") && km.contains("mask")) {
            KeyCode ekey;
            ekey.first = km["key"].toLongLong();
            ekey.second = km["mask"].toULongLong();
            prefs.exclusions.append(ekey);
        }
    }
}

void MainWindow::saveConfig()
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

    QVariantMap bindings;
    {
        QVariantMap key, mouse;
        key["key"] = prefs.globalKey.first;
        key["mask"] = prefs.globalKey.second;
        mouse["key"] = prefs.globalMouse.first;
        mouse["mask"] = prefs.globalMouse.second;
        bindings["keyboard"] = key;
        bindings["mouse"] = mouse;
    }
    settings.setValue("bindings", bindings);

    QList<QVariant> exclusions;
    {
        const int exclusionCount = prefs.exclusions.size();
        for (int i = 0; i < exclusionCount; ++i) {
            QVariantMap exclusion;
            exclusion["key"] = prefs.exclusions[i].first;
            exclusion["mask"] = prefs.exclusions[i].second;
            exclusions.append(exclusion);
        }
    }
    settings.setValue("exclusions", exclusions);
}

void MainWindow::applyConfig()
{
    reloadClients();
    updateBindings();
}

void MainWindow::reloadClients()
{
    const bool cap = broadcasting;
    if (cap)
        stopBroadcast();

    ui->clientList->clear();
    for (const auto& remote : remotePorts) {
        const auto& info = getInformation(remote.first);
        if (!info.title.isEmpty()) {
            QString text = info.title + " (" + QString::number(info.windowId) + ")";
            ui->clientList->addItem(new ClientItem(text, info.title, remote.first, info.windowId, info.icon));
        }
    }

    if (cap)
        startBroadcast();
}

void MainWindow::updateBindings()
{
#warning implement me

    /*
    if (helpers::keyIsNull(prefs.globalKey))
        broadcast::clearBinding(broadcast::Keyboard);
    else
        broadcast::setBinding(broadcast::Keyboard, prefs.globalKey.first, prefs.globalKey.second);

    if (helpers::keyIsNull(prefs.globalMouse))
        broadcast::clearBinding(broadcast::Mouse);
    else
        broadcast::setBinding(broadcast::Mouse, prefs.globalMouse.first, prefs.globalMouse.second);

    broadcast::clearActiveWindowExclusions();
    for (const auto& ex : prefs.exclusions) {
        broadcast::addActiveWindowExclusion(ex.first, ex.second);
        }
    */
}

void MainWindow::clientDoubleClicked(QListWidgetItem* item)
{
    if (!item)
        return;
    ClientItem* witem = static_cast<ClientItem*>(item);
    TemplateChooser chooser(this, chosenTemplates[witem->wpid], temps.keys(), witem->wpid, witem->wid);
    connect(&chooser, &TemplateChooser::chosen, this, &MainWindow::templateChosen);

    chooser.exec();
}

void MainWindow::templateChosen(int32_t pid, const QString& name)
{
    chosenTemplates[pid] = name;
#warning fixme
    //broadcast::clearKeysForWindow(psn);
    if (name.isEmpty())
        return;
    const auto& item = temps[name];
    //broadcast::setKeyTypeForWindow(psn, item.whitelist ? broadcast::WhiteList : broadcast::BlackList);
    const auto& keys = item.keys;
    for (const auto& key : keys) {
        //broadcast::addKeyForWindow(psn, key.first, key.second);
    }
}
