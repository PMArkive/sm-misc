#include <sourcemod>
#include <sdkhooks>
#include <cstrike>
#include <vector>
#include <math>
#include "strafing.inc"
#include "utils.sp"
#include "math.sp"
#include "entities.sp"

/**
 * Applies friction to the player's velocity.
 *
 * @param player     The player data.
 * @param vars       The movement variables.
 */
stock void ApplyFriction(PlayerData player, MovementVars vars)
{
    if (!player.onGround)
        return;

    float speed = GetVectorLength(player.vel);
    if (speed < 0.1)
        return;

    float friction = vars.Friction * vars.EntFriction;
    float control = (speed < vars.Stopspeed) ? vars.Stopspeed : speed;
    float drop = control * friction * vars.Frametime;
    float newspeed = (speed - drop > 0.0) ? speed - drop : 0.0;

    ScaleVector(player.vel, newspeed / speed);
}

/**
 * Applies ground movement to the player's velocity.
 *
 * @param player     The player data.
 * @param vars       The movement variables.
 * @param input      The strafe input.
 */
stock void ApplyGroundMovement(PlayerData player, MovementVars vars, StrafeInput input)
{
    float wishspeed = vars.Maxspeed;
    if (vars.ReduceWishspeed)
        wishspeed *= 0.33333333;

    float wishdir[3];
    GetAngleVectors(input.TargetYaw, wishdir, NULL_VECTOR, NULL_VECTOR);

    float currentspeed = GetVectorDotProduct(player.vel, wishdir);
    float addspeed = wishspeed - currentspeed;
    if (addspeed <= 0.0)
        return;

    float accelspeed = vars.Accelerate * vars.Maxspeed * vars.EntFriction * vars.Frametime;
    if (accelspeed > addspeed)
        accelspeed = addspeed;

    VectorMulAdd(player.vel, wishdir, accelspeed, player.vel);
}

/**
 * Applies air movement to the player's velocity.
 *
 * @param player     The player data.
 * @param vars       The movement variables.
 * @param input      The strafe input.
 */
stock void ApplyAirMovement(PlayerData player, MovementVars vars, StrafeInput input)
{
    float wishdir[3];
    GetAngleVectors(input.TargetYaw, wishdir, NULL_VECTOR, NULL_VECTOR);

    float wishspeed = vars.WishspeedCap;
    float currentspeed = GetVectorDotProduct(player.vel, wishdir);
    float addspeed = wishspeed - currentspeed;
    if (addspeed <= 0.0)
        return;

    float accelspeed = vars.Airaccelerate * wishspeed * vars.EntFriction * vars.Frametime;
    if (accelspeed > addspeed)
        accelspeed = addspeed;

    VectorMulAdd(player.vel, wishdir, accelspeed, player.vel);
}

/**
 * Simulates player movement based on the input and movement variables.
 *
 * @param player     The player data.
 * @param vars       The movement variables.
 * @param input      The strafe input.
 */
stock void SimulateMovement(PlayerData player, MovementVars vars, StrafeInput input)
{
    ApplyFriction(player, vars);

    if (player.onGround)
        ApplyGroundMovement(player, vars, input);
    else
        ApplyAirMovement(player, vars, input);

    // Apply gravity
    player.vel[2] -= vars.Gravity * vars.EntGravity * vars.Frametime;

    // Clamp velocity
    float speed = GetVectorLength(player.vel);
    if (speed > vars.Maxvelocity)
        ScaleVector(player.vel, vars.Maxvelocity / speed);
}

/**
 * Checks if the player can unduck based on their position and the trace result.
 *
 * @param player     The player data.
 * @param trace      The trace result.
 * @return           True if the player can unduck, false otherwise.
 */
stock bool CanUnduck(PlayerData player, CGameTrace trace)
{
    if (player.duckPressed || trace.fraction != 1.0)
        return false;

    float duckedOrigin[3];
    duckedOrigin = player.pos;
    duckedOrigin[2] -= 36.0;

    CGameTrace duckTrace;
    TracePlayerBBox(duckedOrigin, player.pos, GetClientOfUserId(player.userid), MASK_PLAYERSOLID, CONTENTS_SOLID, CTraceFilter(), duckTrace);

    return duckTrace.fraction == 1.0;
}

/**
 * Retrieves the player's position type based on the trace result.
 *
 * @param player     The player data.
 * @param trace      The trace result.
 * @return           The player's position type.
 */
stock PositionType GetPositionType(PlayerData player, CGameTrace trace)
{
    if (trace.startSolid || trace.allSolid)
        return PositionType_Air;

    if (trace.fraction == 1.0)
    {
        if (player.vel[2] > 140.0)
            return PositionType_Air;
        else
            return PositionType_Ground;
    }

    if (trace.planeNormal[2] >= 0.7)
        return PositionType_Ground;

    return PositionType_Air;
}

