### 1. Start Strafe Detection
The start strafe detection logic is implemented in the `RecordStartStrafe` function. It checks for the following conditions:

- Low deviation in start strafe tick differences (< 1.0)
- Always positive start strafe tick differences
- Start strafe tick difference matching the end strafe tick difference

If the start strafe tick differences have a standard deviation less than 0.8, it logs a detection. If the standard deviation is less than or equal to 0.4, it automatically bans the player.

### 2. End Strafe Detection 
The end strafe detection logic is similar to the start strafe detection and is implemented in the `RecordEndStrafe` function. It checks for:

- Low deviation in end strafe tick differences (< 1.0) 
- Always positive end strafe tick differences

If the end strafe tick differences have a standard deviation less than 0.8, it logs a detection. If the standard deviation is less than or equal to 0.4, it automatically bans the player.

### 3. Key Switch Detection
The key switch detection logic is implemented in the `RecordKeySwitch` function. It checks for:

- Too perfect key switches (standard deviation <= 0.25)
- High percentage of null key switch tick differences (>= 95%)

If either of these conditions is met, it logs a detection. If the `bash_antinull` ConVar is enabled, it kicks the player after a short delay.

### 4. W-Only Hack Detection
The `CheckForWOnlyHack` function detects the W-Only hack by checking if the player turns more than 13 degrees in 1 tick while not holding the opposite strafe key. It logs a detection if the percentage of illegal turns is greater than 60%.

### 5. Illegal Movement Detection
The `CheckForIllegalMovement` function detects illegal movements by checking if:

- Player's buttons and sidemove values don't match 
- Player has impossible sidemove values (not divisible by 16 or not equal to the max move speed)

It logs a detection if the player has 10 or more consecutive illegal movements. If the percentage of yaw changes during illegal movements is greater than 30% and the player is not using a joystick, it may ban the player.

### 6. Illegal Turning Detection
The `CheckForIllegalTurning` function detects illegal turning by checking if the player's yaw change matches the expected value based on their sensitivity and m_yaw settings. It logs a detection if the player has a high percentage of illegal yaw changes.

### 7. Gain and Strafe Sync Detection
The `Event_PlayerJump` function detects strafe hacks by analyzing the player's gain percentage, yaw percentage, and timing percentage. It checks if:

- Gain percentage is greater than 85%
- Yaw percentage is less than 60%
- Timing percentage is 100%

If these conditions are met and the player has a high strafe tick count (> 300), it logs a detection. If the gain percentage and timing percentage are both 100%, it automatically bans the player.

### 8. Angle Delay Detection
The angle delay detection logic is spread across multiple functions. It checks if the player freezes their angles for 1 or more ticks after pressing a strafe key until the angle changes again. This detection is not explicitly implemented in the provided code but is mentioned in the detection reasons.

### Additional Checks and Considerations
- The code also checks for null movement stats and logs them if the `bash_print_null_logs` ConVar is enabled.
- It checks if the player is being timed using the shavit-timer plugin and adjusts the detection logic accordingly.
- It handles player teleportation by recording the last teleport tick and ignoring detections for a short period after teleportation.
- It checks for player connections and disconnections, saving and restoring player data if the `bash_persistent_data` ConVar is enabled.

## Detection Reasons

### 1. DR_StartStrafe_LowDeviation
- **Description**: Indicates very likely strafe hacks if the deviation is less than 1.0.
- **Action**: Warn admins.
- **Trigger**: Triggered when the deviation in the player's starting strafe is less than 1.0, suggesting highly consistent and unnatural movement patterns.

### 2. DR_StartStrafe_AlwaysPositive
- **Description**: Might not be strafe hacking but a good indicator of someone trying to bypass anticheat.
- **Action**: Warn admins.
- **Trigger**: Triggered when the player's starting strafe always results in positive values, indicating potential attempts to bypass the anticheat system.

### 3. DR_EndStrafe_LowDeviation
- **Description**: Indicates very likely strafe hacks if the deviation is less than 1.0.
- **Action**: Warn admins.
- **Trigger**: Triggered when the deviation in the player's ending strafe is less than 1.0, suggesting highly consistent and unnatural movement patterns.

### 4. DR_EndStrafe_AlwaysPositive
- **Description**: Might not be strafe hacking but a good indicator of someone trying to bypass anticheat.
- **Action**: Warn admins.
- **Trigger**: Triggered when the player's ending strafe always results in positive values, indicating potential attempts to bypass the anticheat system.

