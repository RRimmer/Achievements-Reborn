Handle g_hInProgressMenu[MPS];
Handle g_hCompletedMenu[MPS];
int g_iCompletedAchievements[MPS];

public void CreateProgressMenu(int iClient)
{
	// create|clear menu from previos use
	if ( !g_hInProgressMenu[iClient] ) {
		g_hInProgressMenu[iClient] = CreateMenu(Handler_ShowAchievements, MenuAction_DisplayItem);
		SetMenuExitBackButton(g_hInProgressMenu[iClient], true);
	}
	RemoveAllMenuItems(g_hInProgressMenu[iClient]);
	
	// create|clear menu from previos use
	if ( !g_hCompletedMenu[iClient] ) {
		g_hCompletedMenu[iClient] = CreateMenu(Handler_ShowAchievements, MenuAction_DisplayItem);
		SetMenuExitBackButton(g_hCompletedMenu[iClient], true);
	}
	RemoveAllMenuItems(g_hCompletedMenu[iClient]);
	
	// create progress menu
	g_iCompletedAchievements[iClient] = 0;
	Handle hAchievementData; 
	char sName[64];
	int	iCount, iBuffer;
	for ( int i = 0; i < g_iTotalAchievements; ++i ) {
		GetArrayString(g_hArray_sAchievementNames, i, SZF(sName));
		if ( !GetTrieValue(g_hTrie_AchievementData, sName, hAchievementData) ) {
			// this can't be, but maybe...
			LogError("???");
			continue;
		}
		
		if ( GetTrieValue(g_hTrie_ClientProgress[iClient], sName, iCount) ) {
			if ( !GetTrieValue(hAchievementData, "count", iBuffer) ) {
				// this can't be, but maybe...
				LogError("?!");
				continue;
			}
			
			// continue !!!
			if ( iCount == -1 ) {
				AddMenuItem(g_hCompletedMenu[iClient], sName, "");
				g_iCompletedAchievements[iClient]++;
				continue;
			}
		}
		
		AddMenuItem(g_hInProgressMenu[iClient], sName, "");
	}
	
	// if menu is empty
	if ( GetMenuItemCount(g_hInProgressMenu[iClient]) == 0 ) {
		AddMenuItem(g_hInProgressMenu[iClient], "", "", ITEMDRAW_DISABLED);
	}
	
	// if menu is empty
	if ( GetMenuItemCount(g_hCompletedMenu[iClient]) == 0 ) {
		AddMenuItem(g_hCompletedMenu[iClient], "", "", ITEMDRAW_DISABLED);
	}
}

public void DisplayAchivementsMenu(int iClient)
{
	Handle hMenu = CreateMenu(Handler_AchivementsMenu);
	SetMenuTitle(hMenu, "%t", "achievements menu: title");
	
	char sBuffer[64];
	FormatEx(SZF(sBuffer), "%t", "achievements menu: own achievements");
	AddMenuItem(hMenu, "own", sBuffer);
	FormatEx(SZF(sBuffer), "%t", "achievements menu: players achievements");
	AddMenuItem(hMenu, "players", sBuffer);
	FormatEx(SZF(sBuffer), "%t", "achievements menu: top");
	AddMenuItem(hMenu, "top", sBuffer);
	
	DisplayMenu(hMenu, iClient, MTF);
}

public void DisplayPlayersMenu(int iClient)
{
	Handle hMenu = CreateMenu(Handler_PlayersMenu);
	SetMenuTitle(hMenu, "%t", "players menu: title");
	
	char sUserId[8], sName[32];
	LC(i) {
		if ( !IsFakeClient(i) && !IsClientSourceTV(i) && i != iClient ) {
			IntToString(UID(i), SZF(sUserId));
			GetClientName(i, SZF(sName));
			AddMenuItem(hMenu, sUserId, sName);
		}
	}
	
	// if menu is empty
	if ( GetMenuItemCount(hMenu) == 0 ) {
		char sBuffer[64];
		FormatEx(SZF(sBuffer), "%t", "players menu: no other players");
		AddMenuItem(hMenu, "", sBuffer, ITEMDRAW_DISABLED);
	}
	
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, iClient, MTF);
}

