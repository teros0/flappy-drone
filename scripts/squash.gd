extends Node2D

func _ready():
	pass

func _process(_delta: float):
	if Utils.is_standalone(self):
		if Input.is_action_just_pressed("reset"):
			get_tree().reload_current_scene()
