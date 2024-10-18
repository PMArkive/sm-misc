#include <sourcemod>
#include <sdktools>
#include <connect>

#pragma semicolon 1
#pragma newdecls required

#include "include/connection_delay.inc"

enum struct ClientData
{
    char name[MAX_NAME_LENGTH];
    char ip[64];
    char steamID[64];
    bool isDelayed;
    float delayUntil;
    int reconnectAttempts;
}

ArrayList g_DelayedClients;
StringMap g_SteamIDMap;
StringMap g_IPMap;

ConVar g_cvDebug;
ConVar g_cvMaxReconnectAttempts;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNative("CD_DelayClientConnection", Native_DelayClientConnection);
    CreateNative("CD_AllowClientConnection", Native_AllowClientConnection);
    CreateNative("CD_IsClientDelayed", Native_IsClientDelayed);
    
    RegPluginLibrary("connection_delay");
    
    return APLRes_Success;
}

public void OnPluginStart()
{
    g_DelayedClients = new ArrayList(sizeof(ClientData));
    g_SteamIDMap = new StringMap();
    g_IPMap = new StringMap();

    g_cvDebug = CreateConVar("cd_debug", "0", "Enable debug logging", _, true, 0.0, true, 1.0);
    g_cvMaxReconnectAttempts = CreateConVar("cd_max_reconnect_attempts", "5", "Maximum number of reconnect attempts before allowing connection", _, true, 1.0);

    CreateTimer(1.0, Timer_ProcessDelayedConnections, _, TIMER_REPEAT);
}

public void OnPluginEnd()
{
    delete g_DelayedClients;
    delete g_SteamIDMap;
    delete g_IPMap;
}

public bool OnClientPreConnectEx(const char[] name, char password[255], const char[] ip, const char[] steamID, char rejectReason[255])
{
    if (g_cvDebug.BoolValue)
    {
        LogMessage("OnClientPreConnectEx: %s (%s) - %s", name, ip, steamID);
    }

    int index = -1;
    if (g_SteamIDMap.GetValue(steamID, index) && index != -1)
    {
        ClientData data;
        g_DelayedClients.GetArray(index, data);

        if (data.isDelayed)
        {
            if (GetGameTime() < data.delayUntil)
            {
                float remainingTime = data.delayUntil - GetGameTime();
                Format(rejectReason, sizeof(rejectReason), "Connection delayed. Please try again in %.1f seconds.", remainingTime);
                return false;
            }
        }
    }

    return true;
}

public bool OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
    if (g_cvDebug.BoolValue)
    {
        LogMessage("OnClientConnect: client %d", client);
    }

    char steamID[64];
    if (!GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID)))
    {
        LogError("Failed to get SteamID for client %d in OnClientConnect", client);
        return true;
    }

    return CheckDelayedConnection(steamID, rejectmsg, maxlen);
}

bool CheckDelayedConnection(const char[] steamID, char[] rejectMessage, int maxlen)
{
    int index = -1;
    if (g_SteamIDMap.GetValue(steamID, index) && index != -1)
    {
        ClientData data;
        g_DelayedClients.GetArray(index, data);

        if (data.isDelayed)
        {
            if (GetGameTime() < data.delayUntil)
            {
                float remainingTime = data.delayUntil - GetGameTime();
                Format(rejectMessage, maxlen, "Connection delayed. Please try again in %.1f seconds.", remainingTime);
                return false;
            }
            else
            {
                data.isDelayed = false;
                g_DelayedClients.SetArray(index, data);
                if (g_cvDebug.BoolValue)
                {
                    LogMessage("Delay expired for %s, allowing connection", steamID);
                }
            }
        }
    }

    return true;
}

