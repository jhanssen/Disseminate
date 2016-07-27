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

#ifndef HELPERS_H
#define HELPERS_H

#include <QListWidget>
#include "Utils.h"

namespace helpers {
inline bool contains(QListWidget* listWidget, const QString &text)
{
    for(int i = 0; i < listWidget->count(); ++i) {
        QListWidgetItem* item = listWidget->item(i);
        if (item->text() == text)
            return true;
    }
    return false;
}

inline QString toQString(const std::string& str)
{
    return QString::fromUtf8(str.c_str(), str.size());
}

inline QString keyToQString(int64_t key, uint64_t mask)
{
    QString keystr = helpers::toQString(broadcast::maskToString(mask));
    if (!keystr.isEmpty())
        keystr += "-";
    return keystr + helpers::toQString(broadcast::keyToString(key));
}
} // namespace helpers

#endif
