int g_iViewTarget[MPS];
int	g_iLastMenuType[MPS];
int	g_iLastMenuSelection[MPS];
int g_iLastGroup[MPS];

public int Handler_AchivementsMenu(Menu hMenu, MenuAction action, int iClient, int iSlot)
{
	switch ( action ) {
		case MenuAction_Select: {
			char sInfo[32];
			GetMenuItem(hMenu, iSlot, SZF(sInfo));
			
			if ( strcmp(sInfo, "own") == 0 ) {
				g_iViewTarget[iClient] = UID(iClient);
				DisplayAchivementsTypeMenu(iClient, iClient);
			}
			else if ( strcmp(sInfo, "players") == 0 ) {
				DisplayPlayersMenu(iClient);
			}
			else if ( strcmp(sInfo, "top") == 0 ) {
				DisplayPlayersTopMenu(iClient);
			}
			else if ( strcmp(sInfo, "inventory") == 0 ) {
				DisplayInventory(iClient);
			}
			else {
				LogError("Invalid menu selection \"%s\" (slot %d)", sInfo, iSlot);
			}
		}
		
		case MenuAction_End: {
			CloseHandle(hMenu);
		}
	}
	return 0;
}

public int Handler_PlayersMenu(Menu hMenu, MenuAction action, int iClient, int iSlot)
{
	switch ( action ) {
		case MenuAction_Select: {
			char sInfo[32];
			GetMenuItem(hMenu, iSlot, SZF(sInfo));
			
			int iUserId = StringToInt(sInfo), 
				iTarget = CID(iUserId);
			
			if ( iTarget ) {
				g_iViewTarget[iClient] = iUserId;
				DisplayAchivementsTypeMenu(iClient, iTarget);
			}
			else {
				char sMessage[128];
				FormatEx(sMessage,sizeof sMessage,"%t", "players menu: player left");
				A_PrintToChat(iClient, sMessage);
				DisplayPlayersMenu(iClient);
			}
		}
		
		case MenuAction_Cancel: {
			if ( iSlot == MenuCancel_ExitBack ) {
				DisplayAchivementsMenu(iClient);
			}
		}
		
		case MenuAction_End: {
			CloseHandle(hMenu);
		}
	}
	return 0;
}

public int Handler_AchivementInvMenu(Menu hMenu, MenuAction action, int iClient, int iSlot)
{
	switch ( action ) {
		case MenuAction_Select: {
			char sInfo[64];
			GetMenuItem(hMenu, iSlot, SZF(sInfo));
			RemoveReward(iClient,sInfo);
			DisplayInventory(iClient);
		}
		case MenuAction_Cancel:
		{
			if (iSlot == MenuCancel_ExitBack)
			{
				DisplayAchivementsMenu(iClient);
			}
		}
	}
	return 0;
}

public int Handler_AchivementTypeMenu(Menu hMenu, MenuAction action, int iClient, int iSlot)
{
	switch ( action ) {
		case MenuAction_Select: {
			if ( iSlot == g_iExitButtonSlot ) {
				// do nothing
			}
			else {
				int iTarget = CID(g_iViewTarget[iClient]);
				if ( iTarget ) {
					if ( iSlot == 1 ) {
						g_iLastMenuType[iClient] = 1;
						DisplayInGroupsMenu(iClient, iTarget);
					}
					else if ( iSlot == 2 ) {
						g_iLastMenuType[iClient] = 2;
						DisplayCompletedMenu(iClient, iTarget,0);
					}
					else if ( iSlot == g_iExitBackButtonSlot ) {
						if ( iTarget == iClient ) {
							DisplayAchivementsMenu(iClient);
						}
						else {
							DisplayPlayersMenu(iClient);
						}
					}
					else {
						LogError("Invalid menu selection (slot %d)", iSlot);
					}
					
				}
				else {
					char sMessage[128];
					FormatEx(sMessage,sizeof sMessage,"%t", "players menu: player left");
					A_PrintToChat(iClient, sMessage);
					DisplayPlayersMenu(iClient);
				}
			}
			
			
		}
	}
	return 0;
}

public int Handler_ShowCompleteAchievements(Menu hMenu, MenuAction action, int iClient, int iSlot)
{
	switch ( action ) {		
		case MenuAction_Select: {
			char sInfo[64];
			GetMenuItem(hMenu, iSlot, SZF(sInfo));
			
			int iTarget = CID(g_iViewTarget[iClient]);
			if ( iTarget ) {
				DisplayAchivementDetailsMenu(iClient, iTarget, sInfo);
				g_iLastMenuSelection[iClient] = GetMenuSelectionPosition();
			}
			else {
				char sMessage[128];
				FormatEx(sMessage,sizeof sMessage,"%t", "players menu: player left");
				A_PrintToChat(iClient, sMessage);
				DisplayPlayersMenu(iClient);
			}
		}
		
		case MenuAction_Cancel: {
			if ( iSlot == MenuCancel_ExitBack ) {
				int iTarget = CID(g_iViewTarget[iClient]);
				if ( iTarget ) {
					DisplayAchivementsTypeMenu(iClient,iTarget);
				}
				else {
					char sMessage[128];
					FormatEx(sMessage,sizeof sMessage,"%t", "players menu: player left");
					A_PrintToChat(iClient, sMessage);
					DisplayPlayersMenu(iClient);
				}
			}
		}
	}
	return 0;
}

