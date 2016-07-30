#include "ScriptEngine.h"
#import <Cocoa/Cocoa.h>

ScriptEngine::ScriptEngine()
    : state(std::make_unique<sel::State>())
{
}

void ScriptEngine::send(const Disseminate::MouseEvent* event)
{
}

void ScriptEngine::loop()
{
}

void ScriptEngine::registerClient(ClientType type, const std::string& uuid)
{
}

void ScriptEngine::unregisterClient(ClientType type, const std::string& uuid)
{
}

bool ScriptEngine::processEvent(NSEvent* event)
{
    return true;
}
