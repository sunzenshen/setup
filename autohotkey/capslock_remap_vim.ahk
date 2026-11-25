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
; - Capslock + Alt + H/J/K/L sends Win+Left/Down/Up/Right. Capslock + Alt + F sends F11.
; - Plain Alt shortcuts pass through for zellij in Alacritty.
; - Mouse buttons are not remapped here: MarbleScroll (github.com/sunzenshen/MarbleScroll) makes the
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


#Persistent
SetCapsLockState, AlwaysOff
; Never leave Win held down by Caps+Alt tiling if the script exits or reloads.
OnExit("ReleaseTilingWin")

; Alan's Mods:
; CapsLock pressed alone is an esc press
CapsLock::Send {Blind}{esc}

; Capslock + Alt + hjkl (Windows Tiling) and f (Fullscreen)
; Win stays held while Capslock+Alt are held, so hjkl can be tapped repeatedly like
; holding Win and tapping arrows. Releasing Win after every press would open Snap Assist,
; which swallows the next press. Win is released when Capslock or Alt is let go.
; vk07 masks the Alt/Win releases so they don't open the app menu or Start menu.
#If GetKeyState("CapsLock", "P") && GetKeyState("Alt", "P")
Capslock & h::TileWindow("Left")
Capslock & j::TileWindow("Down")
Capslock & k::TileWindow("Up")
Capslock & l::TileWindow("Right")
Capslock & f::
    ReleaseTilingWin()
    SendInput {Blind}{vk07}{Alt Up}{F11}
return
#If

TileWindow(direction) {
    global tilingWinHeld
    ; Check the real Win state too, in case another binding already lifted it.
    if (!tilingWinHeld || !GetKeyState("LWin")) {
        tilingWinHeld := true
        SendInput {Blind}{vk07}{Alt Up}{LWin Down}
        SetTimer, CheckTilingChord, 10
    }
    SendInput {Blind}{%direction%}
}

; Fallback for letting go of Capslock; releasing Alt is handled right away below.
CheckTilingChord() {
    if !(GetKeyState("CapsLock", "P") && GetKeyState("Alt", "P"))
        ReleaseTilingWin()
}

ReleaseTilingWin() {
    global tilingWinHeld
    SetTimer, CheckTilingChord, Off
    if (tilingWinHeld) {
        tilingWinHeld := false
        if !GetKeyState("LWin", "P")
            SendInput {Blind}{vk07}{LWin Up}
    }
}

; ~ lets Alt through untouched (zellij keeps working); this only ends a tiling chord.
~LAlt up::ReleaseTilingWin()
~RAlt up::ReleaseTilingWin()
    SetTimer, ReleaseTilingWin, Off
    SendInput {Blind}{vk07}{LWin Up}
    tilingWinHeld := false
return


; --- Default behavior: Capslock + <key> sends Ctrl + <key> (Explicitly mapped) ---
; This section manually maps common keys to Ctrl+Key when Capslock is held.
; This replaces the previous generic #If block for better stability.

#If GetKeyState("CapsLock", "P")
; Letters (a-z), excluding those with specific Capslock overrides below
Capslock & a::Send ^a
Capslock & b::Send ^b
Capslock & c::Send ^c
Capslock & f::Send ^f
Capslock & g::Send ^g
; h, j, k, l are overridden below for Vim navigation
; d, u are overridden below for PgDn/PgUp
; e, w, q is for system functions
Capslock & p::Send ^p
Capslock & r::Send ^r
Capslock & s::Send ^s
Capslock & t::Send ^t
Capslock & v::Send ^v
Capslock & x::Send ^x
Capslock & y::Send ^y
Capslock & z::Send ^z
Capslock & i::Send ^i
Capslock & o::Send ^o
; n, m are for Backspace/Delete

; Numbers (0-9) - Capslock+Number sends Win+Number
Capslock & 0::Send #0
Capslock & 1::Send #1
Capslock & 2::Send #2
Capslock & 3::Send #3
Capslock & 4::Send #4
Capslock & 5::Send #5
Capslock & 6::Send #6
Capslock & 7::Send #7
Capslock & 8::Send #8
Capslock & 9::Send #9

; Other common symbols
Capslock & -::Send ^-
Capslock & =::Send ^=
Capslock & SC029::Send ^{SC029} ; Backtick
; comma, period, brackets, slash, apostrophe are overridden below

