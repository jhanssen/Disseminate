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
#include <QWidget>
#include <QPainter>
#include "Utils.h"

typedef QPair<int64_t, uint64_t> KeyCode;

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
    if (!key && !mask)
        return QString();

    QString keystr = helpers::toQString(broadcast::maskToString(mask));
    if (!keystr.isEmpty())
        keystr += "-";
    return keystr + helpers::toQString(broadcast::keyToString(key));
}

inline QString keyToQString(const KeyCode& code)
{
    return keyToQString(code.first, code.second);
}

inline bool keyIsNull(const KeyCode& code)
{
    return (!code.first && !code.second);
}

class ScreenShotWidget : public QWidget
{
public:
    ScreenShotWidget(QWidget* p)
        : QWidget(p)
    {
        setMinimumSize(100, 100);
        setSizePolicy(QSizePolicy::MinimumExpanding, QSizePolicy::MinimumExpanding);
    }

    void setPixmap(const QPixmap& pm)
    {
        pixmap = pm;
    }

protected:
    void paintEvent(QPaintEvent*)
    {
        QPainter painter(this);
        if (!pixmap.isNull()) {
            QRect wr = rect();
            const double fracx = static_cast<double>(wr.width()) / pixmap.width();
            const double fracy = static_cast<double>(wr.height()) / pixmap.height();
            if (fracx < fracy) {
                // ratio for width
                wr.setHeight(pixmap.height() * fracx);
            } else {
                // ratio for height
                wr.setWidth(pixmap.width() * fracy);
            }
            painter.drawPixmap(wr, pixmap);
        }
    }

private:
    QPixmap pixmap;
};
} // namespace helpers

#endif
