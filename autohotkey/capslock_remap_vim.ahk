; Search 'Alan' for edits
; Suffice to say, anyone reading this can use this freely.
; You don't have to credit Alan, but be cool and credit the rest of these sources (Danik, Gustavo, et al) if you republish these settings.

; Capslock Remapping Script 
; Danik
; danikgames.com
; 
; Functionality:
; - Deactivates capslock for normal (accidental) use.
; - Hold Capslock and drag anywhere in a window to move it (not just the title bar).
; - Access the following functions when pressing Capslock: 
;     Cursor keys           - H, J, K, L (Vim-style)
;     Home, PgDn, PgUp, End - Y, U, I, O (above HJKL)
;     Backspace and Del     - N, M
;     Insert                - B
;     Select all            - A
;     Cut, copy, paste      - S, D, F
;     Close tab, window     - W, E
;     Esc                   - R
;     Next, previous tab    - Tab, Q
;     Undo, redo            - , and .
;  
; To use capslock as you normally would, you can press WinKey + Capslock


; This script is mostly assembled from modified versions of the following awesome scripts:
;
; # Home Row Computing by Gustavo Duarte: http://duartes.org/gustavo/blog/post/home-row-computing for 
; Changes: 
; - Does not need register remapping of AppsKey using SharpKeys.
; - Uses Vim style navigation keys (standard and works better
;   across different language layouts)
; - PgUp, PgDn, Home, End also changed to be symmetrical with Vim layout
; - Added more hotkeys for insert, undo, redo etc.
;
; # Get the Linux Alt+Window Drag Functionality in Windows: http://www.howtogeek.com/howto/windows-vista/get-the-linux-altwindow-drag-functionality-in-windows/
; Changes: The only change was using Capslock instead of Alt. This 
; also removes problems in certain applications.


#Persistent
SetCapsLockState, AlwaysOff

; Alan's Mods:

; Space pressed alone is a space press and is shift if held
; https://stackoverflow.com/questions/39225521/autohotkey-script-to-send-space-when-tapped-and-shift-when-held-it-is-affecting#39226212
#InputLevel, 10  ;set send level for the following code to 10
$Space::
#InputLevel  ;set it back to default value of 0 for any remaining code
now := A_TickCount
while GetKeyState("Space", "P") ; to find out whether space-bar is held 
    if (A_TickCount-now > 180) ; this time is tested on asker's computer
    {
        SendInput {Shift Down}
        KeyWait, Space
        SendInput {Shift Up}
        return
    }
SendInput {Space} ; if key detected to be tapped, send space as per normal   
return

; CapsLock pressed alone is an esc press
CapsLock::Send {Blind}{esc}

Capslock & Up::Send {Volume_Up 1}
Capslock & Down::Send {Volume_Down 1}
Capslock & Right::Send {Media_Next}
Capslock & Left::Send {Media_Prev}

; Make Capslock+; -> Enter Key
Capslock & `;::Send {Blind}{Enter DownTemp}
Capslock & `; up::Send {Blind}{Enter Up}

; control + t -> new tab
Capslock & t::SendInput {Ctrl Down}{t Down}
Capslock & t up::SendInput {Ctrl Up}{t Up}

; Quick launching of common apps using Ctrl+Alt+letter - Alan edit
; File Explorer
^!k::Send #e

; Interesting links that Alan is referencing from:
;https://www.maketecheasier.com/favorite-autohotkey-scripts/
; explanation for {Blind} https://autohotkey.com/docs/commands/Send.htm#blind
; What is the Windows key called? (LWin) https://www.autohotkey.com/docs/KeyList.htm#modifier
; How to send WIN + ?  https://superuser.com/questions/402244/how-to-simulate-wind-in-autohotkey



; Capslock + hjkl (left, down, up, right)

Capslock & h::Send {Blind}{Left DownTemp}
Capslock & h up::Send {Blind}{Left Up}

Capslock & j::Send {Blind}{Down DownTemp}
Capslock & j up::Send {Blind}{Down Up}

Capslock & k::Send {Blind}{Up DownTemp}
Capslock & k up::Send {Blind}{Up Up}

Capslock & l::Send {Blind}{Right DownTemp}
Capslock & l up::Send {Blind}{Right Up}


; Capslock + yuio (pgdown, pgup, home, end)

Capslock & u::SendInput {Blind}{PgDn Down}
Capslock & u up::SendInput {Blind}{PgDn Up}

Capslock & i::SendInput {Blind}{PgUp Down}
Capslock & i up::SendInput {Blind}{PgUp Up}

Capslock & o::SendInput {Blind}{End Down}
Capslock & o up::SendInput {Blind}{End Up}

Capslock & y::SendInput {Blind}{Home Down}
Capslock & y up::SendInput {Blind}{Home Up}


Capslock & a::SendInput {Ctrl Down}{a Down}
Capslock & a up::SendInput {Ctrl Up}{a Up}

; differ from danik's script and use normal keys for copy/paste

