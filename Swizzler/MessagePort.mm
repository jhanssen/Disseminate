#include "MessagePort.h"
#import <Cocoa/Cocoa.h>

MessagePortLocal::MessagePortLocal(const std::string& name)
{
    CFMessagePortContext ctx;
    memset(&ctx, 0, sizeof(CFMessagePortContext));
    ctx.info = this;
    CFStringRef portname = CFStringCreateWithCStringNoCopy(nullptr, name.c_str(),
                                                           kCFStringEncodingASCII, nullptr);
    CFMessagePortRef port = CFMessagePortCreateLocal(nil,
                                                     portname,
                                                     callback,
                                                     &ctx,
                                                     nil);
    if (port) {
        mSource = CFMessagePortCreateRunLoopSource(nil, port, 0);
        CFRunLoopAddSource(CFRunLoopGetCurrent(),
                           mSource,
                           kCFRunLoopCommonModes);
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

CFDataRef MessagePortLocal::callback(CFMessagePortRef port, SInt32 messageID,
                                     CFDataRef data, void *info)
{
    MessagePortLocal* local = static_cast<MessagePortLocal*>(info);
    if (local->mCallback) {
        std::string str;
        if (data) {
            const CFIndex len = CFDataGetLength(data);
            if (len > 0) {
                str = std::string(reinterpret_cast<const char*>(CFDataGetBytePtr(data)), len);
            }
        }
        local->mCallback(messageID, str);
    }
    return 0;
}

MessagePortRemote::MessagePortRemote(const std::string& name)
{
    CFStringRef portname = CFStringCreateWithCStringNoCopy(nullptr, name.c_str(),
                                                           kCFStringEncodingASCII, nullptr);
    mPort = CFMessagePortCreateRemote(nil, portname);
}

MessagePortRemote::~MessagePortRemote()
{
    if (mPort)
        CFRelease(mPort);
}

bool MessagePortRemote::send(int32_t id, const std::string& data)
{
    if (!mPort)
        return false;
    const CFTimeInterval timeout = 10.0;
    CFDataRef dataref = data.empty() ? nullptr : CFDataCreate(NULL, reinterpret_cast<const UInt8*>(data.c_str()), data.size() + 1);
    SInt32 status = CFMessagePortSendRequest(mPort,
                                             id,
                                             dataref,
                                             timeout,
                                             timeout,
                                             NULL,
                                             NULL);
    return (status == kCFMessagePortSuccess);
}

bool MessagePortRemote::send(int32_t id)
{
    return send(id, std::string());
}

bool MessagePortRemote::send(const std::string& data)
{
    return send(0, data);
}
