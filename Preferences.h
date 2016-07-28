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

#ifndef PREFERENCES_H
#define PREFERENCES_H

#include "Helpers.h"
#include <QDialog>
#include <QStringList>
#include <QVector>

namespace Ui {
class Preferences;
}

class Preferences : public QDialog
{
    Q_OBJECT

public:
    struct Config
    {
        KeyCode globalKey, globalMouse;
        QVector<KeyCode> exclusions;
        QStringList automaticWindows;
    };

    explicit Preferences(QWidget *parent, const Config& cfg);
    ~Preferences();

signals:
    void configChanged(const Config& cfg);

private slots:
    void emitConfigChanged();

    void addKeyBind();
    void removeKeyBind();
    void addMouseBind();
    void removeMouseBind();

    void addExclusion();
    void removeExclusion();

    void addWindow();
    void removeWindow();

private:
    KeyCode globalKey, globalMouse;
    Ui::Preferences *ui;
};

#endif // PREFERENCES_H