### 5. DR_StartStrafeMatchesEndStrafe
- **Description**: A way to catch an angle delay hack.
- **Action**: Do nothing.
- **Trigger**: Triggered when the player's starting strafe matches their ending strafe, which could indicate an angle delay hack.

### 6. DR_KeySwitchesTooPerfect
- **Description**: Could be movement config or anti-ghosting keyboard.
- **Action**: Warn admins.
- **Trigger**: Triggered when the player's key switches are too perfect, suggesting the use of a movement configuration or an anti-ghosting keyboard.

### 7. DR_FailedManualAngleTest
- **Description**: Almost definitely strafe hacking.
- **Action**: Ban.
- **Trigger**: Triggered when the player fails a manual angle test, indicating almost definite strafe hacking.

### 8. DR_ButtonsAndSideMoveDontMatch
- **Description**: Could be caused by lag but can be made to detect strafe hacks perfectly.
- **Action**: Ban/Warn based on severity.
- **Trigger**: Triggered when the player's button presses and side movements do not match, which could be caused by lag but is a strong indicator of strafe hacking.

### 9. DR_ImpossibleSideMove
- **Description**: Could be +strafe or controller but most likely strafe hack.
- **Action**: Warn admins/Stop player movements.
- **Trigger**: Triggered when the player performs impossible side movements, suggesting the use of +strafe or a controller but most likely indicating strafe hacking.

### 10. DR_FailedManualMOTDTest
- **Description**: Almost definitely strafe hacking.
- **Action**: Ban.
- **Trigger**: Triggered when the player fails a manual MOTD test, indicating almost definite strafe hacking. `bash_test2` cvar triggers this.

### 11. DR_AngleDelay
- **Description**: Player freezes their angles for 1 or more ticks after they press a button until the angle changes again.
- **Action**: Warn admins.
- **Trigger**: Triggered when the player freezes their angles for one or more ticks after pressing a button until the angle changes again, indicating potential cheating.

### 12. DR_ImpossibleGains
- **Description**: Indicates potential strafe hacks if gains are less than 85%.
- **Action**: Warn admins.
- **Trigger**: Triggered when the player's gains are less than 85%, suggesting potential strafe hacking.

### 13. DR_WiggleHack
- **Description**: Almost definitely strafe hack. Check for IN_LEFT/IN_RIGHT.
- **Action**: Ban.
- **Trigger**: Triggered when the player performs wiggle movements, checking for IN_LEFT/IN_RIGHT inputs, indicating almost definite strafe hacking.

### 14. DR_TurningInfraction
- **Description**: Client turns at impossible speeds.
- **Action**: Warn admins.
- **Trigger**: Triggered when the player turns at impossible speeds, suggesting the use of cheats.

## Event Handling and Detection Logic

### 1. `Event_PlayerJump`
- Handles the `player_jump` event.
- Increments the jump count for the player.
- Calculates various percentages and logs detections if certain conditions are met.
- Resets various counters and flags after processing.

### 2. `OnClientConnected`
- Called when a client connects to the server.
- Initializes various counters and flags for the client.
- Resets the recorded data for start and end strafe, key switches, and other movement-related data.

### 3. `OnClientPutInServer`
- Called when a client is fully connected and put into the server.
- Hooks the `SDKHook_Touch` event for the client.
- Hooks the teleport event and ground flags if the respective libraries are loaded.
- Queries the client's console variables (cvars).

### 4. `OnVGUIMenu`
- Handles the `VGUIMenu` user message.
- Records the client's eye angles and sets a timer to check the angles after a short delay if the client is undergoing a MOTD test.

### 5. `Timer_MOTD`
- Called by the `Timer_MOTD` timer.
- Checks if the client's eye angles have changed significantly since the MOTD test started.
- Logs a detection and notifies the admins if the angles have changed significantly.

### 6. `Hook_DHooks_Teleport`
- Handles the teleport event for the client.
- Updates the last teleport tick for the client.

### 7. `CheckLag`
- Checks for lag by comparing the current engine time with the last check time.
- Schedules itself to run again in the next frame.

### 8. `OnMapStart`
- Called when a new map starts.
- Initializes the persistent data array.
- Creates a timer to update the yaw values for clients.
- Calls `OnClientConnected` and `OnClientPutInServer` for all connected clients if the plugin was loaded late.
- Saves old logs to a new file.

### 9. `Timer_UpdateYaw`
- Called by the `Timer_UpdateYaw` timer.
- Queries the console variables (cvars) for all connected clients. 
