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

#ifndef DISSEMINATE_H
#define DISSEMINATE_H

#include <QMainWindow>
#include "WindowSelector.h"
#include "Preferences.h"

namespace Ui {
class Disseminate;
}

class Disseminate : public QMainWindow
{
    Q_OBJECT

public:
    explicit Disseminate(QWidget *parent = 0);
    ~Disseminate();

private slots:
    void addWindow();
    void removeWindow();

    void windowSelected(const QString& name, uint64_t psn, uint64_t winid, const QPixmap& image);
    void keyAdded(int64_t key, uint64_t mask);
    void preferencesChanged(const Preferences::Config& cfg);

    void startBroadcast();
    void stopBroadcast();

    void addKey();
    void removeKey();

    void whiteListChanged();
    void blackListChanged();

    void preferences();

    void reloadWindows();

private:
    void saveConfig();
    void loadConfig();
    void applyConfig();

private:
    Ui::Disseminate *ui;
    WindowSelector* selector;
    bool broadcasting;

    Preferences::Config prefs;
};

#endif // DISSEMINATE_H
