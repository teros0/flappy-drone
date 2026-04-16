extends Node2D

@onready var ball: Node2D = $Ball
@onready var copter: Node2D = $Copter

@export var default_wrap_buffer: float = 50.0

# Ball-specific redirect config (bottom -> left/right random edge).
@export var ball_bottom_redirect_enabled: bool = true
@export var ball_left_spawn_y_range: Vector2 = Vector2(0.2, 0.8)
@export var ball_right_spawn_y_range: Vector2 = Vector2(0.2, 0.8)

func _ready() -> void:
	_setup_wrappers()

func _process(_delta: float) -> void:
	Utils.handle_reset(self)


func _setup_wrappers() -> void:
	# Copter: standard both-axis wrap.
	var copter_wrapper := _attach_wrapper(copter)
	copter_wrapper.wrap_mode = WorldWrapper.WrapMode.BOTH
	copter_wrapper.enable_bottom_redirect = false

	# Ball: both-axis wrap + diagonal-like bottom redirect to side edges.
	var ball_wrapper := _attach_wrapper(ball)
	ball_wrapper.wrap_mode = WorldWrapper.WrapMode.BOTH
	ball_wrapper.enable_bottom_redirect = ball_bottom_redirect_enabled
	ball_wrapper.left_edge_spawn_y_range = ball_left_spawn_y_range
	ball_wrapper.right_edge_spawn_y_range = ball_right_spawn_y_range


func _attach_wrapper(target: Node2D) -> WorldWrapper:
	var existing_wrapper: WorldWrapper = _find_wrapper(target)
	if existing_wrapper:
		return existing_wrapper

	var wrapper := WorldWrapper.new()
	wrapper.buffer = default_wrap_buffer
	target.add_child(wrapper)
	return wrapper


func _find_wrapper(target: Node2D) -> WorldWrapper:
	for child in target.get_children():
		if child is WorldWrapper:
			return child as WorldWrapper
	return null
