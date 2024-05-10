# host_timescale

`host_timescale ` should not ever be used in TAS runs, and heres why

## general

### 1. PlayerMove wishvel 

in  `CGameMovement::PlayerMove`, `mv->m_flForwardMove`, `mv->m_flSideMove`, and `mv->m_flUpMove` are used to calculate (`wishvel`) based on eye ang.
when `host_timescale` is applied, the movement inputs are multiplied by the `host_timescale` value before being used. as a result, for a given input, the resulting `wishvel` will be scaled by `host_timescale`.

so lets say our inputs are (`fx`, `fy`, `fz`) for forward, side, and up:

```
wishvel = fx * forward + fy * right + fz * up
```

when `host_timescale` (`ts`) becomes:

```
wishvel_scaled = (fx * ts) * forward + (fy * ts) * right + (fz * ts) * up
               = ts * (fx * forward + fy * right + fz * up)
               = ts * wishvel
```

for the same inputs, wishvel is higher when `host_timescale > 1` and shorter when `host_timescale < 1`.... not ideal

### 2. frametime fuckery

(`gpGlobals->frametime`) is used in everything to determine how far the player should move in a single frame.

with `host_timescale` is applied, the game frametime is multiplied by `host_timescale` value. so it messes with a lot here for sure

with velocity `v`, frametime `Δt`. distance (`d`) the player moves in a single frame is calculated as follows:

```
d = v * Δt
```

with `host_timescale` (`ts`), becomes:

```
d_scaled = v * (Δt * ts)
         = (v * ts) * Δt
```

player will move a distance scaled by `host_timescale` in each frame. additionally, the frequency of movement-related checks, such as categorizing the player's position and collision, will be affected by this.

## surfing

now lets talk about our surfing overlords `AirMove`, `AirAccelerate`, `PerformFlyCollisionResolution`, and `ClipVelocity`.

### 1. AirMove and AirAccelerate

`AirMove` calculates `wishdir`, `wishspeed` based on input and eye ang. then these are passed to  `AirAccelerate` and are used with `sv_airaccelerate` to apply acceleration to the velocity.

this is the same problem with PlayerMove but it is actually much worse here

when `host_timescale` is applied, the acceleration is indirectly affected due to the scaled `wishspeed` and game frametime. the scaled `wishspeed` results in a proportionally scaled acceleration, while the scaled frametime affects how much acceleration is applied in each frame.

lets say current velocity is `v`, `wishspeed` is `ws`, `wishdir` is `wd`, and `sv_airaccelerate` is `aa`. the acceleration (`a`) is:

```
a = aa * ws * Δt * wd
```

with `host_timescale` (`ts`) it becomes:

```
a_scaled = aa * (ws * ts) * (Δt * ts) * wd
         = (aa * ts^2) * ws * Δt * wd
         = ts^2 * a
```

so accel is scaled by the square of `host_timescale`, which is fucked up.

### 3. PerformFlyCollisionResolution and ClipVelocity

`PerformFlyCollisionResolution`  is responsible for resolving collisions in surfing. it handles collision response and calls `ClipVelocity` to adjust the player's velocity based on the collision plane normal.

with `host_timescale`, the scaled velocity may result in different collision responses, while the scaled frametime affects the duration of the collision resolution step.

`ClipVelocity` takes the player's current velocity, the collision plane normal, and an elasticity coefficient (`overbounce`) as input and calculates the new velocity after collision.

with `host_timescale` the scaled velocity affects the magnitude of the velocity components parallel and perpendicular to the collision plane, influencing the post-collision velocity.

lets say  current velocity `v`, the collision plane normal `n`, and the elasticity coefficient `e`. the post-collision velocity (`v_post`) is calculated as follows:

```
v_parallel = v - (v · n) * n
v_perp = (v · n) * n
v_post = v_parallel - e * v_perp
```

with `host_timescale` (`ts`) becomes:

