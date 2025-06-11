@tool
extends EditorInspectorPlugin

var property = preload("res://addons/secondorderdynamicsplugin/editor_property.gd")

func _can_handle(object):
	return object is KinematicStats
#
#func _parse_begin(object: Object) -> void:
	#if (object is KinematicStats):
		#add_custom_control(property.new(object))

func _parse_property(object, type, name, hint_type, hint_string, usage_flags, wide):
	if object is KinematicStats:
		return false
		add_property_editor(name, property.new(object))
		return true
	else:
		return false
