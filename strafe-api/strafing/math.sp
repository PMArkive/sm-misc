// math.sp
#include <sourcemod>
#include <sdkhooks>
#include <cstrike>
#include <vector>
#include <math>
#include "strafing.inc"
#include "utils.sp"

/**
 * Calculates the two-argument arctangent of the specified values.
 *
 * @param a          The first value.
 * @param b          The second value.
 * @return           The arctangent of the specified values.
 */
stock float Atan2(float a, float b)
{
    return ArcTangent2(a, b);
}

/**
 * Calculates the square root of the sum of the squares of the specified values.
 *
 * @param a          The first value.
 * @param b          The second value.
 * @return           The square root of the sum of the squares of the specified values.
 */
stock float Hypot(float a, float b)
{
    return SquareRoot(a * a + b * b);
}

/**
 * Normalizes an angle to the range [0, 360) degrees.
 *
 * @param angle      The angle to normalize.
 * @return           The normalized angle.
 */
stock float NormalizeAngle(float angle)
{
    while (angle < 0.0)
        angle += 360.0;
    while (angle >= 360.0)
        angle -= 360.0;
    return angle;
}

/**
 * Normalizes an angle to the range [-180, 180) degrees.
 *
 * @param angle      The angle to normalize.
 * @return           The normalized angle.
 */
stock float NormalizeAngleDeg(float angle)
{
    while (angle >= 180.0)
        angle -= 360.0;
    while (angle < -180.0)
        angle += 360.0;
    return angle;
}

/**
 * Normalizes an angle to the range [-PI, PI) radians.
 *
 * @param angle      The angle to normalize.
 * @return           The normalized angle.
 */
stock float NormalizeAngleRad(float angle)
{
    while (angle >= M_PI)
        angle -= M_PIRAD;
    while (angle < -M_PI)
        angle += M_PIRAD;
    return angle;
}

/**
 * Calculates the distance between two points in 2D space.
 *
 * @param x1         The x-coordinate of the first point.
 * @param y1         The y-coordinate of the first point.
 * @param x2         The x-coordinate of the second point.
 * @param y2         The y-coordinate of the second point.
 * @return           The distance between the two points.
 */
stock float Distance2D(float x1, float y1, float x2, float y2)
{
    return Hypot(x2 - x1, y2 - y1);
}

/**
 * Calculates the distance between two points in 3D space.
 *
 * @param x1         The x-coordinate of the first point.
 * @param y1         The y-coordinate of the first point.
 * @param z1         The z-coordinate of the first point.
 * @param x2         The x-coordinate of the second point.
 * @param y2         The y-coordinate of the second point.
 * @param z2         The z-coordinate of the second point.
 * @return           The distance between the two points.
 */
stock float Distance3D(float x1, float y1, float z1, float x2, float y2, float z2)
{
    return SquareRoot((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1) + (z2 - z1) * (z2 - z1));
}