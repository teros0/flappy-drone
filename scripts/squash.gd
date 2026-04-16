extends Node2D
const PlayerConfigResource = preload("res://scripts/player_config.gd")

@onready var ball: Node2D = $Ball
@onready var copter: Node2D = $Copter

@export var default_wrap_buffer: float = 50.0

# Ball-specific redirect config (bottom -> left/right random edge).
@export var ball_bottom_redirect_enabled: bool = true
@export var ball_left_spawn_y_range: Vector2 = Vector2(0.6, 0.8)
@export var ball_right_spawn_y_range: Vector2 = Vector2(0.6, 0.8)

# Local coop (player 2) bootstrap.
@export var spawn_second_player: bool = true
@export var player_configs: Array[Resource] = []

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
	copters.clear()
	var configs: Array[Resource] = _get_active_player_configs()
	for config in configs:
		var player_node: Node2D = _ensure_player_exists(config)
		if player_node:
			copters.append(player_node)
			_apply_player_config(player_node, config)


func _get_active_player_configs() -> Array[Resource]:
	if not player_configs.is_empty():
		return player_configs

	var defaults: Array[Resource] = []

	var player_one: Resource = PlayerConfigResource.new()
	player_one.player_id = 1
	player_one.node_name = &"Copter"
	player_one.spawn_offset = Vector2.ZERO
	player_one.thrust_up_action = &"ui_up"
	player_one.thrust_down_action = &"ui_down"
	player_one.rotate_left_action = &"ui_left"
	player_one.rotate_right_action = &"ui_right"
	player_one.push_action = &"push"
	defaults.append(player_one)

	if spawn_second_player:
		var player_two: Resource = PlayerConfigResource.new()
		player_two.player_id = 2
		player_two.node_name = &"Copter2"
		player_two.spawn_offset = Vector2(350.0, 0.0)
		player_two.thrust_up_action = &"p2_up"
		player_two.thrust_down_action = &"p2_down"
		player_two.rotate_left_action = &"p2_left"
		player_two.rotate_right_action = &"p2_right"
		player_two.push_action = &"p2_push"
		defaults.append(player_two)

	return defaults


func _ensure_player_exists(config: Resource) -> Node2D:
	if has_node(NodePath(config.node_name)):
		return get_node(NodePath(config.node_name)) as Node2D

	var duplicated := copter.duplicate()
	if not (duplicated is Node2D):
		return null

	var new_player := duplicated as Node2D
	new_player.name = String(config.node_name)
	new_player.position = copter.position + config.spawn_offset
	add_child(new_player)
	return new_player


func _apply_player_config(copter_node: Node2D, config: Resource) -> void:
	copter_node.set("player_id", config.player_id)
	copter_node.set("thrust_up_action", config.thrust_up_action)
	copter_node.set("thrust_down_action", config.thrust_down_action)
	copter_node.set("rotate_left_action", config.rotate_left_action)
	copter_node.set("rotate_right_action", config.rotate_right_action)
	copter_node.set("push_action", config.push_action)


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
