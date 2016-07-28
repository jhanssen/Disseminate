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

#ifndef UTILS_H
#define UTILS_H

#include <cstdint>
#include <functional>
#include <string>

namespace broadcast {
void addWindow(uint64_t window);
void removeWindow(uint64_t window);
void clearWindows();

enum KeyType { WhiteList, BlackList };
void setKeyType(KeyType type);
void addKey(int64_t key, uint64_t mask);
void removeKey(int64_t key, uint64_t mask);
void clearKeys();

void setKeyTypeForWindow(uint64_t psn, KeyType type);
void addKeyForWindow(uint64_t psn, int64_t key, uint64_t mask);
void clearKeysForWindow(uint64_t psn);

void addActiveWindowExclusion(int64_t key, uint64_t mask);
void clearActiveWindowExclusions();

enum Binding { Keyboard, Mouse };
void setBinding(Binding binding, int64_t key, uint64_t mask);
void clearBinding(Binding binding);

bool start();
void stop();

bool startReadKey(const std::function<void(int64_t, uint64_t)>& func);
void stopReadKey();

std::string keyToString(int64_t key);
std::string maskToString(uint64_t mask);

void cleanup();

void checkAllowsAccessibility();
};

#endif
