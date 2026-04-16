extends StaticBody2D

@export var dimensions:Vector2 = Vector2(50, 1000):
	set(value):
		dimensions = value
		if is_inside_tree():
			_update_dimensions()

@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_update_dimensions()
	
func _update_dimensions():
	if sprite and sprite.texture:
		sprite.texture.size = dimensions
		
	if collision and collision.shape is RectangleShape2D:
		collision.shape.size = dimensions


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
