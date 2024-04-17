#include <sourcemod>
#include <sdkhooks>
#include <cstrike>
#include <vector>
#include <math>
#include "strafing.inc"

/**
 * Checks if two vectors are equal within a given tolerance.
 *
 * @param vec1       The first vector.
 * @param vec2       The second vector.
 * @param tolerance  The tolerance value for comparison.
 * @return           True if the vectors are equal, false otherwise.
 */
stock bool VectorsEqual(const float vec1[3], const float vec2[3], float tolerance = 0.001)
{
    return (FloatAbs(vec1[0] - vec2[0]) <= tolerance &&
            FloatAbs(vec1[1] - vec2[1]) <= tolerance &&
            FloatAbs(vec1[2] - vec2[2]) <= tolerance);
}

/**
 * Checks if a vector is zero within a given tolerance.
 *
 * @param vec        The vector to check.
 * @param tolerance  The tolerance value for comparison.
 * @return           True if the vector is zero, false otherwise.
 */
stock bool VectorIsZero(const float vec[3], float tolerance = 0.01)
{
    return (vec[0] > -tolerance && vec[0] < tolerance &&
            vec[1] > -tolerance && vec[1] < tolerance &&
            vec[2] > -tolerance && vec[2] < tolerance);
}

/**
 * Copies the values of one vector to another.
 *
 * @param vIn        The source vector.
 * @param vOut       The destination vector.
 */
stock void VectorCopy(const float vIn[3], float vOut[3])
{
    vOut[0] = vIn[0];
    vOut[1] = vIn[1];
    vOut[2] = vIn[2];
}

/**
 * Linearly interpolates between two vectors based on a given time.
 *
 * @param vec        The start vector.
 * @param dest       The destination vector.
 * @param time       The interpolation time (between 0 and 1).
 * @param res        The result vector.
 */
stock void VectorLerp(const float vec[3], const float dest[3], float time, float res[3])
{
    res[0] = vec[0] + (dest[0] - vec[0]) * time;
    res[1] = vec[1] + (dest[1] - vec[1]) * time;
    res[2] = vec[2] + (dest[2] - vec[2]) * time;
}

/**
 * Adds a scaled vector to another vector.
 *
 * @param vec        The base vector.
 * @param dir        The direction vector.
 * @param scale      The scaling factor.
 * @param result     The result vector.
 */
stock void VectorMulAdd(float vec[3], const float dir[3], float scale, float result[3])
{
    result[0] = vec[0] + scale * dir[0];
    result[1] = vec[1] + scale * dir[1];
    result[2] = vec[2] + scale * dir[2];
}

/**
 * Finds the minimum values between two vectors and stores them in the result vector.
 *
 * @param src        The first vector.
 * @param dest       The second vector.
 * @param res        The result vector.
 */
stock void VectorMin(const float src[3], const float dest[3], float res[3])
{
    res[0] = (src[0] < dest[0]) ? src[0] : dest[0];
    res[1] = (src[1] < dest[1]) ? src[1] : dest[1];
    res[2] = (src[2] < dest[2]) ? src[2] : dest[2];
}

/**
 * Finds the maximum values between two vectors and stores them in the result vector.
 *
 * @param src        The first vector.
 * @param dest       The second vector.
 * @param res        The result vector.
 */
stock void VectorMax(const float src[3], const float dest[3], float res[3])
{
    res[0] = (src[0] > dest[0]) ? src[0] : dest[0];
    res[1] = (src[1] > dest[1]) ? src[1] : dest[1];
    res[2] = (src[2] > dest[2]) ? src[2] : dest[2];
}

/**
 * Generates a random vector within the given range.
 *
 * @param vec        The vector to store the random values.
 * @param flMin      The minimum value for each component.
 * @param flMax      The maximum value for each component.
 */
stock void VectorRand(float vec[3], float flMin, float flMax)
{
    vec[0] = flMin + GetURandomFloat() * (flMax - flMin);
    vec[1] = flMin + GetURandomFloat() * (flMax - flMin);
    vec[2] = flMin + GetURandomFloat() * (flMax - flMin);
}

/**
 * Rotates a vector using a rotation matrix.
 *
 * @param vec        The vector to rotate.
 * @param matrix     The rotation matrix.
 */
stock void VectorRotate(float vec[3], const float matrix[3][3])
{
    vec[0] = GetVectorDotProduct(vec, matrix[0]);
    vec[1] = GetVectorDotProduct(vec, matrix[1]);
    vec[2] = GetVectorDotProduct(vec, matrix[2]);
}

/**
 * Rotates a vector around an axis by a given angle in degrees.
 *
 * @param vec        The vector to rotate.
 * @param dir        The axis of rotation.
 * @param degrees    The rotation angle in degrees.
 */
