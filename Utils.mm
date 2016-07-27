#include "Utils.h"
#include <vector>
#include <unordered_map>
#include <assert.h>
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
    std::function<void(int64_t, uint64_t)> func;
};

struct KeyList
{
    capture::KeyType type;
    std::unordered_map<int64_t, std::vector<uint64_t> > keys;
};

static Windows windows;
static ReadKey readKey = { nullptr, nullptr, nullptr };
static KeyList keyList = { capture::WhiteList, std::unordered_map<int64_t, std::vector<uint64_t> >() };

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

void capture::clearWindows()
{
    assert(windows.sources.empty());
    windows.psns.clear();
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
        const int64_t virt = CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
        const CGEventFlags flags = CGEventGetFlags(event);

        const auto keyit = keyList.keys.find(virt);
        switch (keyList.type) {
        case capture::WhiteList: {
            if (keyit == keyList.keys.end())
                return event;
            const auto& vec = keyit->second;
            if (std::find(vec.begin(), vec.end(), flags) == vec.end())
                return event;
            break; }
        case capture::BlackList: {
            if (keyit == keyList.keys.end())
                break;
            const auto& vec = keyit->second;
            if (std::find(vec.begin(), vec.end(), flags) == vec.end())
                break;
            return event; }
        }

        for (auto& source : windows.sources) {
            if (!equalsPsn(local->psn, source.psn)) {
                //CGEventRef copy = CGEventCreateCopy(event);
                CGEventPostToPSN(&source.psn, event);
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
    if(type == NX_KEYDOWN) {
        ReadKey* readKey = static_cast<ReadKey*>(refcon);
        // CG_EXTERN int64_t CGEventGetIntegerValueField(CGEventRef __nullable event,
        // CGEventField field)
        const int64_t virt = CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
        const CGEventFlags flags = CGEventGetFlags(event);
        readKey->func(virt, flags);
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

bool capture::startReadKey(const std::function<void(int64_t, uint64_t)>& func)
{
    stopReadKey();

    CFRunLoopRef runloop = (CFRunLoopRef)CFRunLoopGetCurrent();
    CGEventMask interestedEvents = CGEventMaskBit(kCGEventKeyDown);
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

void capture::setKeyType(KeyType type)
{
    keyList.type = type;
}

void capture::addKey(int64_t key, uint64_t mask)
{
    keyList.keys[key].push_back(mask);
}

void capture::removeKey(int64_t key, uint64_t mask)
{
    auto it = keyList.keys.find(key);
    assert(it == keyList.keys.end());
    auto& vec = it->second;
    auto vit = std::find(vec.begin(), vec.end(), mask);
    assert(vit == vec.end());
    vec.erase(vit);
    if (vec.empty())
        keyList.keys.erase(it);
}

void capture::clearKeys()
{
    keyList.keys.clear();
}
