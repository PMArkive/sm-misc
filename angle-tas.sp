//https://github.com/followingthefasciaplane/angle-scripts-for-tas

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define MAX_ANGLES 8

char g_angleNames[MAX_ANGLES][32] =
{
    "Forwards",
    "Backwards",
    "Sideways 1",
    "Sideways 2",
    "Half-sideways 1",
    "Half-sideways 2",
    "Backwards Half-sideways 1",
    "Backwards Half-sideways 2"
};

int g_angleTypes[MAX_ANGLES] =
{
    0,   // Forwards
    180, // Backwards
    90,  // Sideways 1
    270, // Sideways 2
    45,  // Half-sideways 1
    315, // Half-sideways 2
    135, // Backwards Half-sideways 1
    225  // Backwards Half-sideways 2
};

float g_fakeAngles[MAXPLAYERS + 1][3];
int g_currentAngle[MAXPLAYERS + 1];

public void OnPluginStart()
{
    RegConsoleCmd("sm_surfangle", Command_SurfAngle, "Changes the player's surfing angle");
}

public void OnClientPutInServer(int client)
{
    g_fakeAngles[client][0] = 0.0;
    g_fakeAngles[client][1] = 0.0;
    g_fakeAngles[client][2] = 0.0;
    g_currentAngle[client] = -1;

    SDKHook(client, SDKHook_ProcessUsercmds, Hook_ProcessUsercmds);
}

public void OnClientDisconnect(int client)
{
    g_fakeAngles[client][0] = 0.0;
    g_fakeAngles[client][1] = 0.0;
    g_fakeAngles[client][2] = 0.0;
    g_currentAngle[client] = -1;

    SDKUnhook(client, SDKHook_ProcessUsercmds, Hook_ProcessUsercmds);
}

public void OnPlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0)
    {
        g_fakeAngles[client][0] = 0.0;
        g_fakeAngles[client][1] = 0.0;
        g_fakeAngles[client][2] = 0.0;
        g_currentAngle[client] = -1;
    }
}

public Action Command_SurfAngle(int client, int args)
{
    if (args < 1)
    {
        PrintToConsole(client, "Usage: sm_surfangle <angle>");
        PrintToConsole(client, "Available angles:");
        for (int i = 0; i < MAX_ANGLES; i++)
        {
            PrintToConsole(client, "%d. %s", i + 1, g_angleNames[i]);
        }
        return Plugin_Handled;
    }

    char arg[32];
    GetCmdArg(1, arg, sizeof(arg));
    int angle = StringToInt(arg) - 1;

    if (angle < 0 || angle >= MAX_ANGLES)
    {
        PrintToConsole(client, "Invalid angle. Please enter a value between 1 and %d.", MAX_ANGLES);
        return Plugin_Handled;
    }

    g_currentAngle[client] = angle;

    PrintHintText(client, "Surfing angle changed to: %s", g_angleNames[angle]);

    return Plugin_Handled;
}

