//
//  HotKeyParser.swift
//  PassHUD
//  Source: https://github.com/marshallbrekka/AutoWin/blob/master/AutoWin/Util/AWKeyCodes.swift

import Foundation
import Carbon
import Cocoa

let modifiersToKeyCodes: NSDictionary = [
    "cmd"  : cmdKey,
    "ctrl" : controlKey,
    "opt"  : optionKey,
    "shift": shiftKey
]

let charsToKeyCodes :NSDictionary = [
    "a":kVK_ANSI_A,
    "b":kVK_ANSI_B,
    "c":kVK_ANSI_C,
    "d":kVK_ANSI_D,
    "e":kVK_ANSI_E,
    "f":kVK_ANSI_F,
    "g":kVK_ANSI_G,
    "h":kVK_ANSI_H,
    "i":kVK_ANSI_I,
    "j":kVK_ANSI_J,
    "k":kVK_ANSI_K,
    "l":kVK_ANSI_L,
    "m":kVK_ANSI_M,
    "n":kVK_ANSI_N,
    "o":kVK_ANSI_O,
    "p":kVK_ANSI_P,
    "q":kVK_ANSI_Q,
    "r":kVK_ANSI_R,
    "s":kVK_ANSI_S,
    "t":kVK_ANSI_T,
    "u":kVK_ANSI_U,
    "v":kVK_ANSI_V,
    "w":kVK_ANSI_W,
    "x":kVK_ANSI_X,
    "y":kVK_ANSI_Y,
    "z":kVK_ANSI_Z,
    "0":kVK_ANSI_0,
    "1":kVK_ANSI_1,
    "2":kVK_ANSI_2,
    "3":kVK_ANSI_3,
    "4":kVK_ANSI_4,
    "5":kVK_ANSI_5,
    "6":kVK_ANSI_6,
    "7":kVK_ANSI_7,
    "8":kVK_ANSI_8,
    "9":kVK_ANSI_9,
    "`":kVK_ANSI_Grave,
    "=":kVK_ANSI_Equal,
    "-":kVK_ANSI_Minus,
    "]":kVK_ANSI_RightBracket,
    "[":kVK_ANSI_LeftBracket,
    "\"":kVK_ANSI_Quote,
    ";":kVK_ANSI_Semicolon,
    "\\":kVK_ANSI_Backslash,
    ",":kVK_ANSI_Comma,
    "/":kVK_ANSI_Slash,
    ".":kVK_ANSI_Period,
    "§":kVK_ISO_Section,
    "f1":kVK_F1,
    "f2":kVK_F2,
    "f3":kVK_F3,
    "f4":kVK_F4,
    "f5":kVK_F5,
    "f6":kVK_F6,
    "f7":kVK_F7,
    "f8":kVK_F8,
    "f9":kVK_F9,
    "f10":kVK_F10,
    "f11":kVK_F11,
    "f12":kVK_F12,
    "f13":kVK_F13,
    "f14":kVK_F14,
    "f15":kVK_F15,
    "f16":kVK_F16,
    "f17":kVK_F17,
    "f18":kVK_F18,
    "f19":kVK_F19,
    "f20":kVK_F20,
    "pad.":kVK_ANSI_KeypadDecimal,
    "pad*":kVK_ANSI_KeypadMultiply,
    "pad+":kVK_ANSI_KeypadPlus,
    "pad/":kVK_ANSI_KeypadDivide,
    "pad-":kVK_ANSI_KeypadMinus,
    "pad=":kVK_ANSI_KeypadEquals,
    "pad0":kVK_ANSI_Keypad0,
    "pad1":kVK_ANSI_Keypad1,
    "pad2":kVK_ANSI_Keypad2,
    "pad3":kVK_ANSI_Keypad3,
    "pad4":kVK_ANSI_Keypad4,
    "pad5":kVK_ANSI_Keypad5,
    "pad6":kVK_ANSI_Keypad6,
    "pad7":kVK_ANSI_Keypad7,
    "pad8":kVK_ANSI_Keypad8,
    "pad9":kVK_ANSI_Keypad9,
    "padclear":kVK_ANSI_KeypadClear,
    "padenter":kVK_ANSI_KeypadEnter,
    "return":kVK_Return,
    "tab":kVK_Tab,
    "space":kVK_Space,
    "delete":kVK_Delete,
    "escape":kVK_Escape,
    "help":kVK_Help,
    "home":kVK_Home,
    "pageup":kVK_PageUp,
    "forwarddelete":kVK_ForwardDelete,
    "end":kVK_End,
    "pagedown":kVK_PageDown,
    "left":kVK_LeftArrow,
    "right":kVK_RightArrow,
    "down":kVK_DownArrow,
    "up":kVK_UpArrow
]

class HotKeyParser {
    class func charToKeyCode(_ char: String) -> UInt32 {
        return charsToKeyCodes.object(forKey: char) as! UInt32
    }

    class func modifiersToModCode(_ modifiers: [String]) -> UInt32 {
        var code: UInt32 = 0
        for mod in modifiers {
            let modCode = modifiersToKeyCodes.object(forKey: mod) as! UInt32
            code |= modCode
        }

        return code
    }
}
