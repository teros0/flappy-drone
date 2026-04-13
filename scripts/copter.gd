extends RigidBody2D

signal left_edge_exited

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

func _ready():
	print("DisplayServer.screen_get_size ", get_viewport_rect().end.y)

func _input(event):
	# Handle Mouse Wheel for Throttle Setting
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			throttle_level = clamp(throttle_level + throttle_step, 0.0, 1.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			throttle_level = clamp(throttle_level - throttle_step, 0.0, 1.0)
			

func _physics_process(_delta):
	var is_thrusting = false
	var rotation_input = 0.0

	if Input.is_action_pressed("ui_up"):
		is_thrusting = true
		# Increase hold_time but cap it at the max_ramp_time
		hold_time = min(hold_time + _delta, max_ramp_time)
	else:
		# Reset hold_time when key is released (or use a decay for "smooth" drop)
		hold_time = 0.0
	
	if Input.is_action_pressed("ui_left"):
		rotation_input -= 1.0
	if Input.is_action_pressed("ui_right"):
		rotation_input += 1.0
	
	# Apply Thust based on persistent throttle level
	if is_thrusting:
		# 1. Normalize hold_time to a 0.0 - 1.0 range
		var t = hold_time / max_ramp_time
		
		# 2. Apply the "Fast then Slow" curve (Square Root)
		# Starts at 0.1, ends at 0.4
		var curve_multiplier = 0.8 + (0.6 * sqrt(t))
		
		# 3. Combine with your persistent throttle_level
		# (Multiply by curve_multiplier to make the throttle feel 'damped')
		effective_thrust = throttle_level * curve_multiplier
		
		var total_thrust = transform.y * -effective_thrust * engine_power * weight_compensation
		apply_central_force(total_thrust)
		
		#print("Current Curve Factor: ", 0.5 + (0.8 * sqrt(hold_time / max_ramp_time)))
		#print("Effective Thrust: ", effective_thrust)
	
	if rotation_input != 0:
		apply_torque(rotation_input * torque_power)

func _integrate_forces(state):
	var transform = state.get_transform()
	
	# Check if we went off the bottom
	if transform.origin.y > screen_height:
		transform.origin.y = 0
		state.set_transform(transform)
		
	# Check if we went off the top
	elif transform.origin.y < 0:
		transform.origin.y = screen_height
		state.set_transform(transform)
