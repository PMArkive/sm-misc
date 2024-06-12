#include <sourcemod>
#include <sdktools>
#include <datapack>

enum struct EntityUpdateInfo
{
    int updateCount;    
    float lastUpdateTime; 
}

KeyValues g_hEntityUpdates;

public void OnPluginStart()
{
    g_hEntityUpdates = new KeyValues("EntityUpdates");
    CreateTimer(0.01, Timer_CheckRapidUpdates, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public void OnPluginEnd()
{
    delete g_hEntityUpdates;
}

public Action Timer_CheckRapidUpdates(Handle timer)
{
    for (int i = 0; i < GetMaxEntities(); i++)
    {
        if (IsValidEntity(i))
        {
            char entityName[64];
            GetEntityClassname(i, entityName, sizeof(entityName));

            if (StrEqual(entityName, "prop_dynamic")) 
            {
                TrackEntityUpdates(i, entityName);
            }
        }
    }
    return Plugin_Continue;
}

void TrackEntityUpdates(int entityIndex, const char[] entityName)
{
    EntityUpdateInfo updateInfo;

    
    if (!GetEntityUpdateInfo(entityIndex, updateInfo))
    {
        updateInfo.updateCount = 0;
        updateInfo.lastUpdateTime = GetEngineTime();
    }

    updateInfo.updateCount++;
    float currentTime = GetEngineTime();

    if (updateInfo.updateCount > 10 && (currentTime - updateInfo.lastUpdateTime) <= 1.0)
    {
        LogRapidUpdate(entityIndex, entityName, updateInfo.updateCount);
        updateInfo.updateCount = 0; 
    }

    updateInfo.lastUpdateTime = currentTime;

    SetEntityUpdateInfo(entityIndex, updateInfo);
}

bool GetEntityUpdateInfo(int entityIndex, EntityUpdateInfo updateInfo)
{
    char key[32];
    IntToString(entityIndex, key, sizeof(key));

    if (g_hEntityUpdates.JumpToKey(key, false))
    {
        updateInfo.updateCount = g_hEntityUpdates.GetNum("updateCount", 0);
        updateInfo.lastUpdateTime = g_hEntityUpdates.GetFloat("lastUpdateTime", 0.0);
        g_hEntityUpdates.GoBack();
        return true;
    }
    return false;
}

void SetEntityUpdateInfo(int entityIndex, EntityUpdateInfo updateInfo)
{
    char key[32];
    IntToString(entityIndex, key, sizeof(key));

    g_hEntityUpdates.JumpToKey(key, true);
    g_hEntityUpdates.SetNum("updateCount", updateInfo.updateCount);
    g_hEntityUpdates.SetFloat("lastUpdateTime", updateInfo.lastUpdateTime);
    g_hEntityUpdates.GoBack();
}

void LogRapidUpdate(int entityIndex, const char[] entityName, int updateCount)
{
    float pos[3];
    GetEntPropVector(entityIndex, Prop_Data, "m_vecOrigin", pos);

    int health = GetEntProp(entityIndex, Prop_Data, "m_iHealth");

    LogToFile("entity_rapid_updates_log.txt",
        "Rapid Update - Entity Index: %d, Classname: %s, Updates: %d, Position: (%.2f, %.2f, %.2f), Health: %d",
        entityIndex, entityName, updateCount, pos[0], pos[1], pos[2], health);
}
