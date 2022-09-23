// ==============================================================================================================================
// >>> GLOBAL INCLUDES
// ==============================================================================================================================
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <achievements>

// ==============================================================================================================================
// >>> PLUGIN INFORMATION
// ==============================================================================================================================

// ==============================================================================================================================
// >>> DEFINES
// ==============================================================================================================================
//#pragma newdecls required
#define MPS 		MAXPLAYERS+1
#define PMP 		PLATFORM_MAX_PATH
#define MTF 		MENU_TIME_FOREVER
#define CID(%0) 	GetClientOfUserId(%0)
#define UID(%0) 	GetClientUserId(%0)
#define SZF(%0) 	%0, sizeof(%0)
#define LC(%0) 		for (int %0 = 1; %0 <= MaxClients; ++%0) if ( IsClientInGame(%0) ) 

// debug stuff
#define DEBUG 1
#if defined DEBUG
stock DebugMessage(const  char[] message, any ...)
{
	char sMessage[256];
	VFormat(sMessage, sizeof(sMessage), message, 2);
	PrintToServer("[Debug] %s", sMessage);
}
#define DbgMsg(%0); DebugMessage(%0);
#else
#define DbgMsg(%0);
#endif

// ==============================================================================================================================
// >>> CONSOLE VARIABLES
// ==============================================================================================================================


// ==============================================================================================================================
// >>> GLOBAL VARIABLES
// ==============================================================================================================================		
ArrayList g_hArray_sAchievementNames;			// array with names
ArrayList g_hArray_sAchievementSound;
Handle g_hTrie_AchievementData;			// name -> event, executor, condition, count, reward
Handle g_hTrie_ClientProgress[MPS];		// name -> count
Handle g_hTrie_EventAchievements;			// event -> array with achievement names

Handle g_hCoreIsLoad;

StringMap hTriggers = null;
enum struct eTriggers
{
    Handle hPlugin;
	Function fncCallback;
}
eTriggers g_eTriggers[64];
int iTriggerNum;

//0 - Разминка(bool)
//1 - Конец раунда(bool)
//2 - Min Player
//3 - Notifacation Type
//4 - Server id
int g_iSettings[5];
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
    CreateNative("Achievements_RegisterTrigger", Native_RegTrigger);
	CreateNative("Achievements_CoreIsLoad", Native_CoreIsLoad);
	g_hCoreIsLoad = CreateGlobalForward("Achievements_OnCoreLoaded", ET_Ignore);
	RegPluginLibrary("achievements");
	return APLRes_Success;
}

public OnPluginStart() 
{	
    hTriggers = new StringMap();
	// load translations
	LoadTranslations("achievements_common.phrases.txt");
	LoadTranslations("achievements.phrases.txt");
	
	CreateDatabase();

	if ( GetEngineVersion() == Engine_CSGO ) {
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

public OnRound(Handle hEvent, const char[] sEventName, bool bDontBroadcast)
{
	if(sEventName[6] == 'e')
		IsRoundEnd = true;
	else
		IsRoundEnd = false;
}

void Achievements_OnCoreLoaded()
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
}

public void OnAllPluginsLoaded()
{
	LoadAchivements();
}

public void OnClientConnected(int iClient)
{
	if(!IsFakeClient(iClient))
		g_hTrie_ClientProgress[iClient] = CreateTrie();
}

public void OnClientPostAdminCheck(int iClient)
{
	if(IsClientInGame(iClient) && !IsFakeClient(iClient))
		LoadClient(iClient);
}

public void OnClientDisconnect(int iClient)
{
	CloseHandle(g_hTrie_ClientProgress[iClient]);
}

// ==============================================================================================================================
// >>> 
// ==============================================================================================================================
public Action Command_Achievements(int iClient, int iArgc)
{
	DisplayAchivementsMenu(iClient);
	return Plugin_Handled;
}