Capslock & s::SendInput {Ctrl Down}{s Down}
Capslock & s up::SendInput {Ctrl Up}{s Up}

Capslock & d::SendInput {Ctrl Down}{d Down}
Capslock & d up::SendInput {Ctrl Up}{d Up}

Capslock & f::SendInput {Ctrl Down}{f Down}
Capslock & f up::SendInput {Ctrl Up}{f Up}

Capslock & z::SendInput {Ctrl Down}{ z Down}
Capslock & z up::SendInput {Ctrl Up}{z Up}

Capslock & x::SendInput {Ctrl Down}{ x Down}
Capslock & x up::SendInput {Ctrl Up}{x Up}

Capslock & c::SendInput {Ctrl Down}{ c Down}
Capslock & c up::SendInput {Ctrl Up}{c Up}

Capslock & v::SendInput {Ctrl Down}{ v Down}
Capslock & v up::SendInput {Ctrl Up}{v Up}


; Capslock + wer (close tab or window)

Capslock & w::SendInput {Ctrl down}{F4}{Ctrl up}
Capslock & e::SendInput {Alt down}{F4}{Alt up}


; Capslock + nm (insert, backspace, del)

Capslock & b::SendInput {Blind}{Insert Down}
Capslock & m::SendInput {Blind}{Del Down}
Capslock & n::SendInput {Blind}{BS Down}
Capslock & BS::SendInput {Blind}{BS Down}


; Make Capslock & Enter equivalent to Control+Enter
Capslock & Enter::SendInput {Ctrl down}{Enter}{Ctrl up}


; Make Capslock & Alt Equivalent to Control+Alt
!Capslock::SendInput {Ctrl down}{Alt Down}
!Capslock up::SendInput {Ctrl up}{Alt up}


; Capslock + TAB/q (prev/next tab)

Capslock & q::SendInput {Ctrl Down}{Tab Down}
Capslock & q up::SendInput {Ctrl Up}{Tab Up}
Capslock & Tab::SendInput {Ctrl Down}{Shift Down}{Tab Down}
Capslock & Tab up::SendInput {Ctrl Up}{Shift Up}{Tab Up}

; Capslock + ,/. (undo/redo)

Capslock & ,::SendInput {Ctrl Down}{z Down}
Capslock & , up::SendInput {Ctrl Up}{z Up}
Capslock & .::SendInput {Ctrl Down}{y Down}
Capslock & . up::SendInput {Ctrl Up}{y Up}

; Capslock + everything else

Capslock & 1::SendInput {Ctrl Down}{ 1 Down}
Capslock & 1 up::SendInput {Ctrl Up}{1 Up}

Capslock & 2::SendInput {Ctrl Down}{ 2 Down}
Capslock & 2 up::SendInput {Ctrl Up}{2 Up}

Capslock & 3::SendInput {Ctrl Down}{ 3 Down}
Capslock & 3 up::SendInput {Ctrl Up}{3 Up}

Capslock & 4::SendInput {Ctrl Down}{ 4 Down}
Capslock & 4 up::SendInput {Ctrl Up}{4 Up}

Capslock & 5::SendInput {Ctrl Down}{ 5 Down}
Capslock & 5 up::SendInput {Ctrl Up}{5 Up}

Capslock & 6::SendInput {Ctrl Down}{ 6 Down}
Capslock & 6 up::SendInput {Ctrl Up}{6 Up}

Capslock & 7::SendInput {Ctrl Down}{ 7 Down}
Capslock & 7 up::SendInput {Ctrl Up}{7 Up}

Capslock & 8::SendInput {Ctrl Down}{ 8 Down}
Capslock & 8 up::SendInput {Ctrl Up}{8 Up}

Capslock & 9::SendInput {Ctrl Down}{ 9 Down}
Capslock & 9 up::SendInput {Ctrl Up}{9 Up}

Capslock & 0::SendInput {Ctrl Down}{ 0 Down}
Capslock & 0 up::SendInput {Ctrl Up}{0 Up}

Capslock & -::SendInput {Ctrl Down}{ - Down}
Capslock & - up::SendInput {Ctrl Up}{- Up}

Capslock & +::SendInput {Ctrl Down}{ + Down}
Capslock & + up::SendInput {Ctrl Up}{+ Up}

Capslock & r::SendInput {Ctrl Down}{ r Down}
Capslock & r up::SendInput {Ctrl Up}{r Up}

Capslock & g::SendInput {Ctrl Down}{ g Down}
Capslock & g up::SendInput {Ctrl Up}{g Up}

Capslock & p::SendInput {Ctrl Down}{ p Down}
Capslock & p up::SendInput {Ctrl Up}{p Up}

; Make Win Key + Capslock work like Capslock
; Alan: right now this is conflicting with cap+space=win
;#Capslock::
;If GetKeyState("CapsLock", "T") = 1
;    SetCapsLockState, AlwaysOff
;Else 
;    SetCapsLockState, AlwaysOn
;Return

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