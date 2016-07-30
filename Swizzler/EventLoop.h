#ifndef EVENTLOOP_H
#define EVENTLOOP_H

#include <functional>
#include <AppKit/NSEvent.h>

class EventLoop
{
public:
    static EventLoop* eventLoop();

    void swizzle();
    //void addEvent(Event&& event);

    void onEvent(const std::function<bool(NSEvent*)>& on);

private:
    EventLoop();
    EventLoop(const EventLoop&) = delete;
    EventLoop& operator=(const EventLoop&) = delete;

private:
    static EventLoop* sEventLoop;
};

#endif
