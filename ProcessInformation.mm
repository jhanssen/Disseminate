/*
    Disseminate, keyboard broadcaster
    Copyright (C) 2016  Jan Erik Hanssen

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include "ProcessInformation.h"
#include "CocoaUtils.h"
#import <Cocoa/Cocoa.h>
#include <QtMac>

static std::string toStdString(NSString* str)
{
    return std::string([str UTF8String]);
}

static QString toQString(NSString* str)
{
    return QString::fromUtf8([str UTF8String]);
}

struct WindowData
{
    pid_t pid;
    struct Entry
    {
        CGWindowID window;
        QPixmap icon;
        QString name;
    };
    std::vector<Entry> windows;
};

void WindowListApplierFunction(const void *inputDictionary, void *context)
{
    ScopedPool pool;

    NSDictionary *entry = (__bridge NSDictionary*)inputDictionary;
    WindowData* data = (__bridge WindowData*)context;

    // The flags that we pass to CGWindowListCopyWindowInfo will automatically filter out most undesirable windows.
    // However, it is possible that we will get back a window that we cannot read from, so we'll filter those out manually.
    int sharingState = [entry[(id)kCGWindowSharingState] intValue];
    if(sharingState != kCGWindowSharingNone)
    {
        const uint64_t layer = [entry[(id)kCGWindowLayer] integerValue];
        if (layer != 0)
            return;

        auto pid = [entry[(id)kCGWindowOwnerPID] integerValue];
        if (pid != data->pid)
            return;

        WindowData::Entry info;

        // Grab the application name, but since it's optional we need to check before we can use it.
        NSString *applicationName = entry[(id)kCGWindowOwnerName];
        if(applicationName != NULL)
        {
            info.name = toQString(applicationName);
        }
        else
        {
            // The application name was not provided, so we use a fake application name to designate this.
            // PID is required so we assume it's present.
            NSString *nameAndPID = [NSString stringWithFormat:@"((unknown)) (%@)", entry[(id)kCGWindowOwnerPID]];
            info.name = toQString(nameAndPID);
            [nameAndPID release];
        }
        auto windowId = [entry[(id)kCGWindowNumber] integerValue];
        info.window = windowId;

        // Grab the Window icon.
        NSRunningApplication* app = [NSRunningApplication runningApplicationWithProcessIdentifier:pid];
        NSImage* icon = [app icon];
        if (icon) {
            NSRect iconRect = NSMakeRect(0, 0, icon.size.width, icon.size.height);
            CGImageRef cgIcon = [icon CGImageForProposedRect:&iconRect context:NULL hints:nil];
            info.icon = QtMac::fromCGImageRef(cgIcon);
        }
        data->windows.push_back(info);

        /*
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
        */
    }
}

static void windowsForPid(pid_t pid, WindowData* windowData)
{
    CGWindowListOption listOptions;
    listOptions = kCGWindowListOptionAll | kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements;

    CFArrayRef windowList = CGWindowListCopyWindowInfo(listOptions, kCGNullWindowID);

    // Copy the returned list, further pruned, to another list. This also adds some bookkeeping
    // information to the list as well as
    windowData->pid = pid;

    CFArrayApplyFunction(windowList, CFRangeMake(0, CFArrayGetCount(windowList)), &WindowListApplierFunction, (__bridge void *)windowData);
    CFRelease(windowList);
}

QPixmap getScreenshot(pid_t pid)
{
    WindowData data;
    windowsForPid(pid, &data);

    if (data.windows.empty())
        return QPixmap();
    auto windowId = data.windows[0].window;
    CGImageRef windowImage = CGWindowListCreateImage(CGRectNull, kCGWindowListOptionIncludingWindow, windowId, kCGWindowImageDefault | kCGWindowImageShouldBeOpaque);
    return QtMac::fromCGImageRef(windowImage);
}

ProcessInformation getInformation(pid_t pid)
{
    WindowData data;
    windowsForPid(pid, &data);

    if (data.windows.empty())
        return ProcessInformation();
    ProcessInformation info = { data.windows[0].icon, data.windows[0].name, data.windows[0].window };
    return info;
}
