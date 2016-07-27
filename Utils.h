#ifndef UTILS_H
#define UTILS_H

#include <cstdint>
#include <functional>

namespace capture {
void addWindow(uint64_t window);
void removeWindow(uint64_t window);

bool start();
void stop();

bool startReadKey(const std::function<void(int64_t)>& func);
void stopReadKey();
};

#endif
