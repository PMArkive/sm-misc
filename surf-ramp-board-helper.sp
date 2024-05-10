#include <sourcemod>
#include <sdktools>
// #include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.7"
#define MIN_SURFACE_NORMAL_Z 0.1
#define MAX_SURFACE_NORMAL_Z 0.7

public Plugin myinfo = {
    name = "surf board helper",
    author = "jesse",
    description = "detects perfect boards on surf ramps",
    version = PLUGIN_VERSION,
    url = "http://www.gcpdot.com/"
};

bool g_bTouchingRamp[MAXPLAYERS + 1];
bool g_bJustStartedTouchingRamp[MAXPLAYERS + 1];
float g_fPreBoardVelocity[MAXPLAYERS + 1][3];
bool g_bDebugMode;
float g_fPerfectBoardThreshold;
float TRACE_DISTANCE;

ConVar g_cvDebugMode;
ConVar g_cvPerfectBoardThreshold;
ConVar g_cvTraceDistance;

public void OnPluginStart() {
    CreateConVar("sm_surfboard_version", PLUGIN_VERSION, "surf board helper version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    g_cvTraceDistance = CreateConVar("sm_surfboard_trace_distance", "32.0", "distance for the trace ray to detect surf ramps", FCVAR_NOTIFY, true, 0.0, true, 100.0);
    g_cvDebugMode = CreateConVar("sm_surfboard_debug", "1", "enable debug mode", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvPerfectBoardThreshold = CreateConVar("sm_surfboard_threshold", "2.0", "threshold for perfect boards (in units)", FCVAR_NOTIFY, true, 0.0);
    AutoExecConfig(true, "surf-perfect-board");

    g_bDebugMode = g_cvDebugMode.BoolValue;
    g_fPerfectBoardThreshold = g_cvPerfectBoardThreshold.FloatValue; //higher = stricter
    TRACE_DISTANCE = g_cvTraceDistance.FloatValue; //play with this

    HookConVarChange(g_cvDebugMode, OnConVarChanged);
    HookConVarChange(g_cvPerfectBoardThreshold, OnConVarChanged);
    HookConVarChange(g_cvTraceDistance, OnConVarChanged);

    // init
    for (int i = 1; i <= MaxClients; i++) {
        ResetClientState(i);
    }
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
    if (convar == g_cvDebugMode) {
        g_bDebugMode = g_cvDebugMode.BoolValue;
        PrintToServer("Debug mode set to: %b", g_bDebugMode);
    } else if (convar == g_cvPerfectBoardThreshold) {
        g_fPerfectBoardThreshold = g_cvPerfectBoardThreshold.FloatValue;
        PrintToServer("Perfect board threshold set to: %.2f", g_fPerfectBoardThreshold);
    } else if (convar == g_cvTraceDistance) {
        TRACE_DISTANCE = g_cvTraceDistance.FloatValue;
        PrintToServer("Trace distance set to: %.2f", TRACE_DISTANCE);
    }
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2]) {
    if (!IsValidClient(client) || !IsPlayerAlive(client)) {
        return;
    }

    float currentVelocity[3];
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", currentVelocity);

    float surfaceNormal[3] = {0.0, 0.0, 0.0};
    bool isOnSurfRamp = IsPlayerOnSurfRamp(client, surfaceNormal);

    if (isOnSurfRamp) {
        if (!g_bTouchingRamp[client]) {

            g_bTouchingRamp[client] = true;
            g_bJustStartedTouchingRamp[client] = true;

            // store the pre-board velocity immediately
            for (int i = 0; i < 3; i++) {
                g_fPreBoardVelocity[client][i] = currentVelocity[i];
            }
        } else {
            // store the post-board velocity and calculate the speed difference
            float preBoardSpeed = GetVectorLength(g_fPreBoardVelocity[client]);
            float postBoardSpeed = GetVectorLength(currentVelocity);
            float speedDifference = postBoardSpeed - preBoardSpeed;

            if (g_bJustStartedTouchingRamp[client]) {
                // display the board status and debug messages
                if (speedDifference >= (0 - g_fPerfectBoardThreshold)) {
                    PrintToChat(client, "\x04Perfect board!");
                } else {
                    PrintToChat(client, "\x02Imperfect board (%.2f units lost)", -speedDifference);
                }

                if (g_bDebugMode) {
                    PrintToChat(client, "\x05Pre-board velocity: %.2f", preBoardSpeed);
                    PrintToChat(client, "\x05Post-board velocity: %.2f", postBoardSpeed);
                    PrintToChat(client, "\x05Speed difference: %.2f", speedDifference);
                }

                g_bJustStartedTouchingRamp[client] = false;
            }
        }
    } else {
        if (g_bTouchingRamp[client]) {

            g_bTouchingRamp[client] = false;
            g_bJustStartedTouchingRamp[client] = false;
        }
    }
}

bool IsValidClient(int client) {
    return (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client));
}

bool IsPlayerOnSurfRamp(int client, float surfaceNormal[3]) {
    if (!IsValidClient(client) || !IsPlayerAlive(client)) {
        return false;
    }

    // declare variables to store start and end positions for the trace
    float startPos[3], endPos[3];

    // get the clients current position and store it in startPos
    GetClientAbsOrigin(client, startPos);

    // calculate the end position for the trace
    endPos[0] = startPos[0];
    endPos[1] = startPos[1];
    endPos[2] = startPos[2] - TRACE_DISTANCE;

    // declare a handle for the trace
    Handle trace = INVALID_HANDLE;

    // perform a trace from startPos to endPos, filtering for world
    TR_TraceRayFilter(startPos, endPos, MASK_SOLID, RayType_EndPoint, TraceFilter_World, trace);

    // init
    bool result = false;

    // check if the trace hit something and the fraction is less than 1.0
    if (TR_DidHit(trace) && TR_GetFraction(trace) < 1.0) {
        float hitPos[3];

        // get the end position of the trace (i.e., the hit position)
        TR_GetEndPosition(hitPos, trace);

        // calculate the distance between startPos and hitPos
        float distance = GetVectorDistance(startPos, hitPos);

        // check if the distance is less than or equal to TRACE_DISTANCE
        if (distance <= TRACE_DISTANCE) {
            // get the surface normal at the hit position and store it in surfaceNormal
            TR_GetPlaneNormal(trace, surfaceNormal);

            // check if the Z component of the surface normal is probs a surf ramp
            result = (surfaceNormal[2] < MAX_SURFACE_NORMAL_Z && surfaceNormal[2] > MIN_SURFACE_NORMAL_Z);
        }
    }

    // close the trace handle
    CloseHandle(trace);

    // return the result (true if the player is on a surf ramp, false otherwise)
    return result;
}

//no world
public bool TraceFilter_World(int entity, int contentsMask) {
    return entity == 0;
}

void ResetClientState(int client) {
    if (g_bDebugMode) {
        PrintToServer("[Debug] Resetting client %d state", client);
    }

    g_bTouchingRamp[client] = false;
    g_bJustStartedTouchingRamp[client] = false;
    g_fPreBoardVelocity[client][0] = 0.0;
    g_fPreBoardVelocity[client][1] = 0.0;
    g_fPreBoardVelocity[client][2] = 0.0;
}
