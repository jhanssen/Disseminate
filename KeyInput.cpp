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

#include "KeyInput.h"
#include "Helpers.h"
#include "Utils.h"
#include "ui_KeyInput.h"

KeyInput::KeyInput(QWidget *parent) :
    QDialog(parent),
    ui(new Ui::KeyInput),
    currentKey(0), currentFlags(0)
{
    ui->setupUi(this);
    connect(this, &KeyInput::accepted, this, &KeyInput::emitKeyAdded);
    capturing = broadcast::startReadKey([this](int64_t key, uint64_t flags) {
            currentKey = key;
            currentFlags = flags;
            updateKey();
        });
}

KeyInput::~KeyInput()
{
    broadcast::stopReadKey();
    delete ui;
}

void KeyInput::emitKeyAdded()
{
    if (currentKey || currentFlags)
        emit keyAdded(currentKey, currentFlags);
}

void KeyInput::updateKey()
{
    ui->keyEdit->setText(helpers::keyToQString(currentKey, currentFlags));
}

void KeyInput::keyPressEvent(QKeyEvent*)
{
}

void KeyInput::keyReleaseEvent(QKeyEvent*)
{
}
