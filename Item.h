#ifndef ITEM_H
#define ITEM_H

#include <QListWidgetItem>
#include <QPixmap>

class WindowItem : public QListWidgetItem
{
public:
    WindowItem(const QString &text, const QString& name, uint64_t psn, uint64_t winid, const QPixmap& icon);

    QString wname;
    uint64_t wpsn;
    uint64_t wid;
    QPixmap wicon;
};

inline WindowItem::WindowItem(const QString& text, const QString& name, uint64_t psn, uint64_t winid, const QPixmap& icon)
    : QListWidgetItem(text), wname(name), wpsn(psn), wid(winid), wicon(icon)
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
