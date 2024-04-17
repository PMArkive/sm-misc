#include <sourcemod>
#include <sdkhooks>
#include <cstrike>
#include <vector>
#include <math>
#include "strafing.inc"
#include "utils.sp"
#include "math.sp"

/**
 * Traces a ray from the start position to the end position.
 *
 * @param start      The start position of the ray.
 * @param end        The end position of the ray.
 * @param mask       The mask for the trace.
 * @param filter     The filter for the trace.
 * @param trace      The trace result.
 * @return           True if the trace hit something, false otherwise.
 */
stock bool TraceRay(const float start[3], const float end[3], int mask, int filter, CTraceFilter filter_instance, CGameTrace &trace)
{
    Handle hRay = TR_RayTraceRayEx(start, end, mask, filter, filter_instance);
    if (hRay != null)
    {
        TR_GetEndPosition(hRay, trace.endpos);
        trace.didHit = TR_DidHit(hRay);
        trace.startSolid = TR_StartSolid(hRay);
        trace.allSolid = TR_AllSolid(hRay);
        TR_GetPlaneNormal(hRay, trace.planeNormal);
        trace.hitEntity = TR_GetEntityIndex(hRay);
        trace.fraction = TR_GetFraction(hRay);
        delete hRay;
        return trace.didHit;
    }
    return false;
}

/**
 * Traces a player's bounding box from the start position to the end position.
 *
 * @param start      The start position of the trace.
 * @param end        The end position of the trace.
 * @param client     The client index for the player.
 * @param mask       The mask for the trace.
 * @param filter     The filter for the trace.
 * @param trace      The trace result.
 * @return           True if the trace hit something, false otherwise.
 */
stock bool TracePlayerBBox(const float start[3], const float end[3], int client, int mask, int filter, CTraceFilter filter_instance, CGameTrace &trace)
{
    float mins[3], maxs[3];
    GetClientMins(client, mins);
    GetClientMaxs(client, maxs);
    Handle hTrace = TR_TraceHullEx(start, end, mins, maxs, mask, filter, filter_instance);
    if (hTrace != null)
    {
        TR_GetEndPosition(hTrace, trace.endpos);
        trace.didHit = TR_DidHit(hTrace);
        trace.startSolid = TR_StartSolid(hTrace);
        trace.allSolid = TR_AllSolid(hTrace);
        TR_GetPlaneNormal(hTrace, trace.planeNormal);
        trace.hitEntity = TR_GetEntityIndex(hTrace);
        trace.fraction = TR_GetFraction(hTrace);
        delete hTrace;
        return trace.didHit;
    }
    return false;
}

/**
 * Retrieves the minimum bounding box dimensions for the client.
 *
 * @param client     The client index.
 * @param mins       The minimum bounding box dimensions.
 */
stock void GetClientMins(int client, float mins[3])
{
    GetEntPropVector(client, Prop_Send, "m_vecMins", mins);
}

/**
 * Retrieves the maximum bounding box dimensions for the client.
 *
 * @param client     The client index.
 * @param maxs       The maximum bounding box dimensions.
 */
stock void GetClientMaxs(int client, float maxs[3])
{
    GetEntPropVector(client, Prop_Send, "m_vecMaxs", maxs);
}

/**
 * Sets the client's bounding box dimensions.
 *
 * @param client     The client index.
 * @param mins       The minimum bounding box dimensions.
 * @param maxs       The maximum bounding box dimensions.
 */
stock void SetClientBBox(int client, const float mins[3], const float maxs[3])
{
    SetEntPropVector(client, Prop_Send, "m_vecMins", mins);
    SetEntPropVector(client, Prop_Send, "m_vecMaxs", maxs);
}

/**
 * Retrieves the client's ground entity index.
 *
 * @param client     The client index.
 * @return           The ground entity index, or -1 if the client is not on the ground.
 */
stock int GetClientGroundEntity(int client)
{
    return GetEntPropEnt(client, Prop_Send, "m_hGroundEntity");
}

/**
 * Sets the client's ground entity index.
 *
 * @param client     The client index.
 * @param entity     The ground entity index.
 */
stock void SetClientGroundEntity(int client, int entity)
{
    SetEntPropEnt(client, Prop_Send, "m_hGroundEntity", entity);
}

/**
 * Retrieves the client's base velocity.
 *
 * @param client     The client index.
 * @param baseVel    The base velocity vector.
 */
stock void GetClientBaseVelocity(int client, float baseVel[3])
{
    GetEntPropVector(client, Prop_Data, "m_vecBaseVelocity", baseVel);
}

