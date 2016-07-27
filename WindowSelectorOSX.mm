#include "WindowSelectorOSX.h"
#import <Cocoa/Cocoa.h>

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

NSString *kAppNameKey = @"applicationName";	// Application Name & PID
NSString *kWindowOriginKey = @"windowOrigin";	// Window Origin as a string
NSString *kWindowSizeKey = @"windowSize";		// Window Size as a string
NSString *kWindowIDKey = @"windowID";			// Window ID
NSString *kWindowLevelKey = @"windowLevel";	// Window Level
NSString *kWindowOrderKey = @"windowOrder";	// The overall front-to-back ordering of the windows as returned by the window server

void WindowListApplierFunction(const void *inputDictionary, void *context)
{
    NSDictionary *entry = (__bridge NSDictionary*)inputDictionary;
    WindowData* data = (__bridge WindowData*)context;
    WindowInfo info;

        // The flags that we pass to CGWindowListCopyWindowInfo will automatically filter out most undesirable windows.
        // However, it is possible that we will get back a window that we cannot read from, so we'll filter those out manually.
        int sharingState = [entry[(id)kCGWindowSharingState] intValue];
        if(sharingState != kCGWindowSharingNone)
        {
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
                info.level = [entry[(id)kCGWindowLayer] integerValue];
                info.order = data->order;
                ++data->order;
                data->info.push_back(info);
        }
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
