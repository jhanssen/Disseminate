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
#include <QInputDialog>

Preferences::Preferences(QWidget *parent, const Config& cfg) :
    QDialog(parent),
    ui(new Ui::Preferences)
{
    ui->setupUi(this);
    for (const auto& str : cfg.automaticWindows) {
        ui->windowList->addItem(str);
    }

    connect(this, &Preferences::accepted, this, &Preferences::emitConfigChanged);
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
    emit configChanged(cfg);
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
