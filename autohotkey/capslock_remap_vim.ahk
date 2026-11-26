; Search 'Alan' for edits
; Suffice to say, anyone reading this can use this freely.
; You don't have to credit Alan, but be cool and credit the rest of these sources (Danik, Gustavo, et al) if you republish these settings.

; Original Capslock Remapping Script Danik danikgames.com (article now offline)
;
; Functionality:
; - Deactivates capslock for normal (accidental) use.
; - Access the following functions when pressing Capslock:
;     - Default behavior: Capslock + mapped letters, minus, equals, backtick,
;         Backspace, Delete, Insert, Home, End, Enter, and F1-F12 sends Ctrl + that key.
;     - Overrides for specific keys:
;         Cursor keys           - H, J, K, L (Vim-style)
;         PgDn, PgUp            - D, U
;         Backspace and Del     - N, M
;         Move Word             - , (Ctrl+Left), . (Ctrl+Right)
;         Close Window          - E (Alt+F4)
;         Close Tab             - W (Ctrl+F4)
;         Next/Previous Tab     - Tab (Ctrl+PgUp), Q (Ctrl+PgDn)
;         Esc                   - Capslock (tap)
;         Ctrl + Space          - Space
;         Enter Key             - ;
;         Virtual Desktops      - [ (Ctrl+Win+Left), ] (Ctrl+Win+Right)
;         Alacritty Mode        - / (Ctrl+Shift+Space)
;         Task View             - ' (Win+Tab)
;         Pinned apps           - 0-9 (Win+Number)
;         Media keys            - Up/Down (volume), Left/Right (previous/next track)
; - Capslock + Alt + H/J/K/L: left/right halves (H/L); repeat moves to the next monitor.
;   K maximizes, J restores/minimizes. Capslock + Alt + F sends F11.
; - Plain Alt shortcuts pass through for zellij in Alacritty.
; - Mouse buttons are not remapped here: MarbleScroll (github.com/sunzenshen/CursedMarbleScroll) makes the
;     side buttons act as middle (click = middle click, hold + move = scroll), matching Linux.


; This script is mostly assembled from modified versions of the following awesome scripts:
;
; # Home Row Computing by Gustavo Duarte: http://duartes.org/gustavo/blog/post/home-row-computing for
; Changes:
; - Does not need register remapping of AppsKey using SharpKeys.
; - Uses Vim style navigation keys (standard and works better
;   across different language layouts)
; - PgUp, PgDn, Home, End also changed to be symmetrical with Vim layout
; - Added more hotkeys for insert, undo, redo etc.
;
; # Get the Linux Alt+Window Drag Functionality in Windows: http://www.howtogeek.com/howto/windows-vista/get-the-linux-altwindow-drag-functionality-in-windows/


#Requires AutoHotkey v2.0
Persistent
SetCapsLockState "AlwaysOff"
; Hover the tray icon to confirm which revision is loaded (bump when behavior changes).
A_IconTip := "capslock_remap_vim (2026-11-25: AHK v2, direct window tiling)"

; Alan's Mods:
; CapsLock pressed alone is an esc press
CapsLock::Send "{Blind}{esc}"

; Capslock + Alt + hjkl (Windows Tiling) and f (Fullscreen)
; Move windows directly to avoid Snap Assist; repeat left/right to cross monitors.
; vk07 masks the Alt release so it does not open the app menu.
#HotIf GetKeyState("CapsLock", "P") && GetKeyState("Alt", "P")
Capslock & h::TileWindow("Left")
Capslock & j::TileWindow("Down")
Capslock & k::TileWindow("Up")
Capslock & l::TileWindow("Right")
Capslock & f::{
    SendInput "{Blind}{vk07}"
    SendInput "{F11}"
}
#HotIf

TileWindow(direction) {
    SendInput "{Blind}{vk07}"
    hwnd := WinExist("A")
    if !hwnd || WinGetClass(hwnd) ~= "^(Progman|WorkerW|Shell_TrayWnd|Shell_SecondaryTrayWnd)$"
        return
    state := WinGetMinMax(hwnd)
    if direction = "Up" {
        WinMaximize hwnd
        return
    }
    if direction = "Down" {
        if state = 1
            WinRestore hwnd
        else
            WinMinimize hwnd
        return
    }
    if state != 0
        WinRestore hwnd
    frame := WindowFrame(hwnd)
    area := WindowMonitor(frame.x + frame.w / 2, frame.y + frame.h / 2)
    half := Floor((area.r - area.l) / 2)
    targetX := direction = "Left" ? area.l : area.l + half
    targetW := direction = "Left" ? half : area.r - targetX
    ; Compare visible frames, allowing for borders and application size rounding.
    if Abs(frame.x - targetX) <= 16 && Abs(frame.y - area.t) <= 16
        && Abs(frame.w - targetW) <= 16 && Abs(frame.h - (area.b - area.t)) <= 16 {
        if MonitorGetCount() = 1
            return
        area := AdjacentMonitor(area, direction)
        half := Floor((area.r - area.l) / 2)
        targetX := direction = "Left" ? area.l + half : area.l
        targetW := direction = "Left" ? area.r - targetX : half
    }
    WinMove targetX - frame.left, area.t - frame.top,
        targetW + frame.left + frame.right, area.b - area.t + frame.top + frame.bottom, hwnd
}

; Retain invisible resize borders while aligning the visible DWM frame.
WindowFrame(hwnd) {
    WinGetPos &x, &y, &w, &h, hwnd
    frame := {x: x, y: y, w: w, h: h, left: 0, top: 0, right: 0, bottom: 0}
    rect := Buffer(16)
    try {
        if DllCall("dwmapi\DwmGetWindowAttribute", "Ptr", hwnd, "UInt", 9, "Ptr", rect, "UInt", 16) = 0 {
            l := NumGet(rect, 0, "Int"), t := NumGet(rect, 4, "Int")
            r := NumGet(rect, 8, "Int"), b := NumGet(rect, 12, "Int")
            frame := {x: l, y: t, w: r - l, h: b - t,
                left: l - x, top: t - y, right: x + w - r, bottom: y + h - b}
        }
    }
    return frame
}

MonitorArea(index) {
    MonitorGetWorkArea index, &l, &t, &r, &b
    return {index: index, l: l, t: t, r: r, b: b}
}

; Use the containing work area, or the nearest one if the center is in a gap.
WindowMonitor(x, y) {
    nearest := MonitorArea(1)
    distance := 1.0e30
    Loop MonitorGetCount() {
        area := MonitorArea(A_Index)
        if x >= area.l && x < area.r && y >= area.t && y < area.b
            return area
        gap := Max(area.l - x, 0, x - area.r) ** 2 + Max(area.t - y, 0, y - area.b) ** 2
        if gap < distance {
            nearest := area
            distance := gap
        }
    }
    return nearest
}

; Choose the nearest edge in the requested direction, wrapping at the extremes.
AdjacentMonitor(current, direction) {
    best := 0
    distance := 1.0e30
    wrap := current
    Loop MonitorGetCount() {
        area := MonitorArea(A_Index)
        if area.index = current.index
            continue
        if direction = "Left" ? area.r > wrap.r : area.l < wrap.l
            wrap := area
        gap := direction = "Left" ? current.l - area.r : area.l - current.r
        if gap >= -16 && gap < distance {
            best := area
            distance := gap
        }
    }
    return best ? best : wrap
}


; --- Default behavior: Capslock + <key> sends Ctrl + <key> (Explicitly mapped) ---
; This section manually maps common keys to Ctrl+Key when Capslock is held.
; This replaces the previous generic #If block for better stability.

#HotIf GetKeyState("CapsLock", "P")
; Letters (a-z), excluding those with specific Capslock overrides below
Capslock & a::Send "^a"
Capslock & b::Send "^b"
Capslock & c::Send "^c"
Capslock & f::Send "^f"
Capslock & g::Send "^g"
; h, j, k, l are overridden below for Vim navigation
; d, u are overridden below for PgDn/PgUp
; e, w, q is for system functions
Capslock & p::Send "^p"
Capslock & r::Send "^r"
Capslock & s::Send "^s"
Capslock & t::Send "^t"
Capslock & v::Send "^v"
Capslock & x::Send "^x"
Capslock & y::Send "^y"
Capslock & z::Send "^z"
Capslock & i::Send "^i"
Capslock & o::Send "^o"
; n, m are for Backspace/Delete

; Numbers (0-9) - Capslock+Number sends Win+Number
Capslock & 0::Send "#0"
Capslock & 1::Send "#1"
Capslock & 2::Send "#2"
Capslock & 3::Send "#3"
Capslock & 4::Send "#4"
Capslock & 5::Send "#5"
Capslock & 6::Send "#6"
Capslock & 7::Send "#7"
Capslock & 8::Send "#8"
Capslock & 9::Send "#9"

; Other common symbols
Capslock & -::Send "^-"
Capslock & =::Send "^="
Capslock & SC029::Send "^{SC029}" ; Backtick
; comma, period, brackets, slash, apostrophe are overridden below

; Editing and function keys
Capslock & Backspace::Send "^{Backspace}"
Capslock & Delete::Send "^{Delete}"
Capslock & Insert::Send "^{Insert}"
Capslock & Home::Send "^{Home}"
Capslock & End::Send "^{End}"
Capslock & Enter::Send "^{Enter}"
Capslock & F1::Send "^{F1}"
Capslock & F2::Send "^{F2}"
Capslock & F3::Send "^{F3}"
Capslock & F4::Send "^{F4}"
Capslock & F5::Send "^{F5}"
Capslock & F6::Send "^{F6}"
Capslock & F7::Send "^{F7}"
Capslock & F8::Send "^{F8}"
Capslock & F9::Send "^{F9}"
Capslock & F10::Send "^{F10}"
Capslock & F11::Send "^{F11}"
Capslock & F12::Send "^{F12}"
#HotIf ; Turn off #If for subsequent code blocks


; Media Keys
Capslock & Up::Send "{Volume_Up 1}"
Capslock & Down::Send "{Volume_Down 1}"
Capslock & Right::Send "{Media_Next}"
Capslock & Left::Send "{Media_Prev}"

; Make Capslock+Space -> Ctrl+Space
Capslock & Space::Send "{Blind}{LCtrl DownTemp}{Space DownTemp}"
Capslock & Space up::Send "{Blind}{LCtrl Up}{Space Up}"

; Make Capslock+; -> Enter Key
Capslock & `;::Send "{Blind}{Enter DownTemp}"
Capslock & `; up::Send "{Blind}{Enter Up}"


; Interesting links that Alan is referencing from:
;https://www.maketecheasier.com/favorite-autohotkey-scripts/
; explanation for {Blind} https://autohotkey.com/docs/commands/Send.htm#blind
; What is the Windows key called? (LWin) https://www.autohotkey.com/docs/KeyList.htm#modifier
; How to send WIN + ?  https://superuser.com/questions/402244/how-to-simulate-wind-in-autohotkey


; --- Specific Capslock Overrides (Matching keyd ctrl_vim) ---

; Capslock + hjkl (left, down, up, right)
Capslock & h::Send "{Blind}{Left DownTemp}"
Capslock & h up::Send "{Blind}{Left Up}"

Capslock & j::Send "{Blind}{Down DownTemp}"
Capslock & j up::Send "{Blind}{Down Up}"

Capslock & k::Send "{Blind}{Up DownTemp}"
Capslock & k up::Send "{Blind}{Up Up}"

Capslock & l::Send "{Blind}{Right DownTemp}"
Capslock & l up::Send "{Blind}{Right Up}"


; Capslock + d, u (PgDn, PgUp)
Capslock & d::SendInput "{Blind}{PgDn Down}"
Capslock & d up::SendInput "{Blind}{PgDn Up}"

Capslock & u::SendInput "{Blind}{PgUp Down}"
Capslock & u up::SendInput "{Blind}{PgUp Up}"


; Capslock + n, m (backspace, del)
Capslock & n::SendInput "{Blind}{BS Down}"
Capslock & n up::SendInput "{Blind}{BS Up}"
Capslock & m::SendInput "{Blind}{Del Down}"
Capslock & m up::SendInput "{Blind}{Del Up}"


; Capslock + ,. (Move Word: Ctrl+Left/Right)
Capslock & ,::SendInput "{Blind}{Ctrl Down}{Left Down}"
Capslock & , up::SendInput "{Blind}{Ctrl Up}{Left Up}"

Capslock & .::SendInput "{Blind}{Ctrl Down}{Right Down}"
Capslock & . up::SendInput "{Blind}{Ctrl Up}{Right Up}"


; Capslock + e (Close Window Alt+F4)
Capslock & e::SendInput "{Alt down}{F4}{Alt up}"

; Capslock + w (Close Tab Ctrl+F4)
Capslock & w::SendInput "{Ctrl down}{F4}{Ctrl up}"


; Capslock + Tab (Next Tab Ctrl+PgUp)
Capslock & Tab::SendInput "{Ctrl Down}{PgUp Down}"
Capslock & Tab up::SendInput "{Ctrl Up}{PgUp Up}"

; Capslock + q (Previous Tab Ctrl+PgDn)
Capslock & q::SendInput "{Ctrl Down}{PgDn Down}"
Capslock & q up::SendInput "{Ctrl Up}{PgDn Up}"


; Capslock + / (Alacritty Terminal Mode: Ctrl+Shift+Space)
Capslock & /::SendInput "{Ctrl Down}{Shift Down}{Space Down}"
Capslock & / up::SendInput "{Ctrl Up}{Shift Up}{Space Up}"

; Capslock + [ and ] (Virtual Desktops: Ctrl+Win+Left/Right)
Capslock & [::Send "{Blind}{Ctrl Down}{LWIN Down}{Left Down}"
Capslock & [ up::Send "{Blind}{Ctrl Up}{LWIN Up}{Left Up}"

Capslock & ]::Send "{Blind}{Ctrl Down}{LWIN Down}{Right Down}"
Capslock & ] up::Send "{Blind}{Ctrl Up}{LWIN Up}{Right Up}"

; Capslock + ' (Task View: Win+Tab)
Capslock & '::Send "{Blind}{LWIN Down}{Tab Down}"
Capslock & ' up::Send "{Blind}{LWIN Up}{Tab Up}"
