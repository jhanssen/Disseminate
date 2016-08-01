/*
  Disseminate, keyboard broadcaster
  Copyright (C) 2016  Jan Erik Hanssen

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include "Utils.h"
#include <assert.h>
#include <Carbon/Carbon.h>
#import <Cocoa/Cocoa.h>

static FILE* logfile = 0;

static void log(const char* format, ...)
{
    va_list ap;
    va_start(ap, format);
    char buf[1024];
    const int len = vsnprintf(buf, sizeof(buf), format, ap);
    va_end(ap);

    if (!logfile) {
        logfile = fopen("/tmp/disseminate.log", "w");
    }
    fwrite(buf, 1, len, logfile);
    fwrite("\n", 1, 2, logfile);
}

struct ReadKey
{
    CFMachPortRef tap;
    CFRunLoopSourceRef source;
    std::function<void(int64_t, uint64_t)> func;
};

static ReadKey readKey = { nullptr, nullptr, nullptr };

static ProcessSerialNumber activePSN()
{
    NSWorkspace* workspace            = [NSWorkspace sharedWorkspace];
    NSDictionary* currentAppInfo      = [workspace activeApplication];

    //Get the PSN of the current application.
    ProcessSerialNumber psn;
    psn.lowLongOfPSN = [[currentAppInfo objectForKey:@"NSApplicationProcessSerialNumberLow"] longValue];
    psn.highLongOfPSN = [[currentAppInfo objectForKey:@"NSApplicationProcessSerialNumberHigh"] longValue];
    return psn;
}

CGEventRef readkeyCGEventCallback(CGEventTapProxy /*proxy*/,
                                  CGEventType type,
                                  CGEventRef event,
                                  void *refcon)
{
    if(type == NX_KEYDOWN) {
        ReadKey* readKey = static_cast<ReadKey*>(refcon);
        // CG_EXTERN int64_t CGEventGetIntegerValueField(CGEventRef __nullable event,
        // CGEventField field)
        const int64_t virt = CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
        const CGEventFlags flags = CGEventGetFlags(event);
        readKey->func(virt, flags);
    }

    return event;
}

bool broadcast::startReadKey(const std::function<void(int64_t, uint64_t)>& func)
{
    stopReadKey();

    CFRunLoopRef runloop = (CFRunLoopRef)CFRunLoopGetCurrent();
    CGEventMask interestedEvents = CGEventMaskBit(kCGEventKeyDown);
    ProcessSerialNumber psn = activePSN();
    readKey.tap = CGEventTapCreateForPSN(&psn, kCGHeadInsertEventTap,
                                         kCGEventTapOptionDefault, interestedEvents, readkeyCGEventCallback, &readKey);
    if (!readKey.tap)
        return false;
    readKey.source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, readKey.tap, 0);
    readKey.func = func;
    CFRunLoopAddSource(runloop, readKey.source, kCFRunLoopCommonModes);
    return true;
}

void broadcast::stopReadKey()
{
    if (readKey.source) {
        CFRunLoopRef runloop = (CFRunLoopRef)CFRunLoopGetCurrent();
        CFRunLoopRemoveSource(runloop, readKey.source, kCFRunLoopCommonModes);
        CFRelease(readKey.source);
        CFMachPortInvalidate(readKey.tap);
        CFRelease(readKey.tap);
        readKey = { nullptr, nullptr, nullptr };
    }
}

