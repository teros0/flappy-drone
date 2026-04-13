extends Node2D

@export var rotation_speed = 3
@export var rotation_direction = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rotation_direction = [-1, 1].pick_random()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	rotate(rotation_direction*rotation_speed*delta) 

func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	queue_free()
