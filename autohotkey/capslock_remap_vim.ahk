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
;     Cursor keys           - H, J, K, L (Vim-style)
;     Home, End             - , and . (modified from original)
;     PgDn, PgUp            - D, F (modified from original)
;     Backspace and Del     - N, M
;     Select All            - (Removed to make way for Tab Nav)
;     Cut, copy, paste      - (Cut/Copy remain, Paste removed to make way for Word Select)
;     Close tab, window     - W, Q (Q is now Close Window)
;     Esc                   - R
;     Next, previous tab    - S, A (modified from original)
;     Undo, redo            - (Removed to make way for Home/End)
;     Tiling                - Y, U, I, O (New)
;     Virtual Desktops      - [, ] (New)
;     Task View             - \ (New)
;     Task Manager          - T (New)
;     Alacritty Mode        - / (New)
;     Fullscreen            - ' (New)
;     Word Navigation       - B, E, V (New/Modified)
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


; Capslock + y, u, i, o (Windows Tiling: Win+Left, Win+Down, Win+Up, Win+Right) - Modified from original PgDn, PgUp, Home, End
Capslock & y::Send {Blind}{LWIN Down}{Left Down}
Capslock & y up::Send {Blind}{LWIN Up}{Left Up}

Capslock & u::Send {Blind}{LWIN Down}{Down Down}
Capslock & u up::Send {Blind}{LWIN Up}{Down Up}

Capslock & i::Send {Blind}{LWIN Down}{Up Down}
Capslock & i up::Send {Blind}{LWIN Up}{Up Up}

Capslock & o::Send {Blind}{LWIN Down}{Right Down}
Capslock & o up::Send {Blind}{LWIN Up}{Right Up}


; Capslock + d, f (PgDn, PgUp) - Modified from original Ctrl+d, Ctrl+f
Capslock & d::SendInput {Blind}{PgDn Down}
Capslock & d up::SendInput {Blind}{PgDn Up}

Capslock & f::SendInput {Blind}{PgUp Down}
Capslock & f up::SendInput {Blind}{PgUp Up}

; Capslock + a, s (Ctrl+PgUp, Ctrl+PgDn for Tab Navigation) - Modified from original Ctrl+a, Ctrl+s
Capslock & a::SendInput {Ctrl Down}{PgUp Down}
Capslock & a up::SendInput {Ctrl Up}{PgUp Up}

Capslock & s::SendInput {Ctrl Down}{PgDn Down}
Capslock & s up::SendInput {Ctrl Up}{PgDn Up}

; Capslock + c (Copy) - Retained Ctrl+c
Capslock & c::SendInput {Ctrl Down}{c Down}
Capslock & c up::SendInput {Ctrl Up}{c Up}

; Capslock + x (Cut) - Retained Ctrl+x
Capslock & x::SendInput {Ctrl Down}{x Down}
Capslock & x up::SendInput {Ctrl Up}{x Up}

; Capslock + w (Close Tab Ctrl+F4)
Capslock & w::SendInput {Ctrl down}{F4}{Ctrl up}

; Capslock + q (Close Window Alt+F4) - Modified from original Ctrl+Tab
Capslock & q::SendInput {Alt down}{F4}{Alt up}


; Capslock + n, m (backspace, del) - Retained original behavior
Capslock & n::SendInput {Blind}{BS Down}
Capslock & n up::SendInput {Blind}{BS Up} ; Ensure release for BS too
Capslock & m::SendInput {Blind}{Del Down}
Capslock & m up::SendInput {Blind}{Del Up} ; Ensure release for Del too


; Capslock & BS::SendInput {Blind}{BS Down} ; This line is redundant if using Capslock & n for BS


; Make Capslock & Enter equivalent to Control+Enter - Retained original behavior
Capslock & Enter::SendInput {Ctrl down}{Enter}{Ctrl up}


; Make Capslock & Alt Equivalent to Control+Alt - Retained original behavior
!Capslock::SendInput {Ctrl down}{Alt Down}
!Capslock up::SendInput {Ctrl up}{Alt up}


; Capslock + Tab (Previous Tab Ctrl+Shift+Tab) - Removed to make way for Ctrl+PgUp/Dn on a/s
; Capslock & Tab::SendInput {Ctrl Down}{Shift Down}{Tab Down}
; Capslock & Tab up::SendInput {Ctrl Up}{Shift Up}{Tab Up}


; Capslock + ,/. (Home/End) - Modified from original undo/redo
Capslock & ,::SendInput {Blind}{Home Down}
Capslock & , up::SendInput {Blind}{Home Up}

Capslock & .::SendInput {Blind}{End Down}
Capslock & . up::SendInput {Blind}{End Up}


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


; New Mappings to match keyd configuration behaviors

; Capslock + [ and ] (Virtual Desktops: Ctrl+Win+Left/Right)
Capslock & [::Send {Blind}{Ctrl Down}{LWIN Down}{Left Down}
Capslock & [ up::Send {Blind}{Ctrl Up}{LWIN Up}{Left Up}

Capslock & ]::Send {Blind}{Ctrl Down}{LWIN Down}{Right Down}
Capslock & ] up::Send {Blind}{Ctrl Up}{LWIN Up}{Right Up}

; Capslock + \ (Show All Desktops/Task View: Win+Tab)
Capslock & \::Send {Blind}{LWIN Down}{Tab Down}
Capslock & \ up::Send {Blind}{LWIN Up}{Tab Up}

; Capslock + / (Alacritty Terminal Mode: Ctrl+Shift+Space)
Capslock & /::SendInput {Ctrl Down}{Shift Down}{Space Down}
Capslock & / up::SendInput {Ctrl Up}{Shift Up}{Space Up}

; Capslock + ' (Fullscreen: F11)
Capslock & '::SendInput {F11 Down}
Capslock & ' up::SendInput {F11 Up}

; Capslock + b (Backward Word: Ctrl+Left) - Modified from original Insert
Capslock & b::SendInput {Ctrl Down}{Left Down}
Capslock & b up::SendInput {Ctrl Up}{Left Up}

; Capslock + e (Select Backwards Word: Ctrl+Shift+Left) - Modified from original Close Window
Capslock & e::SendInput {Ctrl Down}{Shift Down}{Left Down}
Capslock & e up::SendInput {Ctrl Up}{Shift Up}{Left Up}

; Capslock + v (Select Backwards Word: Ctrl+Shift+Left) - Modified from original Paste
Capslock & v::SendInput {Ctrl Down}{Shift Down}{Left Down}
Capslock & v up::SendInput {Ctrl Up}{Shift Up}{Left Up}


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

; don't really use back/front on mouse that much
XButton1::RButton
XButton2::MButton