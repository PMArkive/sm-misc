#include <sourcemod>
#include <sdkhooks>
#include <cstrike>
#include <vector>
#include <math>
#include "strafing/strafing.inc"

/**
 * Calculates the optimal strafe angle for the specified strafe type.
 *
 * @param player     The player data structure.
 * @param vars       The movement variables structure.
 * @param input      The strafe input structure.
 * @return           The strafe angle in radians.
 */
stock float StrafeTheta(PlayerData player, MovementVars vars, StrafeInput input)
{
    if (input.Strafe)
    {
        if (input.StrafeType == StrafeType_MaxAccelCapped)
        {
            return StrafeCappedTheta(player, vars, input);
        }
        else if (input.StrafeType == StrafeType_MaxAccel)
        {
            return MaxAccelTheta(player, vars);
        }
        else if (input.StrafeType == StrafeType_Direction)
        {
            return 0.0;
        }
        else if (input.StrafeType == StrafeType_MaxAngle)
        {
            return MaxAngleTheta(player, vars);
        }
    }

    return 0;
}

/**
 * Calculates the strafe angle for maximum acceleration.
 *
 * @param player     The player data structure.
 * @param vars       The movement variables structure.
 * @return           The strafe angle in radians.
 */
stock float MaxAccelTheta(PlayerData player, MovementVars vars)
{
    float accel = player.onGround ? vars.Accelerate : vars.Airaccelerate;
    float wishspeed = player.onGround ? vars.MaxSpeed : vars.WishspeedCap;
    float accelspeed = accel * vars.MaxSpeed * vars.EntFriction * gpGlobals->frametime;

    if (accelspeed <= 0.0)
        return M_PI;

    if (player.vel.LengthSqr() == 0.0)
        return 0.0;

    float wishspeed_capped = player.onGround ? wishspeed : vars.WishspeedCap;
    float tmp = wishspeed_capped - accelspeed;

    if (tmp <= 0.0)
        return M_PI / 2.0;

    float speed = player.vel.Length();

    if (tmp < speed)
        return ArcCosine(tmp / speed);

    return 0.0;
}

/**
 * Calculates the strafe angle for maximum angle.
 *
 * @param player     The player data structure.
 * @param vars       The movement variables structure.
 * @return           The strafe angle in radians.
 */
stock float MaxAngleTheta(PlayerData player, MovementVars vars)
{
    float speed = player.vel.Length();
    float accel = player.onGround ? vars.Accelerate : vars.Airaccelerate;
    float accelspeed = accel * vars.MaxSpeed * vars.EntFriction * gpGlobals->frametime;
    float wishspeed = player.onGround ? vars.MaxSpeed : vars.WishspeedCap;

    if (accelspeed <= 0.0)
    {
        accelspeed *= -1.0;

        if (accelspeed >= speed)
        {
            if (wishspeed >= speed)
                return 0.0;
            else
                return ArcCosine(wishspeed / speed);
        }
        else
        {
            if (wishspeed >= speed)
                return ArcCosine(accelspeed / speed);
            else
                return ArcCosine(MIN(accelspeed, wishspeed) / speed);
        }
    }
    else
    {
        if (accelspeed >= speed)
            return M_PI;
        else
            return ArcCosine(-accelspeed / speed);
    }
}

/**
 * Calculates the strafe angle for capped acceleration.
 *
 * @param player     The player data structure.
 * @param vars       The movement variables structure.
 * @param input      The strafe input structure.
 * @return           The strafe angle in radians.
 */
stock float StrafeCappedTheta(PlayerData player, MovementVars vars, StrafeInput input)
{
    float theta = MaxAccelTheta(player, vars);

    PlayerData temp = player;
    temp.vel.x = player.vel.Length2D();
    temp.vel.y = 0.0;

    VectorFME(temp, vars, M_PI);

    if (temp.vel.Length2D() > input.CappedLimit)
    {
        if (OvershotCap(player, vars, input))
        {
            theta = M_PI;
        }
        else
        {
            theta = TargetTheta(player, vars, input.CappedLimit);
        }
    }

    return theta;
}

/**
 * Calculates the target theta for a given speed.
 *
 * @param player     The player data structure.
 * @param vars       The movement variables structure.
 * @param target     The target speed.
 * @return           The target theta in radians.
 */
stock float TargetTheta(PlayerData player, MovementVars vars, float target)
{
    float accel = player.onGround ? vars.Accelerate : vars.Airaccelerate;
    float L = vars.WishspeedCap;
    float gamma1 = vars.EntFriction * gpGlobals->frametime * vars.MaxSpeed * accel;

    PlayerData copy = player;
    float lambdaVel = copy.vel.Length2D();

    float cosTheta;

    if (gamma1 <= 2 * L)
    {
        cosTheta = ((target * target - lambdaVel * lambdaVel) / gamma1 - gamma1) / (2 * lambdaVel);
        return ArcCosine(cosTheta);
    }
    else
    {
        cosTheta = SquareRoot((target * target - L * L) / (lambdaVel * lambdaVel));
        return ArcCosine(cosTheta);
    }
}

/**
 * Checks if the player has overshot the capped limit.
 *
 * @param player     The player data structure.
 * @param vars       The movement variables structure.
 * @param input      The strafe input structure.
 * @return           True if the player has overshot the capped limit, false otherwise.
 */
stock bool OvershotCap(PlayerData player, MovementVars vars, StrafeInput input)
{
    PlayerData temp = player;
    temp.vel.x = player.vel.Length2D();
    temp.vel.y = 0.0;

    VectorFME(temp, vars, M_PI);

    return temp.vel.Length2D() > input.CappedLimit;
}

/**
 * Applies the strafing movement to the player.
 *
 * @param player     The player data structure.
 * @param vars       The movement variables structure.
 * @param input      The strafe input structure.
 */
stock void Strafe(PlayerData player, MovementVars vars, StrafeInput input)
{
    float theta = StrafeTheta(player, vars, input);

    Vector2D avec;
    avec.x = Cosine(theta);
    avec.y = Sine(theta);

    VectorFME(player, vars, input, avec);
}

/**
 * Applies the vector force move equation (VectorFME) to the player's velocity.
 *
 * @param player     The player data structure.
 * @param vars       The movement variables structure.
 * @param input      The strafe input structure.
 * @param avec       The direction vector.
 */
stock void VectorFME(PlayerData player, MovementVars vars, StrafeInput input, Vector2D avec)
{
    float wishspeed_capped = player.onGround ? vars.MaxSpeed : vars.WishspeedCap;
    float tmp = wishspeed_capped - player.vel.Dot2D(avec);

    if (tmp <= 0.0)
        return;

    float accel = player.onGround ? vars.Accelerate : vars.Airaccelerate;
    float accelspeed = accel * vars.MaxSpeed * vars.EntFriction * gpGlobals->frametime;

    if (accelspeed <= tmp)
        tmp = accelspeed;

    player.vel.x += avec.x * tmp;
    player.vel.y += avec.y * tmp;
}
