#include "ScriptEngine.h"
#include "MessagePort.h"
#include <map>
#include <memory>
#include <MouseEvent_generated.h>
#import <Cocoa/Cocoa.h>

struct MouseEvent
{
    MouseEvent(int _type, int _button, double _x, double _y)
    {
        internal.type = static_cast<Disseminate::Type>(_type);
        internal.button = static_cast<Disseminate::Button>(_button);
        internal.windowNumber = 0;
        internal.modifiers = 0;
        internal.timestamp = 0.;
        internal.clickCount = 0;
        internal.pressure = 0.;

        internal.location = std::make_unique<Disseminate::Location>(_x, _y);
    }
    MouseEvent(const MouseEvent& other)
    {
        internal.type = other.internal.type;
        internal.button = other.internal.button;
        internal.windowNumber = other.internal.windowNumber;
        internal.modifiers = other.internal.modifiers;
        internal.timestamp = other.internal.timestamp;
        internal.clickCount = other.internal.clickCount;
        internal.pressure = other.internal.pressure;

        if (other.internal.location) {
            internal.location = std::make_unique<Disseminate::Location>(other.internal.location->x(), other.internal.location->y());
        }
    }
    MouseEvent(NSEvent* event);
    MouseEvent& operator=(const MouseEvent& other)
    {
        internal.type = other.internal.type;
        internal.button = other.internal.button;
        internal.windowNumber = other.internal.windowNumber;
        internal.modifiers = other.internal.modifiers;
        internal.timestamp = other.internal.timestamp;
        internal.clickCount = other.internal.clickCount;
        internal.pressure = other.internal.pressure;

        if (other.internal.location) {
            internal.location = std::make_unique<Disseminate::Location>(other.internal.location->x(), other.internal.location->y());
        } else {
            internal.location.reset();
        }
        return *this;
    }

    double x() { return internal.location->x(); }
    float y() { return internal.location->y(); }
    void setX(double x) { internal.location->mutate_x(x); }
    void setY(double y) { internal.location->mutate_y(y); }

    Disseminate::Type type() { return internal.type; }
    void setType(Disseminate::Type arg) { internal.type = arg; }
    Disseminate::Button button() { return internal.button; }
    void setButton(Disseminate::Button arg) { internal.button = arg; };
    int32_t windowNumber() { return internal.windowNumber; }
    void setWindowNumber(int32_t arg) { internal.windowNumber = arg; };
    uint16_t modifiers() { return internal.modifiers; }
    void setModifiers(uint16_t arg) { internal.modifiers = arg; };
    double timestamp() { return internal.timestamp; }
    void setTimestamp(double arg) { internal.timestamp = arg; };
    int32_t clickCount() { return internal.clickCount; }
    void setClickCount(int32_t arg) { internal.clickCount = arg; };
    double pressure() { return internal.pressure; }
    void setPressure(double arg) { internal.pressure = arg; }

    Disseminate::MouseEventT& flat() { return internal; }

private:
    Disseminate::MouseEventT internal;
};

MouseEvent::MouseEvent(NSEvent* event)
{
    switch ([event type]) {
    case NSLeftMouseDown:
        internal.type = Disseminate::Type_Press;
        internal.button = Disseminate::Button_Left;
        break;
    case NSLeftMouseUp:
        internal.type = Disseminate::Type_Release;
        internal.button = Disseminate::Button_Left;
        break;
    case NSRightMouseDown:
        internal.type = Disseminate::Type_Press;
        internal.button = Disseminate::Button_Right;
        break;
    case NSRightMouseUp:
        internal.type = Disseminate::Type_Release;
        internal.button = Disseminate::Button_Right;
        break;
    case NSMouseMoved:
        internal.type = Disseminate::Type_Move;
        internal.button = Disseminate::Button_None;
        break;
    case NSLeftMouseDragged:
        internal.type = Disseminate::Type_Move;
        internal.button = Disseminate::Button_Left;
        break;
    case NSRightMouseDragged:
        internal.type = Disseminate::Type_Move;
        internal.button = Disseminate::Button_Right;
        break;
    default:
        abort();
        break;
    }
    {
        NSPoint location = [event locationInWindow];
        internal.location = std::make_unique<Disseminate::Location>(location.x, location.y);
    }
    internal.modifiers = [event modifierFlags];
    internal.clickCount = [event clickCount];
    internal.pressure = [event pressure];
    internal.timestamp = 0;
    internal.windowNumber = 0;
}

