extends Node2D

@export var scroll_speed: float = 150.0
@onready var camera = $Camera2D
@onready var edge_detector = $LeftEdgeDetector

signal player_fell_behind

func _ready():
	# Connect the signal to detect the player
	edge_detector.body_entered.connect(_on_body_entered)
	
	# Position the edge detector at the left edge of the camera view
	# For a standard 1152x648 window, this would be -576 on X
	var viewport_width = get_viewport_rect().size.x
	edge_detector.position.x = -(viewport_width / 2)

func _physics_process(delta):
	# Move the whole system right
	position.x += scroll_speed * delta

func _on_body_entered(body):
	# Check if the thing hitting the edge is your copter/player
	if body.name == "Copter": # Or use a class_name/group
		player_fell_behind.emit()
		print("Player touched the left edge!")
