#ifndef ITEM_H
#define ITEM_H

#include <QListWidgetItem>

class WindowItem : public QListWidgetItem
{
public:
    WindowItem(const QString &text, const QString& name, uint64_t windowId);

    QString wname;
    uint64_t wid;
};

inline WindowItem::WindowItem(const QString& text, const QString& name, uint64_t windowId)
    : QListWidgetItem(text), wname(name), wid(windowId)
{
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
