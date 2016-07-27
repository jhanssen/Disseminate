#include "Utils.h"
#include <vector>
#import <Cocoa/Cocoa.h>

static bool equalsPsn(const ProcessSerialNumber& p1, const ProcessSerialNumber& p2)
{
    return p1.highLongOfPSN == p2.highLongOfPSN && p1.lowLongOfPSN == p2.lowLongOfPSN;
}

struct LocalWindow;

struct Source
{
    ProcessSerialNumber psn;
    CFMachPortRef tap;
    CFRunLoopSourceRef source;
    LocalWindow* local;
};

struct Windows
{
    std::vector<ProcessSerialNumber> psns;
    std::vector<Source> sources;
};

struct LocalWindow
{
    ProcessSerialNumber psn;
    Windows* windows;
};

struct ReadKey
{
    CFMachPortRef tap;
    CFRunLoopSourceRef source;
    std::function<void(int64_t)> func;
};

static Windows windows;
static ReadKey readKey = { nullptr, nullptr, nullptr };

void capture::addWindow(uint64_t window)
{
    ProcessSerialNumber psn;
    psn.highLongOfPSN = window >> 32;
    psn.lowLongOfPSN = window & 0x00000000FFFFFFFFLLU;
    windows.psns.push_back(psn);
}

void capture::removeWindow(uint64_t window)
{
    ProcessSerialNumber psn;
    psn.highLongOfPSN = window >> 32;
    psn.lowLongOfPSN = window & 0x00000000FFFFFFFFLLU;
    auto it = windows.psns.begin();
    const auto& end = windows.psns.cend();
    while (it != end) {
        if (equalsPsn(*it, psn)) {
            windows.psns.erase(it);
            return;
        }
        ++it;
    }
}

static ProcessSerialNumber activePSN()
{
    NSWorkspace* workspace            = [NSWorkspace sharedWorkspace];
    NSDictionary* currentAppInfo      = [workspace activeApplication];

    //Get the PSN of the current application.
    ProcessSerialNumber psn;
    psn.lowLongOfPSN = [[currentAppInfo objectForKey:@"NSApplicationProcessSerialNumberLow"] longValue];
    psn.highLongOfPSN = [[currentAppInfo objectForKey:@"NSApplicationProcessSerialNumberHigh"] longValue];
    return psn;
}

CGEventRef broadcastCGEventCallback(CGEventTapProxy /*proxy*/,
                                    CGEventType type,
                                    CGEventRef event,
                                    void *refcon)
{
    LocalWindow* local = static_cast<LocalWindow*>(refcon);
    if (!equalsPsn(local->psn, activePSN()))
        return event;
    if(type == NX_KEYDOWN || type == NX_KEYUP) {
        for (auto& source : windows.sources) {
            if (!equalsPsn(local->psn, source.psn)) {
                CGEventRef copy = CGEventCreateCopy(event);
                CGEventPostToPSN(&source.psn, copy);
            }
        }
    }

   // send event to next application
   return event;
}

CGEventRef readkeyCGEventCallback(CGEventTapProxy /*proxy*/,
                                  CGEventType type,
                                  CGEventRef event,
                                  void *refcon)
{
    if(type == NX_KEYDOWN || type == NX_KEYUP) {
        ReadKey* readKey = static_cast<ReadKey*>(refcon);
        // CG_EXTERN int64_t CGEventGetIntegerValueField(CGEventRef __nullable event,
        // CGEventField field)
        const int64_t virt = CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
        readKey->func(virt);
    }

    return event;
}

bool capture::start()
{
    stop();

    CFRunLoopRef runloop = (CFRunLoopRef)CFRunLoopGetCurrent();

    CGEventMask interestedEvents = CGEventMaskBit(kCGEventKeyDown) | CGEventMaskBit(kCGEventKeyUp);
    for (auto& psn : windows.psns) {
        LocalWindow* local = new LocalWindow;
        local->windows = &windows;
        local->psn = psn;

        CFMachPortRef eventTap = CGEventTapCreateForPSN(&psn, kCGHeadInsertEventTap,
                                                        kCGEventTapOptionDefault, interestedEvents, broadcastCGEventCallback, local);
        if (!eventTap)
            return false;
        // by passing self as last argument, you can later send events to this class instance

        CFRunLoopSourceRef source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0);
        CFRunLoopAddSource(runloop, source, kCFRunLoopCommonModes);

        windows.sources.push_back({ psn, eventTap, source, local });
    }
    return true;
}

void capture::stop()
{
    CFRunLoopRef runloop = (CFRunLoopRef)CFRunLoopGetCurrent();
    for (auto& source : windows.sources) {
        CFRunLoopRemoveSource(runloop, source.source, kCFRunLoopCommonModes);
        CFRelease(source.source);
        CFRelease(source.tap);
    }
    windows.sources.clear();
}

bool capture::startReadKey(const std::function<void(int64_t)>& func)
{
    stopReadKey();

    CFRunLoopRef runloop = (CFRunLoopRef)CFRunLoopGetCurrent();
    CGEventMask interestedEvents = CGEventMaskBit(kCGEventKeyDown) | CGEventMaskBit(kCGEventKeyUp);
    ProcessSerialNumber psn = activePSN();
    readKey.tap = CGEventTapCreateForPSN(&psn, kCGHeadInsertEventTap,
                                         kCGEventTapOptionDefault, interestedEvents, readkeyCGEventCallback, &readKey);
    if (!readKey.tap)
        return false;
    readKey.source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, readKey.tap, 0);
    readKey.func = func;
    CFRunLoopAddSource(runloop, readKey.source, kCFRunLoopCommonModes);
    return true;
}

void capture::stopReadKey()
{
    if (readKey.source) {
        CFRunLoopRef runloop = (CFRunLoopRef)CFRunLoopGetCurrent();
        CFRunLoopRemoveSource(runloop, readKey.source, kCFRunLoopCommonModes);
        CFRelease(readKey.source);
        CFRelease(readKey.tap);
        readKey = { nullptr, nullptr, nullptr };
    }
}
