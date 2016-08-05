#ifndef SCRIPTENGINE_H
#define SCRIPTENGINE_H

#include <string>
#include <selene.h>
#include <MouseEvent_generated.h>
#include <KeyEvent_generated.h>
#include <Settings_generated.h>
#include <RemoteAdd_generated.h>
#include <AppKit/NSEvent.h>

class ScriptEngineData;
class EventLoopEvent;

class ScriptEngine
{
public:
    ScriptEngine(const std::string& uuid);
    ~ScriptEngine();

    void evaluate(const std::string& code);

    void processSettings(std::unique_ptr<Disseminate::Settings::GlobalT>& settings);

    void processRemoteMouseEvent(std::unique_ptr<Disseminate::Mouse::EventT>& eventData);
    void processRemoteKeyEvent(std::unique_ptr<Disseminate::Key::EventT>& eventData);

    bool processLocalEvent(const std::shared_ptr<EventLoopEvent>& event);

    enum ClientType { Local, Remote };
    void registerClient(ClientType type, std::unique_ptr<Disseminate::RemoteAdd::EventT>& eventData);
    void registerClient(ClientType type, const std::string& uuid);
    void unregisterClient(ClientType type, const std::string& uuid);
    void clearClients(ClientType type);

private:
    std::unique_ptr<sel::State> state;
    std::unique_ptr<ScriptEngineData> data;
};

inline void ScriptEngine::evaluate(const std::string& code)
{
    state->LoadStr(code);
}

#endif
