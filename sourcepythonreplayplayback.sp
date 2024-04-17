//incomplete attempt to playback ayuto's sourcepython replay files in sourcemod
//https://github.com/Ayuto/ReplayBot

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define MAX_REPLAY_LENGTH 100000
#define TICK_RATE 100.0
#define REPLAY_DIRECTORY "data/trickreplay"

enum struct ReplayData {
    float origin[3];
    float angles[2];
    int buttons;
}

ReplayData g_ReplayData[MAX_REPLAY_LENGTH];
int g_ReplayLength = 0;
int g_ReplayIndex = 0;
bool g_IsPlayingReplay = false;
bool g_IsPaused = false;
int g_ReplayBot = -1;
float g_LastReplayTime = 0.0;

public void OnPluginStart() {
    RegConsoleCmd("sm_loadreplay", Command_LoadReplay);
    RegConsoleCmd("sm_startreplay", Command_StartReplay);
    RegConsoleCmd("sm_stopreplay", Command_StopReplay);
    RegConsoleCmd("sm_pausereplay", Command_PauseReplay);
    RegConsoleCmd("sm_resumereplay", Command_ResumeReplay);
    RegConsoleCmd("sm_resetreplay", Command_ResetReplay);
    RegConsoleCmd("sm_listreplays", Command_ListReplays);

    // Disable bot quota
    SetConVarInt(FindConVar("bot_quota"), 0);
    SetConVarInt(FindConVar("bot_join_after_player"), 0);

    // Disable team balancing
    SetConVarInt(FindConVar("mp_autoteambalance"), 0);
    SetConVarInt(FindConVar("mp_limitteams"), 0);

    // Create replay directory if it doesn't exist
    char replayDir[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, replayDir, sizeof(replayDir), REPLAY_DIRECTORY);
    if (!DirectoryExists(replayDir)) {
        if (!CreateDirectory(replayDir, 511)) {
            LogError("Failed to create directory: %s", replayDir);
        }
    }
}

public void OnMapStart() {
    // Precache bot model
    PrecacheModel("models/player/ct_urban.mdl", true);
}

public Action Command_LoadReplay(int client, int args) {
    if (args < 1) {
        ReplyToCommand(client, "Usage: sm_loadreplay <file>");
        return Plugin_Handled;
    }

    char replayFile[PLATFORM_MAX_PATH];
    GetCmdArg(1, replayFile, sizeof(replayFile));

    // Check for potential buffer overflow
    if (strlen(replayFile) >= PLATFORM_MAX_PATH - strlen(REPLAY_DIRECTORY) - 2) {
        ReplyToCommand(client, "Replay file name is too long.");
        return Plugin_Handled;
    }

    char filePath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, filePath, sizeof(filePath), "%s/%s", REPLAY_DIRECTORY, replayFile);

    if (!LoadReplayFile(filePath)) {
        ReplyToCommand(client, "Failed to load replay file: %s", replayFile);
        LogError("Failed to load replay file: %s", filePath);
        return Plugin_Handled;
    }

    ReplyToCommand(client, "Replay file loaded successfully. Length: %d", g_ReplayLength);

    return Plugin_Handled;
}

public Action Command_StartReplay(int client, int args) {
    if (g_ReplayLength == 0) {
        ReplyToCommand(client, "No replay file loaded.");
        return Plugin_Handled;
    }

    if (g_IsPlayingReplay) {
        ReplyToCommand(client, "Replay is already playing.");
        return Plugin_Handled;
    }

    g_ReplayIndex = 0;
    g_IsPlayingReplay = true;
    g_IsPaused = false;
    g_LastReplayTime = GetEngineTime();

    g_ReplayBot = CreateFakeClient("Replay Bot");
    if (g_ReplayBot == 0) {
        g_ReplayBot = -1; // Ensure g_ReplayBot is reset
        ReplyToCommand(client, "Failed to create replay bot.");
        LogError("Failed to create replay bot.");
        g_IsPlayingReplay = false;
        return Plugin_Handled;
    }

    ChangeClientTeam(g_ReplayBot, 2); // Set bot team to Terrorists (2)
    CS_RespawnPlayer(g_ReplayBot); // Respawn the bot
    SetEntProp(g_ReplayBot, Prop_Send, "m_iHealth", 100); // Set bot health
    SetEntProp(g_ReplayBot, Prop_Data, "m_takedamage", 0, 1); // Disable bot damage

    // Set bot model
    SetEntityModel(g_ReplayBot, "models/player/ct_urban.mdl");

    // Disable round restart
    SetConVarInt(FindConVar("mp_round_restart_delay"), 0);

    ReplyToCommand(client, "Replay started.");

    return Plugin_Handled;
}

public Action Command_StopReplay(int client, int args) {
    if (!g_IsPlayingReplay) {
        ReplyToCommand(client, "No replay is currently playing.");
        return Plugin_Handled;
    }

    g_IsPlayingReplay = false;
    g_IsPaused = false;

    if (g_ReplayBot != -1 && IsClientInGame(g_ReplayBot)) {
        KickClient(g_ReplayBot);
        g_ReplayBot = -1;
    }

    // Restore round restart delay
    SetConVarInt(FindConVar("mp_round_restart_delay"), 7);

    ReplyToCommand(client, "Replay stopped.");

    return Plugin_Handled;
}

public Action Command_PauseReplay(int client, int args) {
    if (!g_IsPlayingReplay) {
        ReplyToCommand(client, "No replay is currently playing.");
        return Plugin_Handled;
    }

    if (g_IsPaused) {
        ReplyToCommand(client, "Replay is already paused.");
        return Plugin_Handled;
    }

    g_IsPaused = true;
    ReplyToCommand(client, "Replay paused.");

    return Plugin_Handled;
}

