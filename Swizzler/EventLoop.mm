#include "EventLoop.h"
#include <deque>
#include <unordered_set>
#include <stdio.h>
#include <objc/runtime.h>
#include "CocoaUtils.h"
#import  <Cocoa/Cocoa.h>

static std::function<bool(const std::shared_ptr<EventLoopEvent>&)> sEventCallback;
static std::function<void()> sTerminateCallback;
static std::deque<std::shared_ptr<EventLoopEvent> > sPendingEvents;
std::map<double, std::vector<std::pair<EventLoopTimer::Type, std::weak_ptr<EventLoopTimer> > > > sTimers;
static std::unordered_set<NSEvent*> sKnownEvents;
static bool sProcessingPending = false;

class EventLoopHack
{
public:
    static uint32_t when(EventLoopTimer* timer)
    {
        return timer->when;
    }
};

static inline double makeInterval(uint32_t when)
{
    ScopedPool pool;
    NSTimeInterval seconds = when / 1000.;
    NSDate* date = [[[NSDate alloc] initWithTimeIntervalSinceNow:seconds] autorelease];
    return [date timeIntervalSince1970];
}


static inline void fireTimers()
{
    ScopedPool pool;
    auto now = [[NSDate date] timeIntervalSince1970];

    // first call all timers
    {
        // copy the list in case someone stops our timers
        // in the callback while we walk them
        const auto copy = sTimers;
        auto it = copy.cbegin();
        while (it != copy.cend()) {
            if (it->first > now)
                break;
            auto& vec = it->second;
            auto t = vec.begin();
            while (t != vec.end()) {
                if (auto shared = t->second.lock()) {
                    (*shared)();
                }
                ++t;
            }
            ++it;
        }
    }

    std::vector<std::pair<EventLoopTimer::Type, std::weak_ptr<EventLoopTimer> > > remakes;

    // then walk the list again and remove the
    // ones we're no longer interrested in
    auto it = sTimers.begin();
    while (it != sTimers.end()) {
        if (it->first > now)
            break;
        auto& vec = it->second;
        auto t = vec.begin();
        while (t != vec.end()) {
            if (auto shared = t->second.lock()) {
                auto type = t->first;
                t = vec.erase(t);
                if (type == EventLoopTimer::Interval) {
                    remakes.push_back(std::make_pair(type, shared));
                }
            } else {
                t = vec.erase(t);
            }
        }
        if (vec.empty())
            sTimers.erase(it++);
        else
            ++it;
    }

    // reinsert interval timers
    auto iit = remakes.begin();
    const auto iend = remakes.end();
    while (iit != iend) {
        if (auto shared = iit->second.lock()) {
            const double interval = makeInterval(EventLoopHack::when(shared.get()));
            sTimers[interval].push_back(std::make_pair(iit->first, iit->second));
        }
        ++iit;
    }
}

static uintptr_t ProcessPending1 = reinterpret_cast<uintptr_t>(&ProcessPending1);
static uintptr_t ProcessPending2 = reinterpret_cast<uintptr_t>(&ProcessPending2);

EventLoop* EventLoop::sEventLoop = 0;

EventLoopEvent::EventLoopEvent(NSEvent* event, Flag flag)
    : evt(event), flg(flag), hasDelta(false), deltaX(0.), deltaY(0.)
{
    if (flg == Retain)
        [evt retain];
}

EventLoopEvent::EventLoopEvent(NSEvent* event, Flag flag, double dx, double dy)
    : evt(event), flg(flag), hasDelta(true), deltaX(dx), deltaY(dy)
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

struct {
    bool has;
    float dx, dy;
} static sDelta = { false, 0., 0, };

static inline void sendEvent(NSEvent* event)
{
    auto wno = [event windowNumber];
    NSWindow* win = [[NSApplication sharedApplication] windowWithWindowNumber:wno];
    if (!win) {
        printf("out 1\n");
        return;
    }
    /*
    NSView* view = [win contentView];
    if (!view) {
        printf("out 2\n");
        return;
    }
    NSView* target = [view hitTest:[event locationInWindow]];
    if (!target) {
        printf("out 3\n");
        return;
        }
    */
    NSResponder* responder = [win firstResponder];
    if (!responder) {
        printf("out 2\n");
        return;
    }
    if (![responder isKindOfClass:[NSView class]]) {
        printf("out 3\n");
        return;
    }
    NSView* target = (NSView*)responder;
    switch ([event type]) {
    case NSLeftMouseDown:
        [target mouseDown:event];
        break;
    case NSRightMouseDown:
        [target rightMouseDown:event];
        break;
    case NSLeftMouseUp:
        [target mouseUp:event];
        break;
    case NSRightMouseUp:
        [target rightMouseUp:event];
        break;
    case NSMouseMoved:
        [target mouseMoved:event];
        break;
    case NSLeftMouseDragged:
        [target mouseDragged:event];
        break;
    case NSRightMouseDragged:
        [target rightMouseDragged:event];
        break;
    case NSKeyDown:
        [target keyDown:event];
        break;
    case NSKeyUp:
        [target keyUp:event];
        break;
    default:
        printf("no joy\n");
        break;
    }
}

