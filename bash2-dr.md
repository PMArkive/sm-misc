## Detection Reasons

### 1. DR_StartStrafe_LowDeviation
- **Description**: Indicates very likely strafe hacks if the deviation is less than 1.0.
- **Action**: Warn admins.
- **Trigger**: This detection reason is triggered when the deviation in the player's starting strafe is less than 1.0, suggesting highly consistent and unnatural movement patterns.

**Code Snippet**:
```cpp
if (g_iStartStrafe_IdenticalCount[client] >= IDENTICAL_STRAFE_MIN)
{
    if (g_iStartStrafe_LastTickDifference[client] < 1.0)
    {
        g_iLastIllegalReason[client] |= DR_StartStrafe_LowDeviation;
    }
}
```
**Explanation**:
- This detection is triggered if the player's starting strafe has been identical for a minimum number of times (`IDENTICAL_STRAFE_MIN`).
- If the deviation (`g_iStartStrafe_LastTickDifference[client]`) is less than 1.0, the detection reason `DR_StartStrafe_LowDeviation` is flagged.

### 2. DR_StartStrafe_AlwaysPositive
- **Description**: Might not be strafe hacking but a good indicator of someone trying to bypass anticheat.
- **Action**: Warn admins.
- **Trigger**: This detection reason is triggered when the player's starting strafe always results in positive values, indicating potential attempts to bypass the anticheat system.

**Code Snippet**:
```cpp
if (g_iStartStrafe_IdenticalCount[client] >= IDENTICAL_STRAFE_MIN)
{
    if (g_iStartStrafe_LastTickDifference[client] > 0)
    {
        g_iLastIllegalReason[client] |= DR_StartStrafe_AlwaysPositive;
    }
}
```
**Explanation**:
- This detection is triggered if the player's starting strafe has been identical for a minimum number of times (`IDENTICAL_STRAFE_MIN`).
- If the deviation (`g_iStartStrafe_LastTickDifference[client]`) is always positive, the detection reason `DR_StartStrafe_AlwaysPositive` is flagged.

### 3. DR_EndStrafe_LowDeviation
- **Description**: Indicates very likely strafe hacks if the deviation is less than 1.0.
- **Action**: Warn admins.
- **Trigger**: This detection reason is triggered when the deviation in the player's ending strafe is less than 1.0, suggesting highly consistent and unnatural movement patterns.

**Code Snippet**:
```cpp
if (g_iEndStrafe_IdenticalCount[client] >= IDENTICAL_STRAFE_MIN)
{
    if (g_iEndStrafe_LastTickDifference[client] < 1.0)
    {
        g_iLastIllegalReason[client] |= DR_EndStrafe_LowDeviation;
    }
}
```
**Explanation**:
- This detection is triggered if the player's ending strafe has been identical for a minimum number of times (`IDENTICAL_STRAFE_MIN`).
- If the deviation (`g_iEndStrafe_LastTickDifference[client]`) is less than 1.0, the detection reason `DR_EndStrafe_LowDeviation` is flagged.

### 4. DR_EndStrafe_AlwaysPositive
- **Description**: Might not be strafe hacking but a good indicator of someone trying to bypass anticheat.
- **Action**: Warn admins.
- **Trigger**: This detection reason is triggered when the player's ending strafe always results in positive values, indicating potential attempts to bypass the anticheat system.

**Code Snippet**:
```cpp
if (g_iEndStrafe_IdenticalCount[client] >= IDENTICAL_STRAFE_MIN)
{
    if (g_iEndStrafe_LastTickDifference[client] > 0)
    {
        g_iLastIllegalReason[client] |= DR_EndStrafe_AlwaysPositive;
    }
}
```
**Explanation**:
- This detection is triggered if the player's ending strafe has been identical for a minimum number of times (`IDENTICAL_STRAFE_MIN`).
- If the deviation (`g_iEndStrafe_LastTickDifference[client]`) is always positive, the detection reason `DR_EndStrafe_AlwaysPositive` is flagged.

### 5. DR_StartStrafeMatchesEndStrafe
- **Description**: A way to catch an angle delay hack.
- **Action**: Do nothing.
- **Trigger**: This detection reason is triggered when the player's starting strafe matches their ending strafe, which could indicate an angle delay hack.

