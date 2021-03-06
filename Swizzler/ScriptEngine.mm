#include "ScriptEngine.h"
#include "MessagePort.h"
#include "FlatbufferTypes.h"
#include <map>
#include <unordered_map>
#include <memory>
#import <Cocoa/Cocoa.h>
#include "EventLoop.h"
#include "Events.h"

MouseEvent::MouseEvent(NSEvent* event)
{
    internal = std::make_shared<Disseminate::Mouse::EventT>();
    switch ([event type]) {
    case NSLeftMouseDown:
        internal->type = Disseminate::Mouse::Type_Press;
        internal->button = Disseminate::Mouse::Button_Left;
        break;
    case NSLeftMouseUp:
        internal->type = Disseminate::Mouse::Type_Release;
        internal->button = Disseminate::Mouse::Button_Left;
        break;
    case NSRightMouseDown:
        internal->type = Disseminate::Mouse::Type_Press;
        internal->button = Disseminate::Mouse::Button_Right;
        break;
    case NSRightMouseUp:
        internal->type = Disseminate::Mouse::Type_Release;
        internal->button = Disseminate::Mouse::Button_Right;
        break;
    case NSMouseMoved:
        internal->type = Disseminate::Mouse::Type_Move;
        internal->button = Disseminate::Mouse::Button_None;
        internal->delta = std::make_unique<Disseminate::Mouse::Location>([event deltaX], [event deltaY]);
        break;
    case NSLeftMouseDragged:
        internal->type = Disseminate::Mouse::Type_Move;
        internal->button = Disseminate::Mouse::Button_Left;
        internal->delta = std::make_unique<Disseminate::Mouse::Location>([event deltaX], [event deltaY]);
        break;
    case NSRightMouseDragged:
        internal->type = Disseminate::Mouse::Type_Move;
        internal->button = Disseminate::Mouse::Button_Right;
        internal->delta = std::make_unique<Disseminate::Mouse::Location>([event deltaX], [event deltaY]);
        break;
    default:
        abort();
        break;
    }
    {
        NSPoint location = [event locationInWindow];
        internal->location = std::make_unique<Disseminate::Mouse::Location>(location.x, location.y);
    }
    internal->modifiers = [event modifierFlags];
    internal->clickCount = [event clickCount];
    internal->pressure = [event pressure];
    internal->timestamp = [event timestamp];
}

KeyEvent::KeyEvent(NSEvent* event)
{
    internal = std::make_shared<Disseminate::Key::EventT>();
    switch ([event type]) {
    case NSKeyUp:
        internal->type = Disseminate::Key::Type_Up;
        break;
    case NSKeyDown:
        internal->type = Disseminate::Key::Type_Down;
        break;
    default:
        abort();
        break;
    }
    {
        NSPoint location = [event locationInWindow];
        internal->location = std::make_unique<Disseminate::Key::Location>(location.x, location.y);
    }
    internal->text = toStdString([event characters]);
    internal->keyCode = [event keyCode];
    internal->modifiers = [event modifierFlags];
    internal->timestamp = [event timestamp];
    internal->repeat = [event isARepeat];
}

namespace enums {
enum { Add, Remove };
}

class ScriptEngineData
{
public:
    ScriptEngineData(const std::string& id)
        : uuid(id), nextTimer(0)
    {
    }

    std::vector<sel::function<bool(int, MouseEvent)> > mouseEventFunctions;
    std::vector<sel::function<bool(int, KeyEvent)> > keyEventFunctions;
    std::vector<sel::function<void(int, int, const std::string&)> > clientChangeFunctions;

    std::vector<std::pair<ScriptEngine::ClientType, std::string> > clients;

    std::unordered_map<std::string, std::shared_ptr<MessagePortRemote> > ports;

    std::string uuid;

    std::shared_ptr<MessagePortRemote> port(const std::string& name)
    {
        auto it = ports.find(name);
        if (it != ports.end())
            return it->second;
        return std::shared_ptr<MessagePortRemote>();
    }
    void makePort(const std::string& name)
    {
        ports[name] = std::make_shared<MessagePortRemote>(name);
    }
    void removePort(const std::string& name)
    {
        auto it = ports.find(name);
        if (it != ports.end())
            ports.erase(it);
    }

    uint32_t nextTimer;
    std::map<uint32_t, std::shared_ptr<EventLoopTimer> > timers;
};

