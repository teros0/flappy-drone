extends Node

static func get_screen_size() -> Vector2:
	return Engine.get_main_loop().root.size
	
static func get_width() -> float:
	return get_screen_size().x

static func get_height() -> float:
	return get_screen_size().y
	
static func is_separate_schene():
	return get_tree().current_scene == self

func get_verbose_tree(node: Node, indent: String = "") -> String:
	var tree_content = _build_tree_string(node, indent)
	
	# Wrap the entire result in XML tags for the LLM
	var wrapped_output = "<scene_tree name=\"" + node.name + "\">\n" + tree_content + "</scene_tree>"
	
	return wrapped_output

# Internal recursive helper to keep the tags from repeating every line
func _build_tree_string(node: Node, indent: String = "") -> String:
	var script_info = ""
	if node.get_script():
		script_info = " -> " + node.get_script().get_path().get_file()
		
	var line = indent + "┖╴" + node.name + " (" + node.get_class() + script_info + ")\n"
	
	for i in range(node.get_child_count()):
		var child = node.get_child(i)
		var is_last = i == node.get_child_count() - 1
		var new_indent = indent + ( "    " if is_last else "┃   ")
		line += _build_tree_string(child, new_indent)
		
	return line
