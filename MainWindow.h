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
#include "ProcessInformation.h"
#include "Preferences.h"
#include "Templates.h"
#include "MessagePort.h"
#include <memory>

namespace Ui {
class Disseminate;
}

class QListWidgetItem;

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    explicit MainWindow(QWidget *parent = 0);
    ~MainWindow();

private slots:
    void keyAdded(int64_t key, uint64_t mask);
    void preferencesChanged(const Preferences::Config& cfg);
    void templatesChanged(const Templates::Config& cfg);
    void clientDoubleClicked(QListWidgetItem* item);

    void startBroadcast();
    void stopBroadcast();

    void addKey();
    void removeKey();

    void whiteListChanged();
    void blackListChanged();

    void preferences();
    void templates();

    void reloadClients();
    void updateBindings();

    void templateChosen(int32_t psn, const QString& name);

    void pushSettings();

private:
    void saveConfig();
    void loadConfig();
    void applyConfig();

private:
    Ui::Disseminate *ui;
    bool broadcasting;

    Preferences::Config prefs;
    Templates::Config temps;
    QMap<int32_t, QString> chosenTemplates;

    MessagePortLocal messagePort;
    std::map<int32_t, std::pair<std::string, std::shared_ptr<MessagePortRemote> > > remotePorts;
};

#endif // DISSEMINATE_H
