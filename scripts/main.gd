extends Node2D

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("reset"):
		get_tree().reload_current_scene()
	$HUD/TotalThrust.text = str($PlayerPair.effective_thrust2)