typedef NSEvent* (*NextEventSignature)(id self, SEL _cmd, NSUInteger mask, NSDate* expiration, NSString* mode, BOOL flag);
static IMP sNextEventMatchingMaskImp = NULL;
static NSEvent* patchedNextEventMatchingMask(id self, SEL _cmd, NSUInteger mask, NSDate* expiration, NSString* mode, BOOL flag)
{
    //printf("next eventing\n");
    ScopedPool pool;
    NextEventSignature sig = (NextEventSignature)sNextEventMatchingMaskImp;
    NSEvent* event;
    for (;;) {
        NSDate* exp = expiration;
        if (!sTimers.empty()) {
            auto t = sTimers.begin();
            printf("we'd like a timeout of %f\n", t->first);
            NSDate* nextTimer = [[[NSDate alloc] initWithTimeIntervalSince1970:t->first] autorelease];
            if (!expiration)
                exp = nextTimer;
            else
                exp = [nextTimer earlierDate:expiration];
        }
        event = sig(self, _cmd, mask, exp, mode, flag);
        if (!event) {
            if (exp != expiration) {
                fireTimers();
                continue;
            }
            return 0;
        }
        if (exp && exp != expiration)
            fireTimers();
        if ([event type] == NSApplicationDefined) {
            printf("got app defined %p\n", [event context]);
            if ([event data1] == ProcessPending1 && [event data2] == ProcessPending2) {
                if (!sPendingEvents.empty()) {
                    auto it = sPendingEvents.begin();
                    const auto end = sPendingEvents.end();
                    NSApplication* app = [NSApplication sharedApplication];
                    while (it != end) {
                        const auto& fake = *it;
                        event = fake->take();
                        if (fake->hasDelta) {
                            sDelta.has = true;
                            sDelta.dx = fake->deltaX;
                            sDelta.dy = fake->deltaY;
                        } else {
                            sDelta.has = false;
                        }
                        NSPoint loc = [event locationInWindow];
                        printf("sending fake event %lu window %lu %f %f ctx %p ts %f\n", [event type], [event windowNumber], loc.x, loc.y, [event context], [event timestamp]);

                        sendEvent(event);
                        // [app sendEvent:event];
                        ++it;
                    }
                    sPendingEvents.clear();
                }
                sProcessingPending = false;
                continue;
            }
        }
#warning maybe only look at mouse/key events or give eventloop a list of wanted types?
        std::shared_ptr<EventLoopEvent> shared = std::make_shared<EventLoopEvent>(event, EventLoopEvent::None);
        if (sEventCallback && !sEventCallback(shared)) {
            NSPoint loc = [event locationInWindow];
            printf("blocking real event %lu window %lu %f %f ctx %p ts %f\n", [event type], [event windowNumber], loc.x, loc.y, [event context], [event timestamp]);
            //[event release];
            continue;
        }
        break;
    }
    switch ([event type]) {
    case NSMouseMoved:
    case NSLeftMouseDragged:
    case NSRightMouseDragged:
        if (sDelta.has)
            sDelta.has = false;
        break;
    default:
        break;
    }
    return event;
}

typedef void (*TerminateSignature)(id self, SEL _cmd, id sender);
static IMP sTerminateImp = NULL;
static void patchedTerminate(id self, SEL _cmd, id sender)
{
    if (sTerminateCallback)
        sTerminateCallback();

    TerminateSignature sig = (TerminateSignature)sTerminateImp;
    sig(self, _cmd, sender);
}

typedef CGFloat (*FloatSignature)(id self, SEL _cmd);
static IMP sDeltaX = NULL;
static CGFloat patchedDeltaX(id self, SEL _cmd)
{
    if (sDelta.has)
        return sDelta.dx;
    FloatSignature sig = (FloatSignature)sDeltaX;
    return sig(self, _cmd);
}
static IMP sDeltaY = NULL;
static CGFloat patchedDeltaY(id self, SEL _cmd)
{
    if (sDelta.has)
        return sDelta.dy;
    FloatSignature sig = (FloatSignature)sDeltaY;
    return sig(self, _cmd);
}

