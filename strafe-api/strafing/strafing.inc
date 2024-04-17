#if defined _strafing_included_
  #endinput
#endif
#define _strafing_included_

enum StrafeType
{
    StrafeType_MaxAccel = 0,
    StrafeType_MaxAngle = 1,
    StrafeType_Capped = 2,
    StrafeType_Direction = 3
}

enum StrafeDir
{
    StrafeDir_Left = 0,
    StrafeDir_Right = 1,
    StrafeDir_Yaw = 3,
    StrafeDir_Buttons = 4
}

enum PositionType
{
    PositionType_Ground = 0,
    PositionType_Air,
    PositionType_Water
}

enum HullType
{
    HullType_Normal = 0,
    HullType_Ducked = 1,
    HullType_Point = 2
}

enum struct PlayerData
{
    float pos[3];
    float vel[3];
    float ang[3];
    bool onGround;
    bool ducking;
    bool duckPressed;
}

enum struct MovementVars
{
    float Friction;
    float EntFriction;
    float Frametime;
    float Gravity;
    float Maxspeed;
    float WishspeedCap;
    float Accelerate;
    float Airaccelerate;
    float EntGravity;
    float Stopspeed;
    float Maxvelocity;
    float Bounce;
    float Stepsize;
    bool ReduceWishspeed;
    bool OnGround;
}

enum struct StrafeInput
{
    float TargetYaw;
    float VectorialOffset;
    float AngleSpeed;
    float Scale;
    bool AFH;
    bool Vectorial;
    bool JumpOverride;
    bool Strafe;
    int Version;
    StrafeType StrafeType;
    float CappedLimit;
}

enum struct ProcessedFrame
{
    bool Processed;
    bool Forward;
    bool Back;
    bool Right;
    bool Left;
    bool Jump;
    bool ForceUnduck;
    float Yaw;
    float ForwardSpeed;
    float SideSpeed;
}