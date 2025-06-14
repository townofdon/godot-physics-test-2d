@tool
extends EditorInspectorPlugin

var Editor = preload("res://addons/kinematics_viz/editor_property.gd")

func _can_handle(object):
	return object is KinematicStats

func _parse_property(object, type, name, hint_type, hint_string, usage_flags, wide):
	if !object is KinematicStats: return false
	if hint_type != PROPERTY_HINT_ENUM: return false
	# kinda hacky, but it works.
	if hint_string != "Vizualizer:0": return false
	add_property_editor(name, Editor.new())
	return true