public void OnClientConnected(int client)
{
    if (g_cvDebug.BoolValue)
    {
        LogMessage("OnClientConnected: client %d", client);
    }

    char steamID[64];
    if (GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID)))
    {
        int index = -1;
        if (g_SteamIDMap.GetValue(steamID, index) && index != -1)
        {
            ClientData data;
            g_DelayedClients.GetArray(index, data);

            if (data.isDelayed)
            {
                if (GetGameTime() < data.delayUntil)
                {
                    data.reconnectAttempts++;
                    g_DelayedClients.SetArray(index, data);

                    if (data.reconnectAttempts < g_cvMaxReconnectAttempts.IntValue)
                    {
                        RequestFrame(Frame_ReconnectClient, GetClientUserId(client));
                    }
                    else
                    {
                        data.isDelayed = false;
                        g_DelayedClients.SetArray(index, data);
                        Call_StartForward(CreateGlobalForward("CD_OnClientDelayedConnect", ET_Ignore, Param_Cell, Param_String));
                        Call_PushCell(client);
                        Call_PushString(steamID);
                        Call_Finish();
                    }
                }
                else
                {
                    data.isDelayed = false;
                    g_DelayedClients.SetArray(index, data);
                    Call_StartForward(CreateGlobalForward("CD_OnClientDelayedConnect", ET_Ignore, Param_Cell, Param_String));
                    Call_PushCell(client);
                    Call_PushString(steamID);
                    Call_Finish();
                }
            }
        }
    }
    else
    {
        LogError("Failed to get SteamID for client %d in OnClientConnected", client);
    }
}

public void OnClientDisconnect(int client)
{
    char steamID[64];
    if (GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID)))
    {
        int index = -1;
        if (g_SteamIDMap.GetValue(steamID, index) && index != -1)
        {
            g_DelayedClients.Erase(index);
            g_SteamIDMap.Remove(steamID);
        }
    }

    char ip[64];
    if (GetClientIP(client, ip, sizeof(ip)))
    {
        g_IPMap.Remove(ip);
    }
}

public void Frame_ReconnectClient(any userid)
{
    int client = GetClientOfUserId(userid);
    if (client && IsClientConnected(client))
    {
        ReconnectClient(client);
    }
}

public Action Timer_ProcessDelayedConnections(Handle timer)
{
    float currentTime = GetGameTime();

    for (int i = 0; i < g_DelayedClients.Length; i++)
    {
        ClientData data;
        g_DelayedClients.GetArray(i, data);

        if (data.isDelayed && currentTime >= data.delayUntil)
        {
            data.isDelayed = false;
            g_DelayedClients.SetArray(i, data);

            if (g_cvDebug.BoolValue)
            {
                LogMessage("Delayed connection expired for %s (%s)", data.name, data.steamID);
            }
        }
    }

    return Plugin_Continue;
}

public int Native_DelayClientConnection(Handle plugin, int numParams)
{
    char steamID[64];
    GetNativeString(1, steamID, sizeof(steamID));

    float delayTime = GetNativeCell(2);

    int index = -1;
    if (!g_SteamIDMap.GetValue(steamID, index))
    {
        ClientData data;
        strcopy(data.steamID, sizeof(data.steamID), steamID);
        data.isDelayed = true;
        data.delayUntil = GetGameTime() + delayTime;
        data.reconnectAttempts = 0;

        index = g_DelayedClients.PushArray(data);
        g_SteamIDMap.SetValue(steamID, index);

        if (g_cvDebug.BoolValue)
        {
            LogMessage("Delayed connection for %s for %.1f seconds", steamID, delayTime);
        }

        return true;
    }

    return false;
}

public int Native_AllowClientConnection(Handle plugin, int numParams)
{
    char steamID[64];
    GetNativeString(1, steamID, sizeof(steamID));

    int index = -1;
    if (g_SteamIDMap.GetValue(steamID, index) && index != -1)
    {
        ClientData data;
        g_DelayedClients.GetArray(index, data);
        data.isDelayed = false;
        g_DelayedClients.SetArray(index, data);

        if (g_cvDebug.BoolValue)
        {
            LogMessage("Allowed connection for %s", steamID);
        }

        return true;
    }

    return false;
}

public int Native_IsClientDelayed(Handle plugin, int numParams)
{
    char steamID[64];
    GetNativeString(1, steamID, sizeof(steamID));

    int index = -1;
    if (g_SteamIDMap.GetValue(steamID, index) && index != -1)
    {
        ClientData data;
        g_DelayedClients.GetArray(index, data);
        return data.isDelayed;
    }

    return false;
}


