#ifndef SCRIPTENGINE_H
#define SCRIPTENGINE_H

#include <string>
#include <selene.h>
#include <MouseEvent_generated.h>
#include <AppKit/NSEvent.h>

class ScriptEngine
{
public:
    ScriptEngine();

    void evaluate(const std::string& code);

    void send(const Disseminate::MouseEvent* event);
    bool processEvent(NSEvent* event);

    enum ClientType { Local, Remote };
    void registerClient(ClientType type, const std::string& uuid);
    void unregisterClient(ClientType type, const std::string& uuid);

private:
    std::unique_ptr<sel::State> state;
};

inline void ScriptEngine::evaluate(const std::string& code)
{
    state->LoadStr(code);
}

#endif