**Code Snippet**:
```cpp
if (g_iStartStrafe_IdenticalCount[client] >= IDENTICAL_STRAFE_MIN && g_iEndStrafe_IdenticalCount[client] >= IDENTICAL_STRAFE_MIN)
{
    if (g_iStartStrafe_LastTickDifference[client] == g_iEndStrafe_LastTickDifference[client])
    {
        g_iLastIllegalReason[client] |= DR_StartStrafeMatchesEndStrafe;
    }
}
```
**Explanation**:
- This detection is triggered if both the player's starting and ending strafe have been identical for a minimum number of times (`IDENTICAL_STRAFE_MIN`).
- If the deviation in starting strafe matches the deviation in ending strafe, the detection reason `DR_StartStrafeMatchesEndStrafe` is flagged.

### 6. DR_KeySwitchesTooPerfect
- **Description**: Could be movement config or anti-ghosting keyboard.
- **Action**: Warn admins.
- **Trigger**: This detection reason is triggered when the player's key switches are too perfect, suggesting the use of a movement configuration or an anti-ghosting keyboard.

**Code Snippet**:
```cpp
if (g_iKeySwitch_Stats[client][KeySwitchData_Difference][BT_Key][g_iKeySwitch_CurrentFrame[client][BT_Key]] < 1.0)
{
    g_iLastIllegalReason[client] |= DR_KeySwitchesTooPerfect;
}
```
**Explanation**:
- This detection is triggered if the difference in key switches (`g_iKeySwitch_Stats[client][KeySwitchData_Difference][BT_Key][g_iKeySwitch_CurrentFrame[client][BT_Key]]`) is less than 1.0, indicating highly consistent and unnatural key switches.

### 7. DR_FailedManualAngleTest
- **Description**: Almost definitely strafe hacking.
- **Action**: Ban.
- **Trigger**: This detection reason is triggered when the player fails a manual angle test, indicating almost definite strafe hacking.

**Code Snippet**:
```cpp
if (g_iYawChangeCount[client] > 0)
{
    g_iLastIllegalReason[client] |= DR_FailedManualAngleTest;
}
```
**Explanation**:
- This detection is triggered if the player's yaw change count (`g_iYawChangeCount[client]`) is greater than 0, indicating that the player has failed a manual angle test.

### 8. DR_ButtonsAndSideMoveDontMatch
- **Description**: Could be caused by lag but can be made to detect strafe hacks perfectly.
- **Action**: Ban/Warn based on severity.
- **Trigger**: This detection reason is triggered when the player's button presses and side movements do not match, which could be caused by lag but is a strong indicator of strafe hacking.

**Code Snippet**:
```cpp
if (g_InvalidButtonSidemoveCount[client] > 0)
{
    g_iLastIllegalReason[client] |= DR_ButtonsAndSideMoveDontMatch;
}
```
**Explanation**:
- This detection is triggered if the player's invalid button sidemove count (`g_InvalidButtonSidemoveCount[client]`) is greater than 0, indicating that the player's button presses and side movements do not match.

### 9. DR_ImpossibleSideMove
- **Description**: Could be +strafe or controller but most likely strafe hack.
- **Action**: Warn admins/Stop player movements.
- **Trigger**: This detection reason is triggered when the player performs impossible side movements, suggesting the use of +strafe or a controller but most likely indicating strafe hacking.

**Code Snippet**:
```cpp
if (g_iIllegalSidemoveCount[client] > 0)
{
    g_iLastIllegalReason[client] |= DR_ImpossibleSideMove;
}
```
**Explanation**:
- This detection is triggered if the player's illegal sidemove count (`g_iIllegalSidemoveCount[client]`) is greater than 0, indicating that the player has performed impossible side movements.

### 10. DR_FailedManualMOTDTest
- **Description**: Almost definitely strafe hacking.
- **Action**: Ban.
- **Trigger**: This detection reason is triggered when the player fails a manual MOTD test, indicating almost definite strafe hacking.

**Code Snippet**:
```cpp
if (g_bMOTDTest[client])
{
    float vAng[3];
    GetClientEyeAngles(client, vAng);
    if (FloatAbs(g_MOTDTestAngles[client][1] - vAng[1]) > 50.0)
    {
        g_iLastIllegalReason[client] |= DR_FailedManualMOTDTest;
    }
}
```
**Explanation**:
- This detection is triggered if the player is undergoing a MOTD test (`g_bMOTDTest[client]`). Triggered by the manual cvar `bash2_test`
- If the difference in yaw angles (`FloatAbs(g_MOTDTestAngles[client][1] - vAng[1])`) is greater than 50.0, the detection reason `DR_FailedManualMOTDTest` is flagged.