std::string broadcast::keyToString(int64_t key)
{
    switch (key) {
    case kVK_ANSI_A:
        return "A";
    case kVK_ANSI_S:
        return "S";
    case kVK_ANSI_D:
        return "D";
    case kVK_ANSI_F:
        return "F";
    case kVK_ANSI_H:
        return "H";
    case kVK_ANSI_G:
        return "G";
    case kVK_ANSI_Z:
        return "Z";
    case kVK_ANSI_X:
        return "X";
    case kVK_ANSI_C:
        return "C";
    case kVK_ANSI_V:
        return "V";
    case kVK_ANSI_B:
        return "B";
    case kVK_ANSI_Q:
        return "Q";
    case kVK_ANSI_W:
        return "W";
    case kVK_ANSI_E:
        return "E";
    case kVK_ANSI_R:
        return "R";
    case kVK_ANSI_Y:
        return "Y";
    case kVK_ANSI_T:
        return "T";
    case kVK_ANSI_1:
        return "1";
    case kVK_ANSI_2:
        return "2";
    case kVK_ANSI_3:
        return "3";
    case kVK_ANSI_4:
        return "4";
    case kVK_ANSI_6:
        return "6";
    case kVK_ANSI_5:
        return "5";
    case kVK_ANSI_Equal:
        return "Equal";
    case kVK_ANSI_9:
        return "9";
    case kVK_ANSI_7:
        return "7";
    case kVK_ANSI_Minus:
        return "Minus";
    case kVK_ANSI_8:
        return "8";
    case kVK_ANSI_0:
        return "0";
    case kVK_ANSI_RightBracket:
        return "RightBracket";
    case kVK_ANSI_O:
        return "O";
    case kVK_ANSI_U:
        return "U";
    case kVK_ANSI_LeftBracket:
        return "LeftBracket";
    case kVK_ANSI_I:
        return "I";
    case kVK_ANSI_P:
        return "P";
    case kVK_ANSI_L:
        return "L";
    case kVK_ANSI_J:
        return "J";
    case kVK_ANSI_Quote:
        return "Quote";
    case kVK_ANSI_K:
        return "K";
    case kVK_ANSI_Semicolon:
        return "Semicolon";
    case kVK_ANSI_Backslash:
        return "Backslash";
    case kVK_ANSI_Comma:
        return "Comma";
    case kVK_ANSI_Slash:
        return "Slash";
    case kVK_ANSI_N:
        return "N";
    case kVK_ANSI_M:
        return "M";
    case kVK_ANSI_Period:
        return "Period";
    case kVK_ANSI_Grave:
        return "Grave";
    case kVK_ANSI_KeypadDecimal:
        return "KeypadDecimal";
    case kVK_ANSI_KeypadMultiply:
        return "KeypadMultiply";
    case kVK_ANSI_KeypadPlus:
        return "KeypadPlus";
    case kVK_ANSI_KeypadClear:
        return "KeypadClear";
    case kVK_ANSI_KeypadDivide:
        return "KeypadDivide";
    case kVK_ANSI_KeypadEnter:
        return "KeypadEnter";
    case kVK_ANSI_KeypadMinus:
        return "KeypadMinus";
    case kVK_ANSI_KeypadEquals:
        return "KeypadEquals";
    case kVK_ANSI_Keypad0:
        return "Keypad0";
    case kVK_ANSI_Keypad1:
        return "Keypad1";
    case kVK_ANSI_Keypad2:
        return "Keypad2";
    case kVK_ANSI_Keypad3:
        return "Keypad3";
    case kVK_ANSI_Keypad4:
        return "Keypad4";
    case kVK_ANSI_Keypad5:
        return "Keypad5";
    case kVK_ANSI_Keypad6:
        return "Keypad6";
    case kVK_ANSI_Keypad7:
        return "Keypad7";
    case kVK_ANSI_Keypad8:
        return "Keypad8";
    case kVK_ANSI_Keypad9:
        return "Keypad9";
    case kVK_Return:
        return "Return";
    case kVK_Tab:
        return "Tab";
    case kVK_Space:
        return "Space";
    case kVK_Delete:
        return "Delete";
    case kVK_Escape:
        return "Escape";
    case kVK_Command:
        return "Command";
    case kVK_Shift:
        return "Shift";
    case kVK_CapsLock:
        return "CapsLock";
    case kVK_Option:
        return "Option";
    case kVK_Control:
        return "Control";
    case kVK_RightShift:
        return "RightShift";
    case kVK_RightOption:
        return "RightOption";
    case kVK_RightControl:
        return "RightControl";
    case kVK_Function:
        return "Function";
    case kVK_F17:
        return "F17";
    case kVK_VolumeUp:
        return "VolumeUp";
    case kVK_VolumeDown:
        return "VolumeDown";
    case kVK_Mute:
        return "Mute";
    case kVK_F18:
        return "F18";
    case kVK_F19:
        return "F19";
    case kVK_F20:
        return "F20";
    case kVK_F5:
        return "F5";
    case kVK_F6:
        return "F6";
    case kVK_F7:
        return "F7";
    case kVK_F3:
        return "F3";
    case kVK_F8:
        return "F8";
    case kVK_F9:
        return "F9";
    case kVK_F11:
        return "F11";
    case kVK_F13:
        return "F13";
    case kVK_F16:
        return "F16";
    case kVK_F14:
        return "F14";
    case kVK_F10:
        return "F10";
    case kVK_F12:
        return "F12";
    case kVK_F15:
        return "F15";
    case kVK_Help:
        return "Help";
    case kVK_Home:
        return "Home";
    case kVK_PageUp:
        return "PageUp";
    case kVK_ForwardDelete:
        return "ForwardDelete";
    case kVK_F4:
        return "F4";
    case kVK_End:
        return "End";
    case kVK_F2:
        return "F2";
    case kVK_PageDown:
        return "PageDown";
    case kVK_F1:
        return "F1";
    case kVK_LeftArrow:
        return "LeftArrow";
    case kVK_RightArrow:
        return "RightArrow";
    case kVK_DownArrow:
        return "DownArrow";
    case kVK_UpArrow:
        return "UpArrow";
    }
    return "Unknown";
}

std::string broadcast::maskToString(uint64_t mask)
{
    std::string m;
    if (mask & kCGEventFlagMaskAlphaShift)
        m = "AlphaShift";
    if (mask & kCGEventFlagMaskShift) {
        if (!m.empty())
            m += "+";
        m += "Shift";
    }
    if (mask & kCGEventFlagMaskControl) {
        if (!m.empty())
            m += "+";
        m += "Control";
    }
    if (mask & kCGEventFlagMaskAlternate) {
        if (!m.empty())
            m += "+";
        m += "Alt";
    }
    if (mask & kCGEventFlagMaskCommand) {
        if (!m.empty())
            m += "+";
        m += "Command";
    }
    if (mask & kCGEventFlagMaskHelp) {
        if (!m.empty())
            m += "+";
        m += "Help";
    }
    if (mask & kCGEventFlagMaskSecondaryFn) {
        if (!m.empty())
            m += "+";
        m += "Option";
    }
    if (mask & kCGEventFlagMaskNumericPad) {
        if (!m.empty())
            m += "+";
        m += "NumericPad";
    }
    // if (mask & kCGEventFlagMaskNonCoalesced) {
    //     if (!m.empty())
    //         m += "+";
    //     m += "NonCoalesced";
    // }
    return m;
}

void broadcast::cleanup()
{
    if (logfile) {
        fclose(logfile);
        logfile = 0;
    }
}

broadcast::Accessible broadcast::checkAllowsAccessibility()
{
    if (AXIsProcessTrustedWithOptions != NULL) {
        // 10.9 and later
        NSDictionary *options = @{(id)kAXTrustedCheckOptionPrompt : @YES};
        if (AXIsProcessTrustedWithOptions((CFDictionaryRef)options))
            return Allowed;
        else
            return Denied;
    }
    return Unknown;
}
