extends Node2D
const PlayerConfigResource = preload("res://scripts/player_config.gd")
const SquashRulesResource = preload("res://scripts/squash_rules.gd")

@onready var ball: Node2D = $Ball
@onready var copter: Node2D = $Copter

@export var default_wrap_buffer: float = 50.0

# Ball-specific redirect config (bottom -> left/right random edge).
@export var ball_bottom_redirect_enabled: bool = true
@export var ball_left_spawn_y_range: Vector2 = Vector2(200.0, 500.0)
@export var ball_right_spawn_y_range: Vector2 = Vector2(200.0, 500.0)

# Local coop (player 2) bootstrap.
@export var spawn_second_player: bool = true
@export var player_configs: Array[Resource] = []
@export var rules: Resource

var copters: Array[Node2D] = []
var scores_by_player_id: Dictionary = {}
var last_touch_player_id: int = -1
var game_over: bool = false
@onready var score_label: Label = $HUD/Score
@onready var state_label: Label = $HUD/State
var ball_spawn_position: Vector2
var active_rules: Resource
var ball_wrapper: WorldWrapper
var pending_receiver_player_id: int = -1
var bottom_pass_count_since_wall: int = 0

func _ready() -> void:
	_init_rules()
	ball_spawn_position = ball.global_position
	_setup_players()
	_setup_wrappers()
	_setup_scoring()
	_refresh_hud()

func _process(_delta: float) -> void:
	Utils.handle_reset(self)

func _setup_players() -> void:
	copters.clear()
	var configs: Array[Resource] = _get_active_player_configs()
	for config in configs:
		var player_node: Node2D = _ensure_player_exists(config)
		if player_node:
			copters.append(player_node)
			_apply_player_config(player_node, config)
			player_node.add_to_group("squash_player")
			_ensure_score_entry(int(player_node.get("player_id")))

func _setup_wrappers() -> void:
	# Copters: standard both-axis wrap.
	for copter_node in copters:
		var copter_wrapper := _attach_wrapper(copter_node)
		copter_wrapper.wrap_mode = WorldWrapper.WrapMode.BOTH
		copter_wrapper.enable_bottom_redirect = false

	# Ball: both-axis wrap + diagonal-like bottom redirect to side edges.
	ball_wrapper = _attach_wrapper(ball)
	ball_wrapper.wrap_mode = WorldWrapper.WrapMode.BOTH
	ball_wrapper.enable_bottom_redirect = ball_bottom_redirect_enabled
	ball_wrapper.left_edge_spawn_y_range = ball_left_spawn_y_range
	ball_wrapper.right_edge_spawn_y_range = ball_right_spawn_y_range
	if not ball_wrapper.wrapped.is_connected(_on_ball_wrapped):
		ball_wrapper.wrapped.connect(_on_ball_wrapped)

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

	if spawn_second_player and active_rules.mode != SquashRules.Mode.SINGLEPLAYER:
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


func _setup_scoring() -> void:
	if ball.has_signal("touched_by_player"):
		ball.touched_by_player.connect(_on_ball_touched_by_player)
	if ball.has_signal("hit_squash_wall"):
		ball.hit_squash_wall.connect(_on_ball_hit_wall)


func _on_ball_touched_by_player(player_id: int) -> void:
	if game_over:
		return
	last_touch_player_id = player_id
	if active_rules.mode == SquashRules.Mode.VERSUS and player_id == pending_receiver_player_id:
		# Successful return: clear pending miss state.
		pending_receiver_player_id = -1
		bottom_pass_count_since_wall = 0
	_refresh_hud()


func _on_ball_hit_wall() -> void:
	if game_over:
		return
	bottom_pass_count_since_wall = 0

	if active_rules.mode == SquashRules.Mode.SINGLEPLAYER:
		# Singleplayer: reward wall hits directly.
		_award_point(1, active_rules.points_per_wall_hit)
		_check_winner()
		_refresh_hud()
		return

	# Versus: wall hit starts opponent's return window.
	if last_touch_player_id < 0:
		_refresh_hud()
		return
	pending_receiver_player_id = _get_other_player_id(last_touch_player_id)
	_refresh_hud()


func _award_point(player_id: int, points: int) -> void:
	_ensure_score_entry(player_id)
	scores_by_player_id[player_id] = int(scores_by_player_id[player_id]) + points


func _ensure_score_entry(player_id: int) -> void:
	if not scores_by_player_id.has(player_id):
		scores_by_player_id[player_id] = 0


func _check_winner() -> void:
	if active_rules.mode == SquashRules.Mode.SINGLEPLAYER:
		if state_label:
			state_label.text = "Singleplayer | Bottom miss after %d pass(es)" % active_rules.bottom_passes_before_miss
		return
	for player_id in scores_by_player_id.keys():
		if int(scores_by_player_id[player_id]) >= active_rules.winning_score:
			game_over = true
			if state_label:
				state_label.text = "Player %d wins! Press R to reset." % int(player_id)
			return
	if state_label:
		if pending_receiver_player_id > 0:
			state_label.text = "P%d must return | Bottom passes: %d/%d" % [pending_receiver_player_id, bottom_pass_count_since_wall, active_rules.bottom_passes_before_miss]
		else:
			state_label.text = "Rally live | Last touch: %s" % _get_last_touch_text()


