#ifndef EVENTLOOP_H
#define EVENTLOOP_H

#include <functional>
#include <memory>
#include <AppKit/NSEvent.h>

class EventLoopEvent
{
public:
    enum Flag { None, Release };
    EventLoopEvent(NSEvent* event, Flag flag)
        : evt(event), flg(flag)
    {
    }
    ~EventLoopEvent();

    NSEvent* evt;
    Flag flg;
};

class EventLoop
{
public:
    static EventLoop* eventLoop();

    void swizzle();
    //void addEvent(Event&& event);

    void onEvent(const std::function<bool(const std::shared_ptr<EventLoopEvent>&)>& on);
    void postEvent(const std::shared_ptr<EventLoopEvent>& evt);

private:
    EventLoop();
    EventLoop(const EventLoop&) = delete;
    EventLoop& operator=(const EventLoop&) = delete;

private:
    static EventLoop* sEventLoop;
};

#endif
