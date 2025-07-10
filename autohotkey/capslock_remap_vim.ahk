; Search 'Alan' for edits
; Suffice to say, anyone reading this can use this freely.
; You don't have to credit Alan, but be cool and credit the rest of these sources (Danik, Gustavo, et al) if you republish these settings.

; Original Capslock Remapping Script Danik danikgames.com (article now offline)
; 
; Functionality:
; - Deactivates capslock for normal (accidental) use.
; - Hold Capslock and drag anywhere in a window to move it (not just the title bar).
; - Access the following functions when pressing Capslock: 
;     - Default behavior: Capslock + <key> sends Ctrl + <key> (explicitly mapped for stability)
;     - Overrides for specific keys:
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
;         Task View             - \ (Win+Tab)
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

; Numbers (0-9) - Capslock+Number sends Ctrl+Number
Capslock & 0::Send ^0
Capslock & 1::Send ^1
Capslock & 2::Send ^2
Capslock & 3::Send ^3
Capslock & 4::Send ^4
Capslock & 5::Send ^5
Capslock & 6::Send ^6
Capslock & 7::Send ^7
Capslock & 8::Send ^8
Capslock & 9::Send ^9

; Other common symbols
Capslock & -::Send ^-
Capslock & =::Send ^=
; comma, period, bracket, backslash, slash, apostrophe are overridden below
#If ; Turn off #If for subsequent code blocks


; Media Keys
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

; Capslock + ' (Virtual Desktop: Ctrl+Win+Down)
Capslock & '::SendInput {Ctrl Down}{LWIN Down}{Down Down}
Capslock & ' up::SendInput {Ctrl Up}{LWIN Up}{Down Up}

; Capslock + \ (Task View: Win+Tab)
Capslock & \::Send {Blind}{LWIN Down}{Tab Down}
Capslock & \ up::Send {Blind}{LWIN Up}{Tab Up}


; Make Capslock & Alt Equivalent to Control+Alt
!Capslock::SendInput {Ctrl down}{Alt Down}
!Capslock up::SendInput {Ctrl up}{Alt up}


; --- Alt Keybinds ---

; Alt + hjkl (Windows Tiling: Win+Left, Win+Down, Win+Up, Win+Right)
Alt & h::Send {Blind}{AltUp}{LWIN Down}{Left Down}
Alt & h up::Send {Blind}{AltUp}{LWIN Up}{Left Up}
Alt & j::Send {Blind}{AltUp}{LWIN Down}{Down Down}
Alt & j up::Send {Blind}{AltUp}{LWIN Up}{Down Up}
Alt & k::Send {Blind}{AltUp}{LWIN Down}{Up Down}
Alt & k up::Send {Blind}{AltUp}{LWIN Up}{Up Up}
Alt & l::Send {Blind}{AltUp}{LWIN Down}{Right Down}
Alt & l up::Send {Blind}{AltUp}{LWIN Up}{Right Up}

; Alt + f (Fullscreen: F11)
Alt & f::Send {Blind}{AltUp}{F11 Down}
Alt & f up::Send {Blind}{AltUp}{F11 Up}

; Alt + ' (Task View: Win+Tab)
Alt & '::Send {Blind}{LWIN Down}{Tab Down}
Alt & ' up::Send {Blind}{LWIN Up}{Tab Up}

; Make Alt+; -> Enter Key
Alt & `;::Send {Blind}{Enter DownTemp}
Alt & `; up::Send {Blind}{Enter Up}

; Alt + 1234 (Launch Taskbar Apps: Win+1234)
Alt & 1::Send {Blind}{LWIN Down}{1 Down}
Alt & 1 up::Send {Blind}{LWIN Up}{1 Up}
Alt & 2::Send {Blind}{LWIN Down}{2 Down}
Alt & 2 up::Send {Blind}{LWIN Up}{2 Up}
Alt & 3::Send {Blind}{LWIN Down}{3 Down}
Alt & 3 up::Send {Blind}{LWIN Up}{3 Up}
Alt & 4::Send {Blind}{LWIN Down}{4 Down}
Alt & 4 up::Send {Blind}{LWIN Up}{4 Up}

; Mouse buttons (retained from original base)
XButton1::RButton
XButton2::MButton