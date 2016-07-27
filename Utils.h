#ifndef UTILS_H
#define UTILS_H

#include <cstdint>
#include <functional>

namespace capture {
void addWindow(uint64_t window);
void removeWindow(uint64_t window);

enum KeyType { WhiteList, BlackList };
void setKeyType(KeyType type);
void addKey(int64_t key, uint64_t mask);
void removeKey(int64_t key, uint64_t mask);

bool start();
void stop();

bool startReadKey(const std::function<void(int64_t, uint64_t)>& func);
void stopReadKey();
};

#endif