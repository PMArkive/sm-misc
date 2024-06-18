#source.python example implementation
import math
from events import Event
from players.entity import Player
from messages import HudMsg

# Initialize the global variables
g_clients = {}
gF_LastAngle = {}
gF_ClientPercentages = {}
gF_SyncCounts = {}
gI_StrafeTrainerTicks = 10 # Framerate of the Sync counter in ticks
gB_StrafeTrainer = {}
sv_air_max_wishspeed = 30.0  # For future reference, this should be here 

# Calculate the optimal strafe angle for the given speed
def perf_strafe_angle(speed):
    return math.degrees(math.atan(30.0 / speed))

# Normalize an angle to be within the range [-180, 180] degrees
def normalize_angle(angle):
    while angle <= -180.0:
        angle += 360.0
    while angle > 180.0:
        angle -= 360.0
    return angle

# Create a visual representation string for the given percentage
def visualize_string(percentage):
    if 0.5 <= percentage <= 1.5:
        spaces = int(round((percentage - 0.5) / 0.05))
        return " " * spaces + "|" + " " * (21 - spaces)
    return "|" if percentage < 1.0 else "                    |"

# Determine the color for the given percentage
def get_percentage_color(percentage):
    percent = int(round(percentage * 100))
    if 80 < percent < 120:
        return (0, 255, 0)    # Green
    elif 120 <= percent <= 150:
        return (128, 255, 0)  # Yellow-green
    elif 150 <= percent <= 180:
        return (255, 128, 0)  # Orange
    elif percent >= 180:
        return (255, 0, 0)    # Red
    elif 50 <= percent <= 80:
        return (0, 255, 128)  # Cyan-green
    elif 25 <= percent <= 50:
        return (0, 128, 255)  # Blue
    return (0, 0, 255)        # Deep blue

# Command to toggle the strafe trainer
def strafe_trainer_command(command, index):
    player = Player(index)
    if index not in gB_StrafeTrainer:
        gB_StrafeTrainer[index] = False
    gB_StrafeTrainer[index] = not gB_StrafeTrainer[index]
    player.chat(f"Strafe Trainer {'enabled' if gB_StrafeTrainer[index] else 'disabled'}")
    return

# Event to handle player command execution
def on_player_run_command(event_data):
    index = event_data['userid']
    player = Player(index)
    
    if not gB_StrafeTrainer.get(index, False):
        return
    
    angles = player.view_angle
    velocity = player.velocity
    speed = velocity.length_2d
    buttons = player.buttons

    # Calculate the angle difference and the perfect strafe angle
    ang_diff = normalize_angle(gF_LastAngle.get(index, angles.y) - angles.y)
    perf_angle = perf_strafe_angle(speed)
    ang_diff = abs(ang_diff)
    percentage = ang_diff / perf_angle

    # Check synchronization of keypresses with mouse movement
    moving_left = buttons & PlayerButtons.MOVELEFT
    moving_right = buttons & PlayerButtons.MOVERIGHT
    sync = False

    if ang_diff < 0 and moving_right:  # View angle moving right and pressing right
        sync = True
    elif ang_diff > 0 and moving_left:  # View angle moving left and pressing left
        sync = True

    # Initialize sync count tracking
    if index not in gF_SyncCounts:
        gF_SyncCounts[index] = {'total': 0, 'synced': 0}

    gF_SyncCounts[index]['total'] += 1  # Increment total ticks
    if sync:
        gF_SyncCounts[index]['synced'] += 1  # Increment synced ticks

    # Append the percentage for later averaging
    if index not in gF_ClientPercentages:
        gF_ClientPercentages[index] = []

    gF_ClientPercentages[index].append(percentage)

    # Calculate average sync over the defined framerate
    if len(gF_ClientPercentages[index]) >= gI_StrafeTrainerTicks:
        average_percentage = sum(gF_ClientPercentages[index]) / gI_StrafeTrainerTicks
        gF_ClientPercentages[index] = []

        vis_string = visualize_string(average_percentage)
        color = get_percentage_color(average_percentage)

        # Calculate sync percentage
        total_ticks = gF_SyncCounts[index]['total']
        synced_ticks = gF_SyncCounts[index]['synced']
        sync_percentage = (synced_ticks / total_ticks) * 100 if total_ticks > 0 else 0

        # Write sync percentage
        sync_message = f"Sync: {sync_percentage:.2f}%"

        # Visualize sync percentage
        message = f"{int(average_percentage * 100)}%\n══════^══════\n {vis_string}\n══════^══════\n{sync_message}"
        HudMsg(message, duration=3.0, x=0.5, y=0.5, color=color).send(player.index)

        # Reset sync counts after displaying the message
        gF_SyncCounts[index] = {'total': 0, 'synced': 0}
    
    # Save the current view angle for the next tick
    gF_LastAngle[index] = angles.y
