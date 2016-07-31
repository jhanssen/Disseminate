#include "EventLoop.h"
#include <deque>
#include <stdio.h>
#include <objc/runtime.h>
#import  <Cocoa/Cocoa.h>

static std::function<bool(const std::shared_ptr<EventLoopEvent>&)> sCallback;
static std::deque<NSEvent*> sPendingEvents;

EventLoop* EventLoop::sEventLoop = 0;

EventLoopEvent::~EventLoopEvent()
{
    if (flg == Release)
        [evt release];
}

EventLoop::EventLoop()
{
}

EventLoop* EventLoop::eventLoop()
{
    if (sEventLoop)
        return sEventLoop;
    sEventLoop = new EventLoop;
    return sEventLoop;
}

typedef NSEvent* (*NextEventSignature)(id self, SEL _cmd, NSUInteger mask, NSDate* expiration, NSString* mode, BOOL flag);
static IMP sNextEventMatchingMaskImp = NULL;
static NSEvent* patchedNextEventMatchingMask(id self, SEL _cmd, NSUInteger mask, NSDate* expiration, NSString* mode, BOOL flag)
{
    printf("next eventing\n");
    if (!sPendingEvents.empty()) {
        NSEvent* event = sPendingEvents.front();
        sPendingEvents.pop_front();
        printf("returning fake event window %lu evtno %ld\n", [event windowNumber], [event eventNumber]);
        return event;
    }
    NextEventSignature sig = (NextEventSignature)sNextEventMatchingMaskImp;
    NSEvent* event;
    for (;;) {
        event = sig(self, _cmd, mask, expiration, mode, flag);
#warning maybe only look at mouse/key events or give eventloop a list of wanted types?
        std::shared_ptr<EventLoopEvent> shared = std::make_shared<EventLoopEvent>(event, EventLoopEvent::None);
        if (sCallback && !sCallback(shared)) {
            continue;
        }
        break;
    }
    return event;
}

void EventLoop::swizzle()
{
    Method original = class_getInstanceMethod([NSApplication class],
                                              @selector(nextEventMatchingMask:untilDate:inMode:dequeue:));
    sNextEventMatchingMaskImp = method_setImplementation(original, (IMP)patchedNextEventMatchingMask);
}

void EventLoop::onEvent(const std::function<bool(const std::shared_ptr<EventLoopEvent>&)>& on)
{
    sCallback = on;
}

// void EventLoop::addEvent(Event&& event)
// {
// }
