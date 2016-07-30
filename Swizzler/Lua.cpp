#include "Lua.h"

Lua::Lua()
    : state(std::make_unique<sel::State>())
{
}

void Lua::send(const Disseminate::MouseEvent* event)
{
}

void Lua::loop()
{
}

void Lua::registerClient(ClientType type, const std::string& uuid)
{
}

void Lua::unregisterClient(ClientType type, const std::string& uuid)
{
}
