extends Node
class_name utils

static func full_name(node: Node) -> String:
	var out := ""
	var current := node
	while current:
		out = current.name + "." + out
		current = current.get_parent()
	return out
