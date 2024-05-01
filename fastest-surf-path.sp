//fastest path between two set points

#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <convar>
#include <sdkhooks>
#include <command>
#include <console>
#include "b.inc"

#define MAX_POINTS 2
#define GRAVITY 800.0
#define TICKRATE 100
#define CURVE_RESOLUTION 100

float g_SurfPoints[MAXPLAYERS + 1][MAX_POINTS][3];         
bool g_SelectedPoints[MAXPLAYERS + 1][MAX_POINTS];          
float g_AirAccelerate;                                      
float g_TickInterval;                                       
int g_GlowSprite;
bool g_ShowGlowSprites = true;

public void OnPluginStart()
{
    RegConsoleCmd("sm_surfmenu", Command_SurfMenu, "Opens the surf ramp path calculator menu");
    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
    g_AirAccelerate = GetConVarFloat(FindConVar("sv_airaccelerate"));
    g_TickInterval = 1.0 / TICKRATE;
    g_GlowSprite = PrecacheModel("materials/sprites/blueglow1.vmt");
    CreateConVar("sm_show_glowsprites", "1", "Toggle display of glow sprites for points", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    HookConVarChange(FindConVar("sm_show_glowsprites"), ConVarChange_ShowGlowSprites);
    CreateTimer(0.1, Timer_DrawPoints, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public void ConVarChange_ShowGlowSprites(ConVar cvar, const char[] oldValue, const char[] newValue)
{
    g_ShowGlowSprites = StrEqual(newValue, "1");
}


public Action Command_SurfMenu(int client, int args)
{
    if (!IsValidClient(client))
    {
        return Plugin_Handled;
    }
    ShowSurfMenu(client);
    return Plugin_Handled;
}

void ShowSurfMenu(int client)
{
    Menu menu = new Menu(MenuHandler_SurfMenu);
    menu.SetTitle("Surf Ramp Path Calculator");
    if (!g_SelectedPoints[client][0])
    {
        menu.AddItem("point_a", "Set Point A");
    }
    else
    {
        menu.AddItem("point_a", "Point A (Selected)", ITEMDRAW_DISABLED);
    }
    if (!g_SelectedPoints[client][1])
    {
        menu.AddItem("point_b", "Set Point B");
    }
    else
    {
        menu.AddItem("point_b", "Point B (Selected)", ITEMDRAW_DISABLED);
    }
    if (g_SelectedPoints[client][0] && g_SelectedPoints[client][1])
    {
        menu.AddItem("calculate", "Calculate Fastest Path");
    }
    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_SurfMenu(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(param2, info, sizeof(info));
        if (StrEqual(info, "point_a"))
        {
            SetPoint(param1, 0);
        }
        else if (StrEqual(info, "point_b"))
        {
            SetPoint(param1, 1);
        }
        else if (StrEqual(info, "calculate"))
        {
            CalculateFastestPath(param1);
        }
        ShowSurfMenu(param1);
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
}

void SetPoint(int client, int index)
{
    float startPos[3], angles[3], endPos[3];
    GetClientEyePosition(client, startPos);
    GetClientEyeAngles(client, angles);
    Handle trace = TR_TraceRayFilterEx(startPos, angles, MASK_SOLID, RayType_Infinite, TraceFilter_AllSolid, client);
    if (TR_DidHit(trace))
    {
        TR_GetEndPosition(endPos, trace);
        g_SurfPoints[client][index][0] = endPos[0];
        g_SurfPoints[client][index][1] = endPos[1];
        g_SurfPoints[client][index][2] = endPos[2];
        g_SelectedPoints[client][index] = true;
        PrintToChat(client, "Point %c set at (%.2f, %.2f, %.2f)", index == 0 ? 'A' : 'B', endPos[0], endPos[1], endPos[2]);
    }
    else
    {
        PrintToChat(client, "No valid surface found under the crosshair.");
    }

    delete trace;
}

public bool TraceFilter_AllSolid(int entity, int contentsMask, int client)
{
    return entity != client;
}

void CalculateFastestPath(int client)
{
    float vStart[3], vEnd[3], vVelocity[3];
    vStart = g_SurfPoints[client][0];
    vEnd = g_SurfPoints[client][1];
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVelocity);
    float fRampAngle = CalculateRampAngle(vStart, vEnd);
    float fFastestTime = CalculateFastestTime(vStart, vEnd, fRampAngle, vVelocity);
    PrintToChat(client, "Fastest time between points: %.2f seconds", fFastestTime);
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (IsValidClient(client))
    {
        ResetSelectedPoints(client);
    }
}

bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client));
}

void ResetSelectedPoints(int client)
{
    for (int i = 0; i < MAX_POINTS; i++)
    {
        g_SelectedPoints[client][i] = false;
        for (int j = 0; j < 3; j++)
        {
            g_SurfPoints[client][i][j] = 0.0;
        }
    }
}

