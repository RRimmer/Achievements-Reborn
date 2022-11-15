public int Native_RegTrigger(Handle hPlugin, int iNumParams)
{
	char sResult[64],sIndex[12];
	g_eTriggers[iTriggerNum].hPlugin = hPlugin;
	g_eTriggers[iTriggerNum].fncCallback = GetNativeFunction(2);
	GetNativeString(1,sResult,sizeof sResult);
	IntToString(iTriggerNum,sIndex,sizeof sIndex);
	hTriggers.SetString(sResult,sIndex);
	iTriggerNum++;
	return 0;
}

public int Native_CoreIsLoad(Handle hPlugin, int iParams)
{
	return g_bLoaded;
}

public int Native_GetClientInfo(Handle hPlugin, int iParams)
{
	int iCount;
	char sName[64];
	GetNativeString(2,SZF(sName));
	GetTrieValue(g_hTrie_ClientProgress[GetNativeCell(1)], sName, iCount);
	return iCount;
}

public int Native_GetEventNames(Handle hPlugin, int iArgs)
{
	return view_as<int>(g_hArray_sAchievementNames);
}

public int Native_GetKV(Handle hPlugin, int iArgs)
{
	return view_as<int>(g_hKeyValues);
}

public int Native_GetInfo(Handle hPlugin, int iArgs)
{
	char sName[64];
	GetNativeString(1,sName,sizeof sName);
	Handle hAchievementData;
	GetTrieValue(g_hTrie_AchievementData, sName, hAchievementData);
	return view_as<int>(hAchievementData);
}

public int Native_ReconstructMenu(Handle hPlugin, int iArgs)
{
	int iClient = GetNativeCell(1);
	CreateProgressMenu(iClient);
	return 0;
}

Action Fwd_Event(int iClient,char[] sName)
{
	Action result = Plugin_Continue;
	
	Call_StartForward(g_hEventWork);
	Call_PushCell(iClient);
	Call_PushString(sName);
	Call_Finish(result);
	
	return result;
}

Action Fwd_AddItem(int iClient, char[] sName, int &iStyle = ITEMDRAW_DEFAULT)
{	
	Action result = Plugin_Continue;
	int style = iStyle;
	
	Call_StartForward(g_hAchAddMenu);
	Call_PushCell(iClient);
	Call_PushString(sName);
	Call_PushCellRef(style);
	Call_Finish(result);

	if(result == Plugin_Changed) 
	{
		iStyle = style;
	}

	return result;
}