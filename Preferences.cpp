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

#include "Preferences.h"
#include "ui_Preferences.h"
#include "Item.h"
#include "KeyInput.h"
#include <QInputDialog>

Preferences::Preferences(QWidget *parent, const Config& cfg) :
    QDialog(parent),
    globalKey(cfg.globalKey),
    globalMouse(cfg.globalMouse),
    ui(new Ui::Preferences)
{
    ui->setupUi(this);
    for (const auto& str : cfg.automaticWindows) {
        ui->windowList->addItem(str);
    }
    for (const auto& ex : cfg.exclusions) {
        ui->exclusionList->addItem(new KeyItem(helpers::keyToQString(ex), ex.first, ex.second));
    }
    ui->keyEdit->setText(helpers::keyToQString(globalKey));
    ui->mouseEdit->setText(helpers::keyToQString(globalMouse));

    connect(this, &Preferences::accepted, this, &Preferences::emitConfigChanged);

    connect(ui->addKeyBind, &QPushButton::clicked, this, &Preferences::addKeyBind);
    connect(ui->removeKeyBind, &QPushButton::clicked, this, &Preferences::removeKeyBind);
    connect(ui->addMouseBind, &QPushButton::clicked, this, &Preferences::addMouseBind);
    connect(ui->removeMouseBind, &QPushButton::clicked, this, &Preferences::removeMouseBind);

    connect(ui->addExclusion, &QPushButton::clicked, this, &Preferences::addExclusion);
    connect(ui->removeExclusion, &QPushButton::clicked, this, &Preferences::removeExclusion);

    connect(ui->addWindow, &QPushButton::clicked, this, &Preferences::addWindow);
    connect(ui->removeWindow, &QPushButton::clicked, this, &Preferences::removeWindow);
}

Preferences::~Preferences()
{
    delete ui;
}

void Preferences::emitConfigChanged()
{
    Config cfg;
    const int windowCount = ui->windowList->count();
    for (int i = 0; i < windowCount; ++i) {
        QListWidgetItem* item = ui->windowList->item(i);
        cfg.automaticWindows.append(item->text());
    }
    const int exclusionCount = ui->exclusionList->count();
    for (int i = 0; i < exclusionCount; ++i) {
        KeyItem* item = static_cast<KeyItem*>(ui->exclusionList->item(i));
        cfg.exclusions.append(KeyCode(item->key, item->mask));
    }
    cfg.globalKey = globalKey;
    cfg.globalMouse = globalMouse;
    emit configChanged(cfg);
}

void Preferences::addKeyBind()
{
    globalKey = KeyInput::getKeyCode(this);
    ui->keyEdit->setText(helpers::keyToQString(globalKey));
}

void Preferences::removeKeyBind()
{
    globalKey = { 0, 0 };
    ui->keyEdit->setText(helpers::keyToQString(globalKey));
}

void Preferences::addMouseBind()
{
    globalMouse = KeyInput::getKeyCode(this);
    ui->mouseEdit->setText(helpers::keyToQString(globalMouse));
}

void Preferences::removeMouseBind()
{
    globalMouse = { 0, 0 };
    ui->mouseEdit->setText(helpers::keyToQString(globalMouse));
}

void Preferences::addExclusion()
{
    const KeyCode kc = KeyInput::getKeyCode(this);
    if (helpers::keyIsNull(kc))
        return;
    const QString str = helpers::keyToQString(kc);
    if (helpers::contains(ui->exclusionList, str))
        return;
    ui->exclusionList->addItem(new KeyItem(str, kc.first, kc.second));
}

void Preferences::removeExclusion()
{
    const auto& items = ui->exclusionList->selectedItems();
    for (auto& item : items) {
        delete item;
    }
}

void Preferences::addWindow()
{
    const QString win = QInputDialog::getText(this, "Window Matching", "Add Window Matching");
    if (!win.isEmpty()) {
        if (ui->windowList->findItems(win, Qt::MatchFixedString).isEmpty()) {
            ui->windowList->addItem(win);
        }
    }
}

void Preferences::removeWindow()
{
    const auto& items = ui->windowList->selectedItems();
    for (auto& item : items) {
        delete item;
    }
}
