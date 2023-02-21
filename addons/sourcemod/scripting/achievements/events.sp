public void Event_ClientCallback(Handle hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int iClient = CID(GetEventInt(hEvent, "userid"));
	ProcessEvents(iClient, hEvent, sEventName, false);
}

public void Event_AttackerCallback(Handle hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int iClient = CID(GetEventInt(hEvent, "attacker"));
	if ( iClient > 0 && iClient <= MaxClients ) {
		ProcessEvents(iClient, hEvent, sEventName, true);
	}
}

void ProcessEvents(int iClient, Handle hEvent, const char[] sEventName, bool bAttacker)
{
	Handle hEventArray;
	int iTarget;
	if(bAttacker)
		iTarget = CID(GetEventInt(hEvent, "userid"));
	else
		iTarget = CID(GetEventInt(hEvent, "attacker"));
	if (!IsClientInGame(iClient) || IsFakeClient(iClient) || !GetTrieValue(g_hTrie_EventAchievements, sEventName, hEventArray) || iTarget == iClient) {
		return;
	}

	if(g_EngineVersion == Engine_CSGO && !g_iSettings[0] && GameRules_GetProp("m_bWarmupPeriod")){
		return;
	}
	if(!g_iSettings[1] && IsRoundEnd){
		return;	
	}
	if(GetNiggers() <= g_iSettings[2]){
		return;
	}
	
	Handle hAchievementData; 
	char 
		sName[64],
		sBuffer[256],
		sParts[8][256],
		sLastEvent[MAXPLAYERS+1][256];
	bool 
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
		iCount = 0;
		
		Action action = Fwd_Event(iClient,sName);
		if(action == Plugin_Handled)
			continue;
		GetTrieString(hAchievementData, "map", sBuffer,sizeof sBuffer);
		if(sBuffer[0])
			if(StrContains(g_sMapName,sBuffer) == -1)
				continue;

		GetTrieValue(g_hTrie_ClientProgress[iClient], sName, iCount);
		GetTrieValue(hAchievementData, "count", iBuffer);
		GetTrieString(hAchievementData, "condition", SZF(sBuffer));
		if((g_iSettings[5] && !strcmp(sLastEvent[iClient],g_iSettings[5]==2?sBuffer:sEventName)) || iCount == -1)
			continue;

		FormatEx(sLastEvent[iClient],sizeof sLastEvent[],g_iSettings[5]==2?sBuffer:sEventName);

		if(iCount < iBuffer && iCount != -1) {
			iParts = ExplodeString(sBuffer, ";", sParts, sizeof(sParts), sizeof(sParts[]));

			for(int l; l < iParts; l++)
			{
				if(!CheckCondition(sParts[l], hEvent))
				{
					bFlag = false;
				}
			}
				
			if ( bFlag || !strcmp("none",sBuffer)) {
				iCount++;
				SetTrieValue(g_hTrie_ClientProgress[iClient], sName, iCount);
				GetClientCookie(iClient, g_hCookie, SZF(sBuffer));
				if(g_hArray_Notif[iClient].FindString(sName) != -1)
				{
					FormatEx(SZF(sBuffer), "%s: name", sName);
					HudMessageByChannel(g_fHudPOS[0], g_fHudPOS[1], g_fHudTime, g_iHudColor[0], g_iHudColor[1], g_iHudColor[2], g_iHudColor[3], 0, 0.0, 0.1, 0.1, 0, iClient, "%t: %i/%i", sBuffer, iCount, iBuffer);
				}

				if ( iCount >= iBuffer ) {
					char sTranslation[64],
						sSound[64],
						sMessage[128];
					int iNotifAll;
					GetTrieValue(hAchievementData, "notification_all",iNotifAll);
					FormatEx(SZF(sTranslation), "%s: name", sName);
					Format(SZF(sTranslation), "%t", sTranslation);
					if(iNotifAll)
					{
						char sClientName[32];
						GetClientName(iClient, SZF(sClientName));
						FormatEx(sMessage,sizeof sMessage,"%t", "client got achievement", sClientName, sTranslation);
						A_PrintToChatAll(sMessage);
					}
					switch(g_iSettings[3])
					{
						case 1:
						{
							FormatEx(sMessage,sizeof sMessage,"%t", "you got achievement: chat", sTranslation);
							A_PrintToChat(iClient, sMessage);
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
					g_iCCAch[iClient]++;
					GiveReward(iClient, sName);
					int iIndex;
					if((iIndex = g_hArray_Notif[iClient].FindString(sName)) != -1)
						g_hArray_Notif[iClient].Erase(iIndex);
					CreateMenuGroups(iClient);
				}
			}
		}
	}
	sLastEvent[iClient][0] = 0; 
}

void HudMessageByChannel(float x, float y, float hold_time, int r, int g, int b, int a, int effect, float fx_time, float fade_in, float fade_out, int channel, int iClient, char[] message, any...)
{
	char buf[PLATFORM_MAX_PATH];
	VFormat(buf, sizeof(buf), message, 15);
	
	SetHudTextParams(x, y, hold_time, r, g, b, a, effect, fx_time, fade_in, fade_out);
	ShowHudText(iClient, channel, buf);
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

stock int GetNiggers()
{
    int b = 0;
    for(int i = 1; i <= MaxClients; i++)
        if(IsClientInGame(i) && !IsFakeClient(i) && !IsClientSourceTV(i)) b++;
 
    return b;
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
					if(StrContains(eventValue,sConditionParts[2],false) != -1) return true;
					else return false;
				}
				else {
					char eventValue[16];
					GetEventString(hEvent, sConditionParts[0], SZF(eventValue));
					for ( int i = 0; i < partsCount; ++i ) {
						if (StrContains(eventValue,sParts[i],false) != -1) {
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