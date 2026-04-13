extends Node

func _ready() -> void:
	var my_bike:Bike = Bike.new();
	my_bike.display_color()
	my_bike.display_name()
	my_bike.accelerate()
