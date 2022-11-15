/********************************************************/
/*						MORE COLORS					   	*/
/*		Авторы: Dr.McKay (rew. by xyligan & Kailo)	   	*/
/* https://forums.alliedmods.net/showthread.php?t=96831 */
/********************************************************/

#pragma semicolon 1
#pragma newdecls required

#if defined _colors_included
 #endinput
#endif
#define _colors_included

#include <regex>

#define MORE_COLORS_VERSION		"1.9.2_fix"
#define MAX_MESSAGE_LENGTH		256
#define MAX_BUFFER_LENGTH		(MAX_MESSAGE_LENGTH * 4)

#define COLOR_RED				0xFF4040
#define COLOR_BLUE				0x99CCFF
#define COLOR_GRAY				0xCCCCCC
#define COLOR_GREEN				0x3EFF3E

Handle g_hCTrie;
bool g_bCSkipList[MAXPLAYERS + 1];
int g_sCTeamColors[] = {0xCCCCCC, 0x4D7942, 0xFF4040};

/**
 * Отправляет сообщение конкретному игроку в области чата
 * Поддерживает цветовые теги
 * 
 * @param iClient		Индекс игрока
 * @param szMessage		Текст сообщения
 * @param ...			Параметры форматирования
*/
stock void CPrintToChat(int iClient, const char[] szMessage, any ...) {
	CCheckTrie();
	
	if(iClient <= 0 || iClient > MaxClients) {
		ThrowError("Invalid client index %i", iClient);
	}
	if(!IsClientInGame(iClient)) {
		ThrowError("Client %i is not in game", iClient);
	}

	char szBuffer[MAX_BUFFER_LENGTH], szBufferNew[MAX_BUFFER_LENGTH];

	SetGlobalTransTarget(iClient);
	Format(szBuffer, sizeof szBuffer, "\x01%s", szMessage);
	VFormat(szBufferNew, sizeof szBufferNew, szBuffer, 3);
	CReplaceColorCodes(szBufferNew);
	CSendMessage(iClient, szBufferNew);
}

/**
 * Отправляет сообщение всем игрокам в области чата
 * Поддерживает цветовые теги
 * 
 * @param szMessage		Текст сообщения
 * @param ...			Параметры форматирования
*/
stock void CPrintToChatAll(const char[] szMessage, any ...) {
	CCheckTrie();

	char szBuffer[MAX_BUFFER_LENGTH], szBufferNew[MAX_BUFFER_LENGTH];

	for(int i = 1; i <= MaxClients; i++) {
		if(!IsClientInGame(i) || g_bCSkipList[i]) {
			g_bCSkipList[i] = false;
			continue;
		}

		SetGlobalTransTarget(i);
		Format(szBuffer, sizeof szBuffer, "\x01%s", szMessage);
		VFormat(szBufferNew, sizeof szBufferNew, szBufferNew, 2);
		CReplaceColorCodes(szBufferNew);
		CSendMessage(i, szBufferNew);
	}
}

/**
 * Отправляет сообщение конкретному игроку в области чата
 * Поддерживает цветовые теги и тег `teamcolor`
 * 
 * @param iClient		Индекс игрока
 * @param iAuthor		Индекс автора, цвет которого будет использоваться
 * @param szMessage		Текст соообщения
 * @param ...			Параметры форматирования
*/
stock void CPrintToChatEx(int iClient, int iAuthor, const char[] szMessage, any ...) {
	CCheckTrie();

	if(iClient <= 0 || iClient > MaxClients) {
		ThrowError("Invalid client index %i", iClient);
	}
	if(!IsClientInGame(iClient)) {
		ThrowError("Client %i is not in game", iClient);
	}
	if(iAuthor <= 0 || iAuthor > MaxClients) {
		ThrowError("Invalid client index %i", iAuthor);
	}
	if(!IsClientInGame(iAuthor)) {
		ThrowError("Client %i is not in game", iAuthor);
	}

	char szBuffer[MAX_BUFFER_LENGTH], szBufferNew[MAX_BUFFER_LENGTH];

	SetGlobalTransTarget(iClient);
	Format(szBuffer, sizeof szBuffer, "\x01%s", szMessage);
	VFormat(szBufferNew, sizeof szBufferNew, szBuffer, 4);
	CReplaceColorCodes(szBufferNew, iAuthor);
	CSendMessage(iClient, szBufferNew, iAuthor);
}

