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
	Call_StartForward(g_hRewardGiven);
	Call_PushCell(iClient);
	Call_PushString(sName);
	Call_Finish();

	Handle hAchievementData;
	char sTriggers[256], sOutcomes[256], sMessage[128];
	GetTrieValue(g_hTrie_AchievementData, sName, hAchievementData);
	
	GetTrieString(hAchievementData, "trigger", SZF(sTriggers));
	GetTrieString(hAchievementData, "outcome", SZF(sOutcomes));

	char sTrigger[8][64], sOutcome[8][64], sIndexTrigger[12];
	int iCountTriggers,
		iCountOutcome;
	if(StrContains(sTriggers,";") != -1) iCountTriggers = ExplodeString(sTriggers, ";", sTrigger, sizeof(sTrigger), sizeof(sTrigger[]));
	else iCountTriggers = 1;
	if(StrContains(sOutcomes,";") != -1) iCountOutcome = ExplodeString(sOutcomes, ";", sOutcome, sizeof(sOutcome), sizeof(sOutcome[]));
	else iCountOutcome = 1;
	if(iCountTriggers != iCountOutcome)
	{
		LogError("В призе достижения %s совершена ошибка",sName);
		return;
	}
	int iIndex;
	for(int i = 0; i <= iCountTriggers-1; i++)
	{
		hTriggers.GetString(iCountTriggers == 1?sTriggers:sTrigger[i],SZF(sIndexTrigger));
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
			LogError("Achievements: Trigger not found[%s]",iCountTriggers == 1?sTriggers:sTrigger[i]);
		}
	}
	Format(sMessage,sizeof sMessage,"%s: reward", sName);
	Format(sMessage,sizeof sMessage,"%t", sMessage);
	Format(sMessage,sizeof sMessage,"%t", "message_reward", sMessage);
	A_PrintToChat(iClient, sMessage);

	LogToFile(g_sLogFile, "Игрок %L получил награду за достижение %s(тип: %s;количество: %s)", iClient, sName, sTriggers, sOutcomes);

	Call_StartForward(g_hRewardGivenPost);
	Call_PushCell(iClient);
	Call_PushString(sName);
	Call_Finish();
}