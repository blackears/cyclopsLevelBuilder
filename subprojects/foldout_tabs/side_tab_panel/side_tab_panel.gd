extends HBoxContainer

@export var active_tab:int = -1:
	set(v):
		active_tab = v
		
		if is_node_ready():
			update_visibility()

#var 

func add_control(control:Control):
	control.visible = false
	%ScrollContainer.add_child(control)
	
	update_tabs()
	update_visibility()

func update_tabs():
	%TabBar.clear_tabs()
	
	for i in %ScrollContainer.get_child_count():
		var child = %ScrollContainer.get_child(i)
		
		%TabBar.add_tab(child.name)

func update_visibility():
	for i in %ScrollContainer.get_child_count():
		var child = %ScrollContainer.get_child(i)
		
		if "visible" in child:
			child.visible = i == active_tab

func _on_tab_bar_tab_selected(tab: int) -> void:
	if tab == active_tab:
		active_tab = -1
	else:
		active_tab = tab
