#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <vector>
#include <entity>
#include <convars>
#include <clients>

#define PLUGIN_VERSION "1.2"
#define TRACE_DISTANCE 64.0
#define MAX_SURFACE_NORMAL_Z 0.7
#define MIN_SURFACE_NORMAL_Z 0.0
#define MODEL_SPRITE "sprites/laserbeam.vmt"

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
        LogError("Critical ConVar(s) missing: sv_airaccelerate or sv_maxvelocity. Plugin will not function correctly.");
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
    // cleanup and rehook
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

// uility functions
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

void PredictVelocity(int client)
{
    float playerVel[3], surfaceNormal[3];
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", playerVel);
    float predictedVel[3] = {0.0, 0.0, 0.0};

    // ensure the vector lengths are non-zero to avoid division by zero errors
    float playerVelMagnitude = GetVectorLength(playerVel);
    if (playerVelMagnitude == 0.0)
    {
        return; // player velocity is zero, cannot predict further
    }

    if (IsPlayerOnSurfRamp(client, surfaceNormal))
    {
        float dotProduct = GetVectorDotProduct(playerVel, surfaceNormal);
        float perpVel[3], parallelVel[3];

        // calculate perpendicular component of the velocity
        ScaleVectorD(surfaceNormal, dotProduct, perpVel);
        SubtractVectors(playerVel, perpVel, parallelVel);

        // calculate air acceleration contribution
        float airAccelerate = gCV_SV_Airaccelerate.FloatValue;
        if (airAccelerate != 0.0)
        {
            float wishSpeed = GetVectorLength(parallelVel);
            
            // cap wishspeed at sv_air_max_wishspeed
            float maxWishSpeed = 30.0; // change this value if sv_air_max_wishspeed is different
            if (wishSpeed > maxWishSpeed)
            {
                wishSpeed = maxWishSpeed;
            }

            if (wishSpeed != 0.0)
            {
                float accelSpeedPerTick = airAccelerate * GetTickInterval() * wishSpeed;
                ScaleVectorD(parallelVel, 1.0 + accelSpeedPerTick / wishSpeed, parallelVel);
            }
        }

        // clamp to maximum velocity
        float maxVelocity = gCV_SV_MaxVelocity.FloatValue;
        ClampVectorLength(parallelVel, maxVelocity);

        // combine vectors to get predicted velocity
        AddVectors(parallelVel, perpVel, predictedVel);
    }

    DrawVelocityTrajectory(client, predictedVel);
}

void DrawVelocityTrajectory(int client, const float predictedVel[3])
{
    float playerPos[3];
    GetClientAbsOrigin(client, playerPos);

    float endPos[3];
    AddVectors(playerPos, predictedVel, endPos);

    DisplayVelocityText(client, predictedVel, endPos);
}

// function to display velocity text.
void DisplayVelocityText(int client, const float predictedVel[3], const float endPos[3])
{
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

// trace filter function to exclude players and entities.
public bool TraceFilter_World(int entity, int contentsMask)
{
    return entity == 0;
}

// function to clamp the length of a vector.
void ClampVectorLength(float vec[3], float maxLength)
{
    float length = SquareRoot((vec[0] * vec[0]) + (vec[1] * vec[1]) + (vec[2] * vec[2]));
    if (length > maxLength)
    {
        float factor = maxLength / length;
        vec[0] *= factor;
        vec[1] *= factor;
        vec[2] *= factor;
    }
}

// function to scale a vector.
void ScaleVectorD(const float vec[3], float scale, float output[3])
{
    output[0] = vec[0] * scale;
    output[1] = vec[1] * scale;
    output[2] = vec[2] * scale;
}