func _init_rules() -> void:
	if rules:
		active_rules = rules
		return
	active_rules = SquashRulesResource.new()


func _refresh_hud() -> void:
	if not score_label or not state_label:
		return
	score_label.text = _build_score_text()
	if not game_over:
		if active_rules.mode == SquashRules.Mode.SINGLEPLAYER:
			state_label.text = "Singleplayer | Score on wall, lose on bottom (%d pass(es))" % active_rules.bottom_passes_before_miss
		else:
			if pending_receiver_player_id > 0:
				state_label.text = "P%d must return | Bottom passes: %d/%d" % [pending_receiver_player_id, bottom_pass_count_since_wall, active_rules.bottom_passes_before_miss]
			else:
				state_label.text = "Rally live | Last touch: %s | First to %d" % [_get_last_touch_text(), active_rules.winning_score]


func _build_score_text() -> String:
	if active_rules.mode == SquashRules.Mode.SINGLEPLAYER:
		_ensure_score_entry(1)
		return "Score: %d" % int(scores_by_player_id[1])
	var player_ids: Array[int] = []
	for key in scores_by_player_id.keys():
		player_ids.append(int(key))
	player_ids.sort()

	var parts: Array[String] = []
	for player_id in player_ids:
		parts.append("P%d: %d" % [player_id, int(scores_by_player_id[player_id])])
	return "  ".join(parts)


func _get_last_touch_text() -> String:
	if last_touch_player_id < 0:
		return "-"
	return "P%d" % last_touch_player_id


@export var ball_horizontal_wrap_speed_multiplier: float = 1.2

@export var ball_redirect_speed: float = 1200.0

func _shoot_ball_towards_center_deferred() -> void:
	call_deferred("_shoot_ball_towards_center")

func _shoot_ball_towards_center() -> void:
	if not (ball is RigidBody2D):
		return
	var vp_size = get_viewport_rect().size
	var center = Vector2(vp_size.x * 0.5, vp_size.y * 0.5)
	var dir = (center - ball.global_position).normalized()
	ball.set_deferred("linear_velocity", dir * ball_redirect_speed)

func _on_ball_wrapped(axis: String, edge: String) -> void:
	if game_over:
		return
		
	if axis == "horizontal":
		if ball is RigidBody2D:
			ball.linear_velocity.x *= ball_horizontal_wrap_speed_multiplier
		return
		
	if axis != "vertical" or edge != "bottom":
		return

	if active_rules.mode == SquashRules.Mode.SINGLEPLAYER:
		bottom_pass_count_since_wall += 1
		if bottom_pass_count_since_wall >= active_rules.bottom_passes_before_miss:
			_award_point(1, -active_rules.points_lost_on_bottom_miss)
			_refresh_hud()
			_reset_rally(1)
		else:
			_shoot_ball_towards_center_deferred()
		return

	# Versus: only count bottom passes while someone is expected to return.
	if pending_receiver_player_id <= 0:
		_shoot_ball_towards_center_deferred()
		return

	bottom_pass_count_since_wall += 1
	if bottom_pass_count_since_wall < active_rules.bottom_passes_before_miss:
		_refresh_hud()
		_shoot_ball_towards_center_deferred()
		return

	var scorer_player_id: int = _get_other_player_id(pending_receiver_player_id)
	if scorer_player_id > 0:
		_award_point(scorer_player_id, active_rules.points_per_wall_hit)
	_check_winner()
	var loser_id: int = pending_receiver_player_id
	_refresh_hud()
	_reset_rally(loser_id)


func _get_other_player_id(player_id: int) -> int:
	var player_ids: Array[int] = []
	for key in scores_by_player_id.keys():
		player_ids.append(int(key))
	player_ids.sort()
	for id in player_ids:
		if id != player_id:
			return id
	return -1


func _reset_rally(loser_id: int) -> void:
	if game_over:
		return
	
	var vp: Rect2 = get_viewport_rect()
	var vp_size: Vector2 = vp.size
	var copter_y: float = vp_size.y * 0.7
	
	var ball_pos: Vector2 = Vector2(vp_size.x * 0.5, vp_size.y * 0.3)
	if loser_id == 1:
		ball_pos = Vector2(vp_size.x * 0.35, vp_size.y * 0.6)
	elif loser_id == 2:
		ball_pos = Vector2(vp_size.x * 0.65, vp_size.y * 0.6)
		
	ball.set_deferred("global_position", ball_pos)
	if ball is RigidBody2D:
		ball.set_deferred("linear_velocity", Vector2.ZERO)
		ball.set_deferred("angular_velocity", 0.0)

	for node in copters:
		var p_id: int = int(node.get("player_id"))
		var target_x: float = vp_size.x * 0.5
		if p_id == 1:
			target_x = vp_size.x * 0.2
		elif p_id == 2:
			target_x = vp_size.x * 0.8
		
		node.set_deferred("global_position", Vector2(target_x, copter_y))
		node.set_deferred("rotation", 0.0)
		if node is RigidBody2D:
			node.set_deferred("linear_velocity", Vector2.ZERO)
			node.set_deferred("angular_velocity", 0.0)

	last_touch_player_id = -1
	pending_receiver_player_id = -1
	bottom_pass_count_since_wall = 0
	_refresh_hud()