```
v_scaled = v * ts
v_parallel_scaled = v_scaled - (v_scaled · n) * n
v_perp_scaled = (v_scaled · n) * n
v_post_scaled = v_parallel_scaled - e * v_perp_scaled
              = ts * (v_parallel - e * v_perp)
              = ts * v_post
```

this definitely fucks with ducking the most but i dont completely understand why yet



## collision detection timing

1. **trace ray inconsistency:**
   frametime is used to calculate the start and end positions of the trace ray. when `host_timescale` is modified, the frame time changes, leading to inconsistencies in the trace ray's positions.

  consider `CEngineTrace::TraceRay`:

   ```cpp
   void CEngineTrace::TraceRay(const Ray_t& ray, unsigned int fMask, ITraceFilter* pTraceFilter, trace_t* pTrace)
   {
       // ...
       float flFrameTime = gpGlobals->frametime;
       Vector vecEndPos = ray.m_Start + ray.m_Delta * flFrameTime;
       // ...
   }
   ```

let's assume the default frame time 0.015 seconds (66.67 tick) and the ray's delta is (100, 0, 0). if `host_timescale` is set to 2, the frame time becomes 0.0075 seconds.

   default trace ray end position: (100 * 0.015, 0, 0) = (1.5, 0, 0)
   trace ray end position with `host_timescale` = 2: (100 * 0.0075, 0, 0) = (0.75, 0, 0)

the trace ray's end position is now inconsistent with the actual movement, leading to inaccurate collision detection.

2. **sweep distance discrepancy:**
 frame time is also used to calculate the sweep distance when performing sweep tests. `host_timescale` can cause discrepancies in the sweep distance

 consider `CEngineTrace::SweepCollideable`:

   ```cpp
   void CEngineTrace::SweepCollideable(ICollideable* pCollide, const Vector& vecAbsStart, const Vector& vecAbsEnd, const QAngle& vecAngles, unsigned int fMask, ITraceFilter* pTraceFilter, trace_t* pTrace)
   {
       // ...
       float flFrameTime = gpGlobals->frametime;
       Vector vecDelta = (vecAbsEnd - vecAbsStart) * flFrameTime;
       // ...
   }
   ```

 so let’s say the sweep distance between `vecAbsStart` and `vecAbsEnd` is 100 units, and the default frame time is 0.015 seconds. If `host_timescale` is set to 0.5, the frame time becomes 0.03 seconds.

   default sweep distance: 100 * 0.015 = 1.5 units
   sweep distance with `host_timescale` = 0.5: 100 * 0.03 = 3 units

   the sweep distance is doubled, potentially causing the sweep test to miss collisions or detect false positives.

3. **collision response inconsistency:**
   when a collision is detected, the new positions and velocities of the involved entities is calculated based on the collision normal and the frame time. 

 consider `CCollisionEvent::RespondToCollision`:

   ```cpp
   void CCollisionEvent::RespondToCollision(CBaseEntity* pEntity, trace_t* pTrace)
   {
       // ...
       float flFrameTime = gpGlobals->frametime;
       Vector vecNewVelocity = pEntity->GetVelocity() - pTrace->plane.normal * pEntity->GetVelocity().Dot(pTrace->plane.normal);
       Vector vecNewPosition = pEntity->GetPosition() + vecNewVelocity * flFrameTime;
       // ...
   }
   ```

so let’s assume the entity's velocity is (100, 0, 0), the collision normal is (0, 1, 0), and the default frame time is 0.015 seconds. now`host_timescale` is set to 3, the frame time becomes 0.005 seconds.

   default new position: (100, 0, 0) * 0.015 = (1.5, 0, 0)
   new position with timescale: (100, 0, 0) * 0.005 = (0.5, 0, 0)

the entity's new position after the collision response is inconsistent

## the importance of frametime consistency

frametime is used through the entire collision detection pipeline and collision detection is highly tied to physics. you can’t tas with timescale mayne

