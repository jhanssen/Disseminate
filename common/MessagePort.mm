#include "MessagePort.h"
#include "CocoaUtils.h"
#import <Cocoa/Cocoa.h>
#include <objc/runtime.h>

static void* remoteKey = &remoteKey;

@interface MessagePortRemoteData : NSObject

-(id)initWithPort:(MessagePortRemote*)r;

@end

@implementation MessagePortRemoteData
{
@public
    MessagePortRemote* remote;
}

-(id)initWithPort:(MessagePortRemote*)r
{
    if (self = [super init]) {
        self->remote = r;
    }
    return self;
}
@end

MessagePortLocal::MessagePortLocal(const std::string& name)
{
    CFMessagePortContext ctx;
    memset(&ctx, 0, sizeof(CFMessagePortContext));
    ctx.info = this;
    CFStringRef portname = CFStringCreateWithCStringNoCopy(nullptr, name.c_str(),
                                                           kCFStringEncodingASCII, nullptr);
    CFMessagePortRef port = CFMessagePortCreateLocal(nil,
                                                     portname,
                                                     messageCallback,
                                                     &ctx,
                                                     nil);
    if (port) {
        mSource = CFMessagePortCreateRunLoopSource(nil, port, 0);
        CFRunLoopAddSource(CFRunLoopGetCurrent(),
                           mSource,
                           kCFRunLoopCommonModes);
        CFMessagePortSetInvalidationCallBack(port, invalidatedCallback);
        CFRelease(port);
    } else {
        mSource = 0;
    }
}

MessagePortLocal::~MessagePortLocal()
{
    if (mSource) {
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), mSource, kCFRunLoopCommonModes);
        CFRelease(mSource);
    }
}

CFDataRef MessagePortLocal::messageCallback(CFMessagePortRef port, SInt32 messageID,
                                            CFDataRef data, void *info)
{
    MessagePortLocal* local = static_cast<MessagePortLocal*>(info);
    if (local->mMessageCallback) {
        std::vector<uint8_t> str;
        if (data) {
            const CFIndex len = CFDataGetLength(data);
            if (len > 0) {
                str.resize(len);
                memcpy(&str[0], CFDataGetBytePtr(data), len);
            }
        }
        local->mMessageCallback(messageID, str);
    }
    return 0;
}

void MessagePortLocal::invalidatedCallback(CFMessagePortRef port, void *info)
{
    MessagePortLocal* local = static_cast<MessagePortLocal*>(info);
    if (local->mInvalidatedCallback) {
        local->mInvalidatedCallback();
    }
}

MessagePortRemote::MessagePortRemote(const std::string& name)
{
    CFStringRef portname = CFStringCreateWithCStringNoCopy(nullptr, name.c_str(),
                                                           kCFStringEncodingASCII, nullptr);
    mPort = CFMessagePortCreateRemote(nil, portname);
    if (mPort) {
        ScopedPool pool;
        NSObject* portObj = (NSObject*)mPort;
        MessagePortRemoteData* data = [[[MessagePortRemoteData alloc] initWithPort:this] autorelease];
        objc_setAssociatedObject(portObj, remoteKey, data, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        CFMessagePortSetInvalidationCallBack(mPort, invalidatedCallback);
    }
}

MessagePortRemote::~MessagePortRemote()
{
    if (mPort)
        CFRelease(mPort);
}

void MessagePortRemote::invalidatedCallback(CFMessagePortRef port, void *info)
{
    NSObject* portObj = (NSObject*)port;
    MessagePortRemoteData* data = (MessagePortRemoteData*)objc_getAssociatedObject(portObj, remoteKey);
    if (data) {
        if (data->remote->mInvalidatedCallback)
            data->remote->mInvalidatedCallback();
        objc_setAssociatedObject(portObj, remoteKey, nil, OBJC_ASSOCIATION_ASSIGN);
    }
}

bool MessagePortRemote::send(int32_t id, const std::vector<uint8_t>& data) const
{
    if (!mPort)
        return false;
    const CFTimeInterval timeout = 10.0;
    CFDataRef dataref = data.empty() ? nullptr : CFDataCreate(NULL, &data[0], data.size() + 1);
    SInt32 status = CFMessagePortSendRequest(mPort,
                                             id,
                                             dataref,
                                             timeout,
                                             timeout,
                                             NULL,
                                             NULL);
    return (status == kCFMessagePortSuccess);
}

bool MessagePortRemote::send(int32_t id) const
{
    return send(id, std::vector<uint8_t>());
}

bool MessagePortRemote::send(const std::vector<uint8_t>& data) const
{
    return send(0, data);
}
