Database g_hSQLdb;

char	g_sAuth[MPS][32];

int	g_iClientId[MPS];

CreateDatabase()
{
	if ( SQL_CheckConfig("achievements") ) {
		// SQL_TConnect(SQLT_OnConnect, "achievements");
		Database.Connect(OnDBConnect, "achievements");
	}
	else {
		char sError[256];
		g_hSQLdb = SQLite_UseDatabase("achievements", SZF(sError));
		if ( !g_hSQLdb ) {
			LogError("SQLite_UseDatabase failure: \"%s\"", sError);
			SetFailState("SQLite_UseDatabase failure: \"%s\"", sError);
		}
		
		CreateTables();
	}
}

public void OnDBConnect(Database hDatabase, const char[] sError, any data)
{
	if(!hDatabase)	// Соединение неудачное
	{
		SetFailState("Database failure: %s", sError);
		return;
	}

	g_hSQLdb = hDatabase;
	CreateTables();
}

CreateTables()
{
	char driver[16],query[1024];
    DBDriver Driver = g_hSQLdb.Driver;
    
    Driver.GetIdentifier(driver, sizeof(driver));

	if(driver[0] == 'm')
    {
		FormatEx(query, sizeof(query),		"CREATE TABLE IF NOT EXISTS `clients`(\
																`id` INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT,\
																`auth` VARCHAR(32) NOT NULL,\
																`server_id` INTEGER NOT NULL);");
		g_hSQLdb.Query(SQL_CheckError, query);

		FormatEx(query, sizeof(query),		"CREATE TABLE IF NOT EXISTS `progress` (\
																`id` INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT,\
																`client_id` INTEGER NOT NULL,\
																`achievement` VARCHAR(64) NOT NULL,\
																`count` INTEGER NOT NULL,\
																`server_id` INTEGER NOT NULL);");
		g_hSQLdb.Query(SQL_CheckError, query);
		g_hSQLdb.SetCharset("utf8");
	}
	else if(driver[0] == 's')
    {
		SQL_LockDatabase(g_hSQLdb);

		FormatEx(query, sizeof(query),		"CREATE TABLE IF NOT EXISTS `clients`(\
																`id` INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,\
																`auth` VARCHAR(32) NOT NULL,\
																`server_id` INTEGER NOT NULL);");
		g_hSQLdb.Query(SQL_CheckError, query);

		FormatEx(query, sizeof(query),		"CREATE TABLE IF NOT EXISTS `progress` (\
																`id` INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,\
																`client_id` INTEGER NOT NULL,\
																`achievement` VARCHAR(64) NOT NULL,\
																`count` INTEGER NOT NULL,\
																`server_id` INTEGER NOT NULL);");

		g_hSQLdb.Query(SQL_CheckError, query);
		g_hSQLdb.SetCharset("utf8");
        SQL_UnlockDatabase(g_hSQLdb);
	}

	Achievements_OnCoreLoaded();
	LC(i) {
		OnClientConnected(i);
		OnClientPostAdminCheck(i);
	}
}

public void SQL_CheckError(Database hDatabase, DBResultSet results, const char[] szError, any data) // проверка ошибки нету ли ошибок
{
	if(szError[0]) LogError("SQL_Callback_CheckError: %s", szError);
}

public SQLT_OnCreateTables(Handle hOwner, Handle hQuery, const char[] sError, any data)
{
	if ( !hQuery ) {
		LogError("SQLT_OnCreateTables failure: \"%s\"", sError);
		SetFailState("SQLT_OnCreateTables failure: \"%s\"", sError);
	}
}

LoadClient(iClient)
{
	if(!IsFakeClient(iClient))
	{
		GetClientAuthId(iClient, AuthId_Steam2, g_sAuth[iClient], sizeof(g_sAuth));
		
		char sQuery[256];
		FormatEx(SZF(sQuery), "SELECT `id` FROM `clients` WHERE `auth` = '%s' AND `server_id` = '%i' LIMIT 1;", g_sAuth[iClient], g_iSettings[4]);
		SQL_TQuery(g_hSQLdb, SQLT_OnLoadClient, sQuery, UID(iClient));
	}
}

