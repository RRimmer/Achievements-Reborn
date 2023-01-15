Database g_hSQLdb;

char g_sAuth[MPS][32];

int g_iClientId[MPS];

public int Native_GetDatabase(Handle hPlugin, int iNumParams)
{
	return view_as<int>(CloneHandle(g_hSQLdb, hPlugin));
}

void CreateDatabase()
{
	if (SQL_CheckConfig("achievements")) {
		Database.Connect(OnDBConnect, "achievements");
	}
	else {
		char sError[256];
		g_hSQLdb = SQLite_UseDatabase("achievements", SZF(sError));
		if (!g_hSQLdb) {
			LogError("SQLite_UseDatabase failure: \"%s\"", sError);
			SetFailState("SQLite_UseDatabase failure: \"%s\"", sError);
		}
		
		CreateTables();
	}
}

public void OnDBConnect(Database hDatabase, const char[] sError, any data)
{
	if (!hDatabase) // Соединение неудачное
	{
		SetFailState("Database failure: %s", sError);
		return;
	}
	
	g_hSQLdb = hDatabase;
	CreateTables();
}

void CreateTables()
{
	char driver[16], query[1024];
	DBDriver Driver = g_hSQLdb.Driver;
	
	Driver.GetIdentifier(driver, sizeof(driver));
	
	if (driver[0] == 'm')
	{
		FormatEx(query, sizeof(query), "CREATE TABLE IF NOT EXISTS `ach_progress`(\
																`id` INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT,\
																`auth` VARCHAR(32) NOT NULL,\
																`name` VARCHAR(64) NOT NULL,\
																`completed` INTEGER NOT NULL,\
																`server_id` INTEGER NOT NULL);");
		g_hSQLdb.Query(SQL_CheckError, query);
		
		FormatEx(query, sizeof(query), "CREATE TABLE IF NOT EXISTS `ach_inventory` (\
																`id` INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT,\
																`client_id` INTEGER NOT NULL,\
																`ach_name` VARCHAR(64) NOT NULL);");
		g_hSQLdb.Query(SQL_CheckError, query);
		g_hSQLdb.SetCharset("utf8");
	}
	else if (driver[0] == 's')
	{
		SQL_LockDatabase(g_hSQLdb);
		
		FormatEx(query, sizeof(query), "CREATE TABLE IF NOT EXISTS `ach_progress`(\
																`id` INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,\
																`auth` VARCHAR(32) NOT NULL,\
																`name` VARCHAR(64) NOT NULL,\
																`completed` INTEGER NOT NULL,\
																`server_id` INTEGER NOT NULL);");
		g_hSQLdb.Query(SQL_CheckError, query);
		
		FormatEx(query, sizeof(query), "CREATE TABLE IF NOT EXISTS `ach_inventory` (\
																`id` INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,\
																`client_id` INTEGER NOT NULL,\
																`ach_name` VARCHAR(64) NOT NULL);");
		
		g_hSQLdb.Query(SQL_CheckError, query);
		g_hSQLdb.SetCharset("utf8");
		SQL_UnlockDatabase(g_hSQLdb);
	}
	
	char sBuffer[128];
	for (int i = 0; i < g_hArray_sAchievementNames.Length; i++)
	{
		g_hArray_sAchievementNames.GetString(i, sBuffer, sizeof sBuffer);
		g_hSQLdb.Format(SZF(query), "ALTER TABLE `ach_progress` ADD `%s` INTEGER NOT NULL;", sBuffer);
		g_hSQLdb.Query(SQL_CheckError2, query);
	}
	LC(i) {
		OnClientPostAdminCheck(i);
	}
}

public void SQL_CheckError(Database hDatabase, DBResultSet results, const char[] szError, any data) // проверка ошибки нету ли ошибок
{
	if (szError[0])LogError("SQL_Callback_CheckError: %s", szError);
}

public void SQL_CheckError2(Database hDatabase, DBResultSet results, const char[] szError, any data) // проверка ошибки нету ли ошибок
{  }

