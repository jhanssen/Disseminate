#ifndef EVENTLOOP_H
#define EVENTLOOP_H

#include <functional>

class EventLoop
{
public:
    static EventLoop* eventLoop();

    void swizzle();
    //void addEvent(Event&& event);

    void onLoopIteration(const std::function<void()>& on);

private:
    EventLoop();
    EventLoop(const EventLoop&) = delete;
    EventLoop& operator=(const EventLoop&) = delete;

private:
    static EventLoop* sEventLoop;
};

#endif