static inline void setEnum(sel::State& state, const std::string& name, int c)
{
    state["enums"][name] = c;
}

ScriptEngine::ScriptEngine(const std::string& uuid)
    : state(std::make_unique<sel::State>(true)),
      data(std::make_unique<ScriptEngineData>(uuid))
{
    state->HandleExceptionsPrintingToStdOut();
    (*state)["uuid"] = [this]() {
        return data->uuid;
    };

    (*state)["MouseEvent"].SetClass<MouseEvent, int, int, double, double>(
        "type", &MouseEvent::type,
        "set_type", &MouseEvent::setType,
        "button", &MouseEvent::button,
        "set_button", &MouseEvent::setButton,
        "x", &MouseEvent::x,
        "set_x", &MouseEvent::setX,
        "y", &MouseEvent::y,
        "set_y", &MouseEvent::setY,
        "modifiers", &MouseEvent::modifiers,
        "set_modifiers", &MouseEvent::setModifiers,
        "clickCount", &MouseEvent::clickCount,
        "set_clickCount", &MouseEvent::setClickCount,
        "pressure", &MouseEvent::pressure,
        "set_pressure", &MouseEvent::setPressure,
        "deltax", &MouseEvent::deltaX,
        "set_deltaX", &MouseEvent::setDeltaX,
        "deltay", &MouseEvent::deltaY,
        "set_deltaY", &MouseEvent::setDeltaY,
        "fromUuid", &MouseEvent::fromUuid,
        "clone", &MouseEvent::clone);
    (*state)["KeyEvent"].SetClass<KeyEvent, int, int, double, double>(
        "type", &KeyEvent::type,
        "set_type", &KeyEvent::setType,
        "keycode", &KeyEvent::keyCode,
        "set_keycode", &KeyEvent::keyCode,
        "x", &KeyEvent::x,
        "set_x", &KeyEvent::setX,
        "y", &KeyEvent::y,
        "set_y", &KeyEvent::setY,
        "modifiers", &KeyEvent::modifiers,
        "set_modifiers", &KeyEvent::setModifiers,
        "text", &KeyEvent::text,
        "set_text", &KeyEvent::setText,
        "repeat", &KeyEvent::repeat,
        "set_repeat", &KeyEvent::setRepeat,
        "fromUuid", &KeyEvent::fromUuid,
        "clone", &KeyEvent::clone);

    setEnum(*state, "MouseMove", Disseminate::Mouse::Type_Move);
    setEnum(*state, "MousePress", Disseminate::Mouse::Type_Press);
    setEnum(*state, "MouseRelease", Disseminate::Mouse::Type_Release);
    setEnum(*state, "MouseButtonNone", Disseminate::Mouse::Button_None);
    setEnum(*state, "MouseButtonLeft", Disseminate::Mouse::Button_Left);
    setEnum(*state, "MouseButtonMiddle", Disseminate::Mouse::Button_Middle);
    setEnum(*state, "MouseButtonRight", Disseminate::Mouse::Button_Right);
    setEnum(*state, "KeyUp", Disseminate::Key::Type_Up);
    setEnum(*state, "KeyDown", Disseminate::Key::Type_Down);
    setEnum(*state, "Add", enums::Add);
    setEnum(*state, "Remove", enums::Remove);
    setEnum(*state, "Local", ScriptEngine::Local);
    setEnum(*state, "Remote", ScriptEngine::Remote);
    setEnum(*state, "WhiteList", Disseminate::Settings::Type_WhiteList);
    setEnum(*state, "BlackList", Disseminate::Settings::Type_BlackList);

    {
        auto clients = (*state)["clients"];
        clients["size"] = [this]() -> int {
            return data->clients.size();
        };
        clients["type"] = [this](int pos) -> int {
            return data->clients.at(pos).first;
        };
        clients["name"] = [this](int pos) {
            return data->clients.at(pos).second;
        };
        clients["on"] = [this](sel::function<void(int, int, const std::string&)> fun) {
            data->clientChangeFunctions.push_back(fun);
        };
    }

    {
        auto timers = (*state)["timers"];
        timers["startTimeout"] = [this](sel::function<void()> cb, uint32_t when) -> int {
            auto next = data->nextTimer++;
            auto timer = EventLoop::eventLoop()->makeTimer();
            timer->onTimeout([this, next, cb]() mutable {
                    {
                        sel::HandlerScope scope(state->GetExceptionHandler());
                        cb();
                    }

                    auto timer = data->timers.find(next);
                    if (timer == data->timers.end())
                        return;
                    timer->second->stop();
                    data->timers.erase(timer);
                });
            timer->start(when, EventLoopTimer::Timeout);
            data->timers[next] = timer;
            return next;
        };
        timers["startInterval"] = [this](sel::function<void()> cb, uint32_t when) -> int {
            auto next = data->nextTimer++;
            auto timer = EventLoop::eventLoop()->makeTimer();
            timer->onTimeout([this, next, cb]() mutable {
                    sel::HandlerScope scope(state->GetExceptionHandler());
                    cb();
                });
            timer->start(when, EventLoopTimer::Interval);
            data->timers[next] = timer;
            return next;
        };
        timers["stop"] = [this](uint32_t id) -> bool {
            auto timer = data->timers.find(id);
            if (timer == data->timers.end())
                return false;
            const bool ok = timer->second->stop();
            data->timers.erase(timer);
            return ok;
        };
    }

    {
        auto mouseEvent = (*state)["mouseEvent"];
        mouseEvent["on"] = [this](sel::function<bool(int, MouseEvent)> fun) {
            data->mouseEventFunctions.push_back(fun);
        };
        mouseEvent["sendToAll"] = [this](MouseEvent event) {
            auto port = data->ports.cbegin();
            const auto end = data->ports.cend();
            while (port != end) {
                flatbuffers::FlatBufferBuilder builder;
                auto flat = event.flat();
                flat->fromUuid = data->uuid;
                // printf("sending to all %s -> %d\n", port->first.c_str(), data->windowNumbers[port->first]);
                auto buffer = Disseminate::Mouse::CreateEvent(builder, flat);
                builder.Finish(buffer);
                std::vector<uint8_t> message(builder.GetBufferPointer(),
                                             builder.GetBufferPointer() + builder.GetSize());

                port->second->send(Disseminate::FlatbufferTypes::MouseEvent, message);
                ++port;
            }
        };
        mouseEvent["sendTo"] = [this](MouseEvent event, const std::string& to) -> bool {
            // send to specific
            const std::shared_ptr<MessagePortRemote>& port = data->port(to);
            if (!port) {
                // boo
                printf("invalid port %f %f - %s\n", event.x(), event.y(), to.c_str());
                return false;
            }
            flatbuffers::FlatBufferBuilder builder;
            auto flat = event.flat();
            flat->fromUuid = data->uuid;
            auto buffer = Disseminate::Mouse::CreateEvent(builder, flat);
            builder.Finish(buffer);
            std::vector<uint8_t> message(builder.GetBufferPointer(),
                                         builder.GetBufferPointer() + builder.GetSize());
            port->send(Disseminate::FlatbufferTypes::MouseEvent, message);
            return true;
        };
        mouseEvent["inject"] = [this](MouseEvent event) {
            EventLoop::eventLoop()->postEvent(std::make_shared<EventLoopEvent>(event));
        };
    }

    {
        auto keyEvent = (*state)["keyEvent"];
        keyEvent["on"] = [this](sel::function<bool(int, KeyEvent)> fun) {
            data->keyEventFunctions.push_back(fun);
        };
        keyEvent["sendToAll"] = [this](KeyEvent event) {
            flatbuffers::FlatBufferBuilder builder;

            auto port = data->ports.cbegin();
            const auto end = data->ports.cend();
            while (port != end) {
                auto flat = event.flat();
                flat->fromUuid = data->uuid;
                auto buffer = Disseminate::Key::CreateEvent(builder, flat);
                builder.Finish(buffer);
                std::vector<uint8_t> message(builder.GetBufferPointer(),
                                             builder.GetBufferPointer() + builder.GetSize());

                port->second->send(Disseminate::FlatbufferTypes::KeyEvent, message);
                ++port;
            }
        };
        keyEvent["sendTo"] = [this](KeyEvent event, const std::string& to) -> bool {
            // send to specific
            const std::shared_ptr<MessagePortRemote>& port = data->port(to);
            if (!port) {
                // boo
                printf("invalid port %f %f - %s\n", event.x(), event.y(), to.c_str());
                return false;
            }
            flatbuffers::FlatBufferBuilder builder;
            auto flat = event.flat();
            flat->fromUuid = data->uuid;
            auto buffer = Disseminate::Key::CreateEvent(builder, flat);
            builder.Finish(buffer);
            std::vector<uint8_t> message(builder.GetBufferPointer(),
                                         builder.GetBufferPointer() + builder.GetSize());
            port->send(Disseminate::FlatbufferTypes::KeyEvent, message);
            return true;
        };
        keyEvent["inject"] = [this](KeyEvent event) {
            EventLoop::eventLoop()->postEvent(std::make_shared<EventLoopEvent>(event));
        };
    }

    (*state)["logString"] = [](const std::string& str) {
        printf("logString -- '%s'\n", str.c_str());
    };
    (*state)["logInt"] = [](int i) {
        printf("logInt -- %d\n", i);
    };
#if 1
    (*state)("capturingMouse = 0\n"
             "function acceptKeys(type, ke)\n"
             "  if type == enums.Remote then\n"
             "    keyEvent.inject(ke)\n"
             "    return true\n"
             "  end\n"
             "  local code = ke:keycode()\n"
             "  local mods = ke:modifiers()\n"
             "  if keys and keys.global then\n"
             "    if keys.global.mousebind then\n"
             "      if code == keys.global.mousebind.keycode and mods == keys.global.mousebind.modifiers then\n"
             "        if ke:type() == enums.KeyDown then\n"
             "          if capturingMouse == 0 then\n"
             "            capturingMouse = 1\n"
             "          else\n"
             "            capturingMouse = 0\n"
             "          end\n"
             "        end\n"
             "        return false\n"
             "      end\n"
             "    end\n"
             "    local sendToAll = true\n"
             "    if keys.global.keys then\n"
             "      for k,v in ipairs(keys.global.keys) do\n"
             "        if keys.global.type == enums.WhiteList then\n"
             "          if v.keycode == code and v.modifiers == mods then\n"
             "            keyEvent.sendToAll(ke)\n"
             "            break\n"
             "          end\n"
             "        else\n"
             "          if v.keycode == code and v.modifiers == mods then\n"
             "            sendToAll = false\n"
             "            break\n"
             "          end\n"
             "        end\n"
             "      end\n"
             "    end\n"
             "    if keys.global.type == enums.BlackList and sendToAll then\n"
             "      keyEvent.sendToAll(ke)\n"
             "    end\n"
             "    if keys.global.exclusions then\n"
             "      for k,v in ipairs(keys.global.exclusions) do\n"
             "        if v.keycode == code and v.modifiers == mods then\n"
             "          return false\n"
             "        end\n"
             "      end\n"
             "    end\n"
             "  end\n"
             "  return true\n"
             "end\n"
             "function acceptMouse(type, me)\n"
             "  if type == enums.Remote then\n"
             "    mouseEvent.inject(me)\n"
             "    return true\n"
             "  end\n"
             "  if capturingMouse == 0 then\n"
             "    return true\n"
             "  end\n"
             "  mouseEvent.sendToAll(me)\n"
             "  return true\n"
             "end\n"
             "mouseEvent.on(acceptMouse)\n"
             "keyEvent.on(acceptKeys)\n");
#endif
#if 0
    (*state)("local foobar\n"
             "function acceptMouseEvent(type, me)\n"
             "  if me:x() > 380 then\n"
             "    logInt(776)\n"
             "    logInt(me:type())\n"
             "    if me:type() == enums.MouseRelease then\n"
             "      local move = MouseEvent.new(enums.MouseMove, enums.MouseButtonNone, 502.386719, 155.292969)\n"
             "      mouseEvent.inject(move)\n"
             "      local press = MouseEvent.new(enums.MousePress, enums.MouseButtonLeft, 502.386719, 155.292969)\n"
             "      mouseEvent.inject(press)\n"
             "      local release = MouseEvent.new(enums.MouseRelease, enums.MouseButtonLeft, 502.386719, 155.292969)\n"
             "      mouseEvent.inject(release)\n"
             "      logInt(777)\n"
             "    end\n"
             "    return false"
             "  end\n"
             "  mouseEvent.sendTo(me, \"abc\")\n"
             "  mouseEvent.sendTo(foobar, \"1ghi\")\n"
             "  foobar:set_x(200)\n"
             "  mouseEvent.sendTo(foobar, \"2ghi\")\n"
             "  return true\n"
             "end\n"
             "function acceptOtherMouseEvent(type, me)\n"
             // "  me:set_x(100)\n"
             // "  mouseEvent.sendTo(me, \"def\")\n"
             // "  foobar = me\n"
             // "  local brandnew = MouseEvent.new(enums.MousePress, enums.MouseButtonLeft, 99, 55.77)\n"
             // "  brandnew:set_x(199)\n"
             // "  mouseEvent.sendTo(brandnew, \"brandnew\")\n"
             "  local me2 = me:clone()\n"
             "  local str1 = \"abchey\"\n"
             "  local str2 = str1\n"
             "  mouseEvent.sendTo(me2, str1)\n"
             "  me:set_x(100)\n"
             "  str1 = \"321\"\n"
             "  mouseEvent.sendTo(me, str1)\n"
             "  mouseEvent.sendTo(me2, str2)\n"
             "  logInt(530)\n"
             "  return true\n"
             "end\n"
             "local blockedKeys = 0\n"
             "function acceptKeyEvent(type, ke)\n"
             "  logString(\"key!!\")\n"
             "  logInt(ke:keycode())\n"
             "  if blockedKeys < 2 then\n"
             "    blockedKeys = blockedKeys + 1\n"
             "    return false\n"
             "  end\n"
             "  return true\n"
             "end\n"
             "function clientChange(change, type, client)\n"
             "  logString(client)\n"
             "  logInt(change)\n"
             "  logInt(type)\n"
             "  logInt(clients.size())\n"
             "  logString(clients.name(0))\n"
             "end\n"
             "local timeoutCnt = 0\n"
             "local timeoutId\n"
             "function onTimeout()\n"
             "  timeoutCnt = timeoutCnt + 1\n"
             "  if timeoutCnt > 3 then\n"
             "    logString(\"stopping\")\n"
             "    timers.stop(timeoutId)\n"
             "    local keyPress = KeyEvent.new(enums.KeyUp, 0, 0, 0)\n"
             "    keyPress:set_text(\"a\")\n"
             "    keyEvent.inject(keyPress)\n"
             "  end\n"
             "  logString(\"timeout\")"
             "end\n"
             "timeoutId = timers.startInterval(onTimeout, 2000)\n"
             "logInt(enums.MouseMove)\n"
             "logInt(clients.size())\n"
             "clients.on(clientChange)\n"
             "keyEvent.on(acceptKeyEvent)\n"
             "mouseEvent.on(acceptOtherMouseEvent)\n"
             //"mouseEvent.on(acceptMouseEvent)\n"
        );
#endif
}

