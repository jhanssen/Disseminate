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

    typedef std::function<void(int32_t id, const std::vector<uint8_t>& data)> Callback;
    void onMessage(const Callback& on) { mCallback = on; }

private:
    static CFDataRef callback(CFMessagePortRef port,
                              SInt32 messageID,
                              CFDataRef data,
                              void *info);

    CFRunLoopSourceRef mSource;
    Callback mCallback;
};

class MessagePortRemote
{
public:
    MessagePortRemote(const std::string& name);
    ~MessagePortRemote();

    bool send(int32_t id) const ;
    bool send(int32_t id, const std::vector<uint8_t>& data) const;
    bool send(const std::vector<uint8_t>& data) const;

private:
    CFMessagePortRef mPort;
};

#endif
