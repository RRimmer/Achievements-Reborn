Handle g_hInProgressMenu[MPS][32];
Handle g_hGroupsMenu[MPS];
Handle g_hCompletedMenu[MPS];
int g_iCompletedAchievements[MPS];

public void CreateMenuGroups(int iClient)
{
	if(g_hTrie_GroupsAchievements != INVALID_HANDLE)
	{
		if ( !g_hGroupsMenu[iClient] ) {
			g_hGroupsMenu[iClient] = CreateMenu(Handler_ShowAchievementsGroup);
			SetMenuExitBackButton(g_hGroupsMenu[iClient], true);
		}
		RemoveAllMenuItems(g_hGroupsMenu[iClient]);
		Handle hTrie = CreateTrieSnapshot(g_hTrie_GroupsAchievements);
		char szKey[32],sBuffer[64];
		Handle hData;
		int iBuffer;
		for(int i = 0; i <= TrieSnapshotLength(hTrie)-1; i++)
		{
			GetTrieSnapshotKey(hTrie,i,SZF(szKey));
			GetTrieValue(g_hTrie_GroupsAchievements,szKey,hData);
			GetTrieValue(hData,"index",iBuffer);
			IntToString(iBuffer,SZF(sBuffer));
			AddMenuItem(g_hGroupsMenu[iClient],szKey, szKey);
			CreateProgressMenu(iClient, szKey, iBuffer);
		}
		CreateCompletedMenu(iClient);
	}
	else
	{
		// create|clear menu from previos use
		if ( !g_hInProgressMenu[iClient][0] ) {
			g_hInProgressMenu[iClient][0] = CreateMenu(Handler_ShowAchievements);
			SetMenuExitBackButton(g_hInProgressMenu[iClient][0], true);
		}
		RemoveAllMenuItems(g_hInProgressMenu[iClient][0]);
		
		// create|clear menu from previos use
		if ( !g_hCompletedMenu[iClient] ) {
			g_hCompletedMenu[iClient] = CreateMenu(Handler_ShowAchievements);
			SetMenuExitBackButton(g_hCompletedMenu[iClient], true);
		}
		RemoveAllMenuItems(g_hCompletedMenu[iClient]);
		
		// create progress menu
		g_iCompletedAchievements[iClient] = 0;
		Handle hAchievementData; 
		char sName[64],
			sBuffer[64];
		int	iCount, iBuffer;
		for ( int i = 0; i < g_iTotalAchievements; ++i ) {
			GetArrayString(g_hArray_sAchievementNames, i, SZF(sName));
			FormatEx(SZF(sBuffer), "%s: name", sName);
			Format(SZF(sBuffer), "%t", sBuffer);
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
				
				if ( iCount == -1 ) {
					AddMenuItem(g_hCompletedMenu[iClient], sName, sBuffer);
					g_iCompletedAchievements[iClient]++;
					continue;
				}
			}
			
			if(GetTrieValue(hAchievementData, "hide", iBuffer) && iBuffer == 0)
			{
				int iStyle;
				Action result = Fwd_AddItem(iClient,sName,iStyle);
				if(result == Plugin_Handled) continue;
				AddMenuItem(g_hInProgressMenu[iClient][0], sName, sBuffer, iStyle?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
			}
		}
		
		// if menu is empty
		if ( GetMenuItemCount(g_hInProgressMenu[iClient][0]) == 0 ) {
			
			FormatEx(SZF(sBuffer), "%t", "achievements in progress menu: empty");
			AddMenuItem(g_hInProgressMenu[iClient][0], "", sBuffer, ITEMDRAW_DISABLED);
		}
		
		// if menu is empty
		if ( GetMenuItemCount(g_hCompletedMenu[iClient]) == 0 ) {
			FormatEx(SZF(sBuffer), "%t", "completed achievements menu: empty");
			AddMenuItem(g_hCompletedMenu[iClient], "", sBuffer, ITEMDRAW_DISABLED);
		}
	}
}

