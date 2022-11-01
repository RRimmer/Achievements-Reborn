void GiveReward(int iClient, const char[] sName)
{
	Handle hAchievementData;
	char sTrigger[8][64], sTriggers[256], sOutcomes[256],sOutcome[8][64],sIndexTrigger[12];
	GetTrieValue(g_hTrie_AchievementData, sName, hAchievementData);
	
	GetTrieString(hAchievementData, "trigger", SZF(sTriggers));
	GetTrieString(hAchievementData, "outcome", SZF(sOutcomes));

	int iCountTriggers = ExplodeString(sTriggers, ";", sTrigger, sizeof(sTrigger), sizeof(sTrigger[]));
	int iCountOutcome = ExplodeString(sOutcomes, ";", sOutcome, sizeof(sOutcome), sizeof(sOutcome[]));
	if(iCountTriggers != iCountOutcome)
	{
		LogError("В призе достижения %s совершена ошибка",sName);
		return;
	}
	int iIndex;
	for(int i = 0; i <= iCountOutcome; i++)
	{
		hTriggers.GetString(sTrigger[i],SZF(sIndexTrigger));
		iIndex = StringToInt(sIndexTrigger);
		Handle hPlugin = g_eTriggers[iIndex].hPlugin;
		Function fncCallback = g_eTriggers[iIndex].fncCallback;
		
		if(fncCallback)
		{
			Call_StartFunction(hPlugin, fncCallback);
			Call_PushCell(iClient);
			Call_PushString(sOutcome[i]);
			Call_Finish();
		}
		else
		{
			LogError("Achievements: Trigger not found[%s]",sTrigger[i]);
		}
	}
}