### 11. DR_AngleDelay
- **Description**: Player freezes their angles for 1 or more ticks after they press a button until the angle changes again.
- **Action**: Warn admins.
- **Trigger**: This detection reason is triggered when the player freezes their angles for one or more ticks after pressing a button until the angle changes again, indicating potential cheating.

**Code Snippet**:
```cpp
if (g_iLastTurnTick[client] - g_iLastPressTick[client][Button_Forward][BT_Key] > 1)
{
    g_iLastIllegalReason[client] |= DR_AngleDelay;
}
```
**Explanation**:
- This detection is triggered if the difference between the last turn tick (`g_iLastTurnTick[client]`) and the last press tick (`g_iLastPressTick[client][Button_Forward][BT_Key]`) is greater than 1, indicating that the player has frozen their angles for one or more ticks after pressing a button.

### 12. DR_ImpossibleGains
- **Description**: Indicates potential strafe hacks if gains are less than 85%.
- **Action**: Warn admins.
- **Trigger**: This detection reason is triggered when the player's gains are less than 85%, suggesting potential strafe hacking.

**Code Snippet**:
```cpp
if (gainPct < 85.0)
{
    g_iLastIllegalReason[client] |= DR_ImpossibleGains;
}
```
**Explanation**:
- This detection is triggered if the player's gain percentage (`gainPct`) is less than 85.0, indicating potential strafe hacking.

### 13. DR_WiggleHack
- **Description**: Almost definitely strafe hack. Check for IN_LEFT/IN_RIGHT.
- **Action**: Ban.
- **Trigger**: This detection reason is triggered when the player performs wiggle movements, checking for IN_LEFT/IN_RIGHT inputs, indicating almost definite strafe hacking.

**Code Snippet**:
```cpp
if (g_iButtons[client][BT_Key] & IN_LEFT && g_iButtons[client][BT_Key] & IN_RIGHT)
{
    g_iLastIllegalReason[client] |= DR_WiggleHack;
}
```
**Explanation**:
- This detection is triggered if the player is pressing both the left (`IN_LEFT`) and right (`IN_RIGHT`) movement keys simultaneously, indicating almost definite strafe hacking.

### 14. DR_TurningInfraction
- **Description**: Client turns at impossible speeds.
- **Action**: Warn admins.
- **Trigger**: This detection reason is triggered when the player turns at impossible speeds, suggesting the use of cheats.

**Code Snippet**:
```cpp
if (g_iYawSpeed[client] > 210.0)
{
    g_iLastIllegalReason[client] |= DR_TurningInfraction;
}
```
**Explanation**:
- This detection is triggered if the player's yaw speed (`g_iYawSpeed[client]`) is greater than 210.0, indicating that the player is turning at impossible speeds.


Sure! Let's go through the event handling logic in `shavit-bash2.sp` and explain how events can trigger detections.

## Event Handling and Detection Logic

### 1. `Event_PlayerJump`

**Function Definition**:
```cpp
public Action Event_PlayerJump(Event event, const char[] name, bool dontBroadcast)
{
    int iclient = GetClientOfUserId(GetEventInt(event, "userid"));

    if(++g_iJump[iclient] == 6)
    {
        float gainPct = GetGainPercent(iclient);
        float yawPct = (float(g_iYawTickCount[iclient]) / float(g_strafeTick[iclient])) * 100.0;
        float timingPct = (float(g_iTimingTickCount[iclient]) / float(g_strafeTick[iclient])) * 100.0;

        float spj;
        if(g_bFirstSixJumps[iclient])
            spj = g_iStrafesDone[iclient] / 5.0;
        else
            spj = g_iStrafesDone[iclient] / 6.0;

        if(g_strafeTick[iclient] > 300)
        {
            if(gainPct > 85.0 && yawPct < 60.0)
            {
                AnticheatLog(iclient, "has %.2f%% gains (Yawing %.1f%%, Timing: %.1f%%, SPJ: %.1f)", gainPct, yawPct, timingPct, spj);

                if(gainPct == 100.0 && timingPct == 100.0)
                {
                    AutoBanPlayer(iclient);
                }
            }
        }

        g_iJump[iclient] = 0;
        g_flRawGain[iclient] = 0.0;
        g_strafeTick[iclient] = 0;
        g_iYawTickCount[iclient] = 0;
        g_iTimingTickCount[iclient] = 0;
        g_iStrafesDone[iclient] = 0;
        g_bFirstSixJumps[iclient] = false;
    }
}
```

