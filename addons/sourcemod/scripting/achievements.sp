// ==============================================================================================================================
// >>> GLOBAL INCLUDES
// ==============================================================================================================================
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <achievements>
#include <morecolors>
#include <csgo_colors>

// ==============================================================================================================================
// >>> PLUGIN INFORMATION
// ==============================================================================================================================
#define PLUGIN_VERSION "R 1.0"
public Plugin myinfo =
{
	name 			= "[Achievements][Reborn] Core",
	author 			= "AlexTheRegent && Pisex",
	description 	= "",
	version 		= PLUGIN_VERSION,
	url 			= "https://hlmod.ru/resources/achievements-core.3936/"
}

// ==============================================================================================================================
// >>> CONSOLE VARIABLES
// ==============================================================================================================================


// ==============================================================================================================================
// >>> GLOBAL VARIABLES
// ==============================================================================================================================		
ArrayList g_hArray_sAchievementNames;			// array with names
ArrayList g_hArray_sAchievementSound;
Handle g_hKeyValues;
Handle g_hTrie_AchievementData;			// name -> event, executor, condition, count, reward
Handle g_hTrie_ClientProgress[MPS];		// name -> count
Handle g_hTrie_EventAchievements;			// event -> array with achievement names
EngineVersion g_EngineVersion;

Handle g_hCoreIsLoad,
	g_hInvAddItem,
	g_hRewardGiven,
	g_hRewardGivenPost,
	g_hEventWork,
	g_hAchAddMenu;

StringMap hTriggers = null;
enum struct eTriggers
{
    Handle hPlugin;
	Function fncCallback;
}
eTriggers g_eTriggers[64];
int iTriggerNum = 0;

//0 - Разминка(bool)
//1 - Конец раунда(bool)
//2 - Min Player
//3 - Notifacation Type
//4 - Server id
//5 - Continue
//6 - Reward_inv(bool)
int g_iSettings[7];
char g_sTag[128],
	g_sMapName[256];
bool IsRoundEnd,
	g_bLoaded;
// panel stuff
int
	g_iExitBackButtonSlot,
	g_iExitButtonSlot,
// total achievements count
	g_iTotalAchievements;

// ==============================================================================================================================
// >>> LOCAL INCLUDES
// ==============================================================================================================================
#include "achievements/menus.sp"
// CreateProgressMenu(iClient)
// DisplayAchivementsMenu(iClient)
// DisplayAchivementsTypeMenu(iClient)
// DisplayInProgressMenu(iClient, iTarget, iItem=0)
// DisplayCompletedMenu(iClient, iTarget, iItem=0)
// DisplayAchivementDetailsMenu(iClient, iTarget, const String:sName[])

#include "achievements/handlers.sp"
// menu handles 

#include "achievements/configuration.sp"
// LoadAchivements();

#include "achievements/sql.sp"
// CreateDatabase();
// LoadClient(iClient);
// LoadProgress(iClient);
// SaveProgress(iClient, const String:sName[]);

#include "achievements/events.sp"
// ProcessEvent(iClient, Handle:hEvent, const String:sEventName[])
#include "achievements/modules.sp"

#include "achievements/reward.sp"
// GiveReward(iClient, const String:sName[]);

// ==============================================================================================================================
// >>> FORWARDS
// ==============================================================================================================================
public APLRes AskPluginLoad2(Handle hMySelf, bool bLate, char[] sError, int iErrorMax)
{
    CreateNative("Achievements_RegisterTrigger", 	Native_RegTrigger);
	CreateNative("Achievements_CoreIsLoad", 		Native_CoreIsLoad);
	CreateNative("Achievements_GetDatabase", 		Native_GetDatabase);
	CreateNative("Achievements_GetKV", 				Native_GetKV);
	CreateNative("Achievements_GetNames",			Native_GetEventNames);
	CreateNative("Achievements_GetInfo",			Native_GetInfo);
	CreateNative("Achievements_ReconstructMenu",	Native_ReconstructMenu);
	CreateNative("Achievements_GetClientInfo",		Native_GetClientInfo);
	g_hCoreIsLoad = CreateGlobalForward("Achievements_OnCoreLoaded", ET_Ignore);
	g_hRewardGivenPost = CreateGlobalForward("Achievements_RewardGiven_Post", ET_Ignore, Param_Cell, Param_String);
	g_hRewardGiven = CreateGlobalForward("Achievements_RewardGiven", ET_Ignore, Param_Cell, Param_String);
	g_hInvAddItem = CreateGlobalForward("Achievements_InventoryItemAdd", ET_Ignore, Param_Cell, Param_String);
	g_hEventWork = CreateGlobalForward("Achievements_Event", ET_Hook, Param_Cell, Param_String);
	g_hAchAddMenu = CreateGlobalForward("Achievements_AddMenu", ET_Hook, Param_Cell, Param_String, Param_CellByRef);
	RegPluginLibrary("achievements");
	return APLRes_Success;
}

