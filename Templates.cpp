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

#include "Templates.h"
#include "KeyInput.h"
#include "Helpers.h"
#include "Item.h"
#include "ui_Templates.h"
#include <QMessageBox>
#include <QInputDialog>
#include <assert.h>

Templates::Templates(QWidget *parent, const Config& cfg) :
    QDialog(parent),
    ui(new Ui::Templates),
    config(cfg)
{
    ui->setupUi(this);

    connect(this, &Templates::accepted, this, &Templates::emitConfigChanged);

    connect(ui->addTemplate, &QPushButton::clicked, this, &Templates::addTemplate);
    connect(ui->removeTemplate, &QPushButton::clicked, this, &Templates::removeTemplate);

    connect(ui->addKey, &QPushButton::clicked, this, &Templates::addKey);
    connect(ui->removeKey, &QPushButton::clicked, this, &Templates::removeKey);

    connect(ui->whitelistRadio, &QRadioButton::toggled, this, &Templates::whiteListChanged);
    connect(ui->blacklistRadio, &QRadioButton::toggled, this, &Templates::blackListChanged);

    connect(ui->templateList, &QListWidget::currentItemChanged, this, &Templates::templateItemChanged);

    // Qt sucks ass, can't get the key by using a range-based for :/
    Config::const_iterator it = config.begin();
    const Config::const_iterator end = config.end();
    while (it != end) {
        ui->templateList->addItem(it.key());
        ++it;
    }
}

Templates::~Templates()
{
    delete ui;
}

void Templates::templateItemChanged(const QListWidgetItem* templ)
{
    ui->keyList->clear();
    if (!templ)
        return;

    const auto& item = config[templ->text()];
    if (item.whitelist) {
        ui->whitelistRadio->setChecked(true);
    } else {
        ui->blacklistRadio->setChecked(true);
    }

    for (const auto& k : item.keys) {
        const QString name = helpers::keyToQString(k.first, k.second);
        if (!helpers::contains(ui->keyList, name)) {
            ui->keyList->addItem(new KeyItem(name, k.first, k.second));
        }
    }
}

void Templates::addTemplate()
{
    const QString win = QInputDialog::getText(this, "Add Template", "Template Name");
    if (!win.isEmpty() && !helpers::contains(ui->templateList, win)) {
        ui->templateList->addItem(win);
        config[win].whitelist = ui->whitelistRadio->isChecked();
    }
}

void Templates::removeTemplate()
{
    const auto& items = ui->templateList->selectedItems();
    for (auto& item : items) {
        config.remove(item->text());
        delete item;
    }
}

void Templates::addKey()
{
    if (!ui->templateList->currentItem()) {
        QMessageBox::information(this, "No template selected", "No template selected");
        return;
    }

    KeyInput readKey(this);
    if (readKey.valid()) {
        connect(&readKey, &KeyInput::keyAdded, this, &Templates::keyAdded);
        readKey.exec();
    } else {
        QMessageBox::critical(this, "Unable to capture key", "Unable to capture key, ensure that the app is allowed to control your computer");
    }
}

void Templates::removeKey()
{
    if (!ui->templateList->currentItem()) {
        QMessageBox::information(this, "No template selected", "No template selected");
        return;
    }
    QListWidgetItem* titem = ui->templateList->currentItem();
    auto& vec = config[titem->text()].keys;

    const auto& items = ui->keyList->selectedItems();
    for (auto& item : items) {
        KeyItem* kitem = static_cast<KeyItem*>(item);
        auto it = vec.begin();
        const auto end = vec.cend();
        while (it != end) {
            if (it->first == kitem->key && it->second == kitem->mask) {
                vec.erase(it);
                break;
            }
            ++it;
        }
        delete item;
    }
}

void Templates::keyAdded(int64_t key, uint64_t mask)
{
    QListWidgetItem* item = ui->templateList->currentItem();
    assert(item);
    const QString name = helpers::keyToQString(key, mask);
    if (!helpers::contains(ui->keyList, name)) {
        config[item->text()].keys.append(KeyCode(key, mask));
        ui->keyList->addItem(new KeyItem(name, key, mask));
    }
}

void Templates::whiteListChanged()
{
    if (!ui->templateList->currentItem()) {
        QMessageBox::information(this, "No template selected", "No template selected");
        return;
    }
    QListWidgetItem* titem = ui->templateList->currentItem();
    if (ui->whitelistRadio->isChecked()) {
        config[titem->text()].whitelist = true;
    }
}

void Templates::blackListChanged()
{
    if (!ui->templateList->currentItem()) {
        QMessageBox::information(this, "No template selected", "No template selected");
        return;
    }
    QListWidgetItem* titem = ui->templateList->currentItem();
    if (ui->blacklistRadio->isChecked()) {
        config[titem->text()].whitelist = false;
    }
}

void Templates::emitConfigChanged()
{
    emit configChanged(config);
}
