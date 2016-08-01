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

#ifndef ITEM_H
#define ITEM_H

#include <QListWidgetItem>
#include <QPixmap>

class ClientItem : public QListWidgetItem
{
public:
    ClientItem(const QString &text, const QString& name, int32_t pid, uint64_t winid, const QPixmap& icon);

    QString wname;
    int32_t wpid;
    uint64_t wid;
    QPixmap wicon;
};

inline ClientItem::ClientItem(const QString& text, const QString& name, int32_t pid, uint64_t winid, const QPixmap& icon)
    : QListWidgetItem(text), wname(name), wpid(pid), wid(winid), wicon(icon)
{
    if (!wicon.isNull()) {
        setIcon(wicon);
    }
}

class KeyItem : public QListWidgetItem
{
public:
    KeyItem(const QString& text, int64_t k, uint64_t m)
        : QListWidgetItem(text), key(k), mask(m)
    {
    }

    int64_t key;
    uint64_t mask;
};

#endif
