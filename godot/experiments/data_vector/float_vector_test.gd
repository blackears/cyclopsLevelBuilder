extends Control


func _on_button_pressed() -> void:
	var f:DataVectorFloat = DataVectorFloat.new([1.0, 2.0, 3.0, 4.0])
	
	f.set_value_vec2(Vector2(7.7, 8.8), 0)
	
	print(f)
	
	
	pass # Replace with function body.
