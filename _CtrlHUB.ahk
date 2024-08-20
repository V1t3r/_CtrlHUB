#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance Force
#Include, %A_ScriptDir%\Socket.ahk
#Include %A_ScriptDir%\PowerPlan.ahk
/*===============================================================================
Changelog
r1. 
Initial setup - everything is hardcoded. base logic fully working
Supports change of powerplans and FanContol software.
Added Prismatik support(maybe put this in lib)
Added block of annoying hotkeys
===============================================================================
*/
;GlobalSwitches
GSPower := 1
GSFan := 1
GSDebug := 1
GSKeyRemap :=1

;Hotkeys variables
IstMainHotkey := "#!h"

;Powerplan lib init
arrPowerPlanNames := DopowerPlan()
;Variables


;Hotkeys setup
Hotkey, %IstMainHotkey%, ActivityMainHotkey

; dummy impossible hotkey for proper work)))
#!^+ScrollLock::
MsgBox WTF HOW DID YOU PRESSED THESE SCHITT?!
return


AppsKey::RWin
^AppsKey::AppsKey

Browser_Search:: ;blocks annoying key
return

Launch_App2::
return

; Tray submenus
Menu, DebugSubMenu, Standard

;tray menu
Menu, Tray, Tip, CtrlHUB. r.1
Menu, Tray, Add, CtrlHUB. r.1, DasTitle

if (GSPower = 1)
{
Menu, Tray, Add, 
Menu, Tray, Add, Energy Save mode, DasPlanPowerSave
Menu, Tray, Add, Balanced mode, DasPlanBalance
Menu, Tray, Add, Max Performance mode, DasPlanMaxPerform
}
else
	{}
	
if (GSFan = 1)
{
Menu, Tray, Add,
Menu, Tray, Add, Silent Fans mode, DasPropellerSilent
Menu, Tray, Add, Minimal Fans speed, DasPropellerMinimal
Menu, Tray, Add, Auto Control Fans, DasPropellerAuto
}
else
	{}
	
Menu, Tray, Add,

if (GSPower = 0) and (GSDebug = 0)
	{
	Menu, Tray, Add, You Disabled Everything!, DasSettings
	Menu, Tray, Add, Click here to open, DasSettings
	}

Menu, Tray, Add, Settings, DasSettings

if (GSDebug = 1) 
	{
	Menu, Tray, Add, Debug Menu, :DebugSubMenu
	}
else
	{}

Menu, Tray, NoStandard	
Menu, Tray, Add, Exit, DasExit
Menu, Tray, Disable, CtrlHUB. r.1
Menu, Tray, Default, CtrlHUB. r.1
Menu, Tray, Check, Energy Save mode
Menu, Tray, Check, Minimal Fans speed
Menu, Tray, Click, 2

;Hotkeys procedures
ActivityMainHotkey:
Menu, Tray, Show
return

;Tray menu procedures
DasTitle: ; This shit should be never enabled
	Menu, Tray, Show
return

DasSettings: ; Settings :|
MsgBox Under construction!
return

DasExit: ;exit
	ExitApp
return

DasPlanPowerSave: ; powersaving mode
	DopowerPlan(arrPowerPlanNames[4])
	Menu, Tray, Check, Energy Save mode
	Menu, Tray, Uncheck, Balanced mode
	Menu, Tray, Uncheck, Max Performance mode
return

DasPlanBalance: ; balanced power mode
	DopowerPlan(arrPowerPlanNames[3])
	Menu, Tray, Uncheck, Energy Save mode
	Menu, Tray, Check, Balanced mode
	Menu, Tray, Uncheck, Max Performance mode
return

DasPlanMaxPerform: ; Max performance mode
	DopowerPlan(arrPowerPlanNames[5])
	Menu, Tray, Uncheck, Energy Save mode
	Menu, Tray, Uncheck, Balanced mode
	Menu, Tray, Check, Max Performance mode
return

DasPropellerSilent: ; Silent Fans
	Run, C:\Software\FanControl\FanControl.exe -c Silent.json -m
	Menu, Tray, Check, Silent Fans mode
	Menu, Tray, Uncheck, Minimal Fans speed
	Menu, Tray, Uncheck, Auto Control Fans
return

DasPropellerMinimal: ; Fans minimal speed
	Run, C:\Software\FanControl\FanControl.exe -c Minimal.json -m
	Menu, Tray, Uncheck, Silent Fans mode
	Menu, Tray, Check, Minimal Fans speed
	Menu, Tray, Uncheck, Auto Control Fans
return

DasPropellerAuto: ; Fans controlled by Motherboard
	Run, C:\Software\FanControl\FanControl.exe -c Motherboard.json -m
	Menu, Tray, Uncheck, Silent Fans mode
	Menu, Tray, Uncheck, Minimal Fans speed
	Menu, Tray, Check, Auto Control Fans
return

DasPropellerFuckEars: ; Fans fullspeed mode
	MsgBox АААА! ТРАХАТЬ УШИ!!!
return




;Prismatik Control "library" made by Unknown warrior - dunno who made that but I will find

