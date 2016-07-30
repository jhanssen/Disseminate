#include "MessagePort.h"
#include "EventLoop.h"
#include <stdio.h>
#include <objc/runtime.h>
#include <string>
#include <deque>
#include <memory>
#include <unistd.h>
#include <FlatbufferTypes.h>
#include <MouseEvent_generated.h>
#import <Cocoa/Cocoa.h>
#import <dispatch/dispatch.h>

// Sucky Cocoa
#undef check
#include "ScriptEngine.h"

@interface DisseminateSwizzle : NSObject

@end

static NSGraphicsContext* sContext = 0;
static NSInteger sEventNumber = 0;
static NSInteger sEventOffset = 0;

static std::string generateUUID()
{
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    CFStringRef strref = CFUUIDCreateString(NULL, uuid);
    CFRelease(uuid);
    NSString* str = (NSString *)strref;
    const std::string string = std::string([str UTF8String]);
    [str release];
    return string;
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

struct Context
{
    std::unique_ptr<MessagePortLocal> port;
    std::unique_ptr<ScriptEngine> lua;
};

static Context context;

// static CFDataRef DisseminateCallback(CFMessagePortRef port,
//                                      SInt32 messageID,
//                                      CFDataRef data,
//                                      void *info)
// {
//     printf("got message %x\n", messageID);
//     // let's make a press and release event
//     NSPoint pt = { 1850.121094, 74.417969 };

//     NSEvent* moved = [NSEvent mouseEventWithType:NSMouseMoved location:pt modifierFlags:0 timestamp:0 windowNumber:messageID
//                                          context:sContext eventNumber:(sEventNumber + 1) clickCount:0 pressure:0];
//     sPendingEvents.push_back(moved);

//     NSEvent* press = [NSEvent mouseEventWithType:NSLeftMouseDown location:pt modifierFlags:0 timestamp:0 windowNumber:messageID
//                                          context:sContext eventNumber:(sEventNumber + 1) clickCount:1 pressure:1];
//     sPendingEvents.push_back(press);

//     NSEvent* release = [NSEvent mouseEventWithType:NSLeftMouseUp location:pt modifierFlags:0 timestamp:0 windowNumber:messageID
//                                            context:sContext eventNumber:(sEventNumber + 1) clickCount:1 pressure:1];
//     sPendingEvents.push_back(release);

//     return 0;
// }

@implementation DisseminateSwizzle

+(void)load
{
    printf("loaded\n");

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
            {
                Method original = class_getInstanceMethod([NSView class], @selector(addCursorRect:cursor:));
                sAddCursorRect = method_setImplementation(original, (IMP)patchedAddCursorRect);
            }
            EventLoop::eventLoop()->swizzle();

            dispatch_async(dispatch_get_main_queue(), ^{
                    EventLoop* loop = EventLoop::eventLoop();

                    const std::string uuid = generateUUID();

                    context.lua = std::make_unique<ScriptEngine>();
                    context.lua->registerClient(ScriptEngine::Local, uuid);

                    printf("creating local %s\n", uuid.c_str());
                    context.port = std::make_unique<MessagePortLocal>(uuid);
                    context.port->onMessage([loop](int32_t id, const std::string& data) {
                            switch (id) {
                            case Disseminate::FlatbufferTypes::Evaluate:
                                context.lua->evaluate(data);
                                break;
                            case Disseminate::FlatbufferTypes::RemoteAdd:
                                context.lua->registerClient(ScriptEngine::Remote, data);
                                break;
                            case Disseminate::FlatbufferTypes::RemoteRemove:
                                context.lua->unregisterClient(ScriptEngine::Remote, data);
                                break;
                            case Disseminate::FlatbufferTypes::MouseEvent: {
                                auto event = Disseminate::GetMouseEvent(data.c_str());
                                context.lua->processRemoteEvent(event);
                                break; }
                            default:
                                break;
                            }
                        });

                    loop->onEvent([](NSEvent* event) -> bool {
                            printf("iteration\n");
                            return context.lua->processLocalEvent(event);
                        });

                    MessagePortRemote remote("jhanssen.disseminate.server");
                    if (!remote.send(getpid(), uuid)) {
                        printf("couldn't inform server\n");
                        //context.port.reset();
                        return;
                    }

                    /*sel::State state;
                    state.LoadStr("function add(a, b)\n"
                                  "  return a + b\n"
                                  "end");
                    int result = state["add"](5, 2);
                    printf("got lua result %d\n", result);*/
                });
        });
}

@end
