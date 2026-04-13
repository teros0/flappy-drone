extends StaticBody2D

@export var speed: float = 300.0
@export var direction: int = 1 # Set this to 1 or -1 in the INSPECTOR for each node

@export var top_limit: float = 0.0
@export var bottom_limit: float = 1500.0

func _ready():
	# If you want to be precise, you can get limits from the project settings
	bottom_limit = ProjectSettings.get_setting("display/window/size/viewport_height")

func _physics_process(delta):
	# 1. Move the node
	global_position.y += direction * speed * delta
	# 2. Check boundaries and FLIP direction
	if direction == 1 and global_position.y >= bottom_limit:
		global_position.y = bottom_limit
		direction = -1
		
	elif direction == -1 and global_position.y <= top_limit:
		global_position.y = top_limit
		direction = 1
