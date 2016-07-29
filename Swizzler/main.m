#include <stdio.h>
#include <objc/runtime.h>
#import <Cocoa/Cocoa.h>

@interface DisseminateSwizzle : NSObject

@end

static IMP sOriginalImp = NULL;

typedef NSEvent* (*Signature)(id self, SEL _cmd, NSUInteger mask, NSDate* expiration, NSString* mode, BOOL flag);

static NSEvent* patchedNextEventMatchingMask(id self, SEL _cmd, NSUInteger mask, NSDate* expiration, NSString* mode, BOOL flag)
{
    Signature sig = (Signature)sOriginalImp;
    printf("next eventing\n");
    NSEvent* event;
    for (;;) {
        event = sig(self, _cmd, mask, expiration, mode, flag);
        switch ([event type]) {
        case NSLeftMouseDown:
        case NSLeftMouseUp:
            printf("skipping mouse events\n");
            continue;
        default:
            break;
        }
        break;
    }
    printf("got event of type %lu\n", [event type]);
    return event;
}

@implementation DisseminateSwizzle

+(void)load
{
    printf("loaded\n");

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
            Method original = class_getInstanceMethod([NSApplication class],
                                                      @selector(nextEventMatchingMask:untilDate:inMode:dequeue:));
            sOriginalImp = method_setImplementation(original, (IMP)patchedNextEventMatchingMask);
        });
}

@end
