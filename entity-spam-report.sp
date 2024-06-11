// entity_rapid_update_tracker.sp
#include <sourcemod>
#include <sdktools>
#include <datapack>

// structure to store entity update information
enum struct EntityUpdateInfo
{
    int updateCount;    // number of updates in the current interval
    float lastUpdateTime; // time of the last update
}

// KeyValues handle for tracking entities
KeyValues g_hEntityUpdates;

public void OnPluginStart()
{
    // initialize the KeyValues handle for tracking entity updates
    g_hEntityUpdates = new KeyValues("EntityUpdates");

    // set a repeating timer to log entity properties every tick (1 tick = 0.01 seconds)
    CreateTimer(0.01, Timer_CheckRapidUpdates, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public void OnPluginEnd()
{
    // close the KeyValues handle when the plugin is unloaded
    delete g_hEntityUpdates;
}

// timer function to check for rapid updates
public Action Timer_CheckRapidUpdates(Handle timer)
{
    // loop through all entities and log properties of interest
    for (int i = 0; i < GetMaxEntities(); i++)
    {
        if (IsValidEntity(i))
        {
            char entityName[64];  // buffer for entity class name
            GetEntityClassname(i, entityName, sizeof(entityName));

            // check for specific class names or log all for analysis
            if (StrEqual(entityName, "prop_dynamic")) // you can filter by other classnames as needed
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

    // retrieve or initialize update info for the entity
    if (!GetEntityUpdateInfo(entityIndex, updateInfo))
    {
        // initialize the update info for the new entity
        updateInfo.updateCount = 0;
        updateInfo.lastUpdateTime = GetEngineTime();
    }

    // update the count and time
    updateInfo.updateCount++;
    float currentTime = GetEngineTime();

    // check if the entity has been updated rapidly (e.g., more than 10 times in the last tick)
    if (updateInfo.updateCount > 10 && (currentTime - updateInfo.lastUpdateTime) <= 1.0)
    {
        LogRapidUpdate(entityIndex, entityName, updateInfo.updateCount);
        updateInfo.updateCount = 0; // reset the count after logging
    }

    // update the last update time
    updateInfo.lastUpdateTime = currentTime;

    // store the updated info back in the KeyValues
    SetEntityUpdateInfo(entityIndex, updateInfo);
}

bool GetEntityUpdateInfo(int entityIndex, EntityUpdateInfo updateInfo)
{
    char key[32];
    IntToString(entityIndex, key, sizeof(key));

    if (g_hEntityUpdates.JumpToKey(key, false))
    {
        // assign values to the struct members from the KeyValues
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
    // retrieve detailed properties
    float pos[3];
    GetEntPropVector(entityIndex, Prop_Data, "m_vecOrigin", pos);

    int health = GetEntProp(entityIndex, Prop_Data, "m_iHealth");

    // log detailed information about the entity with rapid updates
    LogToFile("entity_rapid_updates_log.txt",
        "Rapid Update - Entity Index: %d, Classname: %s, Updates: %d, Position: (%.2f, %.2f, %.2f), Health: %d",
        entityIndex, entityName, updateCount, pos[0], pos[1], pos[2], health);
}
