@tool
extends Node2D

@export var gate_gap: float = 500.0:
	set(value):
		gate_gap = value
		setup_gate()

# Viewport height - adjust to your 1500px resolution
@export var world_height: float = 1500.0

func _ready():
	setup_gate()

func setup_gate():
	# Use get_node_or_null to prevent @tool errors in the editor
	var up_wall = get_node_or_null("Up")
	var down_wall = get_node_or_null("Down")
	var pass_area = get_node_or_null("Collider")
	
	if not up_wall or not down_wall or not pass_area:
		return
	# 1. Calculate the center points for the walls
	# We want the gap to be centered around the root's Y=0
	var half_gap = gate_gap / 2.0
	
	# 2. Position and Scale the UP wall
	# It should go from the top of the viewport to the start of the gap
	var up_height = (world_height / 2.0) - half_gap
	up_wall.position.y = -(half_gap + up_height / 2.0)
	_resize_body(up_wall, up_height)
	
	# 3. Position and Scale the DOWN wall
	# It should go from the end of the gap to the bottom of the viewport
	var down_height = (world_height / 2.0) - half_gap
	down_wall.position.y = (half_gap + down_height / 2.0)
	_resize_body(down_wall, down_height)
	
	# 4. Stretch the Pass Area (Collider)
	# It should fill the empty space in the middle
	var area_shape = pass_area.get_node("CollisionShape2D")
	if area_shape and area_shape.shape is RectangleShape2D:
		area_shape.shape.size = Vector2(50, gate_gap) # 50px wide detection zone
		pass_area.position.y = 0 # Keep it centered

func _resize_body(body: StaticBody2D, height: float):
	# Resize the Sprite
	var sprite = body.get_node_or_null("Sprite2D")
	if sprite and sprite.texture is GradientTexture2D:
		sprite.texture.width = 100 # Fixed wall width
		sprite.texture.height = int(height)
	
	# Resize the CollisionShape
	var col = body.get_node_or_null("CollisionShape2D")
	if col and col.shape is RectangleShape2D:
		col.shape.size = Vector2(100, height)
		
func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
