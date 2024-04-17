//https://github.com/lua9520/source-engine-2018-hl2_src/blob/3bf9df6b2785fa6d951086978a3e66f49427166a/engine/baseclient.cpp#L202
//requirements: cl_restrict_server_commands 0

#include <sourcemod>
#include <dhooks>
#include <sdktools>
#include <clients>
#include <convars>
#include <console>
#include <string>

#pragma semicolon 1
#pragma newdecls required

ConVar g_Cvar_UpdateRate;
ConVar g_Cvar_CmdRate;
ConVar g_Cvar_MinUpdateRate;
ConVar g_Cvar_MinCmdRate;
ConVar g_Cvar_MaxUpdateRate;
ConVar g_Cvar_MaxCmdRate;

int g_iTickrate;

public void OnPluginStart()
{
    float flTickInterval = GetTickInterval();
    if (flTickInterval > 0.0)
    {
        g_iTickrate = RoundToNearest(1.0 / flTickInterval);
        ValidateTickrate();
    }
    else
    {
        SetFailState("Invalid tick interval value.");
    }

    g_Cvar_UpdateRate = CreateConVar("sm_updaterate", "", "Custom cl_updaterate value", FCVAR_PROTECTED);
    g_Cvar_CmdRate = CreateConVar("sm_cmdrate", "", "Custom cl_cmdrate value", FCVAR_PROTECTED);
    g_Cvar_MinUpdateRate = CreateConVar("sm_minupdaterate", "", "Custom sv_minupdaterate value", FCVAR_PROTECTED);
    g_Cvar_MinCmdRate = CreateConVar("sm_mincmdrate", "", "Custom sv_mincmdrate value", FCVAR_PROTECTED);
    g_Cvar_MaxUpdateRate = CreateConVar("sm_maxupdaterate", "", "Custom sv_maxupdaterate value", FCVAR_PROTECTED);
    g_Cvar_MaxCmdRate = CreateConVar("sm_maxcmdrate", "", "Custom sv_maxcmdrate value", FCVAR_PROTECTED);

    SetRates();

    HookEvent("player_spawn", Event_PlayerSpawn);

    AutoExecConfig(true, "ratesunlocker");
}

public void OnConfigsExecuted()
{
    Handle hGameData = LoadGameConfigFile("ratesunlocker.games");
    if (hGameData == null)
    {
        SetFailState("Failed to load ratesunlocker.games.txt");
    }

    int iOffset = GameConfGetOffset(hGameData, "CBaseClient::SetUserCVar");
    if (iOffset == -1)
    {
        SetFailState("Failed to get SetUserCvar offset.");
    }

    DynamicDetour hDetour = DynamicDetour.FromConf(hGameData, "CBaseClient::SetUserCVar");
    if (hDetour == null)
    {
        SetFailState("Failed to create detour for SetUserCvar.");
    }

    if (!hDetour.Enable(Hook_Pre, Detour_OnConVarChanged))
    {
        SetFailState("Failed to detour SetUserCvar.");
    }

    LogMessage("Detour for SetUserCvar successfully enabled.");

    int iOffsetUpdateRate = GameConfGetOffset(hGameData, "CBaseClient::SetUpdateRate");
    if (iOffsetUpdateRate == -1)
    {
        SetFailState("Failed to get SetUpdateRate offset.");
    }

    DynamicDetour hDetourUpdateRate = DynamicDetour.FromConf(hGameData, "CBaseClient::SetUpdateRate");
    if (hDetourUpdateRate == null)
    {
        SetFailState("Failed to create detour for SetUpdateRate.");
    }

    if (!hDetourUpdateRate.Enable(Hook_Pre, Detour_SetUpdateRate))
    {
        SetFailState("Failed to detour CBaseClient::SetUpdateRate.");
    }

    LogMessage("Detour for CBaseClient::SetUpdateRate successfully enabled.");

    CloseHandle(hGameData);
}

public MRESReturn Detour_SetUpdateRate(DHookParam hParams)
{
    hParams.Set(1, g_iTickrate);

    //return MRES_Supercede;
    return MRES_ChangedHandled;
    //the next best approach is to use a post-hook to manipulate m_fSnapshotInterval right after SetUpdateRate has run? not sure how to fully do this
    //https://github.com/lua9520/source-engine-2018-hl2_src/blob/3bf9df6b2785fa6d951086978a3e66f49427166a/engine/baseclient.cpp#L202
}

public MRESReturn Detour_OnConVarChanged(DHookParam hParams)
{
    char sConVarName[64];
    hParams.GetString(2, sConVarName, sizeof(sConVarName));

    if (StrEqual(sConVarName, "cl_updaterate") || StrEqual(sConVarName, "cl_cmdrate"))
    {
        int client = hParams.Get(1);
        if (IsValidConnectedClient(client))
        {
            UpdateClientRates(client);
        }
    }

    return MRES_Ignored;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (IsValidConnectedClient(client))
    {
        UpdateClientRates(client);
    }
}

public void OnClientConnected(int client)
{
    if (IsValidConnectedClient(client))
    {
        UpdateClientRates(client);
    }
}

public void UpdateClientRates(int client)
{
    if (IsValidConnectedClient(client))
    {
        char cmdUpdateRate[64];
        Format(cmdUpdateRate, sizeof(cmdUpdateRate), "cl_updaterate %d", g_iTickrate);
        ClientCommand(client, cmdUpdateRate);

        char cmdCmdRate[64];
        Format(cmdCmdRate, sizeof(cmdCmdRate), "cl_cmdrate %d", g_iTickrate);
        ClientCommand(client, cmdCmdRate);
    }
}

void SetRates()
{
    char sTickrate[8];
    IntToString(g_iTickrate, sTickrate, sizeof(sTickrate));

    g_Cvar_UpdateRate.SetString(sTickrate);
    g_Cvar_CmdRate.SetString(sTickrate);
    g_Cvar_MinUpdateRate.SetString(sTickrate);
    g_Cvar_MinCmdRate.SetString(sTickrate);
    g_Cvar_MaxUpdateRate.SetString(sTickrate);
    g_Cvar_MaxCmdRate.SetString(sTickrate);

    ServerCommand("sv_mincmdrate %s", sTickrate);
    ServerCommand("sv_minupdaterate %s", sTickrate);
    ServerCommand("sv_maxcmdrate %s", sTickrate);
    ServerCommand("sv_maxupdaterate %s", sTickrate);
}

void ValidateTickrate()
{
    if (g_iTickrate <= 0)
    {
        LogError("Invalid tickrate value. Tickrate must be a positive integer. Defaulting to 100.");
        g_iTickrate = 100;
    }
    else if (g_iTickrate > 1000)
    {
        LogError("Invalid tickrate value. Tickrate cannot exceed 1000. Defaulting to 100.");
        g_iTickrate = 100;
    }
}

bool IsValidConnectedClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientConnected(client) && !IsFakeClient(client));
}