/**
 * Отправляет сообщение всем игрокам в области чата
 * Поддерживает цветовые теги и тег `teamcolor`
 *
 * @param iAuthor	  	Индекс автора, цвет которого будет использоваться
 * @param szMessage   	Текст сообщения
 * @param ...			Параметры форматирования
*/
stock void CPrintToChatAllEx(int iAuthor, const char[] szMessage, any ...) {
	CCheckTrie();

	if(iAuthor <= 0 || iAuthor > MaxClients) {
		ThrowError("Invalid client index %i", iAuthor);
	}
	if(!IsClientInGame(iAuthor)) {
		ThrowError("Client %i is not in game", iAuthor);
	}

	char szBuffer[MAX_BUFFER_LENGTH], szBufferNew[MAX_BUFFER_LENGTH];

	for(int i = 1; i <= MaxClients; i++) {
		if(!IsClientInGame(i) || g_bCSkipList[i]) {
			g_bCSkipList[i] = false;
			continue;
		}

		SetGlobalTransTarget(i);
		Format(szBuffer, sizeof szBuffer, "\x01%s", szMessage);
		VFormat(szBufferNew, sizeof szBufferNew, szBuffer, 3);
		CReplaceColorCodes(szBufferNew, iAuthor);
		CSendMessage(i, szBufferNew, iAuthor);
	}
}

/**
 * Отправляет пользовательское сообщение SayText2
 * 
 * @param iClient		Индекс игрока
 * @param szMessage		Текст сообщения
 * @param ...			Параметры форматирования
*/
stock void CSendMessage(int iClient, const char[] szMessage, int iAuthor = 0) {
	if(iAuthor == 0) {
		iAuthor = iClient;
	}

	char szBuffer[MAX_MESSAGE_LENGTH], szGame[16];

	GetGameFolderName(szGame, sizeof szGame);
	strcopy(szBuffer, sizeof szBuffer, szMessage);
	UserMsg index = GetUserMessageId("SayText2");

	if(index == INVALID_MESSAGE_ID) {
		if(StrEqual(szGame, "dod")) {
			int iTeam = GetClientTeam(iAuthor);

			if(iTeam == 0) {
				ReplaceString(szBuffer, sizeof szBuffer, "\x03", "\x04", false);
			} else {
				char szTemp[16];
				Format(szTemp, sizeof szTemp, "\x07%06X", g_sCTeamColors[iTeam - 1]);
				ReplaceString(szBuffer, sizeof szBuffer, "\x03", szTemp, false);
			}
		}

		PrintToChat(iClient, "%s", szBuffer);
		
		return;
	}

	Handle hBuf = StartMessageOne("SayText2", iClient, USERMSG_RELIABLE | USERMSG_BLOCKHOOKS);

	if(GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf) {
		PbSetInt(hBuf, "ent_idx", iAuthor);
		PbSetBool(hBuf, "chat", true);
		PbSetString(hBuf, "msg_name", szBuffer);
		PbAddString(hBuf, "params", "");
		PbAddString(hBuf, "params", "");
		PbAddString(hBuf, "params", "");
		PbAddString(hBuf, "params", "");
	} else {
		BfWriteByte(hBuf, iAuthor);
		BfWriteByte(hBuf, true);
		BfWriteString(hBuf, szBuffer);
	}

	EndMessage();
}

/**
 * Эту функцию следует использовать только прямо перед
 * `CPrintToChatAll` или `CPrintToChatAllEx`. Это вызывает эти функции
 * чтобы пропустить указанного игрока при отправке сообщения
 * После отправки сообщения игрок больше не будет пропущен
 * 
 * @param iClient   Индекс игрока
*/
stock void CSkipNextClient(int iClient) {
	if(iClient <= 0 || iClient > MaxClients) {
		ThrowError("Invalid client index %i", iClient);
	}

	g_bCSkipList[iClient] = true;
}