public Action Command_ResumeReplay(int client, int args) {
    if (!g_IsPlayingReplay) {
        ReplyToCommand(client, "No replay is currently playing.");
        return Plugin_Handled;
    }

    if (!g_IsPaused) {
        ReplyToCommand(client, "Replay is not paused.");
        return Plugin_Handled;
    }

    g_IsPaused = false;
    g_LastReplayTime = GetEngineTime();
    ReplyToCommand(client, "Replay resumed.");

    return Plugin_Handled;
}

public Action Command_ResetReplay(int client, int args) {
    if (!g_IsPlayingReplay) {
        ReplyToCommand(client, "No replay is currently playing.");
        return Plugin_Handled;
    }

    g_ReplayIndex = 0;
    g_LastReplayTime = GetEngineTime();
    ReplyToCommand(client, "Replay reset.");

    return Plugin_Handled;
}

public Action Command_ListReplays(int client, int args) {
    char replayDir[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, replayDir, sizeof(replayDir), REPLAY_DIRECTORY);

    DirectoryListing dir = OpenDirectory(replayDir);
    if (dir == null) {
        ReplyToCommand(client, "Failed to open replay directory.");
        LogError("Failed to open replay directory: %s", replayDir);
        return Plugin_Handled;
    }

    char filename[PLATFORM_MAX_PATH];
    FileType fileType;
    int count = 0;

    while (dir.GetNext(filename, sizeof(filename), fileType)) {
        if (fileType == FileType_File) {
            ReplyToCommand(client, "%d. %s", ++count, filename);
        }
    }

    delete dir;

    if (count == 0) {
        ReplyToCommand(client, "No replay files found.");
    }

    return Plugin_Handled;
}

public void OnGameFrame() {
    if (!g_IsPlayingReplay || g_IsPaused || g_ReplayBot == -1 || !IsClientInGame(g_ReplayBot)) {
        return;
    }

    float currentTime = GetEngineTime();
    float frameInterval = 1.0 / TICK_RATE;
    float timeSinceLastUpdate = currentTime - g_LastReplayTime;

    if (timeSinceLastUpdate < frameInterval) {
        return;
    }

    g_LastReplayTime += frameInterval; // Increment by the expected interval

    if (g_ReplayIndex >= g_ReplayLength - 1) {
        g_ReplayIndex = 0; // Loop the replay
    } else {
        g_ReplayIndex++;
    }

    ReplayData CurrentData;
    CurrentData = g_ReplayData[g_ReplayIndex];

    // Set entity position and eye angles
    float newOrigin[3];
    newOrigin[0] = CurrentData.origin[0];
    newOrigin[1] = CurrentData.origin[1];
    newOrigin[2] = CurrentData.origin[2];

    float newAngles[3];
    newAngles[0] = CurrentData.angles[0];
    newAngles[1] = CurrentData.angles[1];
    newAngles[2] = 0.0; // Roll is usually 0 in CS:S

    // Apply replay data, currently not working for eye angles
    TeleportEntity(g_ReplayBot, newOrigin, newAngles, NULL_VECTOR);
}

public Action OnBotTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) {
    if (victim == g_ReplayBot) {
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

bool LoadReplayFile(const char[] filePath) {
    g_ReplayLength = 0;

    File fileHandle = OpenFile(filePath, "r");
    if (fileHandle == null) {
        LogError("Failed to open replay file: %s", filePath);
        return false;
    }

    char line[256];
    while (fileHandle.ReadLine(line, sizeof(line))) {
        if (g_ReplayLength >= MAX_REPLAY_LENGTH) {
            LogError("Replay file exceeds maximum allowed length: %d", MAX_REPLAY_LENGTH);
            break;
        }

        if (strlen(line) == 0) {
            continue;
        }

        char parts[6][32];
        int numParts = ExplodeString(line, "|", parts, sizeof(parts), sizeof(parts[]));
        if (numParts != 6) {
            LogError("Invalid replay data format: %s", line);
            continue;
        }

        float originX, originY, originZ, pitchAngle, yawAngle;
        int buttons;

        if (!StringToFloatEx(parts[0], originX) ||
            !StringToFloatEx(parts[1], originY) ||
            !StringToFloatEx(parts[2], originZ) ||
            !StringToFloatEx(parts[3], pitchAngle) ||
            !StringToFloatEx(parts[4], yawAngle) ||
            !StringToIntEx(parts[5], buttons)) {
            LogError("Failed to parse replay data: %s", line);
            continue;
        }

        g_ReplayData[g_ReplayLength].origin[0] = originX;
        g_ReplayData[g_ReplayLength].origin[1] = originY;
        g_ReplayData[g_ReplayLength].origin[2] = originZ;
        g_ReplayData[g_ReplayLength].angles[0] = pitchAngle;
        g_ReplayData[g_ReplayLength].angles[1] = yawAngle;
        g_ReplayData[g_ReplayLength].buttons = buttons;

        g_ReplayLength++;
    }

    if (fileHandle.EndOfFile() && g_ReplayLength == 0) {
        LogError("Replay file is empty or corrupted: %s", filePath);
    }

    delete fileHandle;
    return true;
}

bool DirectoryExists(const char[] path) {
    Handle dir = OpenDirectory(path);
    if (dir == null) {
        return false;
    }
    CloseHandle(dir);
    return true;
} 
