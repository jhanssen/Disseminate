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