public void DisplayAchivementsTypeMenu(int iClient, int iTarget)
{
	// new Handle:hMenu = CreateMenu(Handler_AchivementTypeMenu);
	// SetMenuTitle(hMenu, "%t", "achievements menu: title");
	
	// decl String:sBuffer[64];
	// FormatEx(SZF(sBuffer), "%t", "achievements type menu: in progress");
	// AddMenuItem(hMenu, "in progress", sBuffer);
	// FormatEx(SZF(sBuffer), "%t", "achievements type menu: completed");
	// AddMenuItem(hMenu, "completed", sBuffer);
	
	// SetMenuExitBackButton(hMenu, true);
	// DisplayMenu(hMenu, iClient, MTF);
	
	Handle hPanel = CreatePanel();
	
	char sBuffer[64], sName[32];
	GetClientName(iTarget, SZF(sName));
	FormatEx(SZF(sBuffer), "%t", "achievements type menu: title", sName);
	SetPanelTitle(hPanel, sBuffer);
	
	FormatEx(SZF(sBuffer), "%t", "achievements type menu: overall progress", 
		g_iCompletedAchievements[iTarget], g_iTotalAchievements, 
		(g_iCompletedAchievements[iTarget]/float(g_iTotalAchievements)*100));
	DrawPanelText(hPanel, sBuffer);
	
	FormatEx(SZF(sBuffer), "%t", "achievements type menu: in progress");
	DrawPanelItem(hPanel, sBuffer);
	FormatEx(SZF(sBuffer), "%t", "achievements type menu: completed");
	DrawPanelItem(hPanel, sBuffer);
	
	DrawPanelText(hPanel, " ");
	
	SetPanelCurrentKey(hPanel, g_iExitBackButtonSlot);
	FormatEx(SZF(sBuffer), "%t", "menu: back");
	DrawPanelItem(hPanel, sBuffer);
	
	DrawPanelText(hPanel, " ");
	
	SetPanelCurrentKey(hPanel, g_iExitButtonSlot);
	FormatEx(SZF(sBuffer), "%t", "menu: exit");
	DrawPanelItem(hPanel, sBuffer);
	
	SendPanelToClient(hPanel, iClient, Handler_AchivementTypeMenu, MTF);
	CloseHandle(hPanel);
}

void SQL_Callback_TopPlayers(Database database, DBResultSet result, const char[] error, int iClient)
{
    if(result == null)
    {
        LogError("SQL_Callback_TopPlayers: %s", error);
        return;
    }

    iClient = GetClientOfUserId(iClient);
    if(!iClient) return;

    char sBuffer[64], sName[64];
    Panel hPanel = new Panel();

	FormatEx(SZF(sBuffer), "%t", "top menu: title");
	SetPanelTitle(hPanel, sBuffer);

    int count = result.RowCount;

    for(int c = 1; c <= count; c++)
    {
        if(result.FetchRow())
        {
            result.FetchString(0, sName, sizeof(sName));
            FormatEx(sBuffer, sizeof(sBuffer), "%d. %s [%i]", c, sName, result.FetchInt(1));
            hPanel.DrawText(sBuffer);
        }
    }
    hPanel.DrawText(" ");

	SetPanelCurrentKey(hPanel, g_iExitBackButtonSlot);
	FormatEx(SZF(sBuffer), "%t", "menu: back");
	DrawPanelItem(hPanel, sBuffer);

	DrawPanelText(hPanel, " ");

	SetPanelCurrentKey(hPanel, g_iExitButtonSlot);
	FormatEx(SZF(sBuffer), "%t", "menu: exit");
	DrawPanelItem(hPanel, sBuffer);
    hPanel.Send(iClient, HandlerOfPanel, MENU_TIME_FOREVER);
    CloseHandle(hPanel);
}

