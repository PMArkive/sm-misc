# source engine surf / uphill slide physics

## CGameMovement::CategorizingPosition
in the `CGameMovement::CategorizePosition` function (gamemovement.cpp, line 1464), there is a check for the player's vertical velocity.

the `NON_JUMP_VELOCITY` constant is defined as 140.0f (gamemovement.cpp, line 1418). If the player's vertical velocity exceeds this value, they are considered "in the air," and the ground entity is set to NULL.

## ground friction and air movement 
when the player is "uphill sliding," the `CGameMovement::AirMove` function is called instead of `CGameMovement::WalkMove` (gamemovement.cpp, line 2306). the `AirMove` function does not apply ground friction to the player's movement.

## uphill sliding
### conditions
for this to occur, two conditions must be met:
1. the ramp must be steep enough (i.e., the vertical component of the player's velocity along the ramp must exceed `NON_JUMP_VELOCITY`).
2. the player's speed must be high enough.

### ClipVelocity
when a player collides with a surface, their velocity is adjusted to be parallel to the surface using the `ClipVelocity` (gamemovement.cpp, line 2880)

the function calculates the projection of the velocity onto the surface normal and subtracts it from the velocity, effectively making the velocity parallel to the surface.

### gravity and speed loss
during uphill sliding, gravity is applied to the player's velocity every frame in the `CGameMovement::AirMove` (gamemovement.cpp, line 2333) with `AddGravity` (gamemovement.cpp, line 2609)

uphill speed loss is primarily due to gravity

## surfing
### conditions
when a surface is steep enough that the player is always considered "in the air" when colliding with it, similar to uphill. its Z surface normal must be < 0.7.

### speed gain
1. the interaction with `ClipVelocity` and `AddGravity` allows the player to gain speed from gravity when moving down a slope.
2. air strafing enables the player to gain additional horizontal speed and control their position on the slope.

### air strafing 
in `CGameMovement::AirMove` (gamemovement.cpp, line 2263), wishdir (desired movement direction) is calculated based on the forward and side movements.

velocity is then adjusted based on the wishspeed wishdir and the air acceleration value (`sv_airaccelerate`) using the `AirAccelerate` (gamemovement.cpp, line 2308):

### ClipVelocity
after adjusting velocity based on air strafing, the velocity is clipped against the surface using `ClipVelocity` to ensure it remains parallel to the surface (gamemovement.cpp, line 2336).

`TryPlayerMove` (gamemovement.cpp, line 3028) handles the player's collision with surfaces and calls `ClipVelocity` to adjust the velocity.

## key concepts 
1. **wishspeed and wishdir :**
   - wishspeed represents the desired speed at which the player wants to move.
   - wishdir is the desired direction of movement, determined by the player's input (forward, backward, left, and right keys) and the direction they are looking (mouse movement).
- air max wishspeed is by default 30. this is a limitation on the projection of a vector instead of the velocity vector itself.

2. **veer:**
   -  the difference between the player's current velocity and their desired velocity (wishspeed in the wishdir direction).
   - it represents how much the player wants to change their direction of movement.

3. **velocity:**
   - current speed and direction of movement in 3D space.
   - it is represented as a vector with x, y, and z components, indicating the speed and direction along each axis.

4. **gravity:**
   - force that constantly pulls the player downward.
   - in the game, gravity is simulated by continuously decreasing the player's Z velocity over time.

5. **surface normal:**
   - vector that points perpendicular to a surface, such as the ground or a ramp.
   - it indicates the orientation of the surface and is used to calculate how the player's velocity should be adjusted when colliding with the surface.

6. **origin:**
   - current position in 3D space, represented by x, y, and z coordinates.

8. **ClipVelocity:**
   - adjusts the player's velocity when they collide with a surface.
   - it takes into account the surface normal and a backoff value (determined by the player's surface friction) to reflect the velocity off the surface.

9. **AirMove:**
   - handles the player's movement while they are in the air, including surfing.
   - applies gravity and calls other functions like AirAccelerate and TryPlayerMove to update origin and velocity

10. **AirAccelerate:**
    - increases the player's velocity in their desired direction (wishdir) while they are in the air.
    - takes into account the player's wishspeed, wishdir, and an acceleration value (sv_airaccelerate) to determine how much to increase the velocity.

11. **TryPlayerMove:**
    - attempts to move the player from their current position to a new position based on their velocity.
    - checks for collisions with surfaces along the way and calls PerformFlyCollisionResolution if a collision occurs.
- momentum mod surf fix plugin overrides this

12. **CheckParameters:**
    - CheckParameters is a function that checks and adjusts the player's movement parameters, such as sv_maxvelocity and sv_air_max_wishspeed, based on various game settings and limitations.

## surfing example 
1. when a player is surfing, they are considered to be "flying" or in the air.
2. the player's movement is primarily controlled by their wishdir (desired direction) and wishspeed (desired speed), which are determined by their keyboard and mouse inputs.
3. AirMove is responsible for handling the player's movement while surfing. it applies gravity to the player's velocity and calls AirAccelerate to increase the player's velocity in their wishdir.
4. AirAccelerate takes the player's wishdir, wishspeed, and an acceleration value (sv_airaccelerate) to calculate how much to increase the player's velocity. this allows the player to gain speed while surfing.
5. TryPlayerMove then attempts to move the player to a new position based on their updated velocity. 
6. CheckParameters is called in TryPlayerMove to ensure that the player's movement parameters stay within acceptable ranges, preventing any unexpected behavior.​​​​​​​​​​​​​​​​

## note
rngfix and momentum mod surf fix overrides some of this stuff. there’s also game specific code too. this covers general source sdk base movement