/**
 * Retrieves the ground entity index for the player.
 *
 * @param player     The player data.
 * @return           The ground entity index, or -1 if the player is not on the ground.
 */
stock int GetGroundEntity(PlayerData player)
{
    return GetClientGroundEntity(GetClientOfUserId(player.userid));
}

/**
 * Sets the ground entity index for the player.
 *
 * @param player     The player data.
 * @param entity     The ground entity index.
 */
stock void SetGroundEntity(PlayerData player, int entity)
{
    SetClientGroundEntity(GetClientOfUserId(player.userid), entity);
}

/**
 * Checks if the player is on the ground.
 *
 * @param player     The player data.
 * @return           True if the player is on the ground, false otherwise.
 */
stock bool IsOnGround(PlayerData player)
{
    return GetGroundEntity(player) != -1;
}

/**
 * Retrieves the player's bounding box minimum dimensions.
 *
 * @param player     The player data.
 * @param mins       The minimum bounding box dimensions.
 */
stock void GetBBoxMins(PlayerData player, float mins[3])
{
    GetClientMins(GetClientOfUserId(player.userid), mins);
}

/**
 * Retrieves the player's bounding box maximum dimensions.
 *
 * @param player     The player data.
 * @param maxs       The maximum bounding box dimensions.
 */
stock void GetBBoxMaxs(PlayerData player, float maxs[3])
{
    GetClientMaxs(GetClientOfUserId(player.userid), maxs);
}

/**
 * Sets the player's bounding box dimensions.
 *
 * @param player     The player data.
 * @param mins       The minimum bounding box dimensions.
 * @param maxs       The maximum bounding box dimensions.
 */
stock void SetBBox(PlayerData player, const float mins[3], const float maxs[3])
{
    SetClientBBox(GetClientOfUserId(player.userid), mins, maxs);
}

/**
 * Applies player movement based on the movement variables and strafe input.
 *
 * @param player     The player data.
 * @param vars       The movement variables.
 * @param input      The strafe input.
 */
stock void ApplyMovement(PlayerData player, MovementVars vars, StrafeInput input)
{
    PlayerData newPlayer = player;

    CGameTrace trace;
    TracePlayerBBox(player.pos, player.pos, GetClientOfUserId(player.userid), MASK_PLAYERSOLID, CONTENTS_SOLID, CTraceFilter(), trace);
    PositionType posType = GetPositionType(player, trace);

    SimulateMovement(newPlayer, vars, input);

    if (posType == PositionType_Ground)
    {
        float endPos[3];
        endPos = newPlayer.pos;
        endPos[0] += newPlayer.vel[0] * vars.Frametime;
        endPos[1] += newPlayer.vel[1] * vars.Frametime;

        TracePlayerBBox(player.pos, endPos, GetClientOfUserId(player.userid), MASK_PLAYERSOLID, CONTENTS_SOLID, CTraceFilter(), trace);

        if (trace.fraction == 1.0)
        {
            player = newPlayer;
        }
        else
        {
            // Handle ground movement collisions
            float dist = GetVectorLength(trace.endpos, player.pos);
            ScaleVector(newPlayer.vel, dist / (vars.Frametime * GetVectorLength(newPlayer.vel)));

            if (trace.planeNormal[2] >= 0.7)
            {
                newPlayer.pos = trace.endpos;
                ClipVelocity(newPlayer.vel, trace.planeNormal, 1.0);
                player = newPlayer;
            }
            else
            {
                // Try stepping up
                float stepEndPos[3];
                stepEndPos = trace.endpos;
                stepEndPos[2] += vars.Stepsize;

                CGameTrace stepTrace;
                TracePlayerBBox(trace.endpos, stepEndPos, GetClientOfUserId(player.userid), MASK_PLAYERSOLID, CONTENTS_SOLID, CTraceFilter(), stepTrace);

                if (!stepTrace.startSolid && !stepTrace.allSolid)
                {
                    newPlayer.pos = stepTrace.endpos;
                    ClipVelocity(newPlayer.vel, trace.planeNormal, 1.0);
                    player = newPlayer;
                }
                else
                {
                    // Slide along the surface
                    ClipVelocity(newPlayer.vel, trace.planeNormal, 1.0);
                    CrossProduct(trace.planeNormal, newPlayer.vel, player.vel);
                    NormalizeVector(player.vel, player.vel);
                    ScaleVector(player.vel, GetVectorLength(newPlayer.vel));
                    newPlayer.pos = trace.endpos;
                    player = newPlayer;
                }
            }
        }
    }
    else
    {
        // Handle air movement
        player = newPlayer;
    }
}

// Add more physics-related functions as needed...