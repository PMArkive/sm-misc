//this still needs a lot of physics calculations

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <vector>
#include <entity>
#include <convars>
#include <clients>

#define PLUGIN_VERSION "1.3"
#define TRACE_DISTANCE 64.0
#define MAX_SURFACE_NORMAL_Z 0.7
#define MIN_SURFACE_NORMAL_Z 0.0
#define MODEL_SPRITE "sprites/laserbeam.vmt"
#define M_PI 3.14159265358979323846

ConVar gCV_SV_Airaccelerate;
ConVar gCV_SV_MaxVelocity;

public Plugin myinfo =
{
    name = "surf velocity predictor",
    author = "j",
    description = "predicts player velocity on surf ramps for TAS optimization",
    version = PLUGIN_VERSION,
    url = "https://alliedmods.net"
};

public void OnPluginStart()
{
    gCV_SV_Airaccelerate = FindConVar("sv_airaccelerate");
    gCV_SV_MaxVelocity = FindConVar("sv_maxvelocity");

    if (gCV_SV_Airaccelerate == INVALID_HANDLE || gCV_SV_MaxVelocity == INVALID_HANDLE)
    {
        LogError("Critical ConVar(s) missing: sv_airaccelerate, sv_maxvelocity. Plugin will not function correctly.");
        SetFailState("Missing critical ConVars.");
    }

    HookEvents();
}

public void OnPluginEnd()
{
    UnhookAllEvents();
}

public void OnMapStart()
{
    // cleanup previous hooks and re-hook for the new map
    UnhookAllEvents();
    UnhookAllClientHooks();
    HookEvents();
}

public void OnMapEnd()
{
    UnhookAllEvents();
    UnhookAllClientHooks();
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0 && IsClientInGame(client)) 
    {
        SDKHook(client, SDKHook_PreThink, OnPlayerPreThink);
    }
}

public void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0)
    {
        SDKUnhook(client, SDKHook_PreThink, OnPlayerPreThink);
    }
}

public void OnPlayerPreThink(int client)
{
    if (IsPlayerOnSurfRamp(client))
    {
        PredictVelocity(client);
    }
}

// utility functions
void HookEvents()
{
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("player_disconnect", Event_PlayerDisconnect);
}

void UnhookAllEvents()
{
    UnhookEvent("player_spawn", Event_PlayerSpawn);
    UnhookEvent("player_disconnect", Event_PlayerDisconnect);
}

void UnhookAllClientHooks()
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (IsClientInGame(client))
        {
            SDKUnhook(client, SDKHook_PreThink, OnPlayerPreThink);
        }
    }
}

// predicts player velocity considering air acceleration
void PredictVelocity(int client)
{
    float tickInterval = GetTickInterval();
    float airAccelerate = gCV_SV_Airaccelerate.FloatValue;
    float maxVelocity = gCV_SV_MaxVelocity.FloatValue;

    float playerVel[3], playerWishdir[3], predictedPos[3], predictedVel[3];
    GetPlayerVelocity(client, playerVel);
    GetPlayerWishDir(client, playerWishdir);
    float playerWishspeed = GetPlayerWishSpeed(client);

    // apply air acceleration
    float wishspeedCapped = (playerWishspeed > 30.0) ? 30.0 : playerWishspeed;
    float accelSpeed = airAccelerate * wishspeedCapped * tickInterval;

    for (int i = 0; i < 3; i++)
    {
        predictedVel[i] = playerVel[i] + playerWishdir[i] * accelSpeed;
    }

    // clamp velocity to max speed
    float length = SquareRoot(predictedVel[0] * predictedVel[0] + predictedVel[1] * predictedVel[1] + predictedVel[2] * predictedVel[2]);
    if (length > maxVelocity)
    {
        float scale = maxVelocity / length;
        for (int i = 0; i < 3; i++)
        {
            predictedVel[i] *= scale;
        }
    }

    // predict position based on velocity
    GetPlayerPosition(client, predictedPos);
    for (int i = 0; i < 3; i++)
    {
        predictedPos[i] += predictedVel[i] * tickInterval;
    }

    // visualize predicted velocity and position
    DrawVelocityTrajectory(client, predictedVel);
}

