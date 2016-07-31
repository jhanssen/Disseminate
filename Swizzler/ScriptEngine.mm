#include "ScriptEngine.h"
#include "MessagePort.h"
#include "FlatbufferTypes.h"
#include <map>
#include <memory>
#include <MouseEvent_generated.h>
#include "CocoaUtils.h"
#include <mach/mach_time.h>
#import <Cocoa/Cocoa.h>
#include "EventLoop.h"

// From
// http://stackoverflow.com/questions/1597383/cgeventtimestamp-to-nsdate
// Which credits Apple sample code for this routine.
static inline uint64_t timeInNanoseconds(void)
{
    uint64_t time;
    uint64_t timeNano;
    static mach_timebase_info_data_t sTimebaseInfo;

    time = mach_absolute_time();

    // Convert to nanoseconds.

    // If this is the first time we've run, get the timebase.
    // We can use denom == 0 to indicate that sTimebaseInfo is
    // uninitialised because it makes no sense to have a zero
    // denominator is a fraction.
    if (sTimebaseInfo.denom == 0) {
        (void) mach_timebase_info(&sTimebaseInfo);
    }

    // This could overflow; for testing needs we probably don't care.
    timeNano = time * sTimebaseInfo.numer / sTimebaseInfo.denom;
    return timeNano;
}

static inline NSTimeInterval timeIntervalSinceSystemStartup()
{
    return timeInNanoseconds() / 1000000000.0;
}

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

class MouseEvent : public Detachable<Disseminate::MouseEventT>
{
public:
    MouseEvent(int _type, int _button, double _x, double _y)
    {
        internal = std::make_shared<Disseminate::MouseEventT>();
        internal->type = static_cast<Disseminate::Type>(_type);
        internal->button = static_cast<Disseminate::Button>(_button);
        internal->windowNumber = 0;
        internal->modifiers = 0;
        internal->timestamp = timeIntervalSinceSystemStartup();
        internal->clickCount = 0;
        internal->pressure = 0.;

        internal->location = std::make_unique<Disseminate::Location>(_x, _y);
    }
    MouseEvent(std::unique_ptr<Disseminate::MouseEventT>& unique)
    {
        internal.reset(unique.release());
    }
    MouseEvent(NSEvent* event);

    double x() { return internal->location->x(); }
    void setX(double x) { detach(); internal->location->mutate_x(x); }
    float y() { return internal->location->y(); }
    void setY(double y) { detach(); internal->location->mutate_y(y); }

    int32_t type() { return internal->type; }
    void setType(int32_t arg) { detach(); internal->type = static_cast<Disseminate::Type>(arg); }

    int32_t button() { return internal->button; }
    void setButton(int32_t arg) { detach(); internal->button = static_cast<Disseminate::Button>(arg); };

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

    MouseEvent clone() { return MouseEvent(*this); }

    Disseminate::MouseEventT* flat() { return internal.get(); }

protected:
    virtual void detachInternal()
    {
        std::shared_ptr<Disseminate::MouseEventT> other = internal;
        internal = std::make_shared<Disseminate::MouseEventT>();
        internal->type = other->type;
        internal->button = other->button;
        internal->windowNumber = other->windowNumber;
        internal->modifiers = other->modifiers;
        internal->timestamp = other->timestamp;
        internal->clickCount = other->clickCount;
        internal->pressure = other->pressure;
        internal->fromUuid = other->fromUuid;

        if (other->location) {
            internal->location = std::make_unique<Disseminate::Location>(other->location->x(), other->location->y());
        }
    }
};

MouseEvent::MouseEvent(NSEvent* event)
{
    internal = std::make_shared<Disseminate::MouseEventT>();
    switch ([event type]) {
    case NSLeftMouseDown:
        internal->type = Disseminate::Type_Press;
        internal->button = Disseminate::Button_Left;
        break;
    case NSLeftMouseUp:
        internal->type = Disseminate::Type_Release;
        internal->button = Disseminate::Button_Left;
        break;
    case NSRightMouseDown:
        internal->type = Disseminate::Type_Press;
        internal->button = Disseminate::Button_Right;
        break;
    case NSRightMouseUp:
        internal->type = Disseminate::Type_Release;
        internal->button = Disseminate::Button_Right;
        break;
    case NSMouseMoved:
        internal->type = Disseminate::Type_Move;
        internal->button = Disseminate::Button_None;
        break;
    case NSLeftMouseDragged:
        internal->type = Disseminate::Type_Move;
        internal->button = Disseminate::Button_Left;
        break;
    case NSRightMouseDragged:
        internal->type = Disseminate::Type_Move;
        internal->button = Disseminate::Button_Right;
        break;
    default:
        abort();
        break;
    }
    {
        NSPoint location = [event locationInWindow];
        internal->location = std::make_unique<Disseminate::Location>(location.x, location.y);
    }
    internal->modifiers = [event modifierFlags];
    internal->clickCount = [event clickCount];
    internal->pressure = [event pressure];
    internal->timestamp = [event timestamp];
    internal->windowNumber = [event windowNumber];
}

