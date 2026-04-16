extends Resource
class_name PlayerConfig

@export var player_id: int = 1
@export var node_name: StringName = &"Copter"
@export var spawn_offset: Vector2 = Vector2.ZERO

@export var thrust_up_action: StringName = &"ui_up"
@export var thrust_down_action: StringName = &"ui_down"
@export var rotate_left_action: StringName = &"ui_left"
@export var rotate_right_action: StringName = &"ui_right"
@export var push_action: StringName = &"push"
