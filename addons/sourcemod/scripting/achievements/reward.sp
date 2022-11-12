void GiveReward(int iClient, const char[] sName)
{
	char sName2[64];
	strcopy(SZF(sName2),sName);
	if(!g_iSettings[6])
		GetRewardInventory(iClient, sName2);
	else
		AddItemInventory(iClient, sName2);
}

void GetRewardInventory(int iClient, char[] sName)
{
	Handle hAchievementData;
	char sTriggers[256], sOutcomes[256];
	GetTrieValue(g_hTrie_AchievementData, sName, hAchievementData);
	
	GetTrieString(hAchievementData, "trigger", SZF(sTriggers));
	GetTrieString(hAchievementData, "outcome", SZF(sOutcomes));

	char sTrigger[8][64], sOutcome[8][64], sIndexTrigger[12];
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