public void Event_ClientCallback(Handle hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int iClient = CID(GetEventInt(hEvent, "userid"));
	ProcessEvents(iClient, hEvent, sEventName);
}

public void Event_AttackerCallback(Handle hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int iClient = CID(GetEventInt(hEvent, "attacker"));
	if ( iClient > 0 && iClient <= MaxClients ) {
		ProcessEvents(iClient, hEvent, sEventName);
	}
}

void ProcessEvents(int iClient, Handle hEvent, const char[] sEventName)
{
	Handle hEventArray;
	if (IsFakeClient(iClient) || !GetTrieValue(g_hTrie_EventAchievements, sEventName, hEventArray) ) {
		return;
	}

	if(!g_iSettings[0] && GameRules_GetProp("m_bWarmupPeriod")){
		return;
	}
	if(!g_iSettings[1] && IsRoundEnd){
		return;	
	}
	if(GetClientCount() < g_iSettings[2]){
		return;
	}
	
	Handle hAchievementData; 
	char 
		sName[64],
		sBuffer[256],
		sParts[8][256];
	bool 
		bUpdate,
		bFlag; 
	int 
		iBuffer, 
		iCount, 
		iParts;
	int iLength = GetArraySize(hEventArray);
	for ( int i = 0; i < iLength; ++i ) {
		GetArrayString(hEventArray, i, SZF(sName));
		if ( !GetTrieValue(g_hTrie_AchievementData, sName, hAchievementData) ) {
			// this can't be, but maybe...
			LogError("???");
			continue;
		}
		
		bFlag = true;
		bUpdate = false;
		iCount = 0;
		
		bUpdate = GetTrieValue(g_hTrie_ClientProgress[iClient], sName, iCount);
		GetTrieValue(hAchievementData, "count", iBuffer);
		
		if(iCount < iBuffer && iCount != -1) {
			GetTrieString(hAchievementData, "condition", SZF(sBuffer));
			iParts = ExplodeString(sBuffer, ";", sParts, sizeof(sParts), sizeof(sParts[]));

			for(int l; l < iParts; l++)
			{
				if(!CheckCondition(sParts[l], hEvent))
				{
					bFlag = false;
				}
			}
				
			if ( bFlag ) {
				iCount++;
				SetTrieValue(g_hTrie_ClientProgress[iClient], sName, iCount);
				SaveProgress(iClient, sName, bUpdate);

				if ( iCount >= iBuffer ) {
					char sTranslation[64],
						sSound[64];
					int iNotifAll;
					GetTrieValue(hAchievementData, "notification_all",iNotifAll);
					FormatEx(SZF(sTranslation), "%s: name", sName);
					Format(SZF(sTranslation), "%t", sTranslation);
					if(iNotifAll)
					{
						char sClientName[32];
						GetClientName(iClient, SZF(sClientName));
						PrintToChatAll("%t", "client got achievement", sClientName, sTranslation);
					}
					switch(g_iSettings[3])
					{
						case 1:
						{
							PrintToChat(iClient,"%t", "you got achievement: chat", sTranslation);
						}
						case 2:
						{
							PrintCenterText(iClient, "%t", "you got achievement: center", sTranslation);
						}
						case 3:
						{
							AlertText(iClient, "%t", "you got achievement: alert", sTranslation);
						}
					}
					GetTrieString(hAchievementData, "sound_done",sSound,sizeof sSound);
					if(sSound[0])
					{
						float fVolume;
						GetTrieValue(hAchievementData, "sound_done_volume",fVolume);
						EmitSoundToClient(iClient,sSound, _, SNDCHAN_STATIC,SNDLEVEL_NORMAL,SND_NOFLAGS,fVolume);
					}
					SetTrieValue(g_hTrie_ClientProgress[iClient], sName, -1);
					SaveProgress(iClient, sName, bUpdate);
					GiveReward(iClient, sName);
					CreateProgressMenu(iClient);
				}
			}
		}
	}
}

void AlertText(int iClient, const char[] sMessage, any ...)
{
	char sBuffer[512];
	VFormat(sBuffer, sizeof(sBuffer), sMessage, 3);
	Event hEvent = CreateEvent("show_survival_respawn_status", true);
	if(hEvent)
	{
		hEvent.SetString("loc_token", sBuffer);
		hEvent.SetInt("duration", 5);
		hEvent.SetInt("userid", -1);
		hEvent.FireToClient(iClient);
		hEvent.Cancel();
	}
}

bool CheckCondition(char[] sCondition, Handle hEvent)
{
	TrimString(sCondition);
	char sConditionParts[3][128];
	int iParts = ExplodeString(sCondition, " ", sConditionParts, sizeof(sConditionParts), sizeof(sConditionParts[]));
	
	switch (iParts) {
		case 1: {
			if (sCondition[0]) {
				return (GetEventBool(hEvent, sCondition));
			}
			else {
				return true;
			}
		}
		
		case 3: {
			if ( IsCharNumeric(sConditionParts[2][0]) ) {
				switch (sConditionParts[1][0]) {
					case '=': {
						char sParts[3][16];
						int partsCount = ExplodeString(sConditionParts[2], "|", sParts, sizeof(sParts), sizeof(sParts));
						if ( partsCount == 1 ) {
							return (GetEventInt(hEvent, sConditionParts[0])==StringToInt(sConditionParts[2]));
						}
						else {
							int buffer = GetEventInt(hEvent, sConditionParts[0]);
							for ( int i = 0; i < partsCount; ++i ) {
								if ( buffer == StringToInt(sParts[i]) ) {
									return true;
								}
							}
							return false;
						}
					}
					case '>': {
						return (GetEventInt(hEvent, sConditionParts[0])>StringToInt(sConditionParts[2]));
					}
					case '<': {
						return (GetEventInt(hEvent, sConditionParts[0])<StringToInt(sConditionParts[2]));
					}
				}
			}
			else {
				char sParts[8][16];
				int partsCount = ExplodeString(sConditionParts[2], "|", sParts, sizeof(sParts), sizeof(sParts));
				if ( partsCount == 1 ) {
					char eventValue[16];
					GetEventString(hEvent, sConditionParts[0], SZF(eventValue));
					return (!strcmp(eventValue, sConditionParts[2]));
				}
				else {
					char eventValue[16];
					GetEventString(hEvent, sConditionParts[0], SZF(eventValue));
					for ( int i = 0; i < partsCount; ++i ) {
						if ( !strcmp(eventValue, sParts[i]) ) {
							return true;
						}
					}
					return false;
				}
			}
		}
		
		default: {
			LogError("Invalid condition: \"%s\"", sCondition);
			return false;
		}
	}
	
	return true;
}