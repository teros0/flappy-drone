extends RigidBody2D

signal thrust_changed(new_value)

@export var player_id: int = 1
@export var thrust_up_action: StringName = &"ui_up"
@export var thrust_down_action: StringName = &"ui_down"
@export var rotate_left_action: StringName = &"ui_left"
@export var rotate_right_action: StringName = &"ui_right"
@export var push_action: StringName = &"push"

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

# World wrapping
func _input(event):
	# Handle Mouse Wheel for Throttle Setting
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			throttle_level = clamp(throttle_level + throttle_step, 0.0, 1.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			throttle_level = clamp(throttle_level - throttle_step, 0.0, 1.0)


func _physics_process(delta: float) -> void:
	_handle_reset()

	# If we're in a push or retract phase, skip normal controls.
	if _handle_push(delta):
		return

	var is_thrusting_up: bool = Input.is_action_pressed(thrust_up_action)
	var is_thrusting_down: bool = Input.is_action_pressed(thrust_down_action)
	
	var direction: int = 1 if is_thrusting_up else -1
	_handle_thrust(delta, is_thrusting_up or is_thrusting_down, direction)
	_handle_rotation()


func _handle_reset() -> void:
	Utils.handle_reset(self)


func _handle_push(delta: float) -> bool:
	if Input.is_action_just_pressed(push_action) and push_time_left <= 0.0 and return_time_left <= 0.0:
		_start_push()

	# Forward jab
	if push_time_left > 0.0:
		push_time_left -= delta
		linear_velocity = push_direction * push_speed
		angular_velocity = 0.0
		if push_time_left <= 0.0:
			_start_return()
		return true

	# Retract
	if return_time_left > 0.0:
		return_time_left -= delta
		linear_velocity = -push_direction * push_return_speed
		angular_velocity = 0.0
		if return_time_left <= 0.0:
			_end_push()
		return true

	return false


func _handle_thrust(delta: float, is_thrusting: bool, direction: int) -> void:
	# Always update hold_time regardless of key state
	if is_thrusting:
		hold_time = min(hold_time + delta, max_ramp_time)
	else:
		# Spool down twice as fast as it spools up
		hold_time = max(hold_time - (delta * 2.0), 0.0)

	# ALWAYS calculate effective_thrust so it can "die down"
	var t: float = hold_time / max_ramp_time
	var curve_multiplier: float = 0.8 + (0.6 * sqrt(t))

	# If the engine isn't engaged, the thrust applied to physics is 0,
	# but the visual throttle can still show the engine ramping up/down.
	effective_thrust = throttle_level * curve_multiplier

	# Keep HUD in sync.
	thrust_changed.emit(effective_thrust if is_thrusting else 0.0)

	if is_thrusting:
		var total_thrust: Vector2 = transform.y * -effective_thrust * direction * engine_power * weight_compensation
		apply_central_force(total_thrust)


func _handle_rotation() -> void:
	var rotation_input: float = Input.get_axis(rotate_left_action, rotate_right_action)
	if rotation_input != 0.0:
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