void LoadClient(int iClient)
{
	if (!IsFakeClient(iClient))
	{
		GetClientAuthId(iClient, AuthId_Steam2, g_sAuth[iClient], sizeof(g_sAuth));
		
		char sQuery[256];
		g_hSQLdb.Format(SZF(sQuery), "SELECT `id` FROM `ach_progress` WHERE `auth` = '%s' AND `server_id` = '%i' LIMIT 1;", g_sAuth[iClient], g_iSettings[4]);
		g_hSQLdb.Query(SQLT_OnLoadClient, sQuery, UID(iClient));
	}
}

public void SQLT_OnLoadClient(Handle hOwner, Handle hQuery, const char[] sError, any iUserId)
{
	if (!hQuery) {
		LogError("SQLT_OnLoadClient failure: \"%s\"", sError);
		return;
	}
	
	int iClient = CID(iUserId);
	if (!iClient)return;
	
	if (SQL_FetchRow(hQuery)) {
		g_iClientId[iClient] = SQL_FetchInt(hQuery, 0);
		LoadProgress(iClient);
	}
	else {
		char sQuery[256];
		g_hSQLdb.Format(SZF(sQuery), "INSERT INTO `ach_progress` (`auth`,`server_id`,`name`) VALUES ('%s', '%i','%N')", g_sAuth[iClient], g_iSettings[4], iClient);
		g_hSQLdb.Query(SQLT_OnSaveClient, sQuery, iUserId);
	}
}

public void SQLT_OnSaveClient(Handle hOwner, Handle hQuery, const char[] sError, any iUserId)
{
	if (!hQuery) {
		LogError("SQLT_OnSaveClient failure: \"%s\"", sError);
		return;
	}
	
	int iClient = CID(iUserId);
	if (!iClient)return;
	
	LoadClient(iClient);
}

void LoadProgress(int iClient)
{
	char sBuffer[64], 
	sQuery[1024 * 32], 
	fieldNames[1024 * 32];
	
	if (g_hArray_sAchievementNames.Length == 0)return;
	
	int length = g_hArray_sAchievementNames.Length;
	for (int i = 0; i < length; i++)
	{
		g_hArray_sAchievementNames.GetString(i, sBuffer, sizeof sBuffer);
		Format(fieldNames, sizeof fieldNames, "%s`%s`,", fieldNames, sBuffer);
	}
	
	fieldNames[strlen(fieldNames) - 1] = '\0'; // erase last comma
	
	g_hSQLdb.Format(SZF(sQuery), "SELECT %s FROM `ach_progress` WHERE `id` = %d AND `server_id` = %d;", fieldNames, g_iClientId[iClient], g_iSettings[4]);
	g_hSQLdb.Query(SQLT_OnLoadProgress, sQuery, UID(iClient));
}

public void SQLT_OnLoadProgress(Handle hOwner, Handle hQuery, const char[] sError, any iUserId)
{
	if (!hQuery) {
		LogError("SQLT_OnLoadProgress failure: \"%s\"", sError);
		return;
	}
	
	int iClient = CID(iUserId);
	if (!iClient)return;
	char sName[64], iCount;
	if (SQL_FetchRow(hQuery))
	{
		Handle progressTrie = g_hTrie_ClientProgress[iClient];
		for (int i = 0; i < g_hArray_sAchievementNames.Length; i++)
		{
			iCount = SQL_FetchInt(hQuery, i);
			
			g_hArray_sAchievementNames.GetString(i, sName, sizeof sName);
			SetTrieValue(progressTrie, sName, iCount);
		}
		CreateMenuGroups(iClient);
	}
	
}