namespace enums {
enum { Add, Remove };
}

class ScriptEngineData
{
public:
    std::vector<sel::function<bool(int, MouseEvent)> > mouseEventFunctions;
    std::vector<sel::function<void(int, int, const std::string&)> > clientChangeFunctions;

    std::vector<std::pair<ScriptEngine::ClientType, std::string> > clients;

    std::map<std::string, std::shared_ptr<MessagePortRemote> > ports;

    const std::shared_ptr<MessagePortRemote>& port(const std::string& name)
    {
        auto it = ports.find(name);
        if (it != ports.end())
            return it->second;
        ports[name] = std::make_shared<MessagePortRemote>(name);
        it = ports.find(name);
        return it->second;
    }
};

static inline void setEnum(sel::State& state, const std::string& name, int c)
{
    state["enums"][name] = c;
}

ScriptEngine::ScriptEngine()
    : state(std::make_unique<sel::State>()),
      data(std::make_unique<ScriptEngineData>())
{
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
        "set_pressure", &MouseEvent::setPressure);

    setEnum(*state, "MouseMove", Disseminate::Type_Move);
    setEnum(*state, "MousePress", Disseminate::Type_Press);
    setEnum(*state, "MouseRelease", Disseminate::Type_Release);
    setEnum(*state, "MouseButtonNone", Disseminate::Button_None);
    setEnum(*state, "MouseButtonLeft", Disseminate::Button_Left);
    setEnum(*state, "MouseButtonMiddle", Disseminate::Button_Middle);
    setEnum(*state, "MouseButtonRight", Disseminate::Button_Right);
    setEnum(*state, "Add", enums::Add);
    setEnum(*state, "Remove", enums::Remove);

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
            auto buffer = Disseminate::CreateMouseEvent(builder, &event.flat());
            builder.Finish(buffer);
            std::vector<uint8_t> message(builder.GetBufferPointer(),
                                         builder.GetBufferPointer() + builder.GetSize());

            auto port = data->ports.cbegin();
            const auto end = data->ports.cend();
            while (port != end) {
                port->second->send(message);
                ++port;
            }
        };
        mouseEvent["sendTo"] = [this](MouseEvent event, const std::string& to) {
            // send to specific
            const std::shared_ptr<MessagePortRemote>& port = data->port(to);
            flatbuffers::FlatBufferBuilder builder;
            auto buffer = Disseminate::CreateMouseEvent(builder, &event.flat());
            builder.Finish(buffer);
            std::vector<uint8_t> message(builder.GetBufferPointer(),
                                         builder.GetBufferPointer() + builder.GetSize());
            port->send(message);
        };
        mouseEvent["inject"] = [](MouseEvent event) {
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
             "  me:set_x(100)\n"
             "  mouseEvent.sendTo(me, \"530ness\")\n"
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
             "mouseEvent.on(acceptMouseEvent)\n");
}

ScriptEngine::~ScriptEngine()
{
}

void ScriptEngine::registerClient(ClientType type, const std::string& uuid)
{
    data->clients.push_back(std::make_pair(type, uuid));

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
    auto on = data->clientChangeFunctions.begin();
    const auto end = data->clientChangeFunctions.end();
    while (on != end) {
        (*on)(enums::Remove, type, uuid);
        ++on;
    }
}

void ScriptEngine::processRemoteEvent(const Disseminate::MouseEvent* event)
{
}

bool ScriptEngine::processLocalEvent(NSEvent* event)
{
    switch ([event type]) {
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
            MouseEvent localEvent(event);
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
