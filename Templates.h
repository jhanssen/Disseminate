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

#ifndef TEMPLATES_H
#define TEMPLATES_H

#include "Helpers.h"
#include <QDialog>
#include <QString>
#include <QVector>
#include <QMap>

namespace Ui {
class Templates;
}

class QListWidgetItem;

class Templates : public QDialog
{
    Q_OBJECT

public:
    struct ConfigItem
    {
        QVector<KeyCode> keys;
        bool whitelist;
    };
    typedef QMap<QString, ConfigItem> Config;

    explicit Templates(QWidget *parent, const Config& cfg);
    ~Templates();

signals:
    void configChanged(const Config& cfg);

private slots:
    void addKey();
    void removeKey();

    void whiteListChanged();
    void blackListChanged();

    void keyAdded(int64_t key, uint64_t mask);
    void templateItemChanged(const QListWidgetItem* item);

    void emitConfigChanged();

    void addTemplate();
    void removeTemplate();

private:
    Ui::Templates *ui;
    Config config;
};

#endif // TEMPLATES_H
