extends Node2D

@onready var ball: Node2D = $Ball
@onready var copter: Node2D = $Copter

@export var default_wrap_buffer: float = 50.0

# Ball-specific redirect config (bottom -> left/right random edge).
@export var ball_bottom_redirect_enabled: bool = true
@export var ball_left_spawn_y_range: Vector2 = Vector2(0.6, 0.8)
@export var ball_right_spawn_y_range: Vector2 = Vector2(0.6, 0.8)

# Local coop (player 2) bootstrap.
@export var spawn_second_player: bool = true
@export var second_player_spawn_offset: Vector2 = Vector2(350.0, 0.0)
@export var p2_thrust_up_action: StringName = &"p2_up"
@export var p2_thrust_down_action: StringName = &"p2_down"
@export var p2_rotate_left_action: StringName = &"p2_left"
@export var p2_rotate_right_action: StringName = &"p2_right"
@export var p2_push_action: StringName = &"p2_push"

var copters: Array[Node2D] = []

func _ready() -> void:
	_setup_players()
	_setup_wrappers()

func _process(_delta: float) -> void:
	Utils.handle_reset(self)


func _setup_wrappers() -> void:
	# Copters: standard both-axis wrap.
	for copter_node in copters:
		var copter_wrapper := _attach_wrapper(copter_node)
		copter_wrapper.wrap_mode = WorldWrapper.WrapMode.BOTH
		copter_wrapper.enable_bottom_redirect = false

	# Ball: both-axis wrap + diagonal-like bottom redirect to side edges.
	var ball_wrapper := _attach_wrapper(ball)
	ball_wrapper.wrap_mode = WorldWrapper.WrapMode.BOTH
	ball_wrapper.enable_bottom_redirect = ball_bottom_redirect_enabled
	ball_wrapper.left_edge_spawn_y_range = ball_left_spawn_y_range
	ball_wrapper.right_edge_spawn_y_range = ball_right_spawn_y_range


func _setup_players() -> void:
	copters = [copter]
	_configure_copter_inputs(copter, 1)

	if not spawn_second_player:
		return

	var second_player := _ensure_second_player_exists()
	if second_player:
		copters.append(second_player)
		_configure_copter_inputs(second_player, 2)


func _ensure_second_player_exists() -> Node2D:
	if has_node("Copter2"):
		return $Copter2 as Node2D

	var duplicated := copter.duplicate()
	if not (duplicated is Node2D):
		return null

	var second_player := duplicated as Node2D
	second_player.name = "Copter2"
	second_player.position = copter.position + second_player_spawn_offset
	add_child(second_player)
	return second_player


func _configure_copter_inputs(copter_node: Node2D, player_number: int) -> void:
	if player_number == 1:
		copter_node.set("player_id", 1)
		copter_node.set("thrust_up_action", &"ui_up")
		copter_node.set("thrust_down_action", &"ui_down")
		copter_node.set("rotate_left_action", &"ui_left")
		copter_node.set("rotate_right_action", &"ui_right")
		copter_node.set("push_action", &"push")
	else:
		copter_node.set("player_id", 2)
		copter_node.set("thrust_up_action", p2_thrust_up_action)
		copter_node.set("thrust_down_action", p2_thrust_down_action)
		copter_node.set("rotate_left_action", p2_rotate_left_action)
		copter_node.set("rotate_right_action", p2_rotate_right_action)
		copter_node.set("push_action", p2_push_action)


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
