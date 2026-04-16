extends Node
class_name WorldWrapper

@export var buffer: float = 50.0

func _physics_process(_delta):
	var parent = get_parent() as Node2D
	if not parent: return

	var limit_y = Utils.get_height()
	
	if parent.global_position.y > limit_y + buffer:
		parent.global_position.y = -buffer
	elif parent.global_position.y < -buffer:
		parent.global_position.y = limit_y + buffer
