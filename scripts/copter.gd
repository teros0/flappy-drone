extends RigidBody2D

signal left_edge_exited
signal thrust_changed(new_value)

@onready var screen_height: float = get_viewport_rect().end.y

@export var engine_power: float = 7000.0
@export var torque_power: float = 100000.0
@export var weight_compensation: float = 1.2

@export var effective_thrust :float = 0.0

# New Throttle Logic
@export var throttle_level: float = 0.3
@export var throttle_step: float = 0.1
@export var max_ramp_time: float = 1.5 # Seconds to reach 0.4
var hold_time: float = 0.0

# Push (burst) action
@export var push_speed: float = 2500.0
@export var push_duration: float = 0.15
@export var push_return_speed: float = 1800.0
@export var push_return_duration: float = 0.12
var push_time_left: float = 0.0
var return_time_left: float = 0.0
var push_direction: Vector2 = Vector2.ZERO

func _input(event):
	# Handle Mouse Wheel for Throttle Setting
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			throttle_level = clamp(throttle_level + throttle_step, 0.0, 1.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			throttle_level = clamp(throttle_level - throttle_step, 0.0, 1.0)
			
	if Utils.is_standalone(self):
		if Input.is_action_just_pressed("reset"):
			get_tree().reload_current_scene()


func _physics_process(_delta):
	# Handle push burst
	if Input.is_action_just_pressed("push") and push_time_left <= 0.0 and return_time_left <= 0.0:
		_start_push()

	# The punch is a forward jab, then a quick retract.
	if push_time_left > 0.0:
		push_time_left -= _delta
		linear_velocity = push_direction * push_speed
		angular_velocity = 0.0
		if push_time_left <= 0.0:
			_start_return()
		return

	if return_time_left > 0.0:
		return_time_left -= _delta
		linear_velocity = -push_direction * push_return_speed
		angular_velocity = 0.0
		if return_time_left <= 0.0:
			_end_push()
		return

	var is_thrusting = Input.is_action_pressed("ui_up")
	var rotation_input = Input.get_axis("ui_left", "ui_right")

	# Always update hold_time regardless of key state
	if is_thrusting:
		hold_time = min(hold_time + _delta, max_ramp_time)
	else:
		# Spool down twice as fast as it spools up
		hold_time = max(hold_time - (_delta * 2.0), 0.0)

	# ALWAYS calculate effective_thrust so it can "die down"
	var t = hold_time / max_ramp_time
	var curve_multiplier = 0.8 + (0.6 * sqrt(t))

	# If the engine isn't engaged, the thrust applied to physics is 0, 
	# but the VISUAL throttle can still show the engine ramping up/down
	effective_thrust = throttle_level * curve_multiplier

	# ALWAYS emit the signal so the HUD stays in sync
	# If you want the HUD to show 0 when not pressing 'up', 
	# you can multiply by (1.0 if is_thrusting else 0.0)
	thrust_changed.emit(effective_thrust if is_thrusting else 0.0)

	if is_thrusting:
		var total_thrust = transform.y * -effective_thrust * engine_power * weight_compensation
		apply_central_force(total_thrust)

	if rotation_input != 0:
		apply_torque(rotation_input * torque_power)


func _start_push() -> void:
	# Short, strong burst forward in the copter's local "forward" direction
	# Use -transform.y so the top of the rectangle is "forward"
	push_direction = -transform.y.normalized()
	linear_velocity = push_direction * push_speed
	angular_velocity = 0.0
	push_time_left = push_duration


func _start_return() -> void:
	return_time_left = push_return_duration


func _end_push() -> void:
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	push_direction = Vector2.ZERO

func _integrate_forces(state):
	var body_transform = state.get_transform()
	
	# Check if we went off the bottom
	if body_transform.origin.y > screen_height:
		body_transform.origin.y = 0
		state.set_transform(body_transform)
		
	# Check if we went off the top
	elif body_transform.origin.y < 0:
		body_transform.origin.y = screen_height
		state.set_transform(body_transform)