void SaveProgressAll(int iClient)
{
	int iCount;
	char sBuffer[64], 
	sQuery[256];
	
	Transaction hTransaction = new Transaction();
	for (int i = 0; i < g_hArray_sAchievementNames.Length; i++)
	{
		g_hArray_sAchievementNames.GetString(i, sBuffer, sizeof sBuffer);
		GetTrieValue(g_hTrie_ClientProgress[iClient], sBuffer, iCount);
		g_hSQLdb.Format(SZF(sQuery), "UPDATE `ach_progress` SET `%s` = %d WHERE `id` = %d AND `server_id` = '%i';", sBuffer, iCount, g_iClientId[iClient], g_iSettings[4]);
		hTransaction.AddQuery(sQuery);
	}
	g_hSQLdb.Execute(hTransaction, SQLT_OnUpdateProgress, SQL_TransactionFailure, _, DBPrio_High);
}

void RemoveReward(int iClient, char[] sInfo)
{
	char sQuery[256];
	g_hSQLdb.Format(SZF(sQuery), "DELETE FROM `ach_inventory` WHERE `client_id` = '%d'  AND `ach_name` = '%s';", g_iClientId[iClient], sInfo);
	g_hSQLdb.Query(SQLT_OnCheckError, sQuery);
}

void SaveProgressCompleted(int iClient)
{
	char sQuery[256];
	g_hSQLdb.Format(SZF(sQuery), "UPDATE `ach_progress` SET `completed` = `completed`+ 1 WHERE `id` = %d AND `server_id` = '%i';", g_iClientId[iClient], g_iSettings[4]);
	g_hSQLdb.Query(SQLT_OnUpdateProgress2, sQuery);
}

public void SQLT_OnInsertProgress(Handle hOwner, Handle hQuery, const char[] sError, any hDatapack)
{
	if (!hQuery) {
		LogError("SQLT_OnInsertProgress failure: \"%s\"", sError);
	}
}

public void SQLT_OnCheckError(Handle hOwner, Handle hQuery, const char[] sError, any iUserId)
{
	if (!hQuery) {
		LogError("SQLT_OnCheckError failure: \"%s\"", sError);
		return;
	}
}

void AddItemInventory(int iClient, char[] sName)
{
	char sQuery[256];
	g_hSQLdb.Format(SZF(sQuery), "INSERT INTO `ach_inventory` (`client_id`,`ach_name`) VALUES ('%i', '%s')", g_iClientId[iClient], sName);
	g_hSQLdb.Query(SQLT_AddInventoryItem, sQuery, UID(iClient));
	
	Call_StartForward(g_hInvAddItem);
	Call_PushCell(iClient);
	Call_PushString(sName);
	Call_Finish();
}

public void SQLT_AddInventoryItem(Handle hOwner, Handle hQuery, const char[] sError, any hDatapack)
{
	if (!hQuery) {
		LogError("SQLT_AddInventoryItem failure: \"%s\"", sError);
	}
}

public void SQLT_OnUpdateProgress2(Handle hOwner, Handle hQuery, const char[] sError, any hDatapack)
{
	if (!hQuery) {
		LogError("SQLT_AddInventoryItem failure: \"%s\"", sError);
	}
}

public void SQLT_OnUpdateProgress(Database hDatabase, int iType, int iQueries, DBResultSet[] hResults, int[] iQueryData) {  }

void SQL_TransactionFailure(Database hDatabase, int iData, int iNumQueries, const char[] sError, int iFailIndex, int[] iQueryData)
{
	if (iFailIndex)
	{
		LogError("SQL_TransactionFailure (%i): %s (%i)", iData, sError, iFailIndex);
	}
}

public void DisplayPlayersTopMenu(int iClient)
{
	char query[256];
	g_hSQLdb.Format(query, sizeof(query), "SELECT `name`, `completed` FROM `ach_progress` ORDER BY `completed` DESC LIMIT 10;");
	g_hSQLdb.Query(SQL_Callback_TopPlayers, query, GetClientUserId(iClient));
}

public void DisplayInventory(int iClient)
{
	char sQuery[256];
	g_hSQLdb.Format(SZF(sQuery), "SELECT `ach_name` FROM `ach_inventory` WHERE `client_id` = %d;", g_iClientId[iClient]);
	g_hSQLdb.Query(SQL_Callback_InventoryPlayers, sQuery, GetClientUserId(iClient));
} 