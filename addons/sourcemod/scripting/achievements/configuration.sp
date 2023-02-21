void LoadAchivements()
{
	char sPath[PMP];
	BuildPath(Path_SM, SZF(sPath), "configs/achievements.ini");
	
	g_hKeyValues = CreateKeyValues("Settings");
	if ( !FileToKeyValues(g_hKeyValues, sPath) ) {
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
		hGroupData, 
		hEventsArray; 
	char	sName[64], 
		sBuffer[256], 
		sGroupName[64], 
		sExecutor[16],
		sCommands[512]; 
	int 	iBuffer;

	KvGetString(g_hKeyValues,"command",sCommands,sizeof sCommands);
	
	g_iSettings[0] = KvGetNum(g_hKeyValues,"warmup");
	g_iSettings[1] = KvGetNum(g_hKeyValues,"roundend");
	g_iSettings[2] = KvGetNum(g_hKeyValues,"min_players");
	g_iSettings[3] = KvGetNum(g_hKeyValues,"notification");
	g_iSettings[4] = KvGetNum(g_hKeyValues,"server_id");
	g_iSettings[5] = KvGetNum(g_hKeyValues,"continue");
	g_iSettings[6] = KvGetNum(g_hKeyValues,"inv_thisorthat");

	KvGetString(g_hKeyValues,"tag",g_sTag,sizeof g_sTag);

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

	KvGetString(g_hKeyValues,"hud_xy",sCommands,sizeof sCommands);
	if(sCommands[0])
	{
		char sBufs[2][12];
		ExplodeString(sCommands, " ", sBufs, sizeof(sBufs), sizeof(sBufs[]));

		g_fHudPOS[0] = StringToFloat(sBufs[0]);
		g_fHudPOS[1] = StringToFloat(sBufs[1]);
	}
	g_fHudTime = KvGetFloat(g_hKeyValues,"hud_time");

	KvGetString(g_hKeyValues,"hud_color",sCommands,sizeof sCommands);
	if(sCommands[0])
	{
		char sBufs[4][12];
		ExplodeString(sCommands, " ", sBufs, sizeof(sBufs), sizeof(sBufs[]));

		g_iHudColor[0] = StringToInt(sBufs[0]);
		g_iHudColor[1] = StringToInt(sBufs[1]);
		g_iHudColor[2] = StringToInt(sBufs[2]);
		g_iHudColor[3] = StringToInt(sBufs[3]);
	}

	KvRewind(g_hKeyValues);
	if(KvJumpToKey(g_hKeyValues,"Groups"))
	{
		int i = 0;
		if(KvGotoFirstSubKey(g_hKeyValues))
		{
			g_hTrie_GroupsAchievements = CreateTrie();
			do {
				hGroupData = CreateTrie();
				KvGetSectionName(g_hKeyValues, SZF(sGroupName));
				g_hArray_GroupAchievements[i] = CreateArray(ByteCountToCells(64));
				SetTrieValue(hGroupData,"index",i);
				SetTrieValue(hGroupData,"count",KvGetNum(g_hKeyValues,"count",666));
				KvGetString(g_hKeyValues,"event",SZF(sBuffer));
				SetTrieString(hGroupData,"event",sBuffer);
				KvGetString(g_hKeyValues,"executor",SZF(sBuffer));
				SetTrieString(hGroupData,"executor",sBuffer);
				KvGetString(g_hKeyValues,"condition",SZF(sBuffer));
				SetTrieString(hGroupData,"condition",sBuffer);
				KvGetString(g_hKeyValues,"sound_done",SZF(sBuffer));
				PushArrayString(g_hArray_sAchievementSound, sBuffer);
				SetTrieString(hGroupData,"sound_done",sBuffer);
				SetTrieValue(hGroupData,"notification_all",KvGetNum(g_hKeyValues,"notification_all",1));
				SetTrieValue(hGroupData,"sound_done_volume",KvGetFloat(g_hKeyValues,"sound_done_volume",0.5));
				SetTrieValue(g_hTrie_GroupsAchievements,sGroupName,hGroupData);
				PrintToServer(sGroupName);
				i++;
			} while ( KvGotoNextKey(g_hKeyValues) );
		}
	}
	
	KvRewind(g_hKeyValues);
	if(KvJumpToKey(g_hKeyValues,"Achievement"))
	{
		KvGotoFirstSubKey(g_hKeyValues);
		do {
			KvGetSectionName(g_hKeyValues, SZF(sName));
			if ( GetTrieValue(g_hTrie_AchievementData, sName, hAchievementData) ) {
				LogError("Duplicate achievement name \"%s\"", sName);
				continue;
			}
			
			hAchievementData = CreateTrie();

			KvGetString(g_hKeyValues, "group", SZF(sGroupName));
			SetTrieString(hAchievementData, "group", sGroupName);
			if(g_hTrie_GroupsAchievements != INVALID_HANDLE && GetTrieValue(g_hTrie_GroupsAchievements,sGroupName,hGroupData))
			{
				GetTrieValue(hGroupData,"index",iBuffer);
				g_hArray_GroupAchievements[iBuffer].PushString(sName);
			}
			KvGetString(g_hKeyValues, "count", SZF(sBuffer),"");
			if(!strcmp(sBuffer,""))
			{
				GetTrieValue(g_hTrie_GroupsAchievements,sGroupName,hGroupData);
				GetTrieValue(hGroupData,"count",iBuffer);
				SetTrieValue(hAchievementData, "count", iBuffer);
			}
			else
				SetTrieValue(hAchievementData, "count", KvGetNum(g_hKeyValues, "count", 666));

			KvGetString(g_hKeyValues, "event", SZF(sBuffer),"");
			if(!strcmp(sBuffer,""))
			{
				GetTrieValue(g_hTrie_GroupsAchievements,sGroupName,hGroupData);
				GetTrieString(hGroupData,"event",SZF(sBuffer));
			}
			else
				KvGetString(g_hKeyValues, "event", SZF(sBuffer));

			if ( !GetTrieValue(g_hTrie_EventAchievements, sBuffer, hEventsArray) ) {
				hEventsArray = CreateArray(ByteCountToCells(64));
				SetTrieValue(g_hTrie_EventAchievements, sBuffer, hEventsArray);
			}
			PushArrayString(hEventsArray, sName);
			
			
			KvGetString(g_hKeyValues, "executor", SZF(sExecutor),"");
			if(!strcmp(sExecutor,""))
			{
				GetTrieValue(g_hTrie_GroupsAchievements,sGroupName,hGroupData);
				GetTrieString(hGroupData,"executor",SZF(sExecutor));
			}
			else
				KvGetString(g_hKeyValues, "executor", SZF(sExecutor));

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
			
			KvGetString(g_hKeyValues, "trigger", SZF(sBuffer));
			SetTrieString(hAchievementData, "trigger", sBuffer);
			
			KvGetString(g_hKeyValues, "outcome", SZF(sBuffer));
			SetTrieString(hAchievementData, "outcome", sBuffer);
			
			KvGetString(g_hKeyValues, "condition", SZF(sBuffer),"");
			if(!strcmp(sBuffer,""))
			{
				GetTrieValue(g_hTrie_GroupsAchievements,sBuffer,hGroupData);
				GetTrieString(hGroupData,"condition",SZF(sBuffer));
			}
			else
				KvGetString(g_hKeyValues, "condition", SZF(sBuffer),"none");

			SetTrieString(hAchievementData, "condition", sBuffer);

			KvGetString(g_hKeyValues, "map", SZF(sBuffer),"");
			if(!strcmp(sBuffer,""))
			{
				GetTrieValue(g_hTrie_GroupsAchievements,sBuffer,hGroupData);
				GetTrieString(hGroupData,"map",SZF(sBuffer));
			}
			else
				KvGetString(g_hKeyValues, "map", SZF(sBuffer),"");

			SetTrieString(hAchievementData, "map", sBuffer);
			
			SetTrieValue(hAchievementData, "hide", KvGetNum(g_hKeyValues, "hide", 0));

			KvGetString(g_hKeyValues, "notification_all", SZF(sBuffer),"");
			if(!strcmp(sBuffer,""))
			{
				GetTrieValue(g_hTrie_GroupsAchievements,sBuffer,hGroupData);
				GetTrieValue(hGroupData,"notification_all",iBuffer);
				SetTrieValue(hAchievementData, "notification_all", iBuffer);
			}
			else
				SetTrieValue(hAchievementData, "notification_all", KvGetNum(g_hKeyValues, "notification_all", 1));

			
			KvGetString(g_hKeyValues, "sound_done", SZF(sBuffer),"");
			if(!strcmp(sBuffer,""))
			{
				GetTrieValue(g_hTrie_GroupsAchievements,sBuffer,hGroupData);
				GetTrieString(hGroupData,"sound_done",SZF(sBuffer));
			}
			else
				KvGetString(g_hKeyValues, "sound_done", SZF(sBuffer),"");

			SetTrieString(hAchievementData, "sound_done", sBuffer);
			PushArrayString(g_hArray_sAchievementSound, sBuffer);
			
			KvGetString(g_hKeyValues, "sound_done_volume", SZF(sBuffer),"");
			if(!strcmp(sBuffer,""))
			{
				float sV;
				GetTrieValue(g_hTrie_GroupsAchievements,sBuffer,hGroupData);
				GetTrieValue(hGroupData,"sound_done_volume",sV);
				SetTrieValue(hAchievementData, "sound_done_volume", sV);
			}
			else
				SetTrieValue(hAchievementData, "sound_done_volume", KvGetFloat(g_hKeyValues, "sound_done_volume", 0.5));
			
			SetTrieValue(g_hTrie_AchievementData, sName, hAchievementData);
			PushArrayString(g_hArray_sAchievementNames, sName);
			
		} while ( KvGotoNextKey(g_hKeyValues) );
	}
	
	CloseHandle(hHookedClientEvents);
	CloseHandle(hHookedAttackerEvents);
	
	g_iTotalAchievements = GetArraySize(g_hArray_sAchievementNames);
	Ach_OnCoreLoaded();
}