namespace enums {
enum { Add, Remove };
}

class ScriptEngineData
{
public:
    ScriptEngineData(const std::string& id)
        : uuid(id)
    {
    }

    std::vector<sel::function<bool(int, MouseEvent)> > mouseEventFunctions;
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
};

static inline void setEnum(sel::State& state, const std::string& name, int c)
{
    state["enums"][name] = c;
}

ScriptEngine::ScriptEngine(const std::string& uuid)
    : state(std::make_unique<sel::State>()),
      data(std::make_unique<ScriptEngineData>(uuid))
{
    state->HandleExceptionsPrintingToStdOut();

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
        "clone", &MouseEvent::clone);

    setEnum(*state, "MouseMove", Disseminate::Type_Move);
    setEnum(*state, "MousePress", Disseminate::Type_Press);
    setEnum(*state, "MouseRelease", Disseminate::Type_Release);
    setEnum(*state, "MouseButtonNone", Disseminate::Button_None);
    setEnum(*state, "MouseButtonLeft", Disseminate::Button_Left);
    setEnum(*state, "MouseButtonMiddle", Disseminate::Button_Middle);
    setEnum(*state, "MouseButtonRight", Disseminate::Button_Right);
    setEnum(*state, "Add", enums::Add);
    setEnum(*state, "Remove", enums::Remove);
    setEnum(*state, "Local", ScriptEngine::Local);
    setEnum(*state, "Remote", ScriptEngine::Remote);

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
        auto mouseEvent = (*state)["mouseEvent"];
        mouseEvent["on"] = [this](sel::function<bool(int, MouseEvent)> fun) {
            data->mouseEventFunctions.push_back(fun);
        };
        mouseEvent["sendToAll"] = [this](MouseEvent event) {
            flatbuffers::FlatBufferBuilder builder;
            auto flat = event.flat();
            flat->fromUuid = data->uuid;
            auto buffer = Disseminate::CreateMouseEvent(builder, flat);
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
            auto buffer = Disseminate::CreateMouseEvent(builder, flat);
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
            case Disseminate::Button_Left:
                switch (event.type()) {
                case Disseminate::Type_Press:
                    type = NSLeftMouseDown;
                    break;
                case Disseminate::Type_Release:
                    type = NSLeftMouseUp;
                    break;
                case Disseminate::Type_Move:
                    type = NSLeftMouseDragged;
                    break;
                }
                break;
           case Disseminate::Button_Middle:
#warning handle me
                break;
            case Disseminate::Button_Right:
                switch (event.type()) {
                case Disseminate::Type_Press:
                    type = NSRightMouseDown;
                    break;
                case Disseminate::Type_Release:
                    type = NSRightMouseUp;
                    break;
                case Disseminate::Type_Move:
                    type = NSRightMouseDragged;
                    break;
                }
                break;
            case Disseminate::Button_None:
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

            NSEvent* evt = [NSEvent mouseEventWithType:type location:location modifierFlags:0 timestamp:event.timestamp()
                            windowNumber:event.windowNumber() context:0 eventNumber:0 clickCount:count pressure:pressure];
            EventLoop::eventLoop()->postEvent(std::make_shared<EventLoopEvent>(evt, EventLoopEvent::Retain));
        };
    }

    (*state)["logString"] = [](const std::string& str) {
        printf("logString -- '%s'\n", str.c_str());
    };
    (*state)["logInt"] = [](int i) {
        printf("logInt -- %d\n", i);
    };
    (*state)("local foobar\n"
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
             "function clientChange(change, type, client)\n"
             "  logString(client)\n"
             "  logInt(change)\n"
             "  logInt(type)\n"
             "  logInt(clients.size())\n"
             "  logString(clients.name(0))\n"
             "end\n"
             "logInt(enums.MouseMove)\n"
             "logInt(clients.size())\n"
             "clients.on(clientChange)\n"
             "mouseEvent.on(acceptOtherMouseEvent)\n"
             //"mouseEvent.on(acceptMouseEvent)\n"
        );
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

void ScriptEngine::processRemoteEvent(std::unique_ptr<Disseminate::MouseEventT>& eventData)
{
    sel::HandlerScope scope(state->GetExceptionHandler());

    MouseEvent event(eventData);
    auto on = data->mouseEventFunctions.begin();
    const auto end = data->mouseEventFunctions.end();
    while (on != end) {
        MouseEvent remoteEvent(event);
        printf("processing remote-- %p\n", &remoteEvent);
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
            MouseEvent localEvent(nsevent);
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
