public int Native_RegTrigger(Handle hPlugin, int iNumParams)
{
	char sResult[64],sIndex[12];
	iTriggerNum++;
	g_eTriggers[iTriggerNum].hPlugin = hPlugin;
	g_eTriggers[iTriggerNum].fncCallback = GetNativeFunction(2);
	GetNativeString(1,sResult,sizeof sResult);
	IntToString(iTriggerNum,sIndex,sizeof sIndex);
	hTriggers.SetString(sResult,sIndex);
	return 0;
}

public int Native_CoreIsLoad(Handle hPlugin, int iParams)
{
	return g_bLoaded;
}