; in Prismatik
; go to Profiles, check "Expert mode"
; go to Experimental, check "enable server"
; uncheck "listen only on local interface" if you want to control it from other computers
; leave Key empty

; Prismatik machine's IP
global PRISMATIK_IP:="127.0.0.1"
; port from Experimental tab
global PRISMATIK_PORT:=3636

global LOG_DEBUG:=False

LogToFile(action, msg)
{
	if LOG_DEBUG
		FileAppend, % action . " : " . RTrim(msg, " `r`n") . "`n", .\prismatik.log
}
SendCmd(tcp, action, cmd)
{
	LogToFile(action, cmd)
	tcp.sendText(cmd)
	resp:=RTrim(tcp.recvText(), " `r`n")
	LogToFile(action, resp)
	Return resp
}

SendLockedCmd(action, ucmd, param, persist)
{
	myTcp := new SocketTCP()
	if (myTcp.connect(PRISMATIK_IP, PRISMATIK_PORT) = 0)
	{
		Msg:="Failed to connect to " . PRISMATIK_IP . ":" . PRISMATIK_PORT
		LogToFile(action, Msg)
		MsgBox, % Msg
		Return
	}
	LogToFile(action, myTcp.recvText())

	Cmd:="lock`n"
	SendCmd(myTcp, action, Cmd)

	if (persist = 0)
	{
		Cmd:="setpersistonunlock:off`n"
		SendCmd(myTcp, action, Cmd)
	}

	if (param)
		Cmd:="" . ucmd . ":" . param . "`n"
	else
		Cmd:=ucmd . "`n"

	if (SendCmd(myTcp, action, Cmd) = "error")
		MsgBox, % "Could not execute " . ucmd . ":" . param . " to " . action . ". Edit prismatik.ahk."

	Cmd:="unlock`n"
	SendCmd(myTcp, action, Cmd)

	Cmd:="exit`n"
	SendCmd(myTcp, action, Cmd)

	myTcp.disconnect()

	Return
}

SwitchProfile(ProfileName)
{
	SendLockedCmd("switch profile", "setprofile", ProfileName, 0)

	Return
}

SwitchMode(ModeName)
{
	SendLockedCmd("switch mode", "setmode", ModeName, 1)

	Return
}

SwitchStatus(Status)
{
	SendLockedCmd("switch status", "setstatus", Status, 1)

	Return
}

SetColors(Colors)
{
	myTcp := new SocketTCP()
	if (myTcp.connect(PRISMATIK_IP, PRISMATIK_PORT) = 0)
	{
		Msg:="Failed to connect to " . PRISMATIK_IP . ":" . PRISMATIK_PORT
		LogToFile("static color", Msg)
		MsgBox, % Msg
		Return
	}
	LogToFile("static color", myTcp.recvText())

	Cmd:="getcountleds`n"
	Result:=SendCmd(myTcp, "static color", Cmd)
	LedCount:=SubStr(Result, InStr(Result, ":") + 1)
	LedCount+=0
	if (LedCount < 1)
	{
		MsgBox, "found zero LEDs"
		Return
	}

	Cmd:="lock`n"
	SendCmd(myTcp, "static color", Cmd)

	Cmd:="newprofile:autohotkey`n"
	SendCmd(myTcp, "static color", Cmd)

	Cmd:="setpersistonunlock:on`n"
	SendCmd(myTcp, "static color", Cmd)

	Cmd:="setstatus:on`n"
	SendCmd(myTcp, "static color", Cmd)

	LedColors  := ""
	LedsPerColor:=Ceil(LedCount / Colors.MaxIndex())
	for colorIndex, color in Colors
	{
		Loop % LedsPerColor
		{
			LedIndex:= A_Index + (colorIndex - 1) * LedsPerColor
			if (LedIndex <= LedCount)
				LedColors  := LedColors  . Format("{:i}-{};" , LedIndex, color)
		}
	}

	Cmd:="setcolor:" . LedColors . "`n"
	SendCmd(myTcp, "static color", Cmd)

	Cmd:="unlock`n"
	SendCmd(myTcp, "static color", Cmd)

	Cmd:="exit`n"
	SendCmd(myTcp, "static color", Cmd)

	myTcp.disconnect()

	Return
}
/* Explanation how this shit works
; For keys
; see https://www.autohotkey.com/docs/Hotkeys.htm
; and https://www.autohotkey.com/docs/KeyList.htm

; Set static colors
; Ctrl+1
^1::
; Add any number of colors to the list (don't go over your led count)
; the led strip will be split in equal-ish parts with respctive colors
Colors:=["255,0,0","0,255,0","0,0,255"]
SetColors(Colors)
Return


; set a predefined profile
; Ctrl+2
^2::
; change "Lightpack" to desired profile name
SwitchProfile("Lightpack")
Return

; Ctrl+Alt+3
^!3::
SwitchProfile("virtual")
Return

^!4::
SwitchMode("ambilight")
Return

^!5::
SwitchMode("moodlamp")
Return

^!6::
SwitchStatus("on")
Return

^!7::
SwitchStatus("off")
Return
*/
