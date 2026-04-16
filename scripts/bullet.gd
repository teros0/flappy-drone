# Bullet.gd
extends Area2D

@export var speed: float = 1500.0
@export var bullet_impulse: float = 1000
@export var horizontal_despawn_margin: float = 100.0
var direction: Vector2 = Vector2.RIGHT

func _process(delta):
	position += direction * speed * delta
	_despawn_if_outside_horizontal_bounds()

func _on_body_entered(body):
	if body.name == "Copter":
		# Add your damage logic here
		body.apply_central_impulse(direction * bullet_impulse) # Give it a physical kick!
	queue_free()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	# Vertical wrapping intentionally lets bullets leave/re-enter the screen on Y,
	# so we only despawn when outside horizontal world bounds.
	_despawn_if_outside_horizontal_bounds()


func _despawn_if_outside_horizontal_bounds() -> void:
	var viewport_width: float = get_viewport_rect().size.x
	var screen_pos: Vector2 = get_viewport().get_canvas_transform() * global_position
	if screen_pos.x < -horizontal_despawn_margin:
		queue_free()
	elif screen_pos.x > viewport_width + horizontal_despawn_margin:
		queue_free()
