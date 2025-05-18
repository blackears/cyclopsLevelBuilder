@tool
extends HBoxContainer
class_name Vector2iEdit

signal value_changed(value:Vector2i)

@export var value:Vector2i: set = set_value
	
func set_value(v:Vector2i):
		if v == value:
			return
		
		value = v
		
		%spin_x.set_value_no_signal(value.x)
		%spin_y.set_value_no_signal(value.y)
		
		value_changed.emit(value)

func set_value_no_signal(v:Vector2i):
		if v == value:
			return
		
		value = v
		
		%spin_x.set_value_no_signal(value.x)
		%spin_y.set_value_no_signal(value.y)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%spin_x.set_value_no_signal(value.x)
	%spin_y.set_value_no_signal(value.y)
	pass # Replace with function body.


func _on_spin_x_value_changed(v: float) -> void:
	set_value(Vector2i(v, value.y))


func _on_spin_y_value_changed(v: float) -> void:
	set_value(Vector2i(value.x, v))
	pass # Replace with function body.
