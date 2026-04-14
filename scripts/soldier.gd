extends Node2D

@export var bullet_scene: PackedScene
@export var burst_count: int = 3
@export var burst_delay: float = 0.2
@export var cooldown_time: float = 2.0
@export var detection_radius: float = 500

@onready var muzzle = $Muzzle
@onready var detection_range = $DetectionRange
@onready var burst_timer = $BurstTimer
@onready var cooldown_timer = $CooldownTimer

var target: Node2D = null
var shots_fired: int = 0
var is_firing_burst: bool = false # New state flag
var can_fire: bool = true

func _ready():
	detection_range.body_entered.connect(_on_target_entered)
	detection_range.body_exited.connect(_on_target_exited)
	
	burst_timer.one_shot = true
	burst_timer.timeout.connect(_fire_next_shot)
	
	cooldown_timer.one_shot = true
	cooldown_timer.timeout.connect(_on_cooldown_finished)
	
	if $DetectionRange/CollisionShape2D.shape is CircleShape2D:
		$DetectionRange/CollisionShape2D.shape.radius = detection_radius

func _on_target_entered(body):
	if body.name == "Copter":
		target = body
		# FIX: Use call_deferred to avoid the "Flushing Queries" error
		call_deferred("start_shooting_cycle")

func _on_target_exited(body):
	if body == target:
		target = null

func _on_cooldown_finished():
	can_fire = true
	if target:
		start_shooting_cycle()

func start_shooting_cycle():
	# Guard clause: Don't start if already firing, on cooldown, or no target
	if not can_fire or is_firing_burst or not target:
		return
		
	can_fire = false
	is_firing_burst = true
	shots_fired = 0
	_fire_next_shot()

func _fire_next_shot():
	# If target left mid-burst, stop and enter cooldown
	if not target or shots_fired >= burst_count:
		is_firing_burst = false
		cooldown_timer.start(cooldown_time)
		return

	# Spawn the bullet
	var b = bullet_scene.instantiate()
	get_tree().current_scene.add_child(b)
	
	b.global_position = muzzle.global_position
	b.direction = (target.global_position - muzzle.global_position).normalized()
	b.rotation = b.direction.angle()
	
	shots_fired += 1
	burst_timer.start(burst_delay)
