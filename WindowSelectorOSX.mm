#include "WindowSelectorOSX.h"
#import <Cocoa/Cocoa.h>
#include <QtMac>

class ScopedPool
{
public:
    ScopedPool() { mPool = [[NSAutoreleasePool alloc] init]; }
    ~ScopedPool() { [mPool drain]; }

private:
    NSAutoreleasePool* mPool;
};

static std::string toStdString(NSString* str)
{
    return std::string([str UTF8String]);
}

static WindowRect toWindowRect(const CGRect& cg)
{
    WindowRect r;
    r.x = cg.origin.x;
    r.y = cg.origin.y;
    r.width = cg.size.width;
    r.height = cg.size.height;
    return r;
}

struct WindowData
{
    std::vector<WindowInfo> info;
    uint64_t order;
};

void WindowListApplierFunction(const void *inputDictionary, void *context)
{
    ScopedPool pool;

    NSDictionary *entry = (__bridge NSDictionary*)inputDictionary;
    WindowData* data = (__bridge WindowData*)context;
    WindowInfo info;

    // The flags that we pass to CGWindowListCopyWindowInfo will automatically filter out most undesirable windows.
    // However, it is possible that we will get back a window that we cannot read from, so we'll filter those out manually.
    int sharingState = [entry[(id)kCGWindowSharingState] intValue];
    if(sharingState != kCGWindowSharingNone)
    {
        const uint64_t layer = [entry[(id)kCGWindowLayer] integerValue];
        if (layer != 0)
            return;

        // Grab the application name, but since it's optional we need to check before we can use it.
        NSString *applicationName = entry[(id)kCGWindowOwnerName];
        if(applicationName != NULL)
        {
            info.name = toStdString(applicationName);
        }
        else
        {
            // The application name was not provided, so we use a fake application name to designate this.
            // PID is required so we assume it's present.
            NSString *nameAndPID = [NSString stringWithFormat:@"((unknown)) (%@)", entry[(id)kCGWindowOwnerPID]];
            info.name = toStdString(nameAndPID);
            [nameAndPID release];
        }
        info.pid = [entry[(id)kCGWindowOwnerPID] integerValue];

        ProcessSerialNumber psn;
        psn.highLongOfPSN = 0;
        psn.lowLongOfPSN = 0;
        GetProcessForPID(info.pid, &psn);

        info.psn = (static_cast<uint64_t>(psn.highLongOfPSN) << 32) | psn.lowLongOfPSN;

        // Grab the Window Bounds, it's a dictionary in the array, but we want to display it as a string
        CGRect bounds;
        CGRectMakeWithDictionaryRepresentation((CFDictionaryRef)entry[(id)kCGWindowBounds], &bounds);
        info.bounds = toWindowRect(bounds);

        // Grab the Window ID & Window Level. Both are required, so just copy from one to the other
        info.windowId = [entry[(id)kCGWindowNumber] integerValue];
        info.level = layer;
        info.order = data->order;
        ++data->order;

        // Grab the Window icon.
        NSRunningApplication* app = [NSRunningApplication runningApplicationWithProcessIdentifier:info.pid];
        NSImage* icon = [app icon];
        if (icon) {
            NSRect iconRect = NSMakeRect(0, 0, icon.size.width, icon.size.height);
            CGImageRef cgIcon = [icon CGImageForProposedRect:&iconRect context:NULL hints:nil];
            info.image = QtMac::fromCGImageRef(cgIcon);
        }

        data->info.push_back(info);
    }
}

QPixmap getScreenshot(uint64_t windowId)
{
    CGImageRef windowImage = CGWindowListCreateImage(CGRectNull, kCGWindowListOptionIncludingWindow, windowId, kCGWindowImageDefault | kCGWindowImageShouldBeOpaque);
    return QtMac::fromCGImageRef(windowImage);
}

void getWindows(std::vector<WindowInfo>& infos)
{
    CGWindowListOption listOptions;
    listOptions = kCGWindowListOptionAll | kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements;

    CFArrayRef windowList = CGWindowListCopyWindowInfo(listOptions, kCGNullWindowID);

    // Copy the returned list, further pruned, to another list. This also adds some bookkeeping
    // information to the list as well as
    WindowData windowData;

    CFArrayApplyFunction(windowList, CFRangeMake(0, CFArrayGetCount(windowList)), &WindowListApplierFunction, (__bridge void *)&windowData);
    CFRelease(windowList);

    infos = windowData.info;
}