ScriptEngine::~ScriptEngine()
{
}

void ScriptEngine::registerClient(ClientType type, std::unique_ptr<Disseminate::RemoteAdd::EventT>& eventData)
{
    registerClient(type, eventData->uuid);
}

void ScriptEngine::registerClient(ClientType type, const std::string& uuid)
{
    data->clients.push_back(std::make_pair(type, uuid));
    if (type == Remote)
        data->makePort(uuid);

    sel::HandlerScope scope(state->GetExceptionHandler());

    auto on = data->clientChangeFunctions.begin();
    const auto end = data->clientChangeFunctions.end();
    while (on != end) {
        (*on)(enums::Add, type, uuid);
        ++on;
    }
}

void ScriptEngine::unregisterClient(ClientType type, const std::string& uuid)
{
    {
        auto client = data->clients.begin();
        const auto end = data->clients.end();
        while (client != end) {
            if (client->first == type && client->second == uuid) {
                data->clients.erase(client);
                break;
            }
            ++client;
        }
    }
    if (type == Remote)
        data->removePort(uuid);

    sel::HandlerScope scope(state->GetExceptionHandler());

    auto on = data->clientChangeFunctions.begin();
    const auto end = data->clientChangeFunctions.end();
    while (on != end) {
        (*on)(enums::Remove, type, uuid);
        ++on;
    }
}

