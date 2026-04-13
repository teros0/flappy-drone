extends Node2D

@onready var world_height: float = get_viewport_rect().end.y
@export var effective_thrust2: float
@onready var copter = $Copter
@onready var top_ghost = $TopGhost
@onready var bottom_ghost = $BottomGhost

func _process(_delta):
	effective_thrust2 = $Copter.effective_thrust
	# 1. Make ghosts mirror the real drone visually
	# We use local positions so they stay relative to the pair
	top_ghost.position = copter.position + Vector2(0, -world_height)
	bottom_ghost.position = copter.position + Vector2(0, world_height)
	
	# Match the rotation so the ghosts tilt when the drone tilts
	top_ghost.rotation = copter.rotation
	bottom_ghost.rotation = copter.rotation

	# 2. Wrap Logic
	# When the REAL drone is fully past the threshold, we shift the whole pair
	if copter.position.y > world_height:
		position.y += world_height   # Move the root down
		copter.position.y -= world_height # Offset the child back up
		
	elif copter.position.y < 0:
		position.y -= world_height   # Move the root up
		copter.position.y += world_height # Offset the child back down
