#include "ScriptEngine.h"
#import <Cocoa/Cocoa.h>

struct MouseEvent
{
    enum Type { Unknown, Move, Press, Release };
    enum Button { None, Left, Middle, Right };

    MouseEvent()
        : type(Unknown), button(None), x(0), y(0), modifiers(0), clickCount(0), pressure(0)
    {
    }

    MouseEvent(NSEvent* event);

    Type type;
    Button button;
    double x, y;
    unsigned short modifiers;
    int clickCount;
    float pressure;
};

MouseEvent::MouseEvent(NSEvent* event)
{
    switch ([event type]) {
    case NSLeftMouseDown:
        type = Press;
        button = Left;
        break;
    case NSLeftMouseUp:
        type = Release;
        button = Left;
        break;
    case NSRightMouseDown:
        type = Press;
        button = Right;
        break;
    case NSRightMouseUp:
        type = Release;
        button = Right;
        break;
    case NSMouseMoved:
        type = Move;
        button = None;
        break;
    case NSLeftMouseDragged:
        type = Move;
        button = Left;
        break;
    case NSRightMouseDragged:
        type = Move;
        button = Right;
        break;
    default:
        abort();
        break;
    }
    {
        NSPoint location = [event locationInWindow];
        x = location.x;
        y = location.y;
    }
    modifiers = [event modifierFlags];
    clickCount = [event clickCount];
    pressure = [event pressure];
}

class Clients
{
public:
    size_t size() { return vec.size(); }
    int type(size_t pos) { return vec.at(pos).first; }
    std::string name(size_t pos) { return vec.at(pos).second; }

    std::vector<std::pair<ScriptEngine::ClientType, std::string> > vec;
};

namespace constants {
enum { Add, Remove };
}

class ScriptEngineData
{
public:
    std::vector<sel::function<bool(int, MouseEvent)> > mouseEventFunctions;
    std::vector<sel::function<void(int, int, const std::string&)> > clientChangeFunctions;

    Clients clients;
};

static inline void setConstant(sel::State& state, const std::string& name, int c)
{
    state["constants"][name] = c;
}

ScriptEngine::ScriptEngine()
    : state(std::make_unique<sel::State>()),
      data(std::make_unique<ScriptEngineData>())
{
    (*state)["MouseEvent"].SetClass<MouseEvent>(
        "type", &MouseEvent::type,
        "button", &MouseEvent::button,
        "x", &MouseEvent::x,
        "y", &MouseEvent::y,
        "modifiers", &MouseEvent::modifiers,
        "clickCount", &MouseEvent::clickCount,
        "pressure", &MouseEvent::pressure);
    (*state)["clients"].SetObj(data->clients,
                               "size", &Clients::size,
                               "type", &Clients::type,
                               "name", &Clients::name);

    setConstant(*state, "MouseMove", MouseEvent::Move);
    setConstant(*state, "Add", constants::Add);
    setConstant(*state, "Remove", constants::Remove);

    (*state)["onClientChange"] = [this](sel::function<void(int, int, const std::string&)> fun) {
        data->clientChangeFunctions.push_back(fun);
    };

    {
        auto mouseEvent = (*state)["mouseEvent"];
        mouseEvent["on"] = [this](sel::function<bool(int, MouseEvent)> fun) {
            data->mouseEventFunctions.push_back(fun);
        };
        mouseEvent["send"] = [](MouseEvent event) {
            // send to all
        };
        mouseEvent["sendTo"] = [](MouseEvent event, const std::string& to) {
            // send to specific
            printf("remote send mouse event (%f %f) to %s (%p)\n", event.x, event.y, to.c_str(), &event);
        };
        mouseEvent["inject"] = [](MouseEvent event) {
        };
    }

    (*state)["hey"] = [](const std::string& str) {
        printf("hey.. %s\n", str.c_str());
    };
    (*state)["hey2"] = [](int i) {
        printf("hey2.. %d\n", i);
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
             "  me:set_x(100)\n"
             "  mouseEvent.sendTo(me, \"def\")\n"
             "  foobar = me\n"
             "  return true\n"
             "end\n"
             "hey2(constants.MouseMove)\n"
             "mouseEvent.on(acceptOtherMouseEvent)\n"
             "mouseEvent.on(acceptMouseEvent)\n");
}

ScriptEngine::~ScriptEngine()
{
}

void ScriptEngine::registerClient(ClientType type, const std::string& uuid)
{
    data->clients.vec.push_back(std::make_pair(type, uuid));

    auto on = data->clientChangeFunctions.begin();
    const auto end = data->clientChangeFunctions.end();
    while (on != end) {
        (*on)(constants::Add, type, uuid);
        ++on;
    }
}

void ScriptEngine::unregisterClient(ClientType type, const std::string& uuid)
{
    {
        auto client = data->clients.vec.begin();
        const auto end = data->clients.vec.end();
        while (client != end) {
            if (client->first == type && client->second == uuid) {
                data->clients.vec.erase(client);
                break;
            }
            ++client;
        }
    }
    auto on = data->clientChangeFunctions.begin();
    const auto end = data->clientChangeFunctions.end();
    while (on != end) {
        (*on)(constants::Remove, type, uuid);
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
