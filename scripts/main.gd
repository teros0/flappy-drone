extends Node2D

func _ready():
	$PlayerPair.throttle_updated.connect(_on_throttle_updated)

func _process(_delta: float) -> void:
	Utils.handle_reset(self)
	$HUD/TotalThrust.text = str($PlayerPair.throttle_value)

func _on_throttle_updated(val):
	$HUD/ThrottleBar.value = val * 100
