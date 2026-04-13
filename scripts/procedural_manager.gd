extends Node2D

@export var obstacle_scene: PackedScene
@export var carousel_scene: PackedScene
@export var lift_scene: PackedScene
@export var soldier_scene: PackedScene
@export var walls_scene: PackedScene
@export var spawn_distance: float = 1600.0 # How far ahead of camera to spawn
@export var gap_width: float = 800.0      # Horizontal distance between gates
@export var vertical_variance: float = 300


var next_spawn_obstacle: float = 1000.0
var next_spawn_walls: float = get_viewport_rect().size.x / 2
@onready var camera = get_viewport().get_camera_2d()

func _process(_delta):
	# 1. Check if we need to spawn
	# If next_spawn_x is within view range of the camera
	if next_spawn_obstacle < camera.global_position.x + spawn_distance:
		spawn_obstacle()
		
	#if next_spawn_walls < camera.global_position.x + get_viewport_rect().size.x:
		#spawn_walls()	
	
#func spawn_walls():
	#var bottom := walls_scene.instantiate()
	#var top := walls_scene.instantiate()
	#
	#top.position.x += get_viewport_rect().size.x/2 + camera.global_position.x
	#bottom.position.x += get_viewport_rect().size.x/2  + camera.global_position.x
	#bottom.position.y += get_viewport_rect().size.y
	#
	#add_child(top)
	#add_child(bottom)
	#
	#next_spawn_walls += get_viewport_rect().size.x/2
	

func spawn_obstacle():
	var obstacles = [obstacle_scene, carousel_scene, lift_scene, soldier_scene]
	var obstacle = obstacles.pick_random()
	var obs = obstacle.instantiate()
	# Randomize height
	var random_y = randf_range(-vertical_variance, vertical_variance)
	obs.position = Vector2(next_spawn_obstacle, get_viewport_rect().size.y / 2 + random_y)
	
	add_child(obs)
	
	# Advance the spawn pointer
	next_spawn_obstacle += gap_width
