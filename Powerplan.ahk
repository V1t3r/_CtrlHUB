;Usage DopowerPlan() returns populated names, DopowerPlan(%PlanName%) followed by DopowerPlan() to cleanup.
; PowerPlan Names are 129 chars in length and accept most characters.
DopowerPlan(planToChangeTo := "")
{

Static oldSchemeGUID, oldDesc, arrPowerPlanNames := []
tmp := 0, strErr := "", StrPrfn := " call of PowerReadFriendlyName failed with "

if (planToChangeTo)
{
; If a default plan is only to be set
/*
	if (!oldDesc)
	defPowerPlanNames := ["Default", "Balanced", "Power saver", "High performance"]

	loop, 4
	{
	if (planToChangeTo = defPowerPlanNames[A_Index])
	tmp := 1
	}


	if (!tmp)
	{
	Msgbox % planToChangeTo " is not a default power plan!"
	Return
	}
*/
}
else
{
	; Restore old scheme on close
	if (oldDesc)
	{
	tmp := Dllcall("powrprof.dll\PowerSetActiveScheme", "Ptr", 0, "Ptr", oldSchemeGUID, "Uint")
		if (tmp)
		Msgbox % "Error with PowerSetActiveScheme on default plan: " tmp

	VarSetCapacity(oldDesc, 0)
	VarSetCapacity(oldSchemeGUID, 0)
	arrPowerPlanNames := ""
	Return
	}

}


ACCESS_SCHEME := 16 ; For PowerEnumerate
VarSetCapacity(desc, szdesc := 1024)
VarSetCapacity(schemeGUID, szguid := 16)
	if (!oldDesc)
	{
	VarSetCapacity(oldDesc, szdesc)
	VarSetCapacity(oldSchemeGUID, szguid)
	}


if (!oldDesc) ; assume oldDesc memset 0
{
	; GetActivePwrScheme the older flavour
	tmp := DllCall("powrprof\PowerGetActiveScheme", "Ptr", 0, "Ptr*", oldSchemeGUID, "Uint")
		if (tmp)
		strErr := "Error with GetActivePwrScheme on default plan: " . tmp

	tmp := Dllcall("powrprof.dll\PowerReadFriendlyName", "Ptr", 0, "Ptr", oldSchemeGUID, "Ptr", 0, "Ptr", 0, "Ptr", 0, "Ptr*", szdesc) ;sdesc :LPDWORD
		if (tmp != 0)
		{
		strErr .= "`nFirst" . StrPrfn . tmp . "."
		}
	
	tmp := Dllcall("powrprof.dll\PowerReadFriendlyName", "Ptr", 0, "Ptr", oldSchemeGUID, "Ptr", 0, "Ptr", 0, "str", oldDesc, "Ptr*", szdesc) ;use the updated szdesc from first call of fn
		if (tmp != 0)
		{
		strErr .= "`nSecond" . StrPrfn . tmp . "."
		}

}


Loop
{
	r := Dllcall("powrprof.dll\PowerEnumerate", "Ptr", 0, "Ptr", 0, "Ptr", 0, "Uint", ACCESS_SCHEME, "Uint", A_Index-1, "Ptr", &schemeGUID, "Uint*", szguid) ;DWORD
		if (r != 0)
		break

	tmp := Dllcall("powrprof.dll\PowerReadFriendlyName", "Ptr", 0, "Ptr", &schemeGUID, "Ptr", 0, "Ptr", 0, "Ptr", 0, "Ptr*", szdesc) ;sdesc :LPDWORD
		if (tmp != 0)
		{
		strErr .= "`nThird" . StrPrfn . tmp . "."
		}
	
	tmp := Dllcall("powrprof.dll\PowerReadFriendlyName", "Ptr", 0, "Ptr", &schemeGUID, "Ptr", 0, "Ptr", 0, "str", desc, "ptr*", szdesc) ;use the updated szdesc from first call of fn
		if (tmp != 0)
		{
		strErr .= "`nFourth" . StrPrfn . tmp . "."
		}



	plan .= A_Index-1 " - " desc "`n"
	if (planToChangeTo)
	{
		if (desc = planToChangeTo)
		{
		tmp := Dllcall("powrprof.dll\PowerSetActiveScheme", "Ptr", 0, "Ptr", &schemeGUID, "Uint")
			if (tmp)
			strErr .= "`nError with PowerSetActiveScheme on new plan: " . tmp
		r := 259
		Break
		}
	}
	else ; just enumerate and fill on first call
	arrPowerPlanNames[A_Index] := desc

}

	if (r != 259)  ;ERROR_NO_MORE_ITEMS- (should never get here)
	strErr .= "`nError in Power Plan Enumeration: " . r


	if (!planToChangeTo)
	;Msgbox Available power schemes:`n%plan%`nCurrent GUID: %oldSchemeGUID%




VarSetCapacity(schemeGUID, 0)
VarSetCapacity(desc, 0)

	; If only one entry (Balanced) then it's a Modern Standby or "S0 Low Power Idle" install, not the usual S3 Sleep state!. Other power schemes may not be created.
	if (arrPowerPlanNames.Length() = 1) ; Final call to function
	{
	VarSetCapacity(oldDesc, 0)
	VarSetCapacity(oldSchemeGUID, 0)
	}

	if (strErr)
	msgbox, 48, Power Error, % strErr

	if (planToChangeTo)
	return 0
	else
	return arrPowerPlanNames
}