void GetPlayerVelocity(int client, float velocity[3])
{
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
}

void GetPlayerWishDir(int client, float wishdir[3])
{
    float angles[3];
    float fw[3]; 
    float right[3];
    float up[3]; 
    float fmove;
    float smove;
    GetClientEyeAngles(client, angles);
    fmove = GetEntPropFloat(client, Prop_Send, "m_flForwardMove");
    smove = GetEntPropFloat(client, Prop_Send, "m_flSideMove");
    GetAngleVectors(angles, fw, right, up);

    // calculate wish direction
    fw[2] = right[2] = 0.0; // ignore the z-component for horizontal movement
    NormalizeVector(fw, fw);
    NormalizeVector(right, right);

    ScaleVectorD(fw, fmove, fw);
    ScaleVectorD(right, smove, right);
    AddVectors(fw, right, wishdir);
    NormalizeVector(wishdir, wishdir);
}

float GetPlayerWishSpeed(int client)
{
    float fmove = GetEntPropFloat(client, Prop_Send, "m_flForwardMove");
    float smove = GetEntPropFloat(client, Prop_Send, "m_flSideMove");
    return SquareRoot(Pow(fmove, 2.0) + Pow(smove, 2.0));
}

void GetPlayerPosition(int client, float position[3])
{
    GetClientAbsOrigin(client, position);
}

void DrawVelocityTrajectory(int client, const float predictedVel[3]) {
    float playerPos[3];
    GetClientAbsOrigin(client, playerPos);

    float endPos[3];
    AddVectors(playerPos, predictedVel, endPos);

    DisplayVelocityText(client, predictedVel, endPos);
}

void DisplayVelocityText(int client, const float predictedVel[3], const float endPos[3]) {
    char velocityText[64];
    float xyVelocity = SquareRoot(predictedVel[0] * predictedVel[0] + predictedVel[1] * predictedVel[1]);
    Format(velocityText, sizeof(velocityText), "Velocity: %.2f", xyVelocity);

    float captionOffset[3] = {0.0, 0.0, 10.0};  // offset above the end position
    float captionPos[3];
    AddVectors(endPos, captionOffset, captionPos);

    PrintHintText(client, velocityText);  // displaying the text as hint text instead
}

bool IsPlayerOnSurfRamp(int client, float surfaceNormal[3] = {0.0, 0.0, 0.0})
{
    float startPos[3], endPos[3];
    GetClientAbsOrigin(client, startPos);
    endPos[0] = startPos[0];
    endPos[1] = startPos[1];
    endPos[2] = startPos[2] - TRACE_DISTANCE;

    Handle trace = INVALID_HANDLE;
    TR_TraceRayFilter(startPos, endPos, MASK_SOLID, RayType_EndPoint, TraceFilter_World, trace);

    bool result = false;

    if (TR_DidHit(trace) && TR_GetFraction(trace) < 1.0)
    {
        float hitPos[3];
        TR_GetEndPosition(hitPos, trace);

        float distance = GetVectorDistance(startPos, hitPos);
        if (distance <= TRACE_DISTANCE)
        {
            TR_GetPlaneNormal(trace, surfaceNormal);
            result = (surfaceNormal[2] < MAX_SURFACE_NORMAL_Z && surfaceNormal[2] > MIN_SURFACE_NORMAL_Z);
        }
    }

    CloseHandle(trace);
    return result;
}

// trace filter
public bool TraceFilter_World(int entity, int contentsMask)
{
    return entity == 0;
}

void ScaleVectorD(const float vec[3], float scale, float output[3])
{
    output[0] = vec[0] * scale;
    output[1] = vec[1] * scale;
    output[2] = vec[2] * scale;
}