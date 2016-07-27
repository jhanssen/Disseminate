#ifndef HELPERS_H
#define HELPERS_H

#include <QListWidget>

namespace helpers {
bool contains(QListWidget* listWidget, const QString &text)
{
    for(int i = 0; i < listWidget->count(); ++i) {
        QListWidgetItem* item = listWidget->item(i);
        if (item->text() == text)
            return true;
    }
    return false;
}
} // namespace helpers

#endif
