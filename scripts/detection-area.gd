@tool
extends Area2D

signal touched

@export var target_size: Vector2 = Vector2(100, 20):
	set(value):
		target_size = value
		# Only run this if the node is actually ready and in the scene
		if is_node_ready():
			update_sizes()
			#notify_property_list_changed()

func _ready():
	update_sizes()

func update_sizes():
	# Use get_node_or_null to prevent the red error spam
	var sprite = get_node_or_null("Sprite2D")
	var collider = get_node_or_null("CollisionShape2D")
	print(sprite)
	if sprite and sprite.texture is GradientTexture2D:
		# Update the actual generation resolution
		sprite.texture.width = int(target_size.x)
		sprite.texture.height = int(target_size.y)
		
		# If you are using Region, we must update the rect to match the new size
		if sprite.region_enabled:
			sprite.region_rect = Rect2(Vector2.ZERO, target_size)
	
	if collider and collider.shape is RectangleShape2D:
		collider.shape.size = target_size
		print(collider.shape.size)


func _on_body_entered(body: Node2D) -> void:
	touched.emit()