void ScriptEngine::clearClients(ClientType type)
{
    std::vector<std::string> removed;

    {
        auto client = data->clients.begin();
        const auto end = data->clients.end();
        while (client != end) {
            if (client->first == type) {
                removed.push_back(client->second);
                if (type == Remote)
                    data->removePort(client->second);
                client = data->clients.erase(client);
            } else {
                ++client;
            }
        }
    }

    sel::HandlerScope scope(state->GetExceptionHandler());

    auto on = data->clientChangeFunctions.begin();
    const auto end = data->clientChangeFunctions.end();
    while (on != end) {
        for (const auto& uuid : removed) {
            (*on)(enums::Remove, type, uuid);
        }
        ++on;
    }
}

void ScriptEngine::processRemoteMouseEvent(std::unique_ptr<Disseminate::Mouse::EventT>& eventData)
{
    sel::HandlerScope scope(state->GetExceptionHandler());

    MouseEvent event(eventData);
    auto on = data->mouseEventFunctions.begin();
    const auto end = data->mouseEventFunctions.end();
    while (on != end) {
        MouseEvent remoteEvent(event);
        printf("processing remote mouse-- %p\n", &remoteEvent);
        if (!(*on)(Remote, remoteEvent)) {
            return;
        }
        ++on;
    }
}