typedef NSUInteger (*PressedMouseButtonsSignature)(id self, SEL _cmd);
static IMP sPressedMouseButtons = NULL;
static NSUInteger patchedPressedMouseButtons(id self, SEL _cmd)
{
    printf("pressed mouse buttons\n");
    PressedMouseButtonsSignature sig = (PressedMouseButtonsSignature)sPressedMouseButtons;
    return sig(self, _cmd);
}

typedef NSInteger (*ButtonNumberSignature)(id self, SEL _cmd);
static IMP sButtonNumber = NULL;
static NSInteger patchedButtonNumber(id self, SEL _cmd)
{
    printf("button number\n");
    NSEvent* ev = (NSEvent*)self;
    switch ([ev type]) {
    case NSLeftMouseDown:
    case NSLeftMouseUp:
    case NSLeftMouseDragged:
        return 0;
    case NSRightMouseDown:
    case NSRightMouseUp:
    case NSRightMouseDragged:
        return 1;
    default:
        break;
    };
    ButtonNumberSignature sig = (ButtonNumberSignature)sButtonNumber;
    return sig(self, _cmd);
    // NSInteger ret = sig(self, _cmd);
    // printf(" - for %lu -> %ld\n", [ev type], ret);
    // return ret;
}

void EventLoop::postEvent(const std::shared_ptr<EventLoopEvent>& evt)
{
    sPendingEvents.push_back(evt);
    wakeup();
}

void EventLoop::wakeup()
{
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
    {
        Method original = class_getInstanceMethod([NSApplication class],
                                                  @selector(nextEventMatchingMask:untilDate:inMode:dequeue:));
        sNextEventMatchingMaskImp = method_setImplementation(original, (IMP)patchedNextEventMatchingMask);
    }
    {
        Method original = class_getInstanceMethod([NSApplication class],
                                                  @selector(terminate:));
        sTerminateImp = method_setImplementation(original, (IMP)patchedTerminate);
    }
    {
        Method original = class_getInstanceMethod([NSEvent class], @selector(deltaX));
        sDeltaX = method_setImplementation(original, (IMP)patchedDeltaX);
    }
    {
        Method original = class_getInstanceMethod([NSEvent class], @selector(deltaY));
        sDeltaY = method_setImplementation(original, (IMP)patchedDeltaY);
    }
    {
        Method original = class_getInstanceMethod([NSEvent class], @selector(buttonNumber));
        sButtonNumber = method_setImplementation(original, (IMP)patchedButtonNumber);
    }
    {
        Method original = class_getClassMethod([NSEvent class], @selector(pressedMouseButtons));
        sPressedMouseButtons = method_setImplementation(original, (IMP)patchedPressedMouseButtons);
    }
}

void EventLoop::onEvent(const std::function<bool(const std::shared_ptr<EventLoopEvent>&)>& on)
{
    sEventCallback = on;
}

void EventLoop::onTerminate(const std::function<void()>& on)
{
    sTerminateCallback = on;
}

std::shared_ptr<EventLoopTimer> EventLoop::makeTimer()
{
    return std::shared_ptr<EventLoopTimer>(new EventLoopTimer(this));
}

void EventLoop::startTimer(uint32_t when, EventLoopTimer::Type type, const std::shared_ptr<EventLoopTimer>& timer)
{
    const double interval = makeInterval(when);
    sTimers[interval].push_back(std::make_pair(type, timer));
    timer->interval = interval;
    timer->when = when;
}

bool EventLoop::stopTimer(const std::shared_ptr<EventLoopTimer>& timer)
{
    auto& vec = sTimers[timer->interval];
    if (vec.empty())
        return false;
    auto t = vec.begin();
    while (t != vec.end()) {
        if (auto shared = t->second.lock()) {
            if (shared == timer) {
                vec.erase(t);
                if (vec.empty())
                    sTimers.erase(timer->interval);
                return true;
            }
            ++t;
        } else {
            t = vec.erase(t);
        }
    }
    if (vec.empty())
        sTimers.erase(timer->interval);
    return false;
}

EventLoopTimer::EventLoopTimer(EventLoop* l)
    : loop(l), interval(0.), when(0)
{
}

void EventLoopTimer::start(uint32_t timeout, Type type)
{
    loop->startTimer(timeout, type, shared_from_this());
}

bool EventLoopTimer::stop()
{
    return loop->stopTimer(shared_from_this());
}

void EventLoopTimer::onTimeout(const std::function<void()>& func)
{
    callback = func;
}

// void EventLoop::addEvent(Event&& event)
// {
// }
