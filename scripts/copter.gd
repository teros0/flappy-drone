extends RigidBody2D

signal left_edge_exited

@export var screen_height: float = 1500
@export var margin: float = 0.0 # Small buffer so the sprite fully disappears before teleporting

@export var engine_power: float = 7000.0
@export var torque_power: float = 150000.0
@export var weight_compensation: float = 1.2

# New Throttle Logic
@export var throttle_level: float = 0.3
@export var throttle_step: float = 0.1

func _input(event):
	# Handle Mouse Wheel for Throttle Setting
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			throttle_level = clamp(throttle_level + throttle_step, 0.0, 1.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			throttle_level = clamp(throttle_level - throttle_step, 0.0, 1.0)
			
	print(throttle_level)

func _physics_process(_delta):
	var is_thrusting = false
	var rotation_input = 0.0

	# Keyboard now acts as the "Engine Engagement" switch
	if Input.is_action_pressed("ui_up"):
		is_thrusting = true
	
	if Input.is_action_pressed("ui_left"):
		rotation_input -= 1.0
	if Input.is_action_pressed("ui_right"):
		rotation_input += 1.0
	
	# Apply Thust based on persistent throttle level
	if is_thrusting:
		# Use the throttle_level we set with the mouse wheel
		var total_thrust = transform.y * -throttle_level * engine_power * weight_compensation
		apply_central_force(total_thrust)
	
	if rotation_input != 0:
		apply_torque(rotation_input * torque_power)

func _integrate_forces(state):
	var transform = state.get_transform()
	
	# Check if we went off the bottom
	if transform.origin.y > screen_height + margin:
		transform.origin.y = -margin
		state.set_transform(transform)
		
	# Check if we went off the top
	elif transform.origin.y < -margin:
		transform.origin.y = screen_height + margin
		state.set_transform(transform)