public void CreateProgressMenu(int iClient, char[] sKey, int iIndex)
{
	// create|clear menu from previos use
	if ( !g_hInProgressMenu[iClient][iIndex] ) {
		g_hInProgressMenu[iClient][iIndex] = CreateMenu(Handler_ShowAchievements);
		SetMenuExitBackButton(g_hInProgressMenu[iClient][iIndex], true);
	}
	RemoveAllMenuItems(g_hInProgressMenu[iClient][iIndex]);
	
	Handle hAchievementData; 
	char sName[64],
		sBuffer[64];
	int	iCount, iBuffer;
	for(int i = 0; i <= g_hArray_GroupAchievements[iIndex].Length-1; i++)
	{
		g_hArray_GroupAchievements[iIndex].GetString(i,SZF(sName));

		FormatEx(SZF(sBuffer), "%s: name", sName);
		Format(SZF(sBuffer), "%t", sBuffer);
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
			
			if ( iCount == -1 ) continue;
		}
		
		if(GetTrieValue(hAchievementData, "hide", iBuffer) && iBuffer == 0)
		{
			int iStyle;
			Action result = Fwd_AddItem(iClient,sName,iStyle);
			if(result == Plugin_Handled) continue;
			AddMenuItem(g_hInProgressMenu[iClient][iIndex], sName, sBuffer, iStyle?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
		}
	}
	
	// if menu is empty
	if ( GetMenuItemCount(g_hInProgressMenu[iClient][iIndex]) == 0 ) {
		
		FormatEx(SZF(sBuffer), "%t", "achievements in progress menu: empty");
		AddMenuItem(g_hInProgressMenu[iClient][iIndex], "", sBuffer, ITEMDRAW_DISABLED);
	}
}

public void CreateCompletedMenu(int iClient)
{
	if ( !g_hCompletedMenu[iClient] ) {
		g_hCompletedMenu[iClient] = CreateMenu(Handler_ShowCompleteAchievements);
		SetMenuExitBackButton(g_hCompletedMenu[iClient], true);
	}
	RemoveAllMenuItems(g_hCompletedMenu[iClient]);
	
	g_iCompletedAchievements[iClient] = 0;
	Handle hAchievementData; 
	char sName[64],
		sBuffer[64];
	int	iCount, iBuffer;
	for ( int i = 0; i < g_iTotalAchievements; ++i ) {
		GetArrayString(g_hArray_sAchievementNames, i, SZF(sName));
		FormatEx(SZF(sBuffer), "%s: name", sName);
		Format(SZF(sBuffer), "%t", sBuffer);
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
			
			if ( iCount == -1 ) {
				AddMenuItem(g_hCompletedMenu[iClient], sName, sBuffer);
				g_iCompletedAchievements[iClient]++;
				continue;
			}
		}
	}
	
	// if menu is empty
	if ( GetMenuItemCount(g_hCompletedMenu[iClient]) == 0 ) {
		FormatEx(SZF(sBuffer), "%t", "completed achievements menu: empty");
		AddMenuItem(g_hCompletedMenu[iClient], "", sBuffer, ITEMDRAW_DISABLED);
	}
}

public void DisplayAchivementsMenu(int iClient)
{
	Handle hMenu = CreateMenu(Handler_AchivementsMenu);
	SetMenuTitle(hMenu, "%t", "achievements menu: title");
	
	char sBuffer[64];
	FormatEx(SZF(sBuffer), "%t\n \n", "achievements menu: inventory");
	AddMenuItem(hMenu, "inventory", sBuffer);
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

void SQL_Callback_InventoryPlayers(Database database, DBResultSet result, const char[] error, int iClient)
{
    if(result == null)
    {
        LogError("SQL_Callback_InventoryPlayers: %s", error);
        return;
    }

    iClient = GetClientOfUserId(iClient);
    if(!iClient) return;

	
    char sBuffer[64], sName[64];

	int count = result.RowCount;
	if(count == 0)
	{
		FormatEx(sBuffer,sizeof sBuffer,"%t", "InvEmpty");
		A_PrintToChat(iClient, sBuffer);
	}
    Menu hMenu = new Menu(Handler_AchivementInvMenu);

	hMenu.SetTitle("%t\n \n", "inventory menu: title");

    for(int c = 1; c <= count; c++)
    {
        if(result.FetchRow())
        {
            result.FetchString(0, sName, sizeof(sName));
			Format(SZF(sBuffer),"%s: reward",sName);
            Format(sBuffer, sizeof(sBuffer), "%t", sBuffer);
            hMenu.AddItem(sName,sBuffer);
        }
    }
	hMenu.ExitBackButton = true;
	hMenu.Display(iClient,0);
}

public void DisplayInGroupsMenu(int iClient, int iTarget)
{
	if(g_hTrie_GroupsAchievements != INVALID_HANDLE)
	{
		if ( !g_hGroupsMenu[iTarget] ) {
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
			SetMenuTitle(g_hGroupsMenu[iTarget], "%t", "achievements in progress menu: title", sName);
			DisplayMenu(g_hGroupsMenu[iTarget], iClient, MTF);
		}
	}
	else
		DisplayInProgressMenu(iClient,iTarget,0);
}

public void DisplayInProgressMenu(int iClient, int iTarget, int i)
{
	if ( !g_hInProgressMenu[iTarget][i] ) {
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
		SetMenuTitle(g_hInProgressMenu[iTarget][i], "%t", "achievements in progress menu: title", sName);
		DisplayMenu(g_hInProgressMenu[iTarget][i], iClient, MTF);
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
	
	int iCount;
	iCount = GetTrieValue(hAchievementData, "count", iCount)?iCount:-1;

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