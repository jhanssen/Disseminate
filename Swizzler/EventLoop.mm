#include "EventLoop.h"
#include <deque>
#include <unordered_set>
#include <stdio.h>
#include <objc/runtime.h>
#import  <Cocoa/Cocoa.h>

static std::function<bool(const std::shared_ptr<EventLoopEvent>&)> sCallback;
static std::deque<std::shared_ptr<EventLoopEvent> > sPendingEvents;
static std::unordered_set<NSEvent*> sKnownEvents;
static bool sProcessingPending = false;

static uintptr_t ProcessPending1 = reinterpret_cast<uintptr_t>(&ProcessPending1);
static uintptr_t ProcessPending2 = reinterpret_cast<uintptr_t>(&ProcessPending2);

EventLoop* EventLoop::sEventLoop = 0;

EventLoopEvent::EventLoopEvent(NSEvent* event, Flag flag)
    : evt(event), flg(flag)
{
    if (flg == Retain)
        [evt retain];
}

EventLoopEvent::~EventLoopEvent()
{
    if (evt && flg == Retain)
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
    NextEventSignature sig = (NextEventSignature)sNextEventMatchingMaskImp;
    NSEvent* event;
    for (;;) {
        event = sig(self, _cmd, mask, expiration, mode, flag);
        if ([event type] == NSApplicationDefined) {
            printf("got app defined %p\n", [event context]);
            if ([event data1] == ProcessPending1 && [event data2] == ProcessPending2) {
                auto it = sPendingEvents.begin();
                const auto end = sPendingEvents.end();
                NSApplication* app = [NSApplication sharedApplication];
                while (it != end) {
                    event = (*it)->take();
                    NSPoint loc = [event locationInWindow];
                    printf("sending fake event %lu window %lu evtno %ld %f %f ctx %p ts %f\n", [event type], [event windowNumber], [event eventNumber], loc.x, loc.y, [event context], [event timestamp]);

                    [app sendEvent:event];
                    ++it;
                }
                sPendingEvents.clear();
                sProcessingPending = false;
                continue;
            }
        }
#warning maybe only look at mouse/key events or give eventloop a list of wanted types?
        std::shared_ptr<EventLoopEvent> shared = std::make_shared<EventLoopEvent>(event, EventLoopEvent::None);
        if (sCallback && !sCallback(shared)) {
            NSPoint loc = [event locationInWindow];
            printf("blocking real event %lu window %lu evtno %ld %f %f ctx %p ts %f\n", [event type], [event windowNumber], [event eventNumber], loc.x, loc.y, [event context], [event timestamp]);
            //[event release];
            continue;
        }
        break;
    }
    return event;
}

void EventLoop::postEvent(const std::shared_ptr<EventLoopEvent>& evt)
{
    sPendingEvents.push_back(evt);
    if (sProcessingPending)
        return;
    sProcessingPending = true;
    NSEvent* event = [NSEvent otherEventWithType: NSApplicationDefined
                      location: NSMakePoint(0,0)
                      modifierFlags: 0
                      timestamp: 0.0
                      windowNumber: 0
                      context: 0
                      subtype: 0
                      data1: ProcessPending1
                      data2: ProcessPending2];
    [[NSApplication sharedApplication] postEvent:event atStart:YES];
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