void ScriptEngine::processRemoteKeyEvent(std::unique_ptr<Disseminate::Key::EventT>& eventData)
{
    sel::HandlerScope scope(state->GetExceptionHandler());

    KeyEvent event(eventData);
    auto on = data->keyEventFunctions.begin();
    const auto end = data->keyEventFunctions.end();
    while (on != end) {
        KeyEvent remoteEvent(event);
        printf("processing remote key-- %p\n", &remoteEvent);
        if (!(*on)(Remote, remoteEvent)) {
            return;
        }
        ++on;
    }
}

bool ScriptEngine::processLocalEvent(const std::shared_ptr<EventLoopEvent>& event)
{
    sel::HandlerScope scope(state->GetExceptionHandler());

    NSEvent* nsevent = event->nsevt;
    assert(nsevent);
    switch ([nsevent type]) {
    case NSLeftMouseDown:
    case NSLeftMouseUp:
    case NSRightMouseDown:
    case NSRightMouseUp:
    case NSMouseMoved:
    case NSLeftMouseDragged:
    case NSRightMouseDragged: {
        auto on = data->mouseEventFunctions.begin();
        const auto end = data->mouseEventFunctions.end();
        while (on != end) {
#warning think I can move this out of the loop now that MouseEvent are copy-on-write
            MouseEvent localEvent(nsevent);
            //printf("processing local-- %p\n", &localEvent);
            if (!(*on)(Local, localEvent)) {
                return false;
            }
            ++on;
        }
        break; }
    case NSKeyDown:
    case NSKeyUp: {
        auto on = data->keyEventFunctions.begin();
        const auto end = data->keyEventFunctions.end();
        while (on != end) {
#warning think I can move this out of the loop now that KeyEvent are copy-on-write
            KeyEvent localEvent(nsevent);
            //printf("processing local-- %p\n", &localEvent);
            if (!(*on)(Local, localEvent)) {
                return false;
            }
            ++on;
        }
        break; }
    default:
        break;
    }
    return true;
}