public int Handler_ShowAchievements(Menu hMenu, MenuAction action, int iClient, int iSlot)
{
	switch ( action ) {		
		case MenuAction_Select: {
			char sInfo[64];
			GetMenuItem(hMenu, iSlot, SZF(sInfo));
			
			int iTarget = CID(g_iViewTarget[iClient]);
			if ( iTarget ) {
				DisplayAchivementDetailsMenu(iClient, iTarget, sInfo);
				g_iLastMenuSelection[iClient] = GetMenuSelectionPosition();
			}
			else {
				char sMessage[128];
				FormatEx(sMessage,sizeof sMessage,"%t", "players menu: player left");
				A_PrintToChat(iClient, sMessage);
				DisplayPlayersMenu(iClient);
			}
		}
		
		case MenuAction_Cancel: {
			if ( iSlot == MenuCancel_ExitBack ) {
				int iTarget = CID(g_iViewTarget[iClient]);
				if ( iTarget ) {
					if(g_hTrie_GroupsAchievements != INVALID_HANDLE) DisplayInGroupsMenu(iClient,iTarget);
					else DisplayAchivementsTypeMenu(iClient, iClient);
				}
				else {
					char sMessage[128];
					FormatEx(sMessage,sizeof sMessage,"%t", "players menu: player left");
					A_PrintToChat(iClient, sMessage);
					DisplayPlayersMenu(iClient);
				}
			}
		}
	}
	return 0;
}

public int Handler_ShowAchievementsGroup(Menu hMenu, MenuAction action, int iClient, int iSlot)
{
	switch ( action ) {
		case MenuAction_Select: {
			char sIndex[64],sBuffer[64];
			Handle hData;
			GetMenuItem(hMenu, iSlot, SZF(sIndex),_,SZF(sBuffer));
			GetTrieValue(g_hTrie_GroupsAchievements,sIndex,hData);
			GetTrieValue(hData,"index",g_iLastGroup[iClient]);
			DisplayInProgressMenu(iClient, iClient, g_iLastGroup[iClient]);
		}
		case MenuAction_Cancel: {
			if ( iSlot == MenuCancel_ExitBack ) {
				int iTarget = CID(g_iViewTarget[iClient]);
				if ( iTarget ) {
					DisplayAchivementsTypeMenu(iClient, iTarget);
				}
				else {
					char sMessage[128];
					FormatEx(sMessage,sizeof sMessage,"%t", "players menu: player left");
					A_PrintToChat(iClient, sMessage);
					DisplayPlayersMenu(iClient);
				}
			}
		}
	}
	return 0;
}

public int Handler_ShowAchievementDetails(Menu hMenu, MenuAction action, int iClient, int iSlot)
{
	switch ( action ) {
		case MenuAction_Select: {
			if( iSlot == 6)
			{
				if(g_hArray_Notif[iClient].FindString(g_sLastAch[iClient]) != -1) g_hArray_Notif[iClient].Erase(g_hArray_Notif[iClient].FindString(g_sLastAch[iClient]));
				else
				{
					if(g_hArray_Notif[iClient].Length < 32) g_hArray_Notif[iClient].PushString(g_sLastAch[iClient]);
					else
					{
						char sMessage[128];
						FormatEx(sMessage,sizeof sMessage,"%t", "message_maxhud");
						A_PrintToChat(iClient, sMessage);
					}
				}
				DisplayAchivementDetailsMenu(iClient, iClient, g_sLastAch[iClient]);
			}
			else if ( iSlot == g_iExitBackButtonSlot ) {
				int iTarget = CID(g_iViewTarget[iClient]);
				
				if ( iTarget ) {
					switch (g_iLastMenuType[iClient]) {
						case 1: {
							DisplayInProgressMenu(iClient, iTarget, g_iLastGroup[iClient]);
						}
						
						case 2: {
							DisplayCompletedMenu(iClient, iTarget, g_iLastMenuSelection[iClient]);
						}
						
						default: {
							LogError("Invalid menu type %d", g_iLastMenuType[iClient]);
							g_iLastMenuType[iClient] = 0;
						}
					}
				}
				else {
					char sMessage[128];
					FormatEx(sMessage,sizeof sMessage,"%t", "players menu: player left");
					A_PrintToChat(iClient, sMessage);
					DisplayPlayersMenu(iClient);
				}
			}
			else if ( iSlot == g_iExitButtonSlot ) {
				
			}
		}
	}
	return 0;
}

public int HandlerOfPanel(Menu hMenu, MenuAction action, int iClient, int iSlot)
{
	switch ( action ) {
		case MenuAction_Select: {
			if ( iSlot == g_iExitButtonSlot ) {
				// do nothing
			}
			else if(iSlot == g_iExitBackButtonSlot)
			{
				DisplayAchivementsMenu(iClient);
			}
		}
	}
	return 0;
}