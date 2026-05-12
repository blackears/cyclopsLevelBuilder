@tool
extends PanelContainer
class_name UvTriplanarLayoutPanel

signal canceled
signal finished

var plugin:CyclopsLevelBuilder

func _on_bn_okay_pressed() -> void:
	
	finished.emit()


func _on_bn_cancel_pressed() -> void:
	canceled.emit()

func get_uv_transform()->Transform3D:
	var offset:Vector3 = %vector3_offset.value
	var s:Vector3 = %vector3_scale.value
	var xform:Transform3D = Transform3D(Vector3(s.x, 0, 0), Vector3(0, s.y, 0), Vector3(0, 0, s.z), offset)
	return xform

func is_selected_faces_only():
	return %CheckBox_selected_faces.button_pressed
