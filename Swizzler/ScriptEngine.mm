#include "ScriptEngine.h"
#include "MessagePort.h"
#include "FlatbufferTypes.h"
#include <map>
#include <memory>
#include <MouseEvent_generated.h>
#include "CocoaUtils.h"
#import <Cocoa/Cocoa.h>
#include "EventLoop.h"

template<typename T>
class Detachable
{
public:
    virtual ~Detachable() { }

    void detach()
    {
        if (internal.use_count() > 1)
            detachInternal();
    }

protected:
    virtual void detachInternal() = 0;

protected:
    std::shared_ptr<T> internal;
};

class MouseEvent : public Detachable<Disseminate::Mouse::EventT>
{
public:
    MouseEvent(int _type, int _button, double _x, double _y)
    {
        internal = std::make_shared<Disseminate::Mouse::EventT>();
        internal->type = static_cast<Disseminate::Mouse::Type>(_type);
        internal->button = static_cast<Disseminate::Mouse::Button>(_button);
        internal->windowNumber = 0;
        internal->modifiers = 0;
        internal->timestamp = timeIntervalSinceSystemStartup();
        internal->clickCount = 0;
        internal->pressure = 0.;

        internal->location = std::make_unique<Disseminate::Mouse::Location>(_x, _y);
    }
    MouseEvent(std::unique_ptr<Disseminate::Mouse::EventT>& unique)
    {
        internal.reset(unique.release());
    }
    MouseEvent(NSEvent* event);

    double x() { return internal->location->x(); }
    void setX(double x) { detach(); internal->location->mutate_x(x); }
    float y() { return internal->location->y(); }
    void setY(double y) { detach(); internal->location->mutate_y(y); }

    int32_t type() { return internal->type; }
    void setType(int32_t arg) { detach(); internal->type = static_cast<Disseminate::Mouse::Type>(arg); }

    int32_t button() { return internal->button; }
    void setButton(int32_t arg) { detach(); internal->button = static_cast<Disseminate::Mouse::Button>(arg); };

    int32_t windowNumber() { return internal->windowNumber; }
    void setWindowNumber(int32_t arg) { detach(); internal->windowNumber = arg; };

    uint16_t modifiers() { return internal->modifiers; }
    void setModifiers(uint16_t arg) { detach(); internal->modifiers = arg; };

    double timestamp() { return internal->timestamp; }
    void setTimestamp(double arg) { detach(); internal->timestamp = arg; };

    int32_t clickCount() { return internal->clickCount; }
    void setClickCount(int32_t arg) { detach(); internal->clickCount = arg; };

    double pressure() { return internal->pressure; }
    void setPressure(double arg) { detach(); internal->pressure = arg; }

    std::string fromUuid() { return internal->fromUuid; }

    MouseEvent clone() { return MouseEvent(*this); }

    Disseminate::Mouse::EventT* flat() { return internal.get(); }

protected:
    virtual void detachInternal()
    {
        std::shared_ptr<Disseminate::Mouse::EventT> other = internal;
        internal = std::make_shared<Disseminate::Mouse::EventT>();
        internal->type = other->type;
        internal->button = other->button;
        internal->windowNumber = other->windowNumber;
        internal->modifiers = other->modifiers;
        internal->timestamp = other->timestamp;
        internal->clickCount = other->clickCount;
        internal->pressure = other->pressure;
        internal->fromUuid = other->fromUuid;

        if (other->location) {
            internal->location = std::make_unique<Disseminate::Mouse::Location>(other->location->x(), other->location->y());
        }
    }
};

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
        break;
    case NSLeftMouseDragged:
        internal->type = Disseminate::Mouse::Type_Move;
        internal->button = Disseminate::Mouse::Button_Left;
        break;
    case NSRightMouseDragged:
        internal->type = Disseminate::Mouse::Type_Move;
        internal->button = Disseminate::Mouse::Button_Right;
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
    internal->windowNumber = [event windowNumber];
}

class KeyEvent : public Detachable<Disseminate::Key::EventT>
{
public:
    KeyEvent(int _type, int _code, double _x, double _y)
    {
        internal = std::make_shared<Disseminate::Key::EventT>();
        internal->type = static_cast<Disseminate::Key::Type>(_type);
        internal->keyCode = _code;
        internal->windowNumber = 0;
        internal->modifiers = 0;
        internal->timestamp = timeIntervalSinceSystemStartup();
        internal->repeat = false;

        internal->location = std::make_unique<Disseminate::Key::Location>(_x, _y);
    }
    KeyEvent(std::unique_ptr<Disseminate::Key::EventT>& unique)
    {
        internal.reset(unique.release());
    }
    KeyEvent(NSEvent* event);

