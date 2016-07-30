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

class ScriptEngineData
{
public:
    std::vector<sel::function<bool(int, MouseEvent*)> > mouseEventFunctions;
    std::vector<sel::function<void(int, const std::string&)> > clientChangeFunctions;
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

    setConstant(*state, "MouseMove", MouseEvent::Move);

    (*state)["sendMouseEvent"] = [](MouseEvent* event) {
        // send to all
    };
    (*state)["sendMouseEventTo"] = [](MouseEvent* event, const std::string& to) {
        // send to specific
        printf("send mouse event (%f %f) to %s\n", event->x, event->y, to.c_str());
    };
    (*state)["onMouseEvent"] = [this](sel::function<bool(int, MouseEvent*)> fun) {
        data->mouseEventFunctions.push_back(fun);
    };
    (*state)["onClientChange"] = [this](sel::function<void(int, const std::string&)> fun) {
        data->clientChangeFunctions.push_back(fun);
    };
    (*state)["hey"] = [](const std::string& str) {
        printf("hey.. %s\n", str.c_str());
    };
    (*state)["hey2"] = [](int i) {
        printf("hey2.. %d\n", i);
    };
    (*state)("function acceptMouseEvent(type, me)\n"
             "  if me:x() > 380 then\n"
             "    return false"
             "  end\n"
             "  sendMouseEventTo(me, \"abc\")\n"
             "  return true\n"
             "end\n"
             "hey2(constants.MouseMove)\n"
             "onMouseEvent(acceptMouseEvent)\n");
}

ScriptEngine::~ScriptEngine()
{
}

void ScriptEngine::registerClient(ClientType type, const std::string& uuid)
{
}

void ScriptEngine::unregisterClient(ClientType type, const std::string& uuid)
{
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
        MouseEvent localEvent(event);

        auto on = data->mouseEventFunctions.begin();
        const auto end = data->mouseEventFunctions.end();
        while (on != end) {
            printf("processing local--\n");
            if (!(*on)(Local, &localEvent))
                return false;
            ++on;
        }
        break; }
    default:
        break;
    }
    return true;
}
