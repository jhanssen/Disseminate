#ifndef EVENTLOOP_H
#define EVENTLOOP_H

#include <functional>
#include <memory>
#include <map>
#include <vector>
#include <AppKit/NSEvent.h>

class EventLoop;

class EventLoopEvent
{
public:
    enum Flag { None, Retain };
    EventLoopEvent(NSEvent* event, Flag flag);
    EventLoopEvent(NSEvent* event, Flag flag, double dx, double dy);
    ~EventLoopEvent();

    NSEvent* take() { NSEvent* e = evt; evt = 0; return e; }

    NSEvent* evt;
    Flag flg;
    bool hasDelta;
    double deltaX, deltaY;
};

class EventLoopTimer : public std::enable_shared_from_this<EventLoopTimer>
{
public:
    enum Type { Timeout, Interval };

    void start(uint32_t timeout, Type type = Timeout);
    bool stop();

    void onTimeout(const std::function<void()>& func);

    void operator()() { callback(); }

private:
    EventLoopTimer(EventLoop* l);
    EventLoopTimer(const EventLoopTimer&) = delete;
    EventLoopTimer& operator=(const EventLoopTimer&) = delete;

private:
    EventLoop* loop;
    std::function<void()> callback;
    double interval;
    uint32_t when;

    friend class EventLoopHack;
    friend class EventLoop;
};

class EventLoop
{
public:
    static EventLoop* eventLoop();

    void swizzle();
    //void addEvent(Event&& event);

    void onEvent(const std::function<bool(const std::shared_ptr<EventLoopEvent>&)>& on);
    void onTerminate(const std::function<void()>& on);
    void postEvent(const std::shared_ptr<EventLoopEvent>& evt);

    void wakeup();

    std::shared_ptr<EventLoopTimer> makeTimer();

private:
    EventLoop();
    EventLoop(const EventLoop&) = delete;
    EventLoop& operator=(const EventLoop&) = delete;

    void startTimer(uint32_t when, EventLoopTimer::Type type, const std::shared_ptr<EventLoopTimer>& timer);
    bool stopTimer(const std::shared_ptr<EventLoopTimer>& timer);

private:
    static EventLoop* sEventLoop;

    friend class EventLoopTimer;
};

#endif
