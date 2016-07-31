#ifndef SCRIPTENGINE_H
#define SCRIPTENGINE_H

#include <string>
#include <selene.h>
#include <MouseEvent_generated.h>
#include <AppKit/NSEvent.h>

class ScriptEngineData;
class EventLoopEvent;

class ScriptEngine
{
public:
    ScriptEngine(const std::string& uuid);
    ~ScriptEngine();

    void evaluate(const std::string& code);

    void processRemoteEvent(std::unique_ptr<Disseminate::MouseEventT>& eventData);
    bool processLocalEvent(const std::shared_ptr<EventLoopEvent>& event);

    enum ClientType { Local, Remote };
    void registerClient(ClientType type, const std::string& uuid);
    void unregisterClient(ClientType type, const std::string& uuid);

private:
    std::unique_ptr<sel::State> state;
    std::unique_ptr<ScriptEngineData> data;
};

inline void ScriptEngine::evaluate(const std::string& code)
{
    state->LoadStr(code);
}

#endif
