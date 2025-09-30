extends Control

var dragging:bool = false
var drag_start:Vector2
var start_min_size:Vector2

func _on_drag_bar_h_gui_input(event: InputEvent) -> void:
	
	if event is InputEventMouseButton:
		var e:InputEventMouseButton = event
		
		if e.button_index == MOUSE_BUTTON_LEFT:
			if e.is_pressed():
				dragging = true
				drag_start = e.position
				start_min_size = %foldout_base_panel.custom_minimum_size
				
			else:
				dragging = false
	
	if event is InputEventMouseMotion:
		var e:InputEventMouseMotion = event
		
		if dragging:
			var offset:Vector2 = e.position - drag_start
			%foldout_base_panel.custom_minimum_size.x = start_min_size.x - offset.x
		
		
