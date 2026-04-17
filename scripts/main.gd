extends Node2D

@export var wrap_buffer: float = 0.0
@export var wrap_bullets_vertically: bool = true

var score: int = 0
var game_over: bool = false
var game_over_delay: float = 1.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	$PlayerPair.process_mode = Node.PROCESS_MODE_PAUSABLE
	$CameraSystem.process_mode = Node.PROCESS_MODE_PAUSABLE
	$ProceduralManager.process_mode = Node.PROCESS_MODE_PAUSABLE
	
	$PlayerPair.throttle_updated.connect(_on_throttle_updated)
	_inject_wrapper_for_copter()
	get_tree().node_added.connect(_on_node_added)
	
	$ProceduralManager.score_gained.connect(_on_score_gained)
	$CameraSystem.player_fell_behind.connect(_on_player_died)
	_setup_hud()

func _input(event: InputEvent) -> void:
	if game_over and game_over_delay <= 0.0:
		if (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed):
			get_tree().paused = false
			get_tree().reload_current_scene()

func _process(delta: float) -> void:
	if game_over:
		game_over_delay -= delta
		return
	Utils.handle_reset(self)
	
	var hud_thrust = $HUD.get_node_or_null("TotalThrust")
	if hud_thrust:
		hud_thrust.text = str($PlayerPair.throttle_value)

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

func _setup_hud() -> void:
	var score_lbl = Label.new()
	score_lbl.name = "ScoreLabel"
	score_lbl.add_theme_font_size_override("font_size", 48)
	score_lbl.position = Vector2(get_viewport_rect().size.x / 2.0 - 50, 50)
	score_lbl.text = "0"
	$HUD.add_child(score_lbl)
	
	var game_over_lbl = Label.new()
	game_over_lbl.name = "GameOverLabel"
	game_over_lbl.add_theme_font_size_override("font_size", 64)
	game_over_lbl.position = Vector2(get_viewport_rect().size.x / 2.0 - 200, get_viewport_rect().size.y / 2.0)
	game_over_lbl.text = "GAME OVER\\nPress any key to restart"
	game_over_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_lbl.visible = false
	$HUD.add_child(game_over_lbl)

func _on_score_gained() -> void:
	if game_over: return
	score += 1
	var lbl = $HUD.get_node_or_null("ScoreLabel")
	if lbl: lbl.text = str(score)

func _on_player_died() -> void:
	if game_over: return
	game_over = true
	var game_over_lbl = $HUD.get_node_or_null("GameOverLabel")
	if game_over_lbl: game_over_lbl.visible = true
	get_tree().paused = true