/**
 * Проверяет, инициализировано ли дерево цветов, и инициализирует его, если это не так (используется внутри)
*/
stock void CCheckTrie() {
	if(g_hCTrie == INVALID_HANDLE) {
		g_hCTrie = InitColorTrie();
	}
}

/**
 * Заменяет цветовые теги в строке цветовыми кодами (используемыми внутри `CPrintToChat`, `CPrintToChatAll`, `CPrintToChatEx` и `CPrintToChatAllEx`)
 *
 * @param szBuffer		Буфер для обработки
 * @param iAuthor		Необязательный клиентский индекс для тегов `{teamcolor}` или 0, если нет
 * @param bRemoveTags	Необязательное логическое значение, чтобы определить, заменяем ли мы теги цветами или просто удаляем теги, используемые `CRemoveTags`
 * @param iMaxLength	Необязательное значение для максимальной длины буфера, используемое `CRemoveTags`
*/
stock void CReplaceColorCodes(char[] szBuffer, int iAuthor = 0, bool bRemoveTags = false, int iMaxLength = MAX_BUFFER_LENGTH) {
	CCheckTrie();

	if(!bRemoveTags) {
		ReplaceString(szBuffer, iMaxLength, "{default}", "\x01", false);
	} else {
		ReplaceString(szBuffer, iMaxLength, "{default}", "", false);
		ReplaceString(szBuffer, iMaxLength, "{teamcolor}", "", false);
	}

	if(iAuthor != 0 && !bRemoveTags) {
		if(iAuthor < 0 || iAuthor > MaxClients) {
			ThrowError("Invalid client index %i", iAuthor);
		}
		if(!IsClientInGame(iAuthor)) {
			ThrowError("Client %i is not in game", iAuthor);
		}

		ReplaceString(szBuffer, iMaxLength, "{teamcolor}", "\x03", false);
	}

	int value;
	int iCursor;
	
	char szTag[32], szBuff[32];
	char[] szOutput = new char[iMaxLength];
	
	strcopy(szOutput, iMaxLength, szBuffer);
	
	Handle regex = CompileRegex("{[a-zA-Z0-9]+}");
	
	for(int i = 0; i < 1000; i++) {
		if(MatchRegex(regex, szBuffer[iCursor]) < 1) {
			CloseHandle(regex);
			strcopy(szBuffer, iMaxLength, szOutput);

			return;
		}

		GetRegexSubString(regex, 0, szTag, sizeof szTag);
		CStrToLower(szTag);

		iCursor = StrContains(szBuffer[iCursor], szTag, false) + iCursor + 1;
		strcopy(szBuff, sizeof szBuff, szTag);
		ReplaceString(szBuff, sizeof szBuff, "{", "");
		ReplaceString(szBuff, sizeof szBuff, "}", "");
		
		if(!GetTrieValue(g_hCTrie, szBuff, value)) {
			continue;
		}
		
		if(bRemoveTags) {
			ReplaceString(szOutput, iMaxLength, szTag, "", false);
		} else {
			Format(szBuff, sizeof szBuff, "\x07%06X", value);
			ReplaceString(szOutput, iMaxLength, szTag, szBuff, false);
		}
	}

	LogError("[MORE COLORS] Infinite loop broken.");
}

/**
 * Получает часть строки
 * 
 * @param szInput		Строка, из которой нужно получить часть
 * @param szOutput		Буфер для записи
 * @param iMaxLength	Максимальная длина выходного буфера
 * @param iStart		Позиция для начала
 * @param iNumChars		Количество возвращаемых символов или 0 в конце строки
*/
stock void CSubString(const char[] szInput, char[] szOutput, int iMaxLength, int iStart, int iNumChars = 0) {
	int i;

	for(;;) {
		if(i == iMaxLength - 1 || i >= iNumChars || szInput[iStart + i] == '\0') {
			szOutput[i] = '\0';
			
			return;
		}

		szOutput[i] = szInput[iStart + i];
		i++;
	}
}

