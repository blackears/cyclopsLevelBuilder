@tool
extends PanelContainer
class_name UvTriplanarLayoutPanel

signal canceled
signal finished

@onready var vector3_scale:Vector3Edit = %vector3_scale
@onready var vector3_offset:Vector3Edit = %vector3_offset

var plugin:CyclopsLevelBuilder

func _on_bn_okay_pressed() -> void:
	
	finished.emit()


func _on_bn_cancel_pressed() -> void:
	canceled.emit()

func get_uv_transform(axis:MathUtil.Axis)->Transform3D:
	var offset:Vector3 = vector3_offset.value
	var s:Vector3 = vector3_scale.value
	
	#print("offset ", offset)
	match axis:
		MathUtil.Axis.X:
			return Transform3D(Vector3(0, 0, 1) * s.z, 
				Vector3(0, 1, 0) * -s.y,
				Vector3(1, 0, 0) * s.x, 
				Vector3(offset.z, offset.y, offset.x))
		MathUtil.Axis.Y:
			return Transform3D(Vector3(1, 0, 0) * s.x, 
				Vector3(0, 0, 1) * s.z,
				Vector3(0, 1, 0) * s.y, 
				Vector3(offset.x, offset.z, offset.y))
		MathUtil.Axis.Z:
			return Transform3D(Vector3(1, 0, 0) * s.x, 
				Vector3(0, 1, 0) * -s.y,
				Vector3(0, 0, 1) * s.z, 
				Vector3(offset.x, offset.y, offset.z))
			
	return Transform3D()

func is_selected_faces_only():
	return %CheckBox_selected_faces.button_pressed
