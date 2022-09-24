// ==============================================================================================================================
// >>> Функция, создавающая триггер для выдачи награды.
// ==============================================================================================================================
native void Achievements_RegisterTrigger(char[] sName, AchievementReward ItemTake);

typedef AchievementReward = function void (int iClient, const char[] outcome);

native bool Achievements_CoreIsLoad();
forward void Achievements_OnCoreLoaded();