/**
 * Преобразует строку в нижний регистр
 * 
 * @param szBuffer		Буфер для преобразования
*/
stock void CStrToLower(char[] szBuffer) {
	int iLen = strlen(szBuffer);

	for(int i = 0; i < iLen; i++) {
		szBuffer[i] = CharToLower(szBuffer[i]);
	}
}

/**
 * Добавляет цвет в палитру цветов
 *
 * @param szName		Название цвета без фигурных скобок
 * @param color			Шестнадцатеричное представление цвета (0xRRGGBB)
 *
 * @return				Истина, если цвет был успешно добавлен, и ложь, если цвет с таким именем уже существует.
*/
stock bool CAddColor(const char[] szName, any color) {
	CCheckTrie();

	any value;
	
	if(GetTrieValue(g_hCTrie, szName, value)) {
		return false;
	}

	char szNewName[64];

	strcopy(szNewName, sizeof szNewName, szName);
	CStrToLower(szNewName);
	SetTrieValue(g_hCTrie, szNewName, color);
	
	return true;
}

/**
 * Удаляет цветовые метки из сообщения
 * 
 * @param szMessage		Буфер для удаления тегов
 * @param iMaxLength	Максимальная длина буфера
*/
stock void CRemoveTags(char[] szMessage, int iMaxLength) {
	CReplaceColorCodes(szMessage, 0, true, iMaxLength);
}

/**
 * Отвечает на команду цветным текстом
 * 
 * @param iClient		Индекс игрока
 * @param szMessage		Текст сообщения
 * @param ...			Параметры форматирования
*/
stock void CReplyToCommand(int iClient, const char[] szMessage, any ...) {
	char szBuffer[MAX_BUFFER_LENGTH];

	SetGlobalTransTarget(iClient);
	VFormat(szBuffer, sizeof szBuffer, szMessage, 3);

	if(GetCmdReplySource() == SM_REPLY_TO_CONSOLE) {
		CRemoveTags(szBuffer, sizeof szBuffer);
		PrintToConsole(iClient, "%s", szBuffer);
	} else {
		CPrintToChat(iClient, "%s", szBuffer);
	}
}

/**
 * Отвечает на команду цветным текстом
 * 
 * @param iClient		Индекс игрока
 * @param iAuthor		Игрок для `{teamcolor}`
 * @param szMessage		Текст сообщения
 * @param ...			Параметры форматирования
*/
stock void CReplyToCommandEx(int iClient, int iAuthor, const char[] szMessage, any ...) {
	char szBuffer[MAX_BUFFER_LENGTH];

	SetGlobalTransTarget(iClient);
	VFormat(szBuffer, sizeof szBuffer, szMessage, 4);
	
	if(GetCmdReplySource() == SM_REPLY_TO_CONSOLE) {
		CRemoveTags(szBuffer, sizeof szBuffer);
		PrintToConsole(iClient, "%s", szBuffer);
	} else {
		CPrintToChatEx(iClient, iAuthor, "%s", szBuffer);
	}
}

/**
 * Показывает активность администратора с помощью цветнового текста
 * 
 * @param iClient		Индекс игрока
 * @param szMessage		Текст сообщения
 * @param ...			Параметры форматирования
*/
stock void CShowActivity(int iClient, const char[] szMessage, any ...) {
	CCheckTrie();

	if(iClient < 0 || iClient > MaxClients) {
		ThrowError("Invalid client index %d", iClient);
	}
	if(iClient != 0 && !IsClientInGame(iClient)) {
		ThrowError("Client %d is not in game", iClient);
	}

	char szBuffer[MAX_BUFFER_LENGTH], szBufferNew[MAX_BUFFER_LENGTH];

	Format(szBuffer, sizeof szBuffer, "\x01%s", szMessage);
	VFormat(szBufferNew, sizeof szBufferNew, szBuffer, 3);
	CReplaceColorCodes(szBufferNew);
	ShowActivity(iClient, "%s", szBufferNew);
}

