#ifndef LUA_H
#define LUA_H

#include <string>
#include <selene.h>
#include <MouseEvent_generated.h>

class Lua
{
public:
    Lua();

    void evaluate(const std::string& code);

    void send(const Disseminate::MouseEvent* event);
    void loop();

    enum ClientType { Local, Remote };
    void registerClient(ClientType type, const std::string& uuid);
    void unregisterClient(ClientType type, const std::string& uuid);

private:
    std::unique_ptr<sel::State> state;
};

inline void Lua::evaluate(const std::string& code)
{
    state->LoadStr(code);
}

#endif