/**
 * Sets the client's base velocity.
 *
 * @param client     The client index.
 * @param baseVel    The base velocity vector.
 */
stock void SetClientBaseVelocity(int client, const float baseVel[3])
{
    SetEntPropVector(client, Prop_Data, "m_vecBaseVelocity", baseVel);
}

/**
 * Retrieves the client's view offset.
 *
 * @param client     The client index.
 * @param viewOffset The view offset vector.
 */
stock void GetClientViewOffset(int client, float viewOffset[3])
{
    GetEntPropVector(client, Prop_Send, "m_vecViewOffset", viewOffset);
}

/**
 * Sets the client's view offset.
 *
 * @param client     The client index.
 * @param viewOffset The view offset vector.
 */
stock void SetClientViewOffset(int client, const float viewOffset[3])
{
    SetEntPropVector(client, Prop_Send, "m_vecViewOffset", viewOffset);
}

/**
 * Retrieves the client's entity flags.
 *
 * @param client     The client index.
 * @return           The client's entity flags.
 */
stock int GetClientFlags(int client)
{
    return GetEntProp(client, Prop_Data, "m_fFlags");
}

/**
 * Sets the client's entity flags.
 *
 * @param client     The client index.
 * @param flags      The entity flags to set.
 */
stock void SetClientFlags(int client, int flags)
{
    SetEntProp(client, Prop_Data, "m_fFlags", flags);
}

/**
 * Retrieves the client's entity render mode.
 *
 * @param client     The client index.
 * @return           The client's entity render mode.
 */
stock int GetClientRenderMode(int client)
{
    return GetEntProp(client, Prop_Send, "m_nRenderMode");
}

/**
 * Sets the client's entity render mode.
 *
 * @param client     The client index.
 * @param mode       The render mode to set.
 */
stock void SetClientRenderMode(int client, int mode)
{
    SetEntProp(client, Prop_Send, "m_nRenderMode", mode);
}

/**
 * Traces a ray from the start position to the end position, ignoring the specified entity.
 *
 * @param start      The start position of the ray.
 * @param end        The end position of the ray.
 * @param mask       The mask for the trace.
 * @param filter     The filter for the trace.
 * @param ignoreEnt  The entity to ignore during the trace.
 * @param trace      The trace result.
 * @return           True if the trace hit something, false otherwise.
 */
stock bool TraceRayIgnoreEntity(const float start[3], const float end[3], int mask, int filter, int ignoreEnt, CTraceFilter filter_instance, CGameTrace &trace)
{
    Handle hRay = TR_RayTraceRayFilterEx(start, end, mask, filter, ignoreEnt, filter_instance);
    if (hRay != null)
    {
        TR_GetEndPosition(hRay, trace.endpos);
        trace.didHit = TR_DidHit(hRay);
        trace.startSolid = TR_StartSolid(hRay);
        trace.allSolid = TR_AllSolid(hRay);
        TR_GetPlaneNormal(hRay, trace.planeNormal);
        trace.hitEntity = TR_GetEntityIndex(hRay);
        trace.fraction = TR_GetFraction(hRay);
        delete hRay;
        return trace.didHit;
    }
    return false;
}

/**
 * Retrieves the client's velocity vector.
 *
 * @param client     The client index.
 * @param velocity   The velocity vector.
 */
stock void GetClientVelocity(int client, float velocity[3])
{
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
}

/**
 * Sets the client's velocity vector.
 *
 * @param client     The client index.
 * @param velocity   The velocity vector.
 */
stock void SetClientVelocity(int client, const float velocity[3])
{
    SetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
}

/**
 * Retrieves the client's origin vector.
 *
 * @param client     The client index.
 * @param origin     The origin vector.
 */
stock void GetClientOrigin(int client, float origin[3])
{
    GetClientAbsOrigin(client, origin);
}

/**
 * Sets the client's origin vector.
 *
 * @param client     The client index.
 * @param origin     The origin vector.
 */
stock void SetClientOrigin(int client, const float origin[3])
{
    TeleportEntity(client, origin, NULL_VECTOR, NULL_VECTOR);
}

/**
 * Retrieves the client's eye angles vector.
 *
 * @param client     The client index.
 * @param eyeAngles  The eye angles vector.
 */
stock void GetClientEyeAngles(int client, float eyeAngles[3])
{
    GetClientEyeAngles(client, eyeAngles);
}

/**
 * Sets the client's eye angles vector.
 *
 * @param client     The client index.
 * @param eyeAngles  The eye angles vector.
 */
stock void SetClientEyeAngles(int client, const float eyeAngles[3])
{
    TeleportEntity(client, NULL_VECTOR, eyeAngles, NULL_VECTOR);
}