public void OnPluginStart() 
{	
    hTriggers = new StringMap();
	// load translations
	LoadTranslations("achievements_common.phrases.txt");
	LoadTranslations("achievements.phrases.txt");
	
	CreateDatabase();
	g_EngineVersion = GetEngineVersion();
	if ( g_EngineVersion == Engine_CSGO ) {
		g_iExitBackButtonSlot = 7;
		g_iExitButtonSlot = 9;
	}
	else {
		g_iExitBackButtonSlot = 8;
		g_iExitButtonSlot = 10;
	}
	HookEvent("round_end",OnRound);
	HookEvent("round_start",OnRound);
}

public void OnRound(Handle hEvent, const char[] sEventName, bool bDontBroadcast)
{
	if(sEventName[6] == 'e')
		IsRoundEnd = true;
	else
		IsRoundEnd = false;
}

public void Ach_OnCoreLoaded()
{
	g_bLoaded = true;
	Call_StartForward(g_hCoreIsLoad);
	Call_Finish();
}

public void OnMapStart()
{
	for(int i = 0; i <= g_hArray_sAchievementSound.Length - 1; i++)
	{
		char sBuffer[128];
		g_hArray_sAchievementSound.GetString(i,SZF(sBuffer));
		if(sBuffer[0])
		{
			char Sound[128];
			FormatEx(Sound,sizeof Sound,"sound/%s",sBuffer);
			AddFileToDownloadsTable(Sound);
			PrecacheSound(sBuffer, true);
		}
	}
	GetCurrentMap(g_sMapName,sizeof g_sMapName);
}

public void OnAllPluginsLoaded()
{
	LoadAchivements();
}

public void OnClientPostAdminCheck(int iClient)
{
	if(IsClientInGame(iClient) && !IsFakeClient(iClient))
	{
		g_hTrie_ClientProgress[iClient] = CreateTrie();
		LoadClient(iClient);
	}
}

public void OnClientDisconnect(int iClient)
{
	if(g_hTrie_ClientProgress[iClient]) delete g_hTrie_ClientProgress[iClient];
}

// ==============================================================================================================================
// >>> 
// ==============================================================================================================================
public Action Command_Achievements(int iClient, int iArgc)
{
	DisplayAchivementsMenu(iClient);
	return Plugin_Handled;
}

public void A_PrintToChat(int iClient, const char[] sMessage) {
    switch(g_EngineVersion) {
        case Engine_SourceSDK2006: CPrintToChat(iClient, "%s %s", g_sTag, sMessage);
        case Engine_CSS: CPrintToChat(iClient, "%s %s", g_sTag, sMessage);
        case Engine_CSGO: CGOPrintToChat(iClient, "%s %s", g_sTag, sMessage);
    }
}

public void A_PrintToChatAll(const char[] sMessage) {
    switch(g_EngineVersion) {
        case Engine_SourceSDK2006: CPrintToChatAll("%s %s", g_sTag, sMessage);
        case Engine_CSS: CPrintToChatAll("%s %s", g_sTag, sMessage);
        case Engine_CSGO: CGOPrintToChatAll("%s %s", g_sTag, sMessage);
    }
}

public void OnMapEnd()
{
	iTriggerNum = 0;
}