void ScriptEngine::processSettings(std::unique_ptr<Disseminate::Settings::GlobalT>& settings)
{
    auto makeKey = [this](auto obj, auto key) {
        obj["keycode"] = static_cast<double>(key.keyCode());
        obj["modifiers"] = static_cast<double>(key.modifiers());
    };

    auto keys = (*state)["keys"];
    keys.clear();

    auto global = keys["global"];
    auto globalkeys = global["keys"];
    global["type"] = static_cast<int>(settings->type);

    size_t n = settings->keys.size();
    for (size_t i = 0; i < n; ++i) {
        makeKey(globalkeys[i + 1], settings->keys[i]);
    }
    printf("made %zu keys\n", n);

    auto keybind = global["keybind"];
    makeKey(keybind, *settings->toggleKeyboard);

    auto mousebind = global["mousebind"];
    makeKey(mousebind, *settings->toggleMouse);

    auto exclusions = global["exclusions"];
    n = settings->activeExclusions.size();
    for (size_t i = 0; i < n; ++i) {
        makeKey(exclusions[i + 1], settings->activeExclusions[i]);
    }

    auto specifics = global["specifics"];
    for (const auto& s : settings->specifics) {
        auto specific = specifics[s->uuid];
        auto specifickeys = specific["keys"];
        specific["type"] = static_cast<int>(s->type);

        n = s->keys.size();
        for (size_t i = 0; i < n; ++i) {
            makeKey(specifickeys[i + 1], s->keys[i]);
        }
    }

    (*state)("for k,v in ipairs(keys.global.keys) do\n"
             //"  logString(k)\n"
             "  logInt(v.keycode)\n"
             "end\n");
}
