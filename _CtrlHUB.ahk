#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance Force
#Include, %A_ScriptDir%\Socket.ahk
#Include %A_ScriptDir%\PowerPlan.ahk
/*===============================================================================
Changelog
Crutch count = 1
r1. 
Initial build - everything is hardcoded. base logic fully working
Supports change of powerplans and FanContol software.
Added Prismatik support(maybe put this in lib)
Added block of annoying hotkeys

r2.
Added ini config file
Added kostyl number 1
need to try 
#if ...
#if 
for hotkey remap

r3. Settings UI Integration
next will be ini build and rewrite of procedures
rewritten powerplans and added ini section of this

r4. FanControl sex
FanControl fuckin complete
Spagetti code powered FC settings and init
Its now saves last states of Power Plans and Fan Control profile !!! Need to set delay timer to wait Fan Control will launch
fixes fixes fixes
===============================================================================
*/
;Variables
configini=%A_ScriptDir%\config.ini

;global PowerplanEnSave, PowerplanBalance, PowerplanMaxPow
;program first run creating ini file
ifnotexist, %configini%
	{
	MsgBox Welcome to CtrlHUB!`n `n Looks like this is a first time`n that you launched this program.`n We need to create some config file.`n Hit OK to start.	
	;ini creation
	;IniWrite, 1, %configini%, Global_Switches, Power
	IniWrite, 1, %configini%, Global_Switches, Fan
	IniWrite, 1, %configini%, Global_Switches, Debug
	IniWrite, 1, %configini%, Global_Switches, KeyRemap
	IniWrite, "#!h", %configini%, Hotkeys, IstIniMainHotkey
	;PowerPlans ini section
	IniWrite, 1, %configini%, PowerPlans, PowerPlansEnabled
	IniWrite, 3, %configini%, PowerPlans, EnergySave
	IniWrite, 1, %configini%, PowerPlans, BalancedMode
	IniWrite, 2, %configini%, PowerPlans, MaximumPower
	IniWrite, 1, %configini%, PowerPlans, LastPlan
	;FanControl ini section
	IniWrite, 0, %configini%, FanControl, FanControlEnabled
	IniWrite, "", %configini%, FanControl, FanControlFolder
	IniWrite, "", %configini%, FanControl, FanControlSilent
	IniWrite, "", %configini%, FanControl, FanControlMinimal
	IniWrite, "", %configini%, FanControl, FanControlAuto
	IniWrite, "", %configini%, FanControl, FanControlFE
	IniWrite, 1, %configini%, FanControl, LastProfile
	
	
	MsgBox Config file created Thanks for patience.`n Now everything works fine.`n You can find CtrlHUB in tray menu or launch via hotkey.
	}
;Reading ini section
IniRead, GSDebug, %configini%, GlobalSwitches, Debug
IniRead, GSKeyRemap, %configini%, GlobalSwitches, KeyRemap
IniRead, IstMainHotkey, %configini%, Hotkeys, IstIniMainHotkey
;Power Plans ini read
IniRead, GSPowerSwitch, %configini%, PowerPlans, PowerPlansEnabled
IniRead, PowerplanEnSave, %configini%, PowerPlans, EnergySave
IniRead, PowerplanBalance, %configini%, PowerPlans, BalancedMode
IniRead, PowerplanMaxPow, %configini%, PowerPlans, MaximumPower
;FanControl ini Read
IniRead, GSFanSwitch, %configini%, FanControl, FanControlEnabled
IniRead, FCFolder, %configini%, FanControl, FanControlFolder
IniRead, FCPSilent, %configini%, FanControl, FanControlSilent
IniRead, FCPMinimal, %configini%, FanControl, FanControlMinimal
IniRead, FCPAuto, %configini%, FanControl, FanControlAuto
IniRead, FCPSilentSTR, %configini%, FanControl, FanControlSilent
IniRead, FCPMinimalSTR, %configini%, FanControl, FanControlMinimal
IniRead, FCPAutoSTR, %configini%, FanControl, FanControlAuto


;Powerplan lib init
arrpp := DopowerPlan()
SetPPList := ""
Loop, % arrpp.MaxIndex()
	SetPPList .=  arrpp[A_Index] "|"
	
;FanContol Precheck sequence
IfExist, %FCFolder%\FanControl.exe
	{
	Gosub, FCPrecheck
	}
else
	{
	}
	
	
	
;Variables
;Hotkeys vars
WinmodforMainhotkey := 0

; Tray submenus
Menu, DebugSubMenu, Standard

Gosub TrayDraw

Gosub InitPP

Process, Wait, FanControl.exe, 30
NewPID := ErrorLevel  ; Save the value immediately since ErrorLevel is often changed.
if not NewPID
{
    MsgBox FanControl wan't launched in 30 seconds - functionality Disabled
	GSFanSwitch = 0
	Menu, Tray, DeleteAll
	Gosub TrayDraw
    return
}
else 
	{
	Gosub InitFC
	}


;Hotkeys setup
Hotkey, %IstMainHotkey%, ActivityMainHotkey



; dummy impossible hotkey for proper work)))
#!^+ScrollLock::
MsgBox WTF HOW DID YOU PRESSED THESE SCHITT?!
return

^AppsKey::
	if (GSKeyRemap = 1)
		Send {AppsKey}
	else
		Send {AppsKey}; костыль 1
return

AppsKey::
	if (GSKeyRemap = 1)
		Send {RWin}
	else
		Send {AppsKey}
return
	

Browser_Search:: ;blocks annoying key
	if (GSKeyRemap = 1)
		{}
	else
		Send {Browser_Search}
return

Launch_App2::
	if (GSKeyRemap = 1)
		{}
	else
		Send {Launch_App2}
return

;Hotkeys procedures
ActivityMainHotkey:
Menu, Tray, Show
return

;Tray menu procedures
DasTitle: ; This shit should be never enabled
	Menu, Tray, Show
return

TrayDraw:
;tray menu
Menu, Tray, Tip, CtrlHUB. r.4
Menu, Tray, Add, CtrlHUB. r.4, DasTitle

if (GSPowerSwitch = 1)
{
Menu, Tray, Add, 
Menu, Tray, Add, Energy Save mode, DasPlanPowerSave
Menu, Tray, Add, Balanced mode, DasPlanBalance
Menu, Tray, Add, Max Performance mode, DasPlanMaxPerform
}
else
	{}
	
if (GSFanSwitch = 1)
{
Menu, Tray, Add,
Menu, Tray, Add, Silent Fans mode, DasPropellerSilent
Menu, Tray, Add, Minimal Fans speed, DasPropellerMinimal
Menu, Tray, Add, Auto Control Fans, DasPropellerAuto
}
else
	{}
	
Menu, Tray, Add,

if (GSPowerSwitch = 0) and (GSFanSwitch = 0)
	{
	Menu, Tray, Add, You Disabled Everything!, DasSettings
	Menu, Tray, Add, Click here to open, DasSettings
	}

Menu, Tray, Add, Settings, DasSettings

if (GSDebug = 1) 
	{

	}
else
	{
	Menu, Tray, NoStandard
	}

Menu, Tray, Add, Debug Menu, :DebugSubMenu
Menu, Tray, Add, Exit, DasExit
Menu, Tray, Disable, CtrlHUB. r.4
Menu, Tray, Default, CtrlHUB. r.4
if (GSPowerSwitch = 1)
	{
	Menu, Tray, Check, Energy Save mode
	}
else
	{}
if (GSFanSwitch = 1)
	{
Menu, Tray, Check, Minimal Fans speed
	}
else
	{}
Menu, Tray, Click, 2
return


InitPP:
IniRead, LastPP, %configini%, PowerPlans, LastPlan
if (LastPP = 1)
	{
	Gosub DasPlanPowerSave
	}
else if (LastPP = 2)
	{
	Gosub DasPlanBalance
	}
else if (LastPP = 3)
	{
	Gosub DasPlanMaxPerform
	}
else 
	{
	MSGBox Its bad idea to change last Power Plan ini file!
	Gosub DasPlanPowerSave
	}
return

InitFC:
IfExist, %FCFolder%\FanControl.exe
	{
	Gosub InitFCStage2
	}
else
	{
	}

return

InitFCStage2:
IniRead, LastFCP, %configini%, FanControl, LastProfile
if (LastFCP = 1)
	{
	Gosub DasPropellerSilent
	}
else if (LastFCP = 2)
	{
	Gosub DasPropellerMinimal
	}
else if (LastFCP = 3)
	{
	Gosub DasPropellerAuto
	}
else if (LastFCP = 4)
	{
	Gosub DasPropellerFuckEars
	}
else 
	{
	MSGBox Its bad idea to change last Fans Profile in ini file!
	Gosub DasPropellerSilent
	}
return


DasSettings: ; Settings
Gosub, FCPrecheck
Gui, SettingsGUI:Add, Tab3, , Power Plans|Fan Control|Hotkeys
Gui, SettingsGUI:Tab, Power Plans ; power plans tab elements begin
GUi, SettingsGUI:Add, Checkbox, vGSPowerSwitch Checked%GSPowerSwitch% x20 y40, Enable Power plans control
Gui, SettingsGUI:Add, DropDownList, Altsubmit vPowerplanEnSave Choose%PowerplanEnSave% x20 y70 w150, %SetPPList%
Gui, SettingsGUI:Add, DropDownList, Altsubmit vPowerplanBalance Choose%PowerplanBalance% x20 y100 w150, %SetPPList%
Gui, SettingsGUI:Add, DropDownList, Altsubmit vPowerplanMaxPow Choose%PowerplanMaxPow% x20 y130 w150, %SetPPList%
Gui, SettingsGUI:Add, Text, x180 y73,Power saving
Gui, SettingsGUI:Add, Text, x180 y103,Balanced 
Gui, SettingsGUI:Add, Text, x180 y133,Max Performance
Gui, SettingsGUI:Add, Button, gPPSaveBtn x185 y160 w80, Save
Gui, SettingsGUI:Tab ; end of power plans tab elements

Gui, SettingsGUI:Tab, Fan Control ; Fan controls begin
GUi, SettingsGUI:Add, Checkbox, vGSFanSwitch Checked%GSFanSwitch% x20 y40, Enable Fans control
Gui, SettingsGUI:Add, Button, gFCListCreate x170 y35 , FanControl folder
Gui, SettingsGUI:Add, DropDownList, vFCPSilent  x20 y70 w150, %arrFCProf%
Gui, SettingsGUI:Add, DropDownList, vFCPMinimal  x20 y100 w150, %arrFCProf%
Gui, SettingsGUI:Add, DropDownList, vFCPAuto x20 y130 w150, %arrFCProf%
GuiControl,SettingsGUI: ChooseString, FCPSilent, %FCPSilentSTR%
GuiControl,SettingsGUI: ChooseString, FCPMinimal, %FCPMinimalSTR%
GuiControl,SettingsGUI: ChooseString, FCPAuto, %FCPAutoSTR%
Gui, SettingsGUI:Add, Text, x180 y73, Silent mode
Gui, SettingsGUI:Add, Text, x180 y103, Minimal speed
Gui, SettingsGUI:Add, Text, x180 y133, Automatic mode
Gui, SettingsGUI:Add, Button, gFCSaveBtn x185 y160 w80, Save
GUi, SettingsGUI:Add, Checkbox, vFCexeDetected Checked%FCexeDetected% x20 y163, ControlFan founded
GuiControl, SettingsGUI:Disable, ControlFan founded
Gui, SettingsGUI:Tab ; end of fan controls

Gui, SettingsGUI:Tab, Hotkeys ;Hotkeys tab controls
Gui, SettingsGUI:Add, Checkbox, vWinmodforMainhotkey Checked%WinmodforMainhotkey% x20 y40, Win
Gui, SettingsGUI:Add, Text, x75 y40, Menu Hotkey
Gui, SettingsGUI:Add, Hotkey, vIstMainHotkey x20 y60, !h
Gui, SettingsGUI:Add, Checkbox, vWinmodforPPhotkey Checked%WinmodforPPhotkey% x20 y90, Win
Gui, SettingsGUI:Add, Text, x75 y90, Power Plans
Gui, SettingsGUI:Add, Hotkey, vIstFCHotkey x20 y110, !w
Gui, SettingsGUI:Add, Checkbox, vWinmodforFChotkey Checked%WinmodforFChotkey% x20 y140, Win
Gui, SettingsGUI:Add, Text, x75 y140, Fans Control
Gui, SettingsGUI:Add, Hotkey, vIstPPHotkey x20 y160, !q
Gui, SettingsGUI:Add, Checkbox, vAigo108dis Checked%vAigo108dis% x160 y35 w100, Hotkeys remap for Aigo 108
Gui, SettingsGUI:Add, Button, gHCSaveBtn x185 y160 w80, Save
Gui, SettingsGUI:Tab ; end of hotkeys controls

Gui, SettingsGUI:Add, Button, gSetBtn x195 y195 w80, Apply
Gui, SettingsGUI:Add, Button, gCanclBtn x105 y195 w80, Cancel
Gui, SettingsGUI:Show
return 

DasExit: ;exit
	ExitApp
return

DasPlanPowerSave: ; powersaving mode
	GuiControlGet, PowerplanEnSave
	DopowerPlan(arrpp[PowerplanEnSave])
	Menu, Tray, Check, Energy Save mode
	Menu, Tray, Uncheck, Balanced mode
	Menu, Tray, Uncheck, Max Performance mode
	IniWrite, 1, %configini%, PowerPlans, LastPlan
return

DasPlanBalance: ; balanced power mode
	GuiControlGet, PowerplanBalance
	DopowerPlan(arrpp[PowerplanBalance])
	Menu, Tray, Uncheck, Energy Save mode
	Menu, Tray, Check, Balanced mode
	Menu, Tray, Uncheck, Max Performance mode
	IniWrite, 2, %configini%, PowerPlans, LastPlan
return

DasPlanMaxPerform: ; Max performance mode
	GuiControlGet, PowerplanMaxPow
	DopowerPlan(arrpp[PowerplanMaxPow])
	Menu, Tray, Uncheck, Energy Save mode
	Menu, Tray, Uncheck, Balanced mode
	Menu, Tray, Check, Max Performance mode
	IniWrite, 3, %configini%, PowerPlans, LastPlan
return

DasPropellerSilent: ; Silent Fans

	Run, %FCFolder%\FanControl.exe -c %FCPSilent% -m
	Menu, Tray, Check, Silent Fans mode
	Menu, Tray, Uncheck, Minimal Fans speed
	Menu, Tray, Uncheck, Auto Control Fans
IniWrite, 1, %configini%, FanControl, LastProfile
return

DasPropellerMinimal: ; Fans minimal speed
	Run, %FCFolder%\FanControl.exe -c %FCPMinimal% -m
	Menu, Tray, Uncheck, Silent Fans mode
	Menu, Tray, Check, Minimal Fans speed
	Menu, Tray, Uncheck, Auto Control Fans
IniWrite, 2, %configini%, FanControl, LastProfile
return

DasPropellerAuto: ; Fans controlled by Motherboard
	Run, %FCFolder%\FanControl.exe -c %FCPAuto% -m
	Menu, Tray, Uncheck, Silent Fans mode
	Menu, Tray, Uncheck, Minimal Fans speed
	Menu, Tray, Check, Auto Control Fans
IniWrite, 3, %configini%, FanControl, LastProfile
return

DasPropellerFuckEars: ; Fans fullspeed mode
	MsgBox АААА! ТРАХАТЬ УШИ!!!
	FCPFuckEars = fuck_ears.json
	;IniWrite, %FCPFuckEars%, %configini%, FanControl, LastProfile
	Run, %FCFolder%\FanControl.exe -c %FCPFuckEars% -m
	sleep 10000
	Gosub DasPropellerMinimal
return

;-----------------------------Settings procedures--------------------------------
PPSaveBtn:
Gui, SettingsGUI:Submit, NoHide
GuiControlGet, GSPowerSwitch
GuiControlGet, PowerplanEnSave
GuiControlGet, PowerplanBalance
GuiControlGet, PowerplanMaxPow
IniWrite, %GSPowerSwitch%, %configini%, PowerPlans, PowerPlansEnabled
IniWrite, %PowerplanEnSave%, %configini%, PowerPlans, EnergySave
IniWrite, %PowerplanBalance%, %configini%, PowerPlans, BalancedMode
IniWrite, %PowerplanMaxPow%, %configini%, PowerPlans, MaximumPower
Menu, Tray, DeleteAll
Gosub TrayDraw
MSGBox Powerplans settings written!
return

SetBtn:
return

CanclBtn:
Gui, SettingsGUI:Destroy
return

SettingsGUIGuiClose:
Gui, SettingsGUI:Destroy
return

FCListCreate: ; Creates list of Fan Control profiles
arrFCProf := ""
FileSelectFolder, FCFolder
if (FCFolder = "")
{
    MsgBox, You didn't select FC folder
    Return
}
else
{
	Gosub FCExeCheck
    Loop Files, %FCFolder%\Configurations\*.json
    {
        arrFCProf .= A_LoopFileName "|"
    }
    MsgBox %arrFCProf%
    GuiControl, , FCPSilent, %arrFCProf%
    GuiControl, , FCPMinimal, %arrFCProf%
    GuiControl, , FCPAuto, %arrFCProf%
	GuiControl, , FCexeDetected, % FCexeDetected ? 1 : 0  ; Update checkbox is exe detected
    Gui,SettingsGUI:Show
    Return
}
return

FCPrecheck: ; Creates list of Fan Control profiles
;MSGBox, FCFOLDER IS %FCFolder%
arrFCProf := ""
if (FCFolder = "") and (GSFanSwitch = 1)
{
    MsgBox, You didn't select FC folder set it in settings
	FCexeDetected:= 0
    Return
}
if (FCFolder = "") and (GSFanSwitch = 0)
{
	FCexeDetected:= 0
    Return
}
else
{
	Gosub FCExeCheck
    Loop Files, %FCFolder%\Configurations\*.json
    {
        arrFCProf .= A_LoopFileName "|"
    }
   ; MsgBox %arrFCProf%
	Gosub FCCheckConfFiles
    GuiControl, , FCPSilent, %arrFCProf%
    GuiControl, , FCPMinimal, %arrFCProf%
    GuiControl, , FCPAuto, %arrFCProf%
	GuiControl, , FCexeDetected, % FCexeDetected ? 1 : 0  ; Update checkbox is exe detected
    Return
}
return

FCCheckConfFiles:
IfNotExist %FCFolder%\Configurations\%FCPSilentSTR%
	{
	MSGBox %FCPSilentSTR% not found! Setup it in settings!
	FCPSilentSTR := ""
	}
	
IfNotExist %FCFolder%\Configurations\%FCPMinimalSTR%
	{
	MSGBox %FCPMinimalSTR% not found! Setup it in settings!
	FCPMinimalSTR := ""
	}

IfNotExist %FCFolder%\Configurations\%FCPAutoSTR%
	{
	MSGBox %FCPAutoSTR% not found! Setup it in settings!
	FCPAutoSTR := ""
	}

Return

FCSaveBtn:
Gui, SettingsGUI:Submit, NoHide
GuiControlGet, GSFanSwitch
GuiControlGet, FCPSilent
GuiControlGet, FCPMinimal
GuiControlGet, FCPAuto
IniWrite, %GSFanSwitch%, %configini%, FanControl, FanControlEnabled
IniWrite, %FCFolder%, %configini%, FanControl, FanControlFolder
IniWrite, %FCPSilent%, %configini%, FanControl, FanControlSilent
IniWrite, %FCPMinimal%, %configini%, FanControl, FanControlMinimal
IniWrite, %FCPAuto%, %configini%, FanControl, FanControlAuto
Menu, Tray, DeleteAll
Gosub TrayDraw
MSGBox FC Settings saved!
return

HCSaveBtn:
MSGBox This will save Hotkeys settings
return

FCExeCheck:
 IfNotExist, %FCFolder%\FanControl.exe
	{
	MsgBox You choose wrong FC folder! Exe file not detected. Choose right folder!
	FCexeDetected:= 0
	
	}
else
	{
	FCexeDetected:= 1
	}
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
