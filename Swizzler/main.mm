#include <stdio.h>
#include <objc/runtime.h>
#import <Cocoa/Cocoa.h>
#import <dispatch/dispatch.h>
#include <deque>

@interface DisseminateSwizzle : NSObject

@end

std::deque<NSEvent*> sPendingEvents;

static NSGraphicsContext* sContext = 0;
static NSInteger sEventNumber = 0;
static NSInteger sEventOffset = 0;

typedef NSEvent* (*NextEventSignature)(id self, SEL _cmd, NSUInteger mask, NSDate* expiration, NSString* mode, BOOL flag);
static IMP sNextEventMatchingMaskImp = NULL;
static NSEvent* patchedNextEventMatchingMask(id self, SEL _cmd, NSUInteger mask, NSDate* expiration, NSString* mode, BOOL flag)
{
    NextEventSignature sig = (NextEventSignature)sNextEventMatchingMaskImp;
    //printf("next eventing\n");
    NSEvent* event;
    for (;;) {
        if (!sPendingEvents.empty()) {
            event = sPendingEvents.front();
            sPendingEvents.pop_front();
            printf("returning fake event window %lu evtno %ld\n", [event windowNumber], [event eventNumber]);
            return event;
        }
        event = sig(self, _cmd, mask, expiration, mode, flag);
        switch ([event type]) {
        case NSLeftMouseDown:
        case NSLeftMouseUp: {
            NSPoint pt = [event locationInWindow];
            if (!sContext)
                sContext = [event context];
            if (sEventNumber < [event eventNumber])
                sEventNumber = [event eventNumber];
            printf("got mouse event %f %f in window %lu ctx %p evtno %ld\n", pt.x, pt.y, [event windowNumber], [event context], [event eventNumber]);
            // if (pt.x > 1760) {
            //     printf("not passing\n");
            //     continue;
            // }
            //continue;
            break; }
        case NSApplicationDefined:
            printf("app event\n");
            break;
        default:
            break;
        }
        break;
    }
    //printf("got event of type %lu\n", [event type]);
    return event;
}

// typedef void (*VoidSignature)(id self, SEL cmd);

// static IMP sCursorSet = NULL;
// static void patchedCursorSet(id self, SEL _cmd)
// {
//     printf("cursor set\n");
//     VoidSignature sig = (VoidSignature)sCursorSet;
//     sig(self, _cmd);
// }

// static IMP sCursorPush = NULL;
// static void patchedCursorPush(id self, SEL _cmd)
// {
//     printf("cursor push\n");
//     VoidSignature sig = (VoidSignature)sCursorPush;
//     sig(self, _cmd);
// }

typedef void (*AddCursorRectSignature)(id self, SEL _cmd, NSRect rect, NSCursor* cursor);
static IMP sAddCursorRect = NULL;
static void patchedAddCursorRect(id self, SEL _cmd, NSRect rect, NSCursor* cursor)
{
    printf("add cursor\n");
    AddCursorRectSignature sig = (AddCursorRectSignature)sAddCursorRect;
    sig(self, _cmd, rect, cursor);
}


struct PortData {
    CFMessagePortRef port;
    CFRunLoopSourceRef source;
};

static struct PortData portData;

static CFDataRef DisseminateCallback(CFMessagePortRef port,
                                     SInt32 messageID,
                                     CFDataRef data,
                                     void *info)
{
    printf("got message %x\n", messageID);
    // let's make a press and release event
    NSPoint pt = { 1850.121094, 74.417969 };

    NSEvent* moved = [NSEvent mouseEventWithType:NSMouseMoved location:pt modifierFlags:0 timestamp:0 windowNumber:messageID
                                         context:sContext eventNumber:(sEventNumber + 1) clickCount:0 pressure:0];
    sPendingEvents.push_back(moved);

    NSEvent* press = [NSEvent mouseEventWithType:NSLeftMouseDown location:pt modifierFlags:0 timestamp:0 windowNumber:messageID
                                         context:sContext eventNumber:(sEventNumber + 1) clickCount:1 pressure:1];
    sPendingEvents.push_back(press);

    NSEvent* release = [NSEvent mouseEventWithType:NSLeftMouseUp location:pt modifierFlags:0 timestamp:0 windowNumber:messageID
                                           context:sContext eventNumber:(sEventNumber + 1) clickCount:1 pressure:1];
    sPendingEvents.push_back(release);

    return 0;
}

@implementation DisseminateSwizzle

+(void)load
{
    printf("loaded\n");

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
            {
                Method original = class_getInstanceMethod([NSApplication class],
                                                          @selector(nextEventMatchingMask:untilDate:inMode:dequeue:));
                sNextEventMatchingMaskImp = method_setImplementation(original, (IMP)patchedNextEventMatchingMask);
            }
            // {
            //     Method original = class_getInstanceMethod([NSCursor class], @selector(set:));
            //     sCursorSet = method_setImplementation(original, (IMP)patchedCursorSet);
            // }
            // {
            //     Method original = class_getInstanceMethod([NSCursor class], @selector(push:));
            //     sCursorPush = method_setImplementation(original, (IMP)patchedCursorPush);
            // }
            {
                Method original = class_getInstanceMethod([NSView class], @selector(addCursorRect:cursor:));
                sAddCursorRect = method_setImplementation(original, (IMP)patchedAddCursorRect);
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                    printf("creating local\n");
                    portData.port = CFMessagePortCreateLocal(nil,
                                                             CFSTR("jhanssen.disseminate.listener"),
                                                             DisseminateCallback,
                                                             nil,
                                                             nil);
                    portData.source = CFMessagePortCreateRunLoopSource(nil, portData.port, 0);
                    CFRunLoopAddSource(CFRunLoopGetCurrent(),
                                       portData.source,
                                       kCFRunLoopCommonModes);
                });
        });
}

@end
