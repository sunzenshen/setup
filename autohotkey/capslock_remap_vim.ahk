; Search 'Alan' for edits
; Suffice to say, anyone reading this can use this freely.
; You don't have to credit Alan, but be cool and credit the rest of these sources (Danik, Gustavo, et al) if you republish these settings.

; Original Capslock Remapping Script Danik danikgames.com (article now offline)
; 
; Functionality:
; - Deactivates capslock for normal (accidental) use.
; - Hold Capslock and drag anywhere in a window to move it (not just the title bar).
; - Access the following functions when pressing Capslock: 
;     - Default behavior: Capslock + <key> sends Ctrl + <key>
;     - Overrides for specific keys to match keyd's ctrl_vim layer:
;         Cursor keys           - H, J, K, L (Vim-style)
;         PgDn, PgUp            - D, U
;         Backspace and Del     - N, M
;         Move Word             - , (Ctrl+Left), . (Ctrl+Right)
;         Close Window          - E (Alt+F4)
;         Close Tab             - W (Ctrl+F4)
;         Next/Previous Tab     - Tab (Ctrl+PgUp), Q (Ctrl+PgDn)
;         Esc                   - Capslock (tap)
;         Win Key               - Space
;         Enter Key             - ;
;         Virtual Desktops      - [ (Ctrl+Win+Left), ] (Ctrl+Win+Right), ' (Ctrl+Win+Down)
;         Alacritty Mode        - / (Ctrl+Shift+Space)
;  
; To use capslock as you normally would, you can press WinKey + Capslock


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
; Changes: The only change was using Capslock instead of Alt. This 
; also removes problems in certain applications.


#Persistent
SetCapsLockState, AlwaysOff

; Alan's Mods:
; CapsLock pressed alone is an esc press
CapsLock::Send {Blind}{esc}

; Default behavior: Capslock + <key> sends Ctrl + <key>
; This catches all keys not explicitly defined below.
; Ensure this is before specific remappings.
#If GetKeyState("CapsLock", "P")
*::
    ; Exclude specific keys that have dedicated Capslock hotkeys below
    ; Or keys that are part of the Capslock combo itself (like Space, ;, etc.)
    If (A_ThisHotkey contains "Capslock & " AND A_ThisHotkey not contains "Capslock & Space"
        AND A_ThisHotkey not contains "Capslock & `;" AND A_ThisHotkey not contains "Capslock & LButton")
    {
        ; Extract the key name (e.g., "a" from "Capslock & a")
        Key := SubStr(A_ThisHotkey, InStr(A_ThisHotkey, "& ") + 2)
        ; Send Ctrl + that key. {Blind} prevents interference with other hotkeys.
        Send {Blind}{Ctrl Down}%Key%{Ctrl Up}
    }
Return
#If ; Turn off #If for subsequent code blocks

; Media Keys (Retained existing)
Capslock & Up::Send {Volume_Up 1}
Capslock & Down::Send {Volume_Down 1}
Capslock & Right::Send {Media_Next}
Capslock & Left::Send {Media_Prev}

; Make Capslock+Space -> WIN Key
Capslock & Space::Send {Blind}{LWIN DownTemp}
Capslock & Space up::Send {Blind}{LWIN Up}

; Make Capslock+; -> Enter Key
Capslock & `;::Send {Blind}{Enter DownTemp}
Capslock & `; up::Send {Blind}{Enter Up}



; Interesting links that Alan is referencing from:
;https://www.maketecheasier.com/favorite-autohotkey-scripts/
; explanation for {Blind} https://autohotkey.com/docs/commands/Send.htm#blind
; What is the Windows key called? (LWin) https://www.autohotkey.com/docs/KeyList.htm#modifier
; How to send WIN + ?  https://superuser.com/questions/402244/how-to-simulate-wind-in-autohotkey



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


; Capslock + / (Alacritty Terminal Mode: Ctrl+Shift+Space) - Retained existing override
Capslock & /::SendInput {Ctrl Down}{Shift Down}{Space Down}
Capslock & / up::SendInput {Ctrl Up}{Shift Up}{Space Up}

; Capslock + [ and ] (Virtual Desktops: Ctrl+Win+Left/Right)
Capslock & [::Send {Blind}{Ctrl Down}{LWIN Down}{Left Down}
Capslock & [ up::Send {Blind}{Ctrl Up}{LWIN Up}{Left Up}

Capslock & ]::Send {Blind}{Ctrl Down}{LWIN Down}{Right Down}
Capslock & ] up::Send {Blind}{Ctrl Up}{LWIN Up}{Right Up}

; Capslock + \ (Show All Desktops/Task View: Win+Tab)
Capslock & \::Send {Blind}{LWIN Down}{Tab Down}
Capslock & \ up::Send {Blind}{LWIN Up}{Tab Up}

; Capslock + ' (Virtual Desktop: Ctrl+Win+Down)
Capslock & '::SendInput {Ctrl Down}{LWIN Down}{Down Down}
Capslock & ' up::SendInput {Ctrl Up}{LWIN Up}{Down Up}


; Make Capslock & Alt Equivalent to Control+Alt
!Capslock::SendInput {Ctrl down}{Alt Down}
!Capslock up::SendInput {Ctrl up}{Alt up}


; Drag windows anywhere
;
; This script modified from the original: http://www.autohotkey.com/docs/scripts/EasyWindowDrag.htm
; by The How-To Geek
; http://www.howtogeek.com 

Capslock & LButton::
CoordMode, Mouse  ; Switch to screen/absolute coordinates.
MouseGetPos, EWD_MouseStartX, EWD_MouseStartY, EWD_MouseWin
WinGetPos, EWD_OriginalPosX, EWD_OriginalPosY,,, ahk_id %EWD_MouseWin%
WinGet, EWD_WinState, MinMax, ahk_id %EWD_MouseWin% 
if EWD_WinState = 0  ; Only if the window isn't maximized 
    SetTimer, EWD_WatchMouse, 10 ; Track the mouse as the user drags it.
return

EWD_WatchMouse:
GetKeyState, EWD_LButtonState, LButton, P
if EWD_LButtonState = U  ; Button has been released, so drag is complete.
{
    SetTimer, EWD_WatchMouse, off
    return
}
GetKeyState, EWD_EscapeState, Escape, P
if EWD_EscapeState = D  ; Escape has been pressed, so drag is cancelled.
{
    SetTimer, EWD_WatchMouse, off
    WinMove, ahk_id %EWD_MouseWin%,, %EWD_OriginalPosX%, %EWD_OriginalPosY%
    return
}
; Otherwise, reposition the window to match the change in mouse coordinates
; caused by the user having dragged the mouse:
CoordMode, Mouse
MouseGetPos, EWD_MouseX, EWD_MouseY
WinGetPos, EWD_WinX, EWD_WinY,,, ahk_id %EWD_MouseWin%
SetWinDelay, -1   ; Makes the below move faster/smoother.
WinMove, ahk_id %EWD_MouseWin%,, EWD_WinX + EWD_MouseX - EWD_MouseStartX, EWD_WinY + EWD_MouseY - EWD_MouseStartY
EWD_MouseStartX := EWD_MouseX  ; Update for the next timer-call to this subroutine.
EWD_MouseStartY := EWD_MouseY
return

; don't really use back/front on mouse that much
XButton1::RButton
XButton2::MButton