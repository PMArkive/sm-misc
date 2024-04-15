#include <sourcemod>
#include <sdkhooks>
#include <vector>
#include <sdktools>

#define BOOSTER_TRIGGER_ID 1868202
#define MIN_INITIAL_VELOCITY 390.0
#define MAX_INITIAL_VELOCITY 405.0
#define MAX_TOTAL_VELOCITY 1920.0
#define ACCELERATION_DURATION 0.1 // duration to reach full boost

int g_BoosterEntity = -1;
bool g_PlayerEligibleForBoost[MAXPLAYERS + 1];
float g_PlayerStartVelocityY[MAXPLAYERS + 1];
float g_PlayerAccelerationStartTime[MAXPLAYERS + 1];

public void OnMapStart() {
    g_BoosterEntity = FindBoosterEntityByTriggerID(BOOSTER_TRIGGER_ID);
    if (g_BoosterEntity != -1) {
        SDKHook(g_BoosterEntity, SDKHook_StartTouch, OnStartTouchBooster);
        SDKHook(g_BoosterEntity, SDKHook_EndTouch, OnEndTouchBooster);
    }
}

public void OnStartTouchBooster(int entity, int activator) {
    if (activator > 0 && activator <= MaxClients && IsClientInGame(activator) && IsPlayerAlive(activator)) {
        float velocity[3];
        GetEntPropVector(activator, Prop_Data, "m_vecVelocity", velocity);
        float speed = GetVectorLength(velocity);
        bool isOnGround = (GetEntityFlags(activator) & FL_ONGROUND) != 0;
        bool isWithinVelocityRange = (speed >= MIN_INITIAL_VELOCITY && speed <= MAX_INITIAL_VELOCITY);

        g_PlayerEligibleForBoost[activator] = isOnGround && isWithinVelocityRange;
        if (g_PlayerEligibleForBoost[activator]) {
            g_PlayerStartVelocityY[activator] = velocity[1];
            g_PlayerAccelerationStartTime[activator] = GetGameTime();
        }
    }
}

public void OnEndTouchBooster(int entity, int activator) {
    if (activator > 0 && activator <= MaxClients && IsClientInGame(activator)) {
        if (g_PlayerEligibleForBoost[activator]) {
            float elapsed = GetGameTime() - g_PlayerAccelerationStartTime[activator];
            float fraction = elapsed / ACCELERATION_DURATION;
            fraction = fraction > 1.0 ? 1.0 : fraction;

            float velocity[3];
            GetEntPropVector(activator, Prop_Data, "m_vecVelocity", velocity);
            float additionalYVelocity = (MAX_TOTAL_VELOCITY * fraction) - GetVectorLength(velocity);
            velocity[1] += additionalYVelocity;

            // Clamp the total velocity to MAX_TOTAL_VELOCITY
            float totalSpeed = GetVectorLength(velocity);
            if (totalSpeed > MAX_TOTAL_VELOCITY) {
                float scale = MAX_TOTAL_VELOCITY / totalSpeed;
                ScaleVector(velocity, scale);
            }

            SetEntPropVector(activator, Prop_Data, "m_vecVelocity", velocity);
        }
        g_PlayerEligibleForBoost[activator] = false;
    }
}

int FindBoosterEntityByTriggerID(int triggerID) {
    int entity = -1;
    while ((entity = FindEntityByClassname(entity, "trigger_multiple")) != -1) {
        if (GetEntProp(entity, Prop_Data, "m_iHammerID") == triggerID) {
            return entity;
        }
    }
    return -1;
}
