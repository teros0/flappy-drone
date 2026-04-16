extends Node2D

@export var wrap_buffer: float = 0.0
@export var wrap_bullets_vertically: bool = true

func _ready():
	$PlayerPair.throttle_updated.connect(_on_throttle_updated)
	_inject_wrapper_for_copter()
	get_tree().node_added.connect(_on_node_added)

func _process(_delta: float) -> void:
	Utils.handle_reset(self)
	$HUD/TotalThrust.text = str($PlayerPair.throttle_value)

func _on_throttle_updated(val):
	$HUD/ThrottleBar.value = val * 100


func _on_node_added(node: Node) -> void:
	if not wrap_bullets_vertically:
		return
	if node is Area2D and node.name == "Bullet":
		_inject_vertical_wrapper(node as Node2D)


func _inject_wrapper_for_copter() -> void:
	var copter: Node2D = $PlayerPair/Copter
	_inject_vertical_wrapper(copter)


func _inject_vertical_wrapper(target: Node2D) -> void:
	if _find_wrapper(target):
		return
	var wrapper := WorldWrapper.new()
	wrapper.buffer = wrap_buffer
	wrapper.wrap_mode = WorldWrapper.WrapMode.VERTICAL
	wrapper.enable_bottom_redirect = false
	target.add_child(wrapper)


func _find_wrapper(target: Node2D) -> WorldWrapper:
	for child in target.get_children():
		if child is WorldWrapper:
			return child as WorldWrapper
	return null