stock void VectorRotateOnAxis(float vec[3], float dir[3], float degrees)
{
    float st, ct;
    SinCos(DegToRad(degrees), st, ct);

    NormalizeVector(dir, dir);

    float f = dir[0];
    float r = dir[1];
    float u = dir[2];

    float x = vec[0];
    float y = vec[1];
    float z = vec[2];

    vec[0] += (ct + (1 - ct) * f * f) * x;
    vec[0] += ((1 - ct) * f * r - u * st) * y;
    vec[0] += ((1 - ct) * f * z + y * st) * z;

    vec[1] += ((1 - ct) * f * r + u * st) * x;
    vec[1] += (ct + (1 - ct) * r * r) * y;
    vec[1] += ((1 - ct) * r * u - f * st) * z;

    vec[2] += ((1 - ct) * f * u - r * st) * x;
    vec[2] += ((1 - ct) * r * u + f * st) * y;
    vec[2] += (ct + (1 - ct) * u * u) * z;
}

/**
 * Creates a rotation matrix from a forward vector.
 *
 * @param fwd        The forward vector.
 * @param matrix     The rotation matrix.
 */
stock void VectorMatrix(const float fwd[3], float matrix[3][3])
{
    float right[3], up[3];
    GetVectorVectors(fwd, right, up);

    NegateVector(right);

    for (int x = 0; x < 3; ++x)
    {
        matrix[0][x] = fwd[x];
        matrix[1][x] = right[x];
        matrix[2][x] = up[x];
    }
}

/**
 * Creates a rotation matrix from an angle vector.
 *
 * @param ang        The angle vector.
 * @param matrix     The rotation matrix.
 */
stock void AngleMatrix(const float ang[3], float matrix[3][3])
{
    float sy, sp, sr, cy, cp, cr;
    SinCos(DegToRad(ang[0]), sy, cy);
    SinCos(DegToRad(ang[1]), sp, cp);
    SinCos(DegToRad(ang[2]), sr, cr);

    matrix[0][0] = cp * cy;
    matrix[1][0] = cp * sy;
    matrix[2][0] = -sp;

    matrix[0][1] = sp * (sr * cy - cr * sy);
    matrix[1][1] = sp * (sr * sy + cr * cy);
    matrix[2][1] = sr * cp;

    matrix[0][2] = sp * (cr * cy + sr * sy);
    matrix[1][2] = sp * (cr * sy - sr * cy);
    matrix[2][2] = cr * cp;
}

/**
 * Normalizes an angle vector to the range [-180.0, 180.0].
 *
 * @param ang        The angle vector to normalize.
 */
stock void AnglesNormalize(float ang[3])
{
    while (ang[0] > 89.0)
        ang[0] -= 180.0;
    while (ang[0] < -89.0)
        ang[0] += 180.0;
    while (ang[1] > 180.0)
        ang[1] -= 360.0;
    while (ang[1] < -180.0)
        ang[1] += 360.0;
}

/**
 * Normalizes an angle to the range [-180.0, 180.0].
 *
 * @param flAng      The angle to normalize.
 */
stock void AngleNormalize(float &flAng)
{
    if (flAng > 180.0)
        flAng -= 360.0;
    if (flAng < -180.0)
        flAng += 360.0;
}

/**
 * Retrieves the forward, right, and up vectors from a rotation matrix.
 *
 * @param matrix     The rotation matrix.
 * @param fwd        The forward vector.
 * @param right      The right vector.
 * @param up         The up vector.
 */
stock void MatrixVectors(const float matrix[3][3], float fwd[3], float right[3], float up[3])
{
    for (int x = 0; x < 3; x++)
    {
        fwd[x] = matrix[0][x];
        right[x] = matrix[1][x];
        up[x] = matrix[2][x];
    }

    NegateVector(right);
}

/**
 * Retrieves the angle vector from a rotation matrix.
 *
 * @param matrix     The rotation matrix.
 * @param ang        The angle vector.
 */
stock void MatrixAngles(const float matrix[3][3], float ang[3])
{
    float fwd[3], right[3];
    float up[3] = {0.0, 0.0, 1.0};

    for (int x = 0; x < 3; x++)
    {
        fwd[x] = matrix[0][x];
        right[x] = matrix[1][x];
    }

    up[2] = matrix[2][2];

    float xyD = SquareRoot(fwd[0] * fwd[0] + fwd[1] * fwd[1]);
    if (xyD > 0.001)
    {
        ang[0] = Rad2Deg(ArcTangent2(fwd[1], fwd[0]));
        ang[1] = Rad2Deg(ArcTangent2(-fwd[2], xyD));
        ang[2] = Rad2Deg(ArcTangent2(right[2], up[2]));
    }
    else
    {
        ang[0] = Rad2Deg(ArcTangent2(-right[0], right[1]));
        ang[1] = Rad2Deg(ArcTangent2(-fwd[2], xyD));
        ang[2] = 0.0;
    }
}

/**
 * Helper function to calculate sine and cosine of a radian value.
 *
 * @param radian     The radian value.
 * @param sine       The sine value.
 * @param cosine     The cosine value.
 */
stock void SinCos(float radian, float &sine, float &cosine)
{
    sine = Sine(radian);
    cosine = Cosine(radian);
}