public Action Hook_ProcessUsercmds(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
    if (client <= 0 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client))
        return Plugin_Continue;

    if (g_currentAngle[client] == -1)
        return Plugin_Continue;

    float clientAngles[3];
    clientAngles[0] = angles[0];
    clientAngles[1] = angles[1];
    clientAngles[2] = angles[2];

    switch (g_angleTypes[g_currentAngle[client]])
    {
        case 0:   // Forwards
        {
            // No adjustment needed
        }
        case 180: // Backwards
        {
            clientAngles[1] = angles[1] + 180.0;
            SetLocalMoveCommand(client, IN_FORWARD, IN_BACK);
            SetLocalMoveCommand(client, IN_BACK, IN_FORWARD);
            SetLocalMoveCommand(client, IN_MOVELEFT, IN_MOVERIGHT);
            SetLocalMoveCommand(client, IN_MOVERIGHT, IN_MOVELEFT);
        }
        case 90:  // Sideways 1
        {
            clientAngles[1] = angles[1] + 90.0;
            SetLocalMoveCommand(client, IN_FORWARD, IN_MOVERIGHT);
            SetLocalMoveCommand(client, IN_BACK, IN_MOVELEFT);
            SetLocalMoveCommand(client, IN_MOVELEFT, IN_BACK);
            SetLocalMoveCommand(client, IN_MOVERIGHT, IN_FORWARD);
        }
        case 270: // Sideways 2
        {
            clientAngles[1] = angles[1] + 270.0;
            SetLocalMoveCommand(client, IN_FORWARD, IN_MOVELEFT);
            SetLocalMoveCommand(client, IN_BACK, IN_MOVERIGHT);
            SetLocalMoveCommand(client, IN_MOVELEFT, IN_FORWARD);
            SetLocalMoveCommand(client, IN_MOVERIGHT, IN_BACK);
        }
        case 45:  // Half-sideways 1
        {
            clientAngles[1] = angles[1] + 45.0;
            SetLocalMoveCommand(client, IN_FORWARD, IN_FORWARD | IN_MOVERIGHT);
            SetLocalMoveCommand(client, IN_BACK, IN_BACK | IN_MOVELEFT);
            SetLocalMoveCommand(client, IN_MOVELEFT, IN_FORWARD | IN_MOVELEFT);
            SetLocalMoveCommand(client, IN_MOVERIGHT, IN_BACK | IN_MOVERIGHT);
        }
        case 315: // Half-sideways 2
        {
            clientAngles[1] = angles[1] + 315.0;
            SetLocalMoveCommand(client, IN_FORWARD, IN_FORWARD | IN_MOVELEFT);
            SetLocalMoveCommand(client, IN_BACK, IN_BACK | IN_MOVERIGHT);
            SetLocalMoveCommand(client, IN_MOVELEFT, IN_BACK | IN_MOVELEFT);
            SetLocalMoveCommand(client, IN_MOVERIGHT, IN_FORWARD | IN_MOVERIGHT);
        }
        case 135: // Backwards Half-sideways 1
        {
            clientAngles[1] = angles[1] + 135.0;
            SetLocalMoveCommand(client, IN_FORWARD, IN_BACK | IN_MOVERIGHT);
            SetLocalMoveCommand(client, IN_BACK, IN_FORWARD | IN_MOVELEFT);
            SetLocalMoveCommand(client, IN_MOVELEFT, IN_BACK | IN_MOVELEFT);
            SetLocalMoveCommand(client, IN_MOVERIGHT, IN_FORWARD | IN_MOVERIGHT);
        }
        case 225: // Backwards Half-sideways 2
        {
            clientAngles[1] = angles[1] + 225.0;
            SetLocalMoveCommand(client, IN_FORWARD, IN_BACK | IN_MOVELEFT);
            SetLocalMoveCommand(client, IN_BACK, IN_FORWARD | IN_MOVERIGHT);
            SetLocalMoveCommand(client, IN_MOVELEFT, IN_FORWARD | IN_MOVELEFT);
            SetLocalMoveCommand(client, IN_MOVERIGHT, IN_BACK | IN_MOVERIGHT);
        }
    }

    // Normalize the adjusted angles
    while (clientAngles[1] > 180.0)
        clientAngles[1] -= 360.0;
    while (clientAngles[1] < -180.0)
        clientAngles[1] += 360.0;

    // Set the adjusted angles for the client's input
    // SetClientViewEntity(client, client);
    SetEntPropVector(client, Prop_Send, "m_vecViewOffset[1]", clientAngles[1]); //???

    return Plugin_Changed;
}

void SetLocalMoveCommand(int client, int button, int newButtons)
{
    //This is incomplete and does not handle HSW
    int buttons = GetEntProp(client, Prop_Data, "m_nButtons");
    buttons &= ~button;
    buttons |= newButtons;
    SetEntPropFloat(client, Prop_Send, "m_flForwardMove", (buttons & IN_FORWARD) ? 450.0 : ((buttons & IN_BACK) ? -450.0 : 0.0)); 
    SetEntPropFloat(client, Prop_Send, "m_flSideMove", (buttons & IN_MOVERIGHT) ? 450.0 : ((buttons & IN_MOVELEFT) ? -450.0 : 0.0));
    SetEntPropFloat(client, Prop_Send, "m_flUpMove", (buttons & IN_JUMP) ? 450.0 : 0.0);
}
