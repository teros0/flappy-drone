extends RigidBody2D

func _ready():
	var world_wrapper := WorldWrapper.new()
	add_child(world_wrapper)
	print("Screen wrapping active for: ", name)
