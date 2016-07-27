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
    QString keystr = helpers::toQString(capture::maskToString(mask));
    if (!keystr.isEmpty())
        keystr += "-";
    return keystr + helpers::toQString(capture::keyToString(key));
}
} // namespace helpers

#endif
