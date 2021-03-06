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
#include <RemoteAdd_generated.h>
#include <QFile>
#include <QProcess>
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
    connect(ui->reloadClients, &QPushButton::clicked, this, &MainWindow::reloadClients);

    connect(ui->actionAddConfiguration, &QAction::triggered, this, &MainWindow::addConfiguration);
    connect(ui->actionRemoveConfiguration, &QAction::triggered, this, &MainWindow::removeConfiguration);
    connect(ui->actionEditConfiguration, &QAction::triggered, this, &MainWindow::editConfiguration);

    messagePort.onMessage([this](int32_t id, const std::vector<uint8_t>& msg) {
            const auto remoteAdd = Disseminate::RemoteAdd::GetEvent(&msg[0])->UnPack();
            printf("got message %d -> %s\n", id, remoteAdd->uuid.c_str());

            auto remote = std::make_shared<MessagePortRemote>(remoteAdd->uuid);
            // std::weak_ptr<MessagePortRemote> weak = remote;
            remote->onInvalidated([this, id/*, weak*/]() {
                    // if (auto shared = weak.lock()) {
                    // }
                    printf("invalidated port\n");
                    remotePorts.erase(id);
                    reloadClients();
                });
            remotePorts[id] = { remoteAdd->uuid, remoteAdd->client, 0, remote };
            reloadClients();
        });
}

MainWindow::~MainWindow()
{
    //broadcast::stop();
    //broadcast::cleanup();
    stopBroadcast();
    delete ui;
}

const Configuration::Item* MainWindow::currentConfiguration()
{
    const QString txt = ui->configuration->currentText();
    if (txt.isEmpty())
        return 0;

    QVector<Configuration::Item>::const_iterator cfg = configs.begin();
    const QVector<Configuration::Item>::const_iterator end = configs.end();
    while (cfg != end) {
        if (cfg->name == txt) {
            return &*cfg;
        }
        ++cfg;
    }
    return 0;
}

void MainWindow::startBroadcast()
{
    if (broadcasting)
        return;
    // if (ui->clientList->count() < 2) {
    //     QMessageBox::information(this, "No windows to broadcast", "Add at least two windows before broadcasting");
    //     return;
    // }
#warning implement me
    // if (!broadcast::start()) {
    //     QMessageBox::critical(this, "Unable to broadcast", "Unable to broadcast, ensure that the app is allowed to control your computer");
    //     return;
    // }
    broadcasting = true;
    ui->actionStart->setEnabled(false);
    ui->actionStop->setEnabled(true);

    launchClients();
}

void MainWindow::terminate(const QString client)
{
    // find the uuid
    const auto c = client.toStdString();
    for (auto p : remotePorts) {
        if (p.second.client == c) {
            p.second.port->send(Disseminate::FlatbufferTypes::Terminate);
            break;
        }
    }
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

    // Qt sucks balls, why can't I get a pair from QMap in a ranged for loop???
    {
        auto r = running.begin();
        const auto end = running.end();
        while (r != end) {
            terminate(r.key());
            (*r)->waitForFinished();
            ++r;
        }
    }
    qDeleteAll(running);
    running.clear();
}

void MainWindow::launchClients()
{
    if (!running.isEmpty())
        return;
    const Configuration::Item* config = currentConfiguration();
    if (!config)
        return;
    // assume the executable name is the app name
    QString app = config->appPath;
    QString exe;
    {
        int ls = app.lastIndexOf('/');
        if (ls != -1) {
            int la = app.lastIndexOf(".app");
            if (la > ls) {
                exe = app.mid(ls + 1, (la - ls) - 1);
            }
        }
    }
    if (exe.isEmpty())
        return;
    app += "/Contents/MacOS/" + exe;
    if (QFile::exists(app)) {
        QString swizzlerPath = QApplication::applicationDirPath() + "/../../../Swizzler/libSwizzler.dylib";
        //QMessageBox::critical(0, swizzlerPath, swizzlerPath);
        app = "\"" + app + "\"";
        if (QFile::exists(swizzlerPath)) {
            for (const auto& client : config->clients) {
                QProcess* proc = new QProcess(this);
                connect(proc, &QProcess::errorOccurred, [proc](QProcess::ProcessError error) {
                        QMessageBox::critical(0, "Launch error", "Launch error " + proc->errorString());
                    });
                QProcessEnvironment env = proc->processEnvironment();
                env.insert("DYLD_INSERT_LIBRARIES", swizzlerPath);
                env.insert("DISSEMINATE_CLIENT", client);
                proc->setProcessEnvironment(env);
                proc->start(app);

                running[client] = proc;
            }
        }
    }
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

    {
        flatbuffers::FlatBufferBuilder builder;
        auto buffer = Disseminate::Settings::CreateGlobal(builder, &global);
        builder.Finish(buffer);

        std::vector<uint8_t> message(builder.GetBufferPointer(),
                                     builder.GetBufferPointer() + builder.GetSize());
        for (auto r : remotePorts) {
            r.second.port->send(Disseminate::FlatbufferTypes::Settings, message);
        }
    }

    Disseminate::RemoteAdd::EventT addEvent;
    // push over all remotes
    for (auto r : remotePorts) {
        r.second.port->send(Disseminate::FlatbufferTypes::RemoteClear);
        const auto& self = r.second.uuid;
        for (auto o : remotePorts) {
            if (o.second.uuid != self) {
                addEvent.uuid = o.second.uuid;

                flatbuffers::FlatBufferBuilder builder;
                auto buffer = Disseminate::RemoteAdd::CreateEvent(builder, &addEvent);
                builder.Finish(buffer);

                std::vector<uint8_t> message(builder.GetBufferPointer(),
                                             builder.GetBufferPointer() + builder.GetSize());
                r.second.port->send(Disseminate::FlatbufferTypes::RemoteAdd, message);
            }
        }
    }

}