public SQLT_OnLoadClient(Handle hOwner, Handle hQuery, const char[] sError, any iUserId)
{
	if ( !hQuery ) {
		LogError("SQLT_OnLoadClient failure: \"%s\"", sError);
		return;
	}
	
	int iClient = CID(iUserId);
	if ( !iClient ) return;
	
	if ( SQL_FetchRow(hQuery) ) {
		g_iClientId[iClient] = SQL_FetchInt(hQuery, 0);
		LoadProgress(iClient);
	}
	else {
		char sQuery[256];
		FormatEx(SZF(sQuery), "INSERT INTO `clients` (`auth`,`server_id`) VALUES ('%s', '%i')", g_sAuth[iClient],g_iSettings[4]);
		SQL_TQuery(g_hSQLdb, SQLT_OnSaveClient, sQuery, iUserId);
	}
}

public SQLT_OnSaveClient(Handle hOwner, Handle hQuery, const char[] sError, any iUserId)
{
	if ( !hQuery ) {
		LogError("SQLT_OnSaveClient failure: \"%s\"", sError);
		return;
	}
	
	int iClient = CID(iUserId);
	if ( !iClient ) return;
	
	LoadClient(iClient);
}

LoadProgress(iClient)
{
	char sQuery[256];
	FormatEx(SZF(sQuery), "SELECT `achievement`, `count` FROM `progress` WHERE `client_id` = %d AND `server_id`;", g_iClientId[iClient],g_iSettings[4]);
	SQL_TQuery(g_hSQLdb, SQLT_OnLoadProgress, sQuery, UID(iClient));
}

public SQLT_OnLoadProgress(Handle hOwner, Handle hQuery, const char[]sError, any iUserId)
{
	if ( !hQuery ) {
		LogError("SQLT_OnLoadProgress failure: \"%s\"", sError);
		return;
	}
	
	int iClient = CID(iUserId);
	if ( !iClient ) return;
	
	char sName[64], iCount;
	while ( SQL_FetchRow(hQuery) ) {
		SQL_FetchString(hQuery, 0, SZF(sName));
		iCount = SQL_FetchInt(hQuery, 1);
		
		SetTrieValue(g_hTrie_ClientProgress[iClient], sName, iCount);
	}
	
	CreateProgressMenu(iClient);
}

SaveProgress(int iClient, const char[] sName, bool bUpdate)
{
	int iCount;
	GetTrieValue(g_hTrie_ClientProgress[iClient], sName, iCount);
	
	char sQuery[256];
	if ( bUpdate ) {
		FormatEx(SZF(sQuery), "UPDATE `progress` SET `count` = %d WHERE `client_id` = %d AND `achievement` = '%s' AND `server_id` = '%i';", iCount, g_iClientId[iClient], sName,g_iSettings[4]);
		SQL_TQuery(g_hSQLdb, SQLT_OnUpdateProgress, sQuery);
	}
	else {
		FormatEx(SZF(sQuery), "INSERT INTO `progress` (`client_id`, `achievement`, `count`, `server_id`) VALUES (%d, '%s', %d, %i);", g_iClientId[iClient], sName, iCount,g_iSettings[4]);
		SQL_TQuery(g_hSQLdb, SQLT_OnInsertProgress, sQuery);
	}
	
}

public void SQLT_OnInsertProgress(Handle hOwner, Handle hQuery, const char[] sError, any hDatapack)
{
	if ( !hQuery ) {
		LogError("SQLT_OnInsertProgress failure: \"%s\"", sError);
	}
}

public void SQLT_OnUpdateProgress(Handle hOwner, Handle hQuery, const char[] sError, any hDatapack)
{
	if ( !hQuery ) {
		LogError("SQLT_OnUpdateProgress failure: \"%s\"", sError);
	}
}