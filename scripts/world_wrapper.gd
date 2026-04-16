extends Node
class_name WorldWrapper

@export var buffer: float = 50.0
@export var wrap_mode: WrapMode = WrapMode.BOTH
@export var enable_bottom_redirect: bool = false

# Bottom redirection can pick between left/right edge and supports
# configurable vertical spawn ranges for each side.
@export var left_edge_spawn_y_range: Vector2 = Vector2(0.6, 0.8)
@export var right_edge_spawn_y_range: Vector2 = Vector2(0.6, 0.8)

enum WrapMode { HORIZONTAL, VERTICAL, BOTH }
enum ExitSide { LEFT, RIGHT }

func _init(mode: WrapMode = WrapMode.BOTH):
	wrap_mode = mode

func _physics_process(_delta: float) -> void:
	var parent = get_parent() as Node2D
	if not parent:
		return

	var limit_x: float = Utils.get_width()
	var limit_y: float = Utils.get_height()

	if _wraps_vertical():
		_wrap_vertical(parent, limit_x, limit_y)
	if _wraps_horizontal():
		_wrap_horizontal(parent, limit_x)


func _wraps_vertical() -> bool:
	return wrap_mode == WrapMode.VERTICAL or wrap_mode == WrapMode.BOTH


func _wraps_horizontal() -> bool:
	return wrap_mode == WrapMode.HORIZONTAL or wrap_mode == WrapMode.BOTH


func _wrap_vertical(parent: Node2D, limit_x: float, limit_y: float) -> void:
	if parent.global_position.y > limit_y + buffer:
		if enable_bottom_redirect:
			_apply_bottom_redirect(parent, limit_x, limit_y)
		else:
			parent.global_position.y = -buffer
	elif parent.global_position.y < -buffer:
		parent.global_position.y = limit_y + buffer


func _wrap_horizontal(parent: Node2D, limit_x: float) -> void:
	if parent.global_position.x > limit_x + buffer:
		parent.global_position.x = -buffer
	elif parent.global_position.x < -buffer:
		parent.global_position.x = limit_x + buffer


func _apply_bottom_redirect(parent: Node2D, limit_x: float, limit_y: float) -> void:
	var exit_side: ExitSide = _pick_bottom_exit_side()
	if exit_side == ExitSide.LEFT:
		parent.global_position.x = -buffer
		parent.global_position.y = _pick_spawn_y(limit_y, left_edge_spawn_y_range)
	else:
		parent.global_position.x = limit_x + buffer
		parent.global_position.y = _pick_spawn_y(limit_y, right_edge_spawn_y_range)


func _pick_bottom_exit_side() -> ExitSide:
	if randf() < 0.5:
		return ExitSide.LEFT
	return ExitSide.RIGHT


func _pick_spawn_y(limit_y: float, normalized_range: Vector2) -> float:
	var min_ratio: float = clamp(min(normalized_range.x, normalized_range.y), 0.0, 1.0)
	var max_ratio: float = clamp(max(normalized_range.x, normalized_range.y), 0.0, 1.0)
	return randf_range(min_ratio * limit_y, max_ratio * limit_y)