    double x() { return internal->location->x(); }
    void setX(double x) { detach(); internal->location->mutate_x(x); }
    float y() { return internal->location->y(); }
    void setY(double y) { detach(); internal->location->mutate_y(y); }

    int32_t type() { return internal->type; }
    void setType(int32_t arg) { detach(); internal->type = static_cast<Disseminate::Key::Type>(arg); }

    int32_t keyCode() { return internal->keyCode; }
    void setKeyCode(int32_t arg) { detach(); internal->keyCode = arg; }

    int32_t windowNumber() { return internal->windowNumber; }
    void setWindowNumber(int32_t arg) { detach(); internal->windowNumber = arg; };

    uint32_t modifiers() { return internal->modifiers; }
    void setModifiers(uint16_t arg) { detach(); internal->modifiers = arg; };

    double timestamp() { return internal->timestamp; }
    void setTimestamp(double arg) { detach(); internal->timestamp = arg; };

    std::string text() { return internal->text; }
    void setText(std::string arg) { detach(); internal->text = arg; }

    bool repeat() { return internal->repeat; }
    void setRepeat(bool arg) { detach(); internal->repeat = arg; }

    std::string fromUuid() { return internal->fromUuid; }

    KeyEvent clone() { return KeyEvent(*this); }

    Disseminate::Key::EventT* flat() { return internal.get(); }

protected:
    virtual void detachInternal()
    {
        std::shared_ptr<Disseminate::Key::EventT> other = internal;
        internal = std::make_shared<Disseminate::Key::EventT>();
        internal->type = other->type;
        internal->keyCode = other->keyCode;
        internal->windowNumber = other->windowNumber;
        internal->modifiers = other->modifiers;
        internal->timestamp = other->timestamp;
        internal->text = other->text;
        internal->repeat = other->repeat;
        internal->fromUuid = other->fromUuid;

        if (other->location) {
            internal->location = std::make_unique<Disseminate::Key::Location>(other->location->x(), other->location->y());
        }
    }
};

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
    internal->windowNumber = [event windowNumber];
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

    std::map<std::string, std::shared_ptr<MessagePortRemote> > ports;

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
        "windownumber", &MouseEvent::windowNumber,
        "set_windownumber", &MouseEvent::setWindowNumber,
        "clickCount", &MouseEvent::clickCount,
        "set_clickCount", &MouseEvent::setClickCount,
        "pressure", &MouseEvent::pressure,
        "set_pressure", &MouseEvent::setPressure,
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
        "windownumber", &KeyEvent::windowNumber,
        "set_windownumber", &KeyEvent::setWindowNumber,
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
            flatbuffers::FlatBufferBuilder builder;
            auto flat = event.flat();
            flat->fromUuid = data->uuid;
            auto buffer = Disseminate::Mouse::CreateEvent(builder, flat);
            builder.Finish(buffer);
            std::vector<uint8_t> message(builder.GetBufferPointer(),
                                         builder.GetBufferPointer() + builder.GetSize());

            auto port = data->ports.cbegin();
            const auto end = data->ports.cend();
            while (port != end) {
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
            ScopedPool pool;
            NSEventType type = static_cast<NSEventType>(0);
            NSPoint location;
            int count = 1;
            float pressure = 1;
            switch (event.button()) {
            case Disseminate::Mouse::Button_Left:
                switch (event.type()) {
                case Disseminate::Mouse::Type_Press:
                    type = NSLeftMouseDown;
                    break;
                case Disseminate::Mouse::Type_Release:
                    type = NSLeftMouseUp;
                    break;
                case Disseminate::Mouse::Type_Move:
                    type = NSLeftMouseDragged;
                    break;
                }
                break;
            case Disseminate::Mouse::Button_Middle:
#warning handle me
                break;
            case Disseminate::Mouse::Button_Right:
                switch (event.type()) {
                case Disseminate::Mouse::Type_Press:
                    type = NSRightMouseDown;
                    break;
                case Disseminate::Mouse::Type_Release:
                    type = NSRightMouseUp;
                    break;
                case Disseminate::Mouse::Type_Move:
                    type = NSRightMouseDragged;
                    break;
                }
                break;
            case Disseminate::Mouse::Button_None:
                count = 0;
                pressure = 0;
                type = NSMouseMoved;
                break;
            }
            if (!type) {
                printf("no valid event type\n");
                return;
            }
            location.x = event.x();
            location.y = event.y();

            NSEvent* evt = [NSEvent mouseEventWithType:type location:location modifierFlags:event.modifiers() timestamp:event.timestamp()
                            windowNumber:event.windowNumber() context:0 eventNumber:0 clickCount:count pressure:pressure];
            EventLoop::eventLoop()->postEvent(std::make_shared<EventLoopEvent>(evt, EventLoopEvent::Retain));
        };
    }

    {
        auto keyEvent = (*state)["keyEvent"];
        keyEvent["on"] = [this](sel::function<bool(int, KeyEvent)> fun) {
            data->keyEventFunctions.push_back(fun);
        };
        keyEvent["sendToAll"] = [this](KeyEvent event) {
            flatbuffers::FlatBufferBuilder builder;
            auto flat = event.flat();
            flat->fromUuid = data->uuid;
            auto buffer = Disseminate::Key::CreateEvent(builder, flat);
            builder.Finish(buffer);
            std::vector<uint8_t> message(builder.GetBufferPointer(),
                                         builder.GetBufferPointer() + builder.GetSize());

            auto port = data->ports.cbegin();
            const auto end = data->ports.cend();
            while (port != end) {
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
            ScopedPool pool;
            NSEventType type = static_cast<NSEventType>(0);
            NSPoint location;
            switch (event.type()) {
            case Disseminate::Key::Type_Up:
                type = NSKeyUp;
                break;
            case Disseminate::Key::Type_Down:
                type = NSKeyDown;
                break;
            }
            if (!type) {
                printf("no valid event type\n");
                return;
            }
            location.x = event.x();
            location.y = event.y();

            auto wrapper = fromStdString(event.text());
            NSEvent* evt = [NSEvent keyEventWithType:type location:location modifierFlags:event.modifiers() timestamp:event.timestamp()
                            windowNumber:event.windowNumber() context:0 characters:wrapper->str() charactersIgnoringModifiers:wrapper->str()
                            isARepeat:event.repeat() keyCode: event.keyCode()];
            EventLoop::eventLoop()->postEvent(std::make_shared<EventLoopEvent>(evt, EventLoopEvent::Retain));
        };
    }

    (*state)["logString"] = [](const std::string& str) {
        printf("logString -- '%s'\n", str.c_str());
    };
    (*state)["logInt"] = [](int i) {
        printf("logInt -- %d\n", i);
    };
#if 1
    (*state)("function acceptKeys(type, ke)\n"
             "  logInt(1)\n"
             "  if type == enums.Remote then\n"
             "    keyEvent.inject(ke)\n"
             "    return true\n"
             "  end\n"
             "  logInt(2)\n"
             "  local code = ke:keycode()\n"
             "  local mods = ke:modifiers()\n"
             "  logInt(3)\n"
             "  if keys and keys.global then\n"
             "    if keys.global.keys then\n"
             "      for k,v in ipairs(keys.global.keys) do\n"
             "        logString(\"testing\")\n"
             "        logInt(v.modifiers)\n"
             "        logInt(mods)\n"
             "        if v.keycode == code and v.modifiers == mods then\n"
             "          logInt(30)\n"
             "          keyEvent.sendToAll(ke)\n"
             "        end\n"
             "      end\n"
             "    end\n"
             "    logInt(4)\n"
             "    if keys.global.exclusions then\n"
             "      for k,v in ipairs(keys.global.exclusions) do\n"
             "        if v.keycode == code and v.modifiers == mods then\n"
             "          logInt(40)\n"
             "          return false\n"
             "        end\n"
             "      end\n"
             "    end\n"
             "  end\n"
             "  logInt(5)\n"
             "  return true\n"
             "end\n"
             "keyEvent.on(acceptKeys)\n");
#endif
#if 0
    (*state)("local foobar\n"
             "local wnum = 0\n"
             "function acceptMouseEvent(type, me)\n"
             "  if me:x() > 380 then\n"
             "    logInt(776)\n"
             "    logInt(me:type())\n"
             "    if me:type() == enums.MouseRelease then\n"
             "      local move = MouseEvent.new(enums.MouseMove, enums.MouseButtonNone, 502.386719, 155.292969)\n"
             "      move:set_windownumber(me:windownumber())\n"
             "      mouseEvent.inject(move)\n"
             "      local press = MouseEvent.new(enums.MousePress, enums.MouseButtonLeft, 502.386719, 155.292969)\n"
             "      press:set_windownumber(me:windownumber())\n"
             "      mouseEvent.inject(press)\n"
             "      local release = MouseEvent.new(enums.MouseRelease, enums.MouseButtonLeft, 502.386719, 155.292969)\n"
             "      release:set_windownumber(me:windownumber())\n"
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
             "    wnum = ke:windownumber()\n"
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
             "    keyPress:set_windownumber(wnum)\n"
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

    NSEvent* nsevent = event->evt;
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
            printf("processing local-- %p\n", &localEvent);
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
            printf("processing local-- %p\n", &localEvent);
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
