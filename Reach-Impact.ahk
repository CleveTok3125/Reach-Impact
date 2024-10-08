#NoEnv
#KeyHistory 0
#SingleInstance force
SendMode Input
#WinActivateForce
SetBatchLines -1
#MaxThreadsPerHotkey 1

SearchImage(imageFile) {
    CoordMode, Screen

    ImageSearch, foundX, foundY, FX, FY, ScreenWidth, ScreenHeight, *32 %imageFile%
    
    if (ErrorLevel = 0) {
        check := 1
        return check, foundX, foundY
    } else {
        check := 0
    }
    return
}

Loose_SearchImage(imageFile, opts := 75) {
    CoordMode, Screen

    ImageSearch, foundX, foundY, FX, FY, ScreenWidth, ScreenHeight, *%opts% *Trans %imageFile% ; Because some details are shaded, often details related to special filters or transparency. Changing *n ( `*75` ) and finding the right value should help.
    
    if (ErrorLevel = 0) {
        check := 1
        return check, foundX, foundY
    } else {
        check := 0
    }
    return
}

ClickImage(imageFile, opts := "", isclick := "1", bitdeep := 75) {
    i := 0
    MouseGetPos, OutputVarX, OutputVarY
    while 1 {
        tempImageFile := imageFile . i . ".png"

        if (FileExist(tempImageFile)) {
            if (opts = "L") {
                Loose_SearchImage(tempImageFile, bitdeep)
            } else {
                SearchImage(tempImageFile)
            }

            if (check) {
                ;MsgBox % tempImageFile
                Click, %foundX%, %foundY%
                Sleep 100
                MouseMove, OutputVarX, OutputVarY
                break
            } else {
                i += 1
            }
        } else {
            if (isclick = "1") {
                Click
            }
            Sleep 100
            break
        }
        Sleep 100
    }
    return
}

Led() {
    if !GetKeyState("CapsLock", "T") {
        SetCapsLockState 1
    } else {
        SetCapsLockState 0
    }
    if !GetKeyState("NumLock", "T") {
        SetNumLockState 1
    } else {
        SetNumLockState 0
    }
    Sleep 200
}

global foundX := 0
global foundY := 0
global FX, FY
global default_i
global check := 0
global ScreenWidth, ScreenHeight
global MouseSpeed, orgMouseSpeed, adjustMouseSpeed

#IfWinActive ahk_exe GenshinImpact.exe

; =========================
/*
These are the search coordinates. With the default value, the search will start from 0x0 to ScreenWidthxScreenHeight (find the entire screen). These values can be adjusted for better performance.
EG: 1920x1080 screen

    SysGet, ScreenWidth, 78 ; Search to 1920
    SysGet, ScreenHeight, 79 ; Search to 1080
    FX := 0 ; Search from 0
    FY := 0 ; Search from 0

Due to the inconsistency of CoordMode, for each hotkey that does not use coordinates returned from functions such as SearchImage, Loose_SearchImage, ClickImage it is necessary to add the line `CoordMode, Mouse, Screen` to ensure accuracy.
*/
WinGetPos, FX, FY, ScreenWidth, ScreenHeight, ahk_exe GenshinImpact.exe
ScreenWidth := ScreenWidth + FX
ScreenHeight := ScreenHeight + FY
; =========================

; =========================
/*
Let's say that when talking to an NPC and having 4 dialogue options,
"0.png" will be the snapshot to search for and select the first dialogue choice,
"1.png" will be the snapshot to search for and select the second dialogue option,
"2.png" will be the screenshot to search for and select the third dialogue option,
"3.png" will be the screenshot to search for and select the fourth dialogue option,
and so on.
The first dialogue selection will be the last selection (the one closest to the text box).
The variable `default_i` is a variable to determine which dialogue option should be selected first. If that option is not available, the next options will be found. For example, `default_i := 1` will always look for the second dialogue choice first.
To learn how to generate image data, please visit `https://www.autohotkey.com/docs/v2/lib/ImageSearch.htm#Remarks`
*/
default_i := 0
; =========================

; =========================
; MouseSpeed simply means the speed of the mouse cursor when controlled with the arrow keys (almost like Mouse Keys). The higher the value, the lower the accuracy.
; The hotkeys in the mV section will use these values.
MouseSpeed := (ScreenWidth+ScreenHeight-FX-FY)//100
orgMouseSpeed := MouseSpeed
adjustMouseSpeed := MouseSpeed//2
; =========================

; mI
~home:: ; Press `home` to enable/disable the script
    Suspend -1
    if A_IsSuspended {
        Loop 4 {
            Led()
        }
    } else {
        Loop 2 {
            Led()
        }
    }
    return

~+home:: ; Reload scripts
    Loop 6 {
        Led()
    }
    Reload
    return
    
