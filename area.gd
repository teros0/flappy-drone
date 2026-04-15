extends Node2D

signal capture_completed
signal capture_progress_updated(current_time: float, max_time: float)

@export var required_time: float = 5.0
var time_spent: float = 0.0
var is_player_inside: bool = false
var direction: int = 1
@export var movement_speed: float = 500.0

@onready var area_2d = $Area2D
@onready var color_rect = $Area2D/ColorRect

func _ready():
	area_2d.body_entered.connect(_on_body_entered)
	area_2d.body_exited.connect(_on_body_exited)
	
	color_rect.color = Color.RED


func _process(delta: float) -> void:
	area_2d.position.x += direction * movement_speed * delta

	var rect_width = color_rect.size.x 
	var viewport_width = get_viewport_rect().size.x

	if area_2d.global_position.x + rect_width/2 > viewport_width:
		direction = -1
	elif area_2d.global_position.x - rect_width/2 < 0:
		direction = 1

func _physics_process(delta):
	if is_player_inside:
		time_spent = min(time_spent + delta, required_time)
		
		# Calculate 0.0 to 1.0 progress
		var progress = time_spent / required_time
		
		# Shift color: lerp from Red to Green based on progress
		color_rect.color = Color.RED.lerp(Color.GREEN, progress)
		
		# Tell the HUD to update
		capture_progress_updated.emit(time_spent, required_time)
		
		if time_spent >= required_time:
			_on_capture_complete()
	else:
		# Optional: Decay progress if the player leaves
		time_spent = max(time_spent - (delta * 0.8), 0.0)
		var progress = time_spent / required_time
		color_rect.color = Color.RED.lerp(Color.GREEN, progress)
		capture_progress_updated.emit(time_spent, required_time)

func _on_body_entered(body):
	if body.name == "Copter" or body is RigidBody2D:
		is_player_inside = true

func _on_body_exited(body):
	if body.name == "Copter" or body is RigidBody2D:
		is_player_inside = false

func _on_capture_complete():
	print("Area Captured!")
	capture_completed.emit()
	set_physics_process(false)
