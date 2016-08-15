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

#ifndef CONFIGURATION_H
#define CONFIGURATION_H

#include <QDialog>
#include <QPixmap>
#include <QStringList>

namespace Ui {
class Configuration;
}

class Configuration : public QDialog
{
    Q_OBJECT
public:
    explicit Configuration(QWidget *parent = 0);
    ~Configuration();

    struct Item
    {
        QString name;
        QString appPath;
        QPixmap appIcon;
        QStringList clients;
    };
    void setItem(const Item& item);

signals:
    void itemSelected(const Item& item);

private slots:
    void selectApplication();
    void addClient();
    void removeClients();
    void emitItemSelected();

private:
    Ui::Configuration *ui;
};

#endif // CONFIGURATION_H
