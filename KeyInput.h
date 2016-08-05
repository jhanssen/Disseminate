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

#ifndef KEYINPUT_H
#define KEYINPUT_H

#include "Helpers.h"
#include <QDialog>

namespace Ui {
class KeyInput;
}

class KeyFilter;

class KeyInput : public QDialog
{
    Q_OBJECT

public:
    explicit KeyInput(QWidget *parent = 0);
    ~KeyInput();

    bool valid() const { return capturing; }

    static KeyCode getKeyCode(QWidget* parent);

protected:
    void keyPressEvent(QKeyEvent*);
    void keyReleaseEvent(QKeyEvent*);

signals:
    void keyAdded(int64_t key, uint64_t mask);

private slots:
    void emitKeyAdded();

private:
    void updateKey();

private:
    Ui::KeyInput *ui;
    KeyFilter* filter;
    int64_t currentKey;
    uint64_t currentFlags;
    bool capturing;
};

#endif // KEYINPUT_H