**Explanation**:
- This function handles the `player_jump` event.
- It increments the jump count for the player (`g_iJump[iclient]`).
- If the player has jumped six times, it calculates various percentages (gain, yaw, timing) and the strafes per jump (SPJ).
- If the strafe tick count is greater than 300 and the gain percentage is greater than 85% while the yaw percentage is less than 60%, it logs the detection.
- If both the gain percentage and timing percentage are 100%, the player is automatically banned.
- The function resets various counters and flags after processing.

### 2. `OnClientConnected`

**Function Definition**:
```cpp
public void OnClientConnected(int client)
{
    if(IsFakeClient(client))
        return;

    GetClientIP(client, g_sPlayerIp[client], 16);

    for(int idx; idx < MAX_FRAMES; idx++)
    {
        g_bStartStrafe_IsRecorded[client][idx]         = false;
        g_bEndStrafe_IsRecorded[client][idx]           = false;
    }

    for(int idx; idx < MAX_FRAMES_KEYSWITCH; idx++)
    {
        g_bKeySwitch_IsRecorded[client][BT_Key][idx]   = false;
        g_bKeySwitch_IsRecorded[client][BT_Move][idx]  = false;
    }

    g_iStartStrafe_CurrentFrame[client]        = 0;
    g_iEndStrafe_CurrentFrame[client]          = 0;
    g_iKeySwitch_CurrentFrame[client][BT_Key]  = 0;
    g_iKeySwitch_CurrentFrame[client][BT_Move] = 0;
    g_bCheckedYet[client] = false;
    g_iStartStrafe_LastTickDifference[client] = 0;
    g_iEndStrafe_LastTickDifference[client] = 0;
    g_iStartStrafe_IdenticalCount[client] = 0;
    g_iEndStrafe_IdenticalCount[client]   = 0;

    g_iYawSpeed[client] = 210.0;
    g_mYaw[client] = 0.0;
    g_mYawChangedCount[client] = 0;
    g_mYawCheckedCount[client] = 0;
    g_mFilter[client] = false;
    g_mFilterChangedCount[client] = 0;
    g_mFilterCheckedCount[client] = 0;
    g_mRawInput[client] = true;
    g_mRawInputChangedCount[client] = 0;
    g_mRawInputCheckedCount[client] = 0;
    g_mCustomAccel[client] = 0;
    g_mCustomAccelChangedCount[client] = 0;
    g_mCustomAccelCheckedCount[client] = 0;
    g_mCustomAccelMax[client] = 0.0;
    g_mCustomAccelMaxChangedCount[client] = 0;
    g_mCustomAccelMaxCheckedCount[client] = 0;
    g_mCustomAccelScale[client] = 0.0;
    g_mCustomAccelScaleChangedCount[client] = 0;
    g_mCustomAccelScaleCheckedCount[client] = 0;
    g_mCustomAccelExponent[client] = 0.0;
    g_mCustomAccelExponentChangedCount[client] = 0;
    g_mCustomAccelExponentCheckedCount[client] = 0;
    g_Sensitivity[client] = 0.0;
    g_SensitivityChangedCount[client] = 0;
    g_SensitivityCheckedCount[client] = 0;
    g_JoySensitivity[client] = 0.0;
    g_JoySensitivityChangedCount[client] = 0;
    g_JoySensitivityCheckedCount[client] = 0;
    g_ZoomSensitivity[client] = 0.0;
    g_ZoomSensitivityChangedCount[client] = 0;
    g_ZoomSensitivityCheckedCount[client] = 0;

    g_iLastInvalidButtonCount[client] = 0;

    g_JoyStick[client] = false;
    g_JoyStickChangedCount[client] = 0;
}
```

**Explanation**:
- This function is called when a client connects to the server.
- It initializes various counters and flags for the client.
- It resets the recorded data for start and end strafe, key switches, and other movement-related data.

### 3. `OnClientPutInServer`

**Function Definition**:
```cpp
public void OnClientPutInServer(int client)
{
    if(IsFakeClient(client))
        return;

    SDKHook(client, SDKHook_Touch, Hook_OnTouch);

    if(g_bDhooksLoaded)
    {
        DHookEntity(g_hTeleport, false, client);
    }

    #if defined TIMER
    if(g_bSendProxyLoaded)
    {
        SendProxy_Hook(client, "m_fFlags", Prop_Int, Hook_GroundFlags);
    }
    #endif

    QueryForCvars(client);
}
```

