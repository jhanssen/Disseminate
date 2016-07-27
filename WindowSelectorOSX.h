#ifndef WINDOWSELECTOROSX_H
#define WINDOWSELECTOROSX_H

#include <string>
#include <vector>
#include <QPixmap>

struct WindowRect
{
    int x, y;
    int width, height;
};

struct WindowInfo
{
    std::string name;
    uint64_t pid;
    WindowRect bounds;
    uint64_t windowId;
    uint64_t level;
    uint64_t order;
    uint64_t psn;
    QPixmap image;
};

void getWindows(std::vector<WindowInfo>& windows);
QPixmap getScreenshot(uint64_t windowId);

#endif
