extends Node2D

func _ready():
	$PlayerPair.throttle_updated.connect(_on_throttle_updated)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("reset"):
		get_tree().reload_current_scene()
	$HUD/TotalThrust.text = str($PlayerPair.throttle_value)

func _on_throttle_updated(val):
	$HUD/ThrottleBar.value = val * 100
