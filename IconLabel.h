#ifndef ICONLABEL_H
#define ICONLABEL_H

#include <QWidget>
#include <QString>
#include <QPixmap>

class QPaintEvent;

class IconLabel : public QWidget
{
public:
    IconLabel(QWidget* parent);

    void setText(const QString& text) { mText = text; update(); }
    void setIcon(const QPixmap& icon) { mIcon = icon; update(); }

private:
    void paintEvent(QPaintEvent* e);

private:
    QString mText;
    QPixmap mIcon;
};

#endif
