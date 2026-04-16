extends RigidBody2D

@export var decay_on_wall_hit: float = 0.4
@export var minimum_speed: float = 0.0

func _ready():
	# Disable gravity so the ball is fully driven by collisions / impulses
	gravity_scale = 0.0
	contact_monitor = true
	max_contacts_reported = 8


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	# Detect collisions this physics step and, if we hit a squash wall,
	# apply a controllable decay to the ball's speed.
	if state.get_contact_count() == 0:
		return

	var i: int = 0
	while i < state.get_contact_count():
		var collider: Object = state.get_contact_collider_object(i)
		if collider and collider.is_in_group("squash_wall"):
			if decay_on_wall_hit > 0.0:
				var v: Vector2 = state.linear_velocity
				var speed: float = v.length()
				if speed > 0.0:
					var new_speed: float = max(speed * (1.0 - decay_on_wall_hit), minimum_speed)
					if new_speed < speed:
						state.linear_velocity = v.normalized() * new_speed
			break
		i += 1
