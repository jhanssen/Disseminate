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

#include "IconLabel.h"
#include <QPainter>

IconLabel::IconLabel(QWidget* parent)
    : QWidget(parent)
{
}

void IconLabel::paintEvent(QPaintEvent* e)
{
    QPainter p(this);

    int w = 0;
    if (!mIcon.isNull()) {
        const int h = height();
        const int ph = mIcon.height();
        const float ratio = h / static_cast<float>(ph);
        p.drawPixmap(0, 0, mIcon.width() * ratio, mIcon.height() * ratio, mIcon);
        w += mIcon.width() * ratio + 5;
    }

    // only take what's past the last '/'
    QString txt = mText;
    const int ls = txt.lastIndexOf('/');
    if (ls != -1) {
        txt = txt.mid(ls + 1);
    }

    p.drawText(w, 0, width() - w, height(), Qt::AlignLeft | Qt::AlignVCenter, txt);
}