void MainWindow::addKey()
{
    KeyInput readKey(this);
    connect(&readKey, &KeyInput::keyAdded, this, &MainWindow::keyAdded);
    readKey.exec();
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

    ui->configuration->clear();
    configs.clear();
    QList<QVariant> configurations = settings.value("configurations").toList();
    for (const auto& config : configurations) {
        const QVariantMap cm = config.toMap();
        if (cm.contains("appPath") && cm.contains("name")) {
            Configuration::Item item;
            item.name = cm["name"].toString();
            item.appPath = cm["appPath"].toString();
            item.appIcon = cm["appIcon"].value<QPixmap>();
            if (cm.contains("clients")) {
                QList<QVariant> clients = cm["clients"].toList();
                for (const auto& client : clients) {
                    item.clients.append(client.toString());
                }
            }
            configs.append(item);

            ui->configuration->addItem(item.appIcon, item.name);
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

    QList<QVariant> configurations;
    {
        for (const auto& item : configs) {
            QVariantMap cfg;
            cfg["name"] = item.name;
            cfg["appPath"] = item.appPath;
            cfg["appIcon"] = item.appIcon;
            QList<QVariant> clients;
            for (const auto& client : item.clients) {
                clients.append(client);
            }
            cfg["clients"] = clients;

            configurations.append(cfg);
        }
    }
    settings.setValue("configurations", configurations);
}

void MainWindow::applyConfig()
{
    reloadClients();
    updateBindings();
}

void MainWindow::reloadClients()
{
    ui->clientList->clear();
    for (auto& remote : remotePorts) {
        const auto& info = getInformation(remote.first);
        remote.second.windowId = info.windowId;
        if (!info.title.isEmpty()) {
            QString text = info.title + " - " + QString::fromStdString(remote.second.client) + " (" + QString::number(info.windowId) + ")";
            ui->clientList->addItem(new ClientItem(text, info.title, remote.first, info.windowId, info.icon));
        }
    }
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

void MainWindow::addConfiguration()
{
    Configuration config;
    connect(&config, &Configuration::itemSelected, this, &MainWindow::configurationAdded);
    config.exec();
}

void MainWindow::editConfiguration()
{
    if (configs.isEmpty())
        return;
    const QString txt = ui->configuration->currentText();
    if (txt.isEmpty())
        return;

    // find our item
    Configuration::Item item;
    for (const auto& i : configs) {
        if (i.name == txt) {
            item = i;
            break;
        }
    }
    if (item.name.isEmpty())
        return;

    Configuration config;
    config.setItem(item);
    connect(&config, &Configuration::itemSelected, this, &MainWindow::configurationEdited);
    config.exec();
}

void MainWindow::removeConfiguration()
{
    const QString txt = ui->configuration->currentText();
    if (txt.isEmpty())
        return;

    QVector<Configuration::Item>::iterator cfg = configs.begin();
    const QVector<Configuration::Item>::const_iterator end = configs.end();
    while (cfg != end) {
        if (cfg->name == txt) {
            configs.erase(cfg);
            for (int i = 0; i < ui->configuration->count(); ++i) {
                if (ui->configuration->itemText(i) == txt) {
                    ui->configuration->removeItem(i);
                    break;
                }
            }
            break;
        }
        ++cfg;
    }

    saveConfig();
}

void MainWindow::configurationAdded(const Configuration::Item& item)
{
    if (item.name.isEmpty())
        return;
    for (const auto& i : configs) {
        if (i.name == item.name)
            return;
    }
    configs.append(item);
    ui->configuration->addItem(item.appIcon, item.name);

    saveConfig();
}

void MainWindow::configurationEdited(const Configuration::Item& item)
{
    if (item.name.isEmpty())
        return;
    for (auto& i : configs) {
        if (i.name == item.name) {
            i = item;
            for (int i = 0; i < ui->configuration->count(); ++i) {
                if (ui->configuration->itemText(i) == item.name) {
                    ui->configuration->setItemIcon(i, item.appIcon);
                    break;
                }
            }
            break;
        }
    }

    saveConfig();
}
