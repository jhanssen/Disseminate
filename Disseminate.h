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
#include <QMap>
#include "WindowSelector.h"
#include "Preferences.h"
#include "Templates.h"

namespace Ui {
class Disseminate;
}

class QListWidgetItem;

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
    void templatesChanged(const Templates::Config& cfg);
    void windowDoubleClicked(QListWidgetItem* item);

    void startBroadcast();
    void stopBroadcast();

    void addKey();
    void removeKey();

    void whiteListChanged();
    void blackListChanged();

    void preferences();
    void templates();

    void reloadWindows();
    void updateBindings();

    void templateChosen(uint64_t psn, const QString& name);

private:
    void saveConfig();
    void loadConfig();
    void applyConfig();

private:
    Ui::Disseminate *ui;
    WindowSelector* selector;
    bool broadcasting;

    Preferences::Config prefs;
    Templates::Config temps;
    QMap<uint64_t, QString> chosenTemplates;
};

#endif // DISSEMINATE_H