/**
 * Показывает активность администратора с помощью цветнового текста
 * 
 * @param iClient		Индекс игрока
 * @param szTag			Тег для добавления к сообщению (поддерживаются цветные теги)
 * @param szMessage		Текст сообщения
 * @param ...			Параметры форматирования
*/
stock void CShowActivityEx(int iClient, const char[] szTag, const char[] szMessage, any ...) {
	CCheckTrie();

	if(iClient < 0 || iClient > MaxClients) {
		ThrowError("Invalid client index %d", iClient);
	}
	if(iClient != 0 && !IsClientInGame(iClient)) {
		ThrowError("Client %d is not in game", iClient);
	}

	char szBuffer[MAX_BUFFER_LENGTH], szBufferNew[MAX_BUFFER_LENGTH];

	Format(szBuffer, sizeof szBuffer, "\x01%s", szMessage);
	VFormat(szBufferNew, sizeof szBufferNew, szBuffer, 4);
	CReplaceColorCodes(szBufferNew);
	strcopy(szBuffer, sizeof szBuffer, szTag);
	CReplaceColorCodes(szBuffer);
	ShowActivityEx(iClient, szTag, "%s", szBufferNew);
}

/**
 * Тег для добавления к сообщению (поддерживаются цветные теги)
 * 
 * @param iClient		Индекс игрока
 * @param szTag			Тег для добавления к сообщению (поддерживаются цветные теги)
 * @param szMessage		Текст сообщения
 * @param ...			Параметры форматирования
*/
stock void CShowActivity2(int iClient, const char[] szTag, const char[] szMessage, any ...) {
	CCheckTrie();

	if(iClient < 0 || iClient > MaxClients) {
		ThrowError("Invalid client index %d", iClient);
	}
	if(iClient != 0 && !IsClientInGame(iClient)) {
		ThrowError("Client %d is not in game", iClient);
	}

	char szBuffer[MAX_BUFFER_LENGTH], szBufferNew[MAX_BUFFER_LENGTH];

	Format(szBuffer, sizeof szBuffer, "\x01%s", szMessage);
	VFormat(szBufferNew, sizeof szBufferNew, szBuffer, 4);
	CReplaceColorCodes(szBufferNew);
	strcopy(szBuffer, sizeof szBuffer, szTag);
	CReplaceColorCodes(szBuffer);
	ShowActivity2(iClient, szBuffer, "%s", szBufferNew);
}

/**
 * Определяет, существует ли имя цвета
 * 
 * @param szColor		Название цвета для проверки
 *
 * @return				Истина, если цвет существует, и ложь в противном случае
*/
stock bool CColorExists(const char[] szColor) {
	CCheckTrie();

	any temp;

	return GetTrieValue(g_hCTrie, szColor, temp);
}

/**
 * Возвращает шестнадцатеричное представление цвета команды игрока (НЕ инициализирует дерево)
 *
 * @param iClient		Индекс игрока
 *
 * @return				Цвет команды игрока в шестнадцатеричном формате или зеленый, если он неизвестен
*/
stock any CGetTeamColor(int iClient) {
	if(iClient <= 0 || iClient > MaxClients) {
		ThrowError("Invalid client index %i", iClient);
	}
	if(!IsClientInGame(iClient)) {
		ThrowError("Client %i is not in game", iClient);
	}

	any value;
	
	switch(GetClientTeam(iClient)) {
		case 1: {
			value = COLOR_GRAY;
		}

		case 2: {
			value = COLOR_RED;
		}
		
		case 3: {
			value = COLOR_BLUE;
		}
		
		default: {
			value = COLOR_GREEN;
		}
	}

	return value;
}

