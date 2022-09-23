GiveReward(int iClient, const char[] sName)
{
	Handle hAchievementData;
	char sTrigger[64],sOutcome[64],sIndexTrigger[12];
	GetTrieValue(g_hTrie_AchievementData, sName, hAchievementData);
	
	GetTrieString(hAchievementData, "trigger", SZF(sTrigger));
	GetTrieString(hAchievementData, "outcome", SZF(sOutcome));
	hTriggers.GetString(sTrigger,SZF(sIndexTrigger));
	int iIndex = StringToInt(sIndexTrigger);
	Handle hPlugin = g_eTriggers[iIndex].hPlugin;
	Function fncCallback = g_eTriggers[iIndex].fncCallback;
	
	if(fncCallback)
	{
		Call_StartFunction(hPlugin, fncCallback);
		Call_PushCell(iClient);
		Call_PushString(sOutcome);
		Call_Finish();
	}
	else
	{
		LogError("Achievements: Trigger not found[%s]",sName);
	}
}