float CalculateRampAngle(const float vStart[3], const float vEnd[3])
{
    float fDeltaX = vEnd[0] - vStart[0];
    float fDeltaY = vEnd[1] - vStart[1];
    float fDeltaZ = vEnd[2] - vStart[2];
    return ArcTangent2(SquareRoot(fDeltaX * fDeltaX + fDeltaY * fDeltaY), fDeltaZ);
}

float CalculateFastestTime(const float vStart[3], const float vEnd[3], float fRampAngle, const float vVelocity[3])
{
    float fScalingFactor = CalculateScalingFactor(vStart, vEnd);
    float fThetaMax = CalculateThetaMax(vStart, vEnd);
    float fFastestTime = 0.0;
    float fDeltaTheta = fThetaMax / CURVE_RESOLUTION;
    float fPrevX = 0.0;
    float fPrevY = 0.0;
    float fPrevVelocity = GetVectorLength(vVelocity);
    for (int i = 1; i <= CURVE_RESOLUTION; i++)
    {
        float fTheta = i * fDeltaTheta;
        float fX = fScalingFactor * (fTheta - Sine(fTheta));
        float fY = fScalingFactor * (1 - Cosine(fTheta));
        float fDistance = SquareRoot(Pow(fX - fPrevX, 2.0) + Pow(fY - fPrevY, 2.0));
        float fAcceleration = g_AirAccelerate * g_TickInterval;
        float fGravityComponent = GRAVITY * Sine(fRampAngle) * g_TickInterval;
        float fTime = CalculateSegmentTime(fDistance, fPrevVelocity, fAcceleration, fGravityComponent);
        fFastestTime += fTime;
        fPrevX = fX;
        fPrevY = fY;
        fPrevVelocity = CalculateSegmentEndVelocity(fPrevVelocity, fAcceleration, fGravityComponent, fTime);
    }
    return fFastestTime;
}

float CalculateScalingFactor(const float vStart[3], const float vEnd[3])
{
    float fDeltaX = vEnd[0] - vStart[0];
    float fDeltaY = vEnd[1] - vStart[1];
    float fDistance = SquareRoot(fDeltaX * fDeltaX + fDeltaY * fDeltaY);
    return fDistance / (2.0 * FLOAT_PI);
}

float CalculateThetaMax(const float vStart[3], const float vEnd[3])
{
    float fDeltaX = vEnd[0] - vStart[0];
    float fDeltaY = vEnd[1] - vStart[1];
    return ArcTangent2(fDeltaY, fDeltaX);
}

float CalculateSegmentTime(float fDistance, float fInitialVelocity, float fAcceleration, float fGravityComponent)
{
    float fDiscriminant = Pow(fInitialVelocity, 2.0) + 2.0 * (fAcceleration + fGravityComponent) * fDistance;
    if (fDiscriminant < 0.0)
    {
        return 0.0;
    }
    float fTime1 = (-fInitialVelocity + SquareRoot(fDiscriminant)) / (fAcceleration + fGravityComponent);
    float fTime2 = (-fInitialVelocity - SquareRoot(fDiscriminant)) / (fAcceleration + fGravityComponent);
    return MaxValue(fTime1, fTime2);
}

float CalculateSegmentEndVelocity(float fInitialVelocity, float fAcceleration, float fGravityComponent, float fTime)
{
    return fInitialVelocity + (fAcceleration + fGravityComponent) * fTime;
}

float MaxValue(float a, float b)
{
    return (a > b) ? a : b;
}

float GetVectorLength(const float vec[3])
{
    return SquareRoot(vec[0] * vec[0] + vec[1] * vec[1] + vec[2] * vec[2]);
}

public void OnMapStart()
{
    g_GlowSprite = PrecacheModel("materials/sprites/blueglow1.vmt");

    CreateTimer(0.1, Timer_DrawPoints, _, TIMER_REPEAT);
}

public Action Timer_DrawPoints(Handle timer)
{
    if (!g_ShowGlowSprites) {
        return Plugin_Continue;
    }

    for (int client = 1; client <= MaxClients; client++)
    {
        if (IsValidClient(client))
        {
            for (int i = 0; i < MAX_POINTS; i++)
            {
                if (g_SelectedPoints[client][i])
                {
                    float origin[3];
                    origin[0] = g_SurfPoints[client][i][0];
                    origin[1] = g_SurfPoints[client][i][1];
                    origin[2] = g_SurfPoints[client][i][2];
                    
                    TE_SetupGlowSprite(origin, g_GlowSprite, 0.1, 0.5, 255);
                    TE_SendToAll();
                }
            }
        }
    }

    return Plugin_Continue;
}

float ArcTangent2(float y, float x)
{
    if (x == 0.0)
    {
        return y > 0.0 ? FLOAT_PI / 2 : (y < 0.0 ? -FLOAT_PI / 2 : 0.0);
    }
    return ArcTangent(y / x) + (x < 0.0 ? FLOAT_PI : 0.0);
}

float Sine(float x)
{
    return Sine(x * FLOAT_PI / 180.0);
}

float Cosine(float x)
{
    return Cosine(x * FLOAT_PI / 180.0);
}
