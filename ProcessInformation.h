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

#ifndef PROCESSINFORMATION_H
#define PROCESSINFORMATION_H

#include <QPixmap>
#include <unistd.h>

struct ProcessInformation
{
    QPixmap icon;
    QString title;
    uint64_t windowId;
};

ProcessInformation getInformation(pid_t pid);
QPixmap getScreenshot(pid_t pid);

#endif