public void DisplayInProgressMenu(int iClient, int iTarget, int iItem)
{
	if ( !g_hInProgressMenu[iTarget] ) {
		char sMessage[128];
		FormatEx(sMessage,sizeof sMessage,"%t", "client is not loaded");
		A_PrintToChat(iClient, sMessage);
		
		if ( iTarget == iClient ) {
			DisplayAchivementsMenu(iClient);
		}
		else {
			DisplayPlayersMenu(iClient);
		}
	}
	else {
		char sName[32];
		GetClientName(iTarget, SZF(sName));
		SetMenuTitle(g_hInProgressMenu[iTarget], "%t", "achievements in progress menu: title", sName);
		DisplayMenuAtItem(g_hInProgressMenu[iTarget], iClient, iItem, MTF);
	}
}

public void DisplayCompletedMenu(int iClient, int iTarget, int iItem)
{
	if ( !g_hCompletedMenu[iTarget] ) {
		char sMessage[128];
		FormatEx(sMessage,sizeof sMessage,"%t", "client is not loaded");
		A_PrintToChat(iClient, sMessage);
		
		if ( iTarget == iClient ) {
			DisplayAchivementsMenu(iClient);
		}
		else {
			DisplayPlayersMenu(iClient);
		}
	}
	else {
		char sName[32];
		GetClientName(iTarget, SZF(sName));
		SetMenuTitle(g_hCompletedMenu[iTarget], "%t", "completed achievements menu: title", sName);
		DisplayMenuAtItem(g_hCompletedMenu[iTarget], iClient, iItem, MTF);
	}
}

public void DisplayAchivementDetailsMenu(int iClient, int iTarget, const char[] sName)
{
	Handle hAchievementData;
	if ( !GetTrieValue(g_hTrie_AchievementData, sName, hAchievementData) ) {
		// this can't be, but maybe...
		LogError("???");
		return;
	}
	
	int iCount = (GetTrieValue(hAchievementData, "count", iCount)?iCount:-1);
	
	Handle hPanel = CreatePanel();
	
	char sClientName[32];
	GetClientName(iTarget, SZF(sClientName));
	
	char sBuffer[256], sTranslation[64];
	FormatEx(SZF(sBuffer), "%t", "achievement details menu: title", sClientName);
	SetPanelTitle(hPanel, sBuffer);
	
	FormatEx(SZF(sTranslation), "%s: name", sName);
	FormatEx(SZF(sBuffer), "%t%t", "achievement details menu: name", sTranslation);
	DrawPanelText(hPanel, sBuffer);
	
	FormatEx(SZF(sTranslation), "%s: description", sName);
	FormatEx(SZF(sBuffer), "%t%t", "achievement details menu: description", sTranslation, iCount);
	DrawPanelText(hPanel, sBuffer);
	
	FormatEx(SZF(sTranslation), "%s: reward", sName);
	FormatEx(SZF(sBuffer), "%t%t", "achievement details menu: reward", sTranslation);
	DrawPanelText(hPanel, sBuffer);
	
	int iBuffer;
	if ( !GetTrieValue(g_hTrie_ClientProgress[iTarget], sName, iBuffer) ) {
		iBuffer = 0;
	}
	
	if(iBuffer == -1)
		FormatEx(SZF(sBuffer), "%t", "achievement details menu: progress",iCount, iCount, (iCount/float(iCount))*100);
	else
		FormatEx(SZF(sBuffer), "%t", "achievement details menu: progress",iBuffer, iCount, (iBuffer/float(iCount))*100);
	DrawPanelText(hPanel, sBuffer);
	
	DrawPanelText(hPanel, " ");
	
	SetPanelCurrentKey(hPanel, g_iExitBackButtonSlot);
	FormatEx(SZF(sBuffer), "%t", "menu: back");
	DrawPanelItem(hPanel, sBuffer);
	
	DrawPanelText(hPanel, " ");
	
	SetPanelCurrentKey(hPanel, g_iExitButtonSlot);
	FormatEx(SZF(sBuffer), "%t", "menu: exit");
	DrawPanelItem(hPanel, sBuffer);
	
	SendPanelToClient(hPanel, iClient, Handler_ShowAchievementDetails, MTF);
	CloseHandle(hPanel);
}