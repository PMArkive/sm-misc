#include <sourcemod>
#include <sdktools>

#define BOOSTER_TRIGGER_ID 1868202 //c strip west booster
#define MIN_INITIAL_VELOCITY 390.0 //min pre
#define MAX_INITIAL_VELOCITY 405.0 //max pre
#define MAX_BOOST_VELOCITY 1920.0 //fixed boost

int g_BoosterEntity = -1;
bool g_PlayerEligibleForBoost[MAXPLAYERS + 1];

public void OnMapStart() {
    g_BoosterEntity = FindBoosterEntityByTriggerID(BOOSTER_TRIGGER_ID);
    if (g_BoosterEntity != -1) {
        HookSingleEntityOutput(g_BoosterEntity, "OnStartTouch", OnStartTouchBooster);
        HookSingleEntityOutput(g_BoosterEntity, "OnEndTouch", OnEndTouchBooster);
    }
}

//when we first touch the trigger
public void OnStartTouchBooster(const char[] output, int caller, int activator, float delay) {
    if (activator > 0 && activator <= MaxClients && IsClientInGame(activator) && IsPlayerAlive(activator)) {
        float velocity[3];
        GetEntPropVector(activator, Prop_Data, "m_vecVelocity", velocity);
        float speed = GetVectorLength(velocity);

        bool isOnGround = (GetEntityFlags(activator) & FL_ONGROUND) != 0; //check if player is on the ground walking
        bool isWithinVelocityRange = (speed >= MIN_INITIAL_VELOCITY && speed <= MAX_INITIAL_VELOCITY); //check if player is within pre range

        g_PlayerEligibleForBoost[activator] = isOnGround && isWithinVelocityRange;
    }
}

//when we last touch the trigger
public void OnEndTouchBooster(const char[] output, int caller, int activator, float delay) {
    if (activator > 0 && activator <= MaxClients && IsClientInGame(activator)) {
        //if criteria is met set a new velocity
        if (g_PlayerEligibleForBoost[activator]) {
            float newVelocity[3];
            newVelocity[0] = 0.0; // x
            newVelocity[1] = MAX_BOOST_VELOCITY; // y, the direction of the booster
            newVelocity[2] = 0.0; // z

            // apply, teleportentity probs isnt a great way to do this tbh
            TeleportEntity(activator, NULL_VECTOR, NULL_VECTOR, newVelocity);
        }


        //reset the player's eligibility for the next touch
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