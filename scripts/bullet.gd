# Bullet.gd
extends Area2D

@export var speed: float = 1500.0
@export var bullet_impulse: float = 1000
var direction: Vector2 = Vector2.RIGHT

func _process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body.name == "Copter":
		# Add your damage logic here
		body.apply_central_impulse(direction * bullet_impulse) # Give it a physical kick!
	queue_free()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
