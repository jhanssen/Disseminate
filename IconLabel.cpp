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
    p.drawText(w, 0, width() - w, height(), Qt::AlignLeft | Qt::AlignVCenter, mText);
}
