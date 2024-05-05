### 1. key vector operations
- `VectorMA`: performs vector addition with scaling. takes a starting vector, a direction vector, and a scale factor, and finds the resulting vector.
- `VectorCopy`: copies the contents of one vector to another.
- `VectorToArray`: converts a vector to a float array for easier manipulation.
- `CloseEnough`: checks if two vectors are close enough to each other within a specified epsilon tolerance.

### 2. plane clipping
when the player collides with a surface, calculates the plane normal and clips the player's velocity against it. clipping process involves the following steps:
1. calculate the plane normal of the collision.
2. find the dot product of the velocity and the plane normal.
3. scale the plane normal by the dot product and subtract it from velocity.
4. repeat the clipping process for all planes the player collides with.

### 3. valid plane search
when rampbug detected, searches for a valid plane to clip velocity against. examines the collision plane normal and compares it against a set of criteria to determine if it's a valid plane. if a valid plane is found, velocity is clipped against it to resolve the rampbug.

### 4. noclip workaround
if no valid plane is found, a workaround performs additional traces with offset positions to find a valid plane.  `momsurffix_enable_noclip_workaround` 

## cvars

### 1. `momsurffix_ramp_bumpcount` (default: 8, min: 4, max: 16)
the number of iterations to attempt to solve rampbugs. higher value means more attempts to fix the rampbug, but may impact performance.

### 2. `momsurffix_ramp_initial_retrace_length` (default: 0.2, min: 0.2, max: 5.0)
the initial offset distance used for retracing. helps to find a valid plane to clip against.

### 3. `momsurffix_enable_noclip_workaround` (default: 1, min: 0, max: 1)
when enabled, performs additional traces with offset positions to find a valid plane if we detect a rampbug and no valid plane is found. may impact performance.
