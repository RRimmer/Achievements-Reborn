void LoadAchivements()
{
	char sPath[PMP];
	BuildPath(Path_SM, SZF(sPath), "configs/achievements.ini");
	
	Handle hKeyValues = CreateKeyValues("Settings");
	if ( !FileToKeyValues(hKeyValues, sPath) ) {
		LogError("File \"%s\" not found", sPath);
		SetFailState("File \"%s\" not found", sPath);
	}
	
	Handle hHookedClientEvents = CreateTrie();	
	Handle hHookedAttackerEvents = CreateTrie();
	
	// reload will result in memory leak
	g_hArray_sAchievementNames = CreateArray(ByteCountToCells(64));
	g_hArray_sAchievementSound = CreateArray(ByteCountToCells(64));
	g_hTrie_AchievementData = CreateTrie();
	g_hTrie_EventAchievements = CreateTrie();
	
	Handle 
		hAchievementData, 
		hEventsArray; 
	char	sName[64], 
		sBuffer[256], 
		sExecutor[16],
		sCommands[512]; 
	int 	iBuffer;

	KvGetString(hKeyValues,"command",sCommands,sizeof sCommands);
	
	g_iSettings[0] = KvGetNum(hKeyValues,"warmup");
	g_iSettings[1] = KvGetNum(hKeyValues,"roundend");
	g_iSettings[2] = KvGetNum(hKeyValues,"min_players");
	g_iSettings[3] = KvGetNum(hKeyValues,"notification");
	g_iSettings[4] = KvGetNum(hKeyValues,"server_id");
	KvGetString(hKeyValues,"tag",g_sTag,sizeof g_sTag);

	if(sCommands[0])
	{
		char sBufs[64][64];
		int count = ExplodeString(sCommands, ";", sBufs, sizeof(sBufs), sizeof(sBufs[]));

		for(int c; c < count; c++)
		{
			Format(sBufs[c], sizeof(sBufs[]), "%s", sBufs[c]);
			RegConsoleCmd(sBufs[c], Command_Achievements);
		}
	}
	else
	{
		RegConsoleCmd("sm_achievements", 	Command_Achievements);
		RegConsoleCmd("sm_ach", 			Command_Achievements);
	}
	
	KvRewind(hKeyValues);
	if(KvJumpToKey(hKeyValues,"Achievement"))
	{
		KvGotoFirstSubKey(hKeyValues);
		do {
			KvGetSectionName(hKeyValues, SZF(sName));
			if ( GetTrieValue(g_hTrie_AchievementData, sName, hAchievementData) ) {
				LogError("Duplicate achievement name \"%s\"", sName);
				continue;
			}
			
			hAchievementData = CreateTrie();
			KvGetString(hKeyValues, "event", SZF(sBuffer));
			if ( !GetTrieValue(g_hTrie_EventAchievements, sBuffer, hEventsArray) ) {
				hEventsArray = CreateArray(ByteCountToCells(64));
				SetTrieValue(g_hTrie_EventAchievements, sBuffer, hEventsArray);
			}
			PushArrayString(hEventsArray, sName);
			
			KvGetString(hKeyValues, "executor", SZF(sExecutor));
			if (!strcmp(sExecutor, "userid")) {
				if ( !GetTrieValue(hHookedClientEvents, sBuffer, iBuffer) && !HookEventEx(sBuffer, Event_ClientCallback) ) {
					LogError("Invalid event name \"%s\"", sBuffer);
					continue;
				}
				SetTrieValue(hHookedClientEvents, sBuffer, 1);
			}
			else if (!strcmp(sExecutor, "attacker")) {
				if ( !GetTrieValue(hHookedAttackerEvents, sBuffer, iBuffer) && !HookEventEx(sBuffer, Event_AttackerCallback) ) {
					LogError("Invalid event name \"%s\"", sBuffer);
					continue;
				}
				SetTrieValue(hHookedAttackerEvents, sBuffer, 1);
			}
			
			SetTrieString(hAchievementData, "event", sBuffer);
			SetTrieString(hAchievementData, "executor", sExecutor);
			
			KvGetString(hKeyValues, "trigger", SZF(sBuffer));
			SetTrieString(hAchievementData, "trigger", sBuffer);
			
			KvGetString(hKeyValues, "outcome", SZF(sBuffer));
			SetTrieString(hAchievementData, "outcome", sBuffer);
			
			KvGetString(hKeyValues, "condition", SZF(sBuffer));
			SetTrieString(hAchievementData, "condition", sBuffer);
			
			SetTrieValue(hAchievementData, "count", KvGetNum(hKeyValues, "count", 666));
			SetTrieValue(hAchievementData, "notification_all", KvGetNum(hKeyValues, "notification_all", 1));
			
			KvGetString(hKeyValues, "sound_done", SZF(sBuffer));
			SetTrieString(hAchievementData, "sound_done", sBuffer);
			SetTrieValue(hAchievementData, "sound_done_volume", KvGetFloat(hKeyValues, "sound_done_volume", 0.5));
			
			SetTrieValue(g_hTrie_AchievementData, sName, hAchievementData);
			PushArrayString(g_hArray_sAchievementNames, sName);
			PushArrayString(g_hArray_sAchievementSound, sBuffer);
			
		} while ( KvGotoNextKey(hKeyValues) );
	}
	
	CloseHandle(hHookedClientEvents);
	CloseHandle(hHookedAttackerEvents);
	CloseHandle(hKeyValues);
	
	g_iTotalAchievements = GetArraySize(g_hArray_sAchievementNames);
}