; Editing and function keys
Capslock & Backspace::Send ^{Backspace}
Capslock & Delete::Send ^{Delete}
Capslock & Insert::Send ^{Insert}
Capslock & Home::Send ^{Home}
Capslock & End::Send ^{End}
Capslock & Enter::Send ^{Enter}
Capslock & F1::Send ^{F1}
Capslock & F2::Send ^{F2}
Capslock & F3::Send ^{F3}
Capslock & F4::Send ^{F4}
Capslock & F5::Send ^{F5}
Capslock & F6::Send ^{F6}
Capslock & F7::Send ^{F7}
Capslock & F8::Send ^{F8}
Capslock & F9::Send ^{F9}
Capslock & F10::Send ^{F10}
Capslock & F11::Send ^{F11}
Capslock & F12::Send ^{F12}
#If ; Turn off #If for subsequent code blocks


; Media Keys
Capslock & Up::Send {Volume_Up 1}
Capslock & Down::Send {Volume_Down 1}
Capslock & Right::Send {Media_Next}
Capslock & Left::Send {Media_Prev}

; Make Capslock+Space -> Ctrl+Space
Capslock & Space::Send {Blind}{LCtrl DownTemp}{Space DownTemp}
Capslock & Space up::Send {Blind}{LCtrl Up}{Space Up}

; Make Capslock+; -> Enter Key
Capslock & `;::Send {Blind}{Enter DownTemp}
Capslock & `; up::Send {Blind}{Enter Up}


; Interesting links that Alan is referencing from:
;https://www.maketecheasier.com/favorite-autohotkey-scripts/
; explanation for {Blind} https://autohotkey.com/docs/commands/Send.htm#blind
; What is the Windows key called? (LWin) https://www.autohotkey.com/docs/KeyList.htm#modifier
; How to send WIN + ?  https://superuser.com/questions/402244/how-to-simulate-wind-in-autohotkey


; --- Specific Capslock Overrides (Matching keyd ctrl_vim) ---

; Capslock + hjkl (left, down, up, right)
Capslock & h::Send {Blind}{Left DownTemp}
Capslock & h up::Send {Blind}{Left Up}

Capslock & j::Send {Blind}{Down DownTemp}
Capslock & j up::Send {Blind}{Down Up}

Capslock & k::Send {Blind}{Up DownTemp}
Capslock & k up::Send {Blind}{Up Up}

Capslock & l::Send {Blind}{Right DownTemp}
Capslock & l up::Send {Blind}{Right Up}


; Capslock + d, u (PgDn, PgUp)
Capslock & d::SendInput {Blind}{PgDn Down}
Capslock & d up::SendInput {Blind}{PgDn Up}

Capslock & u::SendInput {Blind}{PgUp Down}
Capslock & u up::SendInput {Blind}{PgUp Up}


; Capslock + n, m (backspace, del)
Capslock & n::SendInput {Blind}{BS Down}
Capslock & n up::SendInput {Blind}{BS Up}
Capslock & m::SendInput {Blind}{Del Down}
Capslock & m up::SendInput {Blind}{Del Up}


; Capslock + ,. (Move Word: Ctrl+Left/Right)
Capslock & ,::SendInput {Blind}{Ctrl Down}{Left Down}
Capslock & , up::SendInput {Blind}{Ctrl Up}{Left Up}

Capslock & .::SendInput {Blind}{Ctrl Down}{Right Down}
Capslock & . up::SendInput {Blind}{Ctrl Up}{Right Up}


; Capslock + e (Close Window Alt+F4)
Capslock & e::SendInput {Alt down}{F4}{Alt up}

; Capslock + w (Close Tab Ctrl+F4)
Capslock & w::SendInput {Ctrl down}{F4}{Ctrl up}


; Capslock + Tab (Next Tab Ctrl+PgUp)
Capslock & Tab::SendInput {Ctrl Down}{PgUp Down}
Capslock & Tab up::SendInput {Ctrl Up}{PgUp Up}

; Capslock + q (Previous Tab Ctrl+PgDn)
Capslock & q::SendInput {Ctrl Down}{PgDn Down}
Capslock & q up::SendInput {Ctrl Up}{PgDn Up}


; Capslock + / (Alacritty Terminal Mode: Ctrl+Shift+Space)
Capslock & /::SendInput {Ctrl Down}{Shift Down}{Space Down}
Capslock & / up::SendInput {Ctrl Up}{Shift Up}{Space Up}

; Capslock + [ and ] (Virtual Desktops: Ctrl+Win+Left/Right)
Capslock & [::Send {Blind}{Ctrl Down}{LWIN Down}{Left Down}
Capslock & [ up::Send {Blind}{Ctrl Up}{LWIN Up}{Left Up}

Capslock & ]::Send {Blind}{Ctrl Down}{LWIN Down}{Right Down}
Capslock & ] up::Send {Blind}{Ctrl Up}{LWIN Up}{Right Up}

; Capslock + ' (Task View: Win+Tab)
Capslock & '::Send {Blind}{LWIN Down}{Tab Down}
Capslock & ' up::Send {Blind}{LWIN Up}{Tab Up}
