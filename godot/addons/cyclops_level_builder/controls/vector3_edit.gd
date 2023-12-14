@tool
extends HBoxContainer
class_name Vector3Edit

signal value_changed(value:Vector3)

@export var value:Vector3:
	get:
		return value
	set(v):
		if value == v:
			return
			
		value = v
		value_changed.emit(v)
		dirty = true
		
var dirty:bool = true

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if dirty:
		%edit_x.value = value.x
		%edit_y.value = value.y
		%edit_z.value = value.z
		dirty = false
	


func _on_edit_x_value_changed(v:float):
	value = Vector3(v, value.y, value.z)


func _on_edit_y_value_changed(v:float):
	value = Vector3(value.x, v, value.z)


func _on_edit_z_value_changed(v:float):
	value = Vector3(value.x, value.y, v)
