extends Control

func _ready() -> void:
	var g = preload("res://grid_content.tscn").instantiate()
	
	%side_tabs.add_control(g)
	#%side_tabs.active_tab = 0


	var h = preload("res://grid_content.tscn").instantiate()
	%side_tabs.add_control(h)
	