**Explanation**:
- This function is called when a client is fully connected and put into the server.
- It hooks the `SDKHook_Touch` event for the client.
- If the `dhooks` library is loaded, it hooks the teleport event for the client.
- If the `sendproxy` library is loaded, it hooks the ground flags for the client.
- It queries the client's console variables (cvars).

### 4. `OnVGUIMenu`

**Function Definition**:
```cpp
public Action OnVGUIMenu(UserMsg msg_id, Protobuf msg, const int[] players, int playersNum, bool reliable, bool init)
{
    int iclient = players[0];

    if(g_bMOTDTest[iclient])
    {
        GetClientEyeAngles(iclient, g_MOTDTestAngles[iclient]);
        CreateTimer(0.1, Timer_MOTD, GetClientUserId(iclient));
    }
}
```

**Explanation**:
- This function handles the `VGUIMenu` user message.
- If the client is undergoing a MOTD test (`g_bMOTDTest[iclient]`), it records the client's eye angles and sets a timer (`Timer_MOTD`) to check the angles after a short delay.

### 5. `Timer_MOTD`

**Function Definition**:
```cpp
public Action Timer_MOTD(Handle timer, any data)
{
    int iclient = GetClientOfUserId(data);

    if(iclient != 0)
    {
        float vAng[3];
        GetClientEyeAngles(iclient, vAng);
        if(FloatAbs(g_MOTDTestAngles[iclient][1] - vAng[1]) > 50.0)
        {
            PrintToAdmins("%N is strafe hacking", iclient);
        }
        g_bMOTDTest[iclient] = false;
    }
}
```

**Explanation**:
- This function is called by the `Timer_MOTD` timer.
- It checks if the client's eye angles have changed significantly (by more than 50 degrees) since the MOTD test started.
- If the angles have changed significantly, it logs a detection and notifies the admins.

### 6. `Hook_DHooks_Teleport`

**Function Definition**:
```cpp
public MRESReturn Hook_DHooks_Teleport(int client, Handle hParams)
{
    if(!IsClientConnected(client) || IsFakeClient(client) || !IsPlayerAlive(client))
        return MRES_Ignored;

    g_iLastTeleportTick[client] = g_iCmdNum[client];

    return MRES_Ignored;
}
```

**Explanation**:
- This function handles the teleport event for the client.
- It updates the last teleport tick (`g_iLastTeleportTick[client]`) for the client.

### 7. `CheckLag`

**Function Definition**:
```cpp
public void CheckLag(any data)
{
    if(GetEngineTime() - g_fLag_LastCheckTime > 0.02)
    {
        //g_fLastLagTime = GetEngineTime();
    }

    g_fLag_LastCheckTime = GetEngineTime();

    RequestFrame(CheckLag);
}
```

**Explanation**:
- This function checks for lag by comparing the current engine time with the last check time.
- It schedules itself to run again in the next frame.

### 8. `OnMapStart`

**Function Definition**:
```cpp
public void OnMapStart()
{
    delete g_aPersistentData;
    g_aPersistentData = new ArrayList(sizeof(fuck_sourcemod));

    CreateTimer(g_hQueryRate.FloatValue, Timer_UpdateYaw, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

    if(g_bLateLoad)
    {
        for(int iclient = 1; iclient <= MaxClients; iclient++)
        {
            if(IsClientInGame(iclient))
            {
                OnClientConnected(iclient);
                OnClientPutInServer(iclient);
            }
        }
    }

    SaveOldLogs();
}
```

**Explanation**:
- This function is called when a new map starts.
- It initializes the persistent data array.
- It creates a timer (`Timer_UpdateYaw`) to update the yaw values for clients.
- If the plugin was loaded late, it calls `OnClientConnected` and `OnClientPutInServer` for all connected clients.
- It saves old logs to a new file.

### 9. `Timer_UpdateYaw`

**Function Definition**:
```cpp
public Action Timer_UpdateYaw(Handle timer, any data)
{
    for(int iclient = 1; iclient <= MaxClients; iclient++)
    {
        if(IsClientInGame(iclient) && !IsFakeClient(iclient))
        {
            QueryForCvars(iclient);
        }
    }
}
```

**Explanation**:
- This function is called by the `Timer_UpdateYaw` timer.
- It queries the console variables (cvars) for all connected clients.