; mII
~]:: ; Press `]` to start skip mode in the quest, (should hold down) `[` to stop
    i := default_i
    while 1 {
        if GetKeyState("[") & 1 {
            break
        }
        try {
            Sleep 1000
            SearchImage(".\data\chat\" . i . ".png")
            if (check) {
                Sleep 3000
                Click, %foundX%, %foundY%
            } else {
                i := i + 1
            }
        } catch {
            i := default_i
            Send {space}
        }
    }
    return

; mIII
~backspace::
    ClickImage(".\data\cancel\")
    return
~enter::
    ClickImage(".\data\confirm\")
    return
~+enter:: ; Shift + Enter - "Click anywhere to close"
    CoordMode, Mouse, Screen
    X := ScreenWidth - 1
    Y := FY + 1
    Click, %X%, %Y%, 1
    return
~-::
    ClickImage(".\data\neg\")
    return
~+-:: ; Shift + - ; In the drag and drop bar to select the quantity
    ClickImage(".\data\drag\", "L", 0)
    if (check) {
        Click, %foundX%, %foundY%, Left, , Down
        Sleep 50
        Loop 2 {
            MouseMove, -ScreenWidth/2, 0, , R
            Sleep 2
        }
        Click, , , Left, , Up
        MouseMove, foundX, foundY
    }
    return
~=:: ; +
    ClickImage(".\data\pos\")
    return
~+=:: ; Shift + = ; In the drag and drop bar to select the quantity
    ClickImage(".\data\drag\", "L", 0)
    if (check) {
        Click, %foundX%, %foundY%, Left, , Down
        Sleep 50
        Loop 2 {
            MouseMove, ScreenWidth/2, 0, , R
            Sleep 2
        }
        Click, , , Left, , Up
        MouseMove, foundX, foundY
    }
    return

; mIV
~PgUP::
    Send {WheelUp}
    return
~PgDn::
    Send {WheelDown}
    return
~H & T::
    Send {WheelUp}
    return
~H & G::
    Send {WheelDown}
    return
~\::esc ; remap the esc key because most hotkeys are on the right
    return
~RAlt::LAlt
    return
~End::
    Send {MButton}
    return
~`::
    Send {MButton}
    return
~n::
    Loop {
        Send {w down}
        if GetKeyState("TAB") & 1 {
            break
        }
        Sleep 50
    }
    Send {w up}
    Return
~H & F::
    while GetKeyState("f", "P") & 1 {
        if GetKeyState("TAB") & 1 {
            break
        }
        Random, rand, 20, 30
        Sleep %rand%
        Send {f 3}
        Random, rand, 20, 30
        Sleep %rand%
        Send {WheelDown 1}
        Random, rand, 20, 30
        Sleep %rand%
    }
    Return

; mV
~+RCtrl:: ; Shift + RCtrl to switch to drag and drop mode, Double Press to Click (not recommend)
    if GetKeyState("LButton", "P") {
        Click, , , Left, Up
    } else {    
        Click, , , Left, Down    
    }
    return
~!RCtrl::RButton
/*
    Click, , , Right, Down
    Sleep 50
    Click, , , Right, Up
*/
    return
~RCtrl::LButton
/*
    Click, , , Left, Down
    Sleep 50
    Click, , , Left, Up
*/
    return
~+Up:: ; Move cursor to center of screen
    MouseMove, (ScreenWidth-FX)/2-1, (ScreenHeight-FY)/2-1
    return
~+Down::
    MouseSpeed := orgMouseSpeed
    return
~+Right::
    MouseSpeed := MouseSpeed + adjustMouseSpeed
    return
~+Left::
    MouseSpeed := MouseSpeed - adjustMouseSpeed
    return
~Right & Up::
    MouseMove, %MouseSpeed%, -%MouseSpeed%, , R
    return
~Up & Right::
    MouseMove, %MouseSpeed%, -%MouseSpeed%, , R
    return
~Left & Up::
    MouseMove, -%MouseSpeed%, -%MouseSpeed%, , R
    return
~Up & Left::
    MouseMove, -%MouseSpeed%, -%MouseSpeed%, , R
    return
~Down & Right::
    MouseMove, %MouseSpeed%, %MouseSpeed%, , R
    return
~Right & Down::
    MouseMove, %MouseSpeed%, %MouseSpeed%, , R
    return
~Left & Down::
    MouseMove, -%MouseSpeed%, %MouseSpeed%, , R
    return
~Down & Left::
    MouseMove, -%MouseSpeed%, %MouseSpeed%, , R
    return
~*Up::
    MouseMove, 0, -%MouseSpeed%, , R
    return
~*Down::
    MouseMove, 0, %MouseSpeed%, , R
    return
~*Left::
    MouseMove, -%MouseSpeed%, 0, , R
    return
~*Right::
    MouseMove, %MouseSpeed%, 0, , R
    return

; mVI
; There may be some NPCs whose interactive dialogue options are out of order compared to the order in ahk. This depends on the image data you create. Below is just sample code.

~+`:: ; Shift + ` - Click on any visible dialogue option
    i := default_i
    while 1 {
        tempImageFile := ".\data\chat\" . i . ".png"
        if (FileExist(tempImageFile)) {
            SearchImage(tempImageFile)
            if (check) {
                Click, %foundX%, %foundY%
                Sleep 100
                break
            } else {
                i += 1
            }
        } else {
            Sleep 100
            break
        }
        Sleep 100
    }
    return

+1:: ; Shift + 1
    SearchImage(".\data\chat\0.png")
    Click, %foundX%, %foundY%
    return

+2:: ; Shift + 2
    SearchImage(".\data\chat\1.png")
    Click, %foundX%, %foundY%
    return

+3:: ; Shift + 3
    SearchImage(".\data\chat\2.png")
    Click, %foundX%, %foundY%
    return

+4:: ; Shift + 4
    SearchImage(".\data\chat\3.png")
    Click, %foundX%, %foundY%
    return