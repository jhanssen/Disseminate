#ifndef ITEM_H
#define ITEM_H

#include <QListWidgetItem>

class Item : public QListWidgetItem
{
public:
    Item(const QString &text, uint64_t windowId);

    uint64_t wid;
};

inline Item::Item(const QString& text, uint64_t windowId)
    : QListWidgetItem(text), wid(windowId)
{
}

#endif
