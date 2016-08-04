#ifndef MESSAGEPORT_H
#define MESSAGEPORT_H

#include <vector>
#include <string>
#include <functional>
#include <CoreFoundation/CFData.h>
#include <CoreFoundation/CFMessagePort.h>
#include <CoreFoundation/CFRunLoop.h>

class MessagePortLocal
{
public:
    MessagePortLocal(const std::string& name);
    ~MessagePortLocal();

    typedef std::function<void(int32_t id, const std::vector<uint8_t>& data)> MessageCallback;
    void onMessage(const MessageCallback& on) { mMessageCallback = on; }

    typedef std::function<void()> InvalidatedCallback;
    void onInvalidated(const InvalidatedCallback& on) { mInvalidatedCallback = on; }

private:
    static CFDataRef messageCallback(CFMessagePortRef port,
                                     SInt32 messageID,
                                     CFDataRef data,
                                     void *info);
    static void invalidatedCallback(CFMessagePortRef ms, void *info);

    CFRunLoopSourceRef mSource;
    MessageCallback mMessageCallback;
    InvalidatedCallback mInvalidatedCallback;
};

class MessagePortRemote
{
public:
    MessagePortRemote(const std::string& name);
    ~MessagePortRemote();

    bool send(int32_t id) const ;
    bool send(int32_t id, const std::vector<uint8_t>& data) const;
    bool send(int32_t id, const std::string& data) const;
    bool send(const std::vector<uint8_t>& data) const;

    typedef std::function<void()> InvalidatedCallback;
    void onInvalidated(const InvalidatedCallback& on) { mInvalidatedCallback = on; }

private:
    static void invalidatedCallback(CFMessagePortRef ms, void *info);

    CFMessagePortRef mPort;
    InvalidatedCallback mInvalidatedCallback;
};

#endif
