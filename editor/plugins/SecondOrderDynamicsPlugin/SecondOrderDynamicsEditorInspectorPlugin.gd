extends EditorInspectorPlugin

var property = preload("res://editor/plugins/SecondOrderDynamicsPlugin/SecondOrderDynamicsEditorProperty.gd")

func _can_handle(object):
	return object is SecondOrderDynamics

func _parse_property(object, type, name, hint_type, hint_string, usage_flags, wide):
	if object is SecondOrderDynamics:
		add_property_editor(name, property.new(object))
		return true
	else:
		return false