/**
 * Инициализирует дерево цветов
*/
stock Handle InitColorTrie() {
	Handle hTrie = CreateTrie();
	
	SetTrieValue(hTrie, "aliceblue", 0xF0F8FF);
	SetTrieValue(hTrie, "allies", 0x4D7942);
	SetTrieValue(hTrie, "ancient", 0xEB4B4B);
	SetTrieValue(hTrie, "antiquewhite", 0xFAEBD7);
	SetTrieValue(hTrie, "aqua", 0x00FFFF);
	SetTrieValue(hTrie, "aquamarine", 0x7FFFD4);
	SetTrieValue(hTrie, "arcana", 0xADE55C);
	SetTrieValue(hTrie, "axis", 0xFF4040);
	SetTrieValue(hTrie, "azure", 0x007FFF);
	SetTrieValue(hTrie, "beige", 0xF5F5DC);
	SetTrieValue(hTrie, "bisque", 0xFFE4C4);
	SetTrieValue(hTrie, "black", 0x000000);
	SetTrieValue(hTrie, "blanchedalmond", 0xFFEBCD);
	SetTrieValue(hTrie, "blue", 0x99CCFF);
	SetTrieValue(hTrie, "blueviolet", 0x8A2BE2);
	SetTrieValue(hTrie, "brown", 0xA52A2A);
	SetTrieValue(hTrie, "burlywood", 0xDEB887);
	SetTrieValue(hTrie, "cadetblue", 0x5F9EA0);
	SetTrieValue(hTrie, "chartreuse", 0x7FFF00);
	SetTrieValue(hTrie, "chocolate", 0xD2691E);
	SetTrieValue(hTrie, "collectors", 0xAA0000);
	SetTrieValue(hTrie, "common", 0xB0C3D9);
	SetTrieValue(hTrie, "community", 0x70B04A);
	SetTrieValue(hTrie, "coral", 0xFF7F50);
	SetTrieValue(hTrie, "cornflowerblue", 0x6495ED);
	SetTrieValue(hTrie, "cornsilk", 0xFFF8DC);
	SetTrieValue(hTrie, "corrupted", 0xA32C2E);
	SetTrieValue(hTrie, "crimson", 0xDC143C);
	SetTrieValue(hTrie, "cyan", 0x00FFFF);
	SetTrieValue(hTrie, "darkblue", 0x00008B);
	SetTrieValue(hTrie, "darkcyan", 0x008B8B);
	SetTrieValue(hTrie, "darkgoldenrod", 0xB8860B);
	SetTrieValue(hTrie, "darkgray", 0xA9A9A9);
	SetTrieValue(hTrie, "darkgrey", 0xA9A9A9);
	SetTrieValue(hTrie, "darkgreen", 0x006400);
	SetTrieValue(hTrie, "darkkhaki", 0xBDB76B);
	SetTrieValue(hTrie, "darkmagenta", 0x8B008B);
	SetTrieValue(hTrie, "darkolivegreen", 0x556B2F);
	SetTrieValue(hTrie, "darkorange", 0xFF8C00);
	SetTrieValue(hTrie, "darkorchid", 0x9932CC);
	SetTrieValue(hTrie, "darkred", 0x8B0000);
	SetTrieValue(hTrie, "darksalmon", 0xE9967A);
	SetTrieValue(hTrie, "darkseagreen", 0x8FBC8F);
	SetTrieValue(hTrie, "darkslateblue", 0x483D8B);
	SetTrieValue(hTrie, "darkslategray", 0x2F4F4F);
	SetTrieValue(hTrie, "darkslategrey", 0x2F4F4F);
	SetTrieValue(hTrie, "darkturquoise", 0x00CED1);
	SetTrieValue(hTrie, "darkviolet", 0x9400D3);
	SetTrieValue(hTrie, "deeppink", 0xFF1493);
	SetTrieValue(hTrie, "deepskyblue", 0x00BFFF);
	SetTrieValue(hTrie, "dimgray", 0x696969);
	SetTrieValue(hTrie, "dimgrey", 0x696969);
	SetTrieValue(hTrie, "dodgerblue", 0x1E90FF);
	SetTrieValue(hTrie, "exalted", 0xCCCCCD);
	SetTrieValue(hTrie, "firebrick", 0xB22222);
	SetTrieValue(hTrie, "floralwhite", 0xFFFAF0);
	SetTrieValue(hTrie, "forestgreen", 0x228B22);
	SetTrieValue(hTrie, "frozen", 0x4983B3);
	SetTrieValue(hTrie, "fuchsia", 0xFF00FF);
	SetTrieValue(hTrie, "fullblue", 0x0000FF);
	SetTrieValue(hTrie, "fullred", 0xFF0000);
	SetTrieValue(hTrie, "gainsboro", 0xDCDCDC);
	SetTrieValue(hTrie, "genuine", 0x4D7455);
	SetTrieValue(hTrie, "ghostwhite", 0xF8F8FF);
	SetTrieValue(hTrie, "gold", 0xFFD700);
	SetTrieValue(hTrie, "goldenrod", 0xDAA520);
	SetTrieValue(hTrie, "gray", 0xCCCCCC);
	SetTrieValue(hTrie, "grey", 0xCCCCCC);
	SetTrieValue(hTrie, "green", 0x3EFF3E);
	SetTrieValue(hTrie, "greenyellow", 0xADFF2F);
	SetTrieValue(hTrie, "haunted", 0x38F3AB);
	SetTrieValue(hTrie, "honeydew", 0xF0FFF0);
	SetTrieValue(hTrie, "hotpink", 0xFF69B4);
	SetTrieValue(hTrie, "immortal", 0xE4AE33);
	SetTrieValue(hTrie, "indianred", 0xCD5C5C);
	SetTrieValue(hTrie, "indigo", 0x4B0082);
	SetTrieValue(hTrie, "ivory", 0xFFFFF0);
	SetTrieValue(hTrie, "khaki", 0xF0E68C);
	SetTrieValue(hTrie, "lavender", 0xE6E6FA);
	SetTrieValue(hTrie, "lavenderblush", 0xFFF0F5);
	SetTrieValue(hTrie, "lawngreen", 0x7CFC00);
	SetTrieValue(hTrie, "legendary", 0xD32CE6);
	SetTrieValue(hTrie, "lemonchiffon", 0xFFFACD);
	SetTrieValue(hTrie, "lightblue", 0xADD8E6);
	SetTrieValue(hTrie, "lightcoral", 0xF08080);
	SetTrieValue(hTrie, "lightcyan", 0xE0FFFF);
	SetTrieValue(hTrie, "lightgoldenrodyellow", 0xFAFAD2);
	SetTrieValue(hTrie, "lightgray", 0xD3D3D3);
	SetTrieValue(hTrie, "lightgrey", 0xD3D3D3);
	SetTrieValue(hTrie, "lightgreen", 0x99FF99);
	SetTrieValue(hTrie, "lightpink", 0xFFB6C1);
	SetTrieValue(hTrie, "lightsalmon", 0xFFA07A);
	SetTrieValue(hTrie, "lightseagreen", 0x20B2AA);
	SetTrieValue(hTrie, "lightskyblue", 0x87CEFA);
	SetTrieValue(hTrie, "lightslategray", 0x778899);
	SetTrieValue(hTrie, "lightslategrey", 0x778899);
	SetTrieValue(hTrie, "lightsteelblue", 0xB0C4DE);
	SetTrieValue(hTrie, "lightyellow", 0xFFFFE0);
	SetTrieValue(hTrie, "lime", 0x00FF00);
	SetTrieValue(hTrie, "limegreen", 0x32CD32);
	SetTrieValue(hTrie, "linen", 0xFAF0E6);
	SetTrieValue(hTrie, "magenta", 0xFF00FF);
	SetTrieValue(hTrie, "maroon", 0x800000);
	SetTrieValue(hTrie, "mediumaquamarine", 0x66CDAA);
	SetTrieValue(hTrie, "mediumblue", 0x0000CD);
	SetTrieValue(hTrie, "mediumorchid", 0xBA55D3);
	SetTrieValue(hTrie, "mediumpurple", 0x9370D8);
	SetTrieValue(hTrie, "mediumseagreen", 0x3CB371);
	SetTrieValue(hTrie, "mediumslateblue", 0x7B68EE);
	SetTrieValue(hTrie, "mediumspringgreen", 0x00FA9A);
	SetTrieValue(hTrie, "mediumturquoise", 0x48D1CC);
	SetTrieValue(hTrie, "mediumvioletred", 0xC71585);
	SetTrieValue(hTrie, "midnightblue", 0x191970);
	SetTrieValue(hTrie, "mintcream", 0xF5FFFA);
	SetTrieValue(hTrie, "mistyrose", 0xFFE4E1);
	SetTrieValue(hTrie, "moccasin", 0xFFE4B5);
	SetTrieValue(hTrie, "mythical", 0x8847FF);
	SetTrieValue(hTrie, "navajowhite", 0xFFDEAD);
	SetTrieValue(hTrie, "navy", 0x000080);
	SetTrieValue(hTrie, "normal", 0xB2B2B2);
	SetTrieValue(hTrie, "oldlace", 0xFDF5E6);
	SetTrieValue(hTrie, "olive", 0x9EC34F);
	SetTrieValue(hTrie, "olivedrab", 0x6B8E23);
	SetTrieValue(hTrie, "orange", 0xFFA500);
	SetTrieValue(hTrie, "orangered", 0xFF4500);
	SetTrieValue(hTrie, "orchid", 0xDA70D6);
	SetTrieValue(hTrie, "palegoldenrod", 0xEEE8AA);
	SetTrieValue(hTrie, "palegreen", 0x98FB98);
	SetTrieValue(hTrie, "paleturquoise", 0xAFEEEE);
	SetTrieValue(hTrie, "palevioletred", 0xD87093);
	SetTrieValue(hTrie, "papayawhip", 0xFFEFD5);
	SetTrieValue(hTrie, "peachpuff", 0xFFDAB9);
	SetTrieValue(hTrie, "peru", 0xCD853F);
	SetTrieValue(hTrie, "pink", 0xFFC0CB);
	SetTrieValue(hTrie, "plum", 0xDDA0DD);
	SetTrieValue(hTrie, "powderblue", 0xB0E0E6);
	SetTrieValue(hTrie, "purple", 0x800080);
	SetTrieValue(hTrie, "rare", 0x4B69FF);
	SetTrieValue(hTrie, "red", 0xFF4040);
	SetTrieValue(hTrie, "rosybrown", 0xBC8F8F);
	SetTrieValue(hTrie, "royalblue", 0x4169E1);
	SetTrieValue(hTrie, "saddlebrown", 0x8B4513);
	SetTrieValue(hTrie, "salmon", 0xFA8072);
	SetTrieValue(hTrie, "sandybrown", 0xF4A460);
	SetTrieValue(hTrie, "seagreen", 0x2E8B57);
	SetTrieValue(hTrie, "seashell", 0xFFF5EE);
	SetTrieValue(hTrie, "selfmade", 0x70B04A);
	SetTrieValue(hTrie, "sienna", 0xA0522D);
	SetTrieValue(hTrie, "silver", 0xC0C0C0);
	SetTrieValue(hTrie, "skyblue", 0x87CEEB);
	SetTrieValue(hTrie, "slateblue", 0x6A5ACD);
	SetTrieValue(hTrie, "slategray", 0x708090);
	SetTrieValue(hTrie, "slategrey", 0x708090);
	SetTrieValue(hTrie, "snow", 0xFFFAFA);
	SetTrieValue(hTrie, "springgreen", 0x00FF7F);
	SetTrieValue(hTrie, "steelblue", 0x4682B4);
	SetTrieValue(hTrie, "strange", 0xCF6A32);
	SetTrieValue(hTrie, "tan", 0xD2B48C);
	SetTrieValue(hTrie, "teal", 0x008080);
	SetTrieValue(hTrie, "thistle", 0xD8BFD8);
	SetTrieValue(hTrie, "tomato", 0xFF6347);
	SetTrieValue(hTrie, "turquoise", 0x40E0D0);
	SetTrieValue(hTrie, "uncommon", 0xB0C3D9);
	SetTrieValue(hTrie, "unique", 0xFFD700);
	SetTrieValue(hTrie, "unusual", 0x8650AC);
	SetTrieValue(hTrie, "valve", 0xA50F79);
	SetTrieValue(hTrie, "vintage", 0x476291);
	SetTrieValue(hTrie, "violet", 0xEE82EE);
	SetTrieValue(hTrie, "wheat", 0xF5DEB3);
	SetTrieValue(hTrie, "white", 0xFFFFFF);
	SetTrieValue(hTrie, "whitesmoke", 0xF5F5F5);
	SetTrieValue(hTrie, "yellow", 0xFFFF00);
	SetTrieValue(hTrie, "yellowgreen", 0x9ACD32);

	return hTrie;
}