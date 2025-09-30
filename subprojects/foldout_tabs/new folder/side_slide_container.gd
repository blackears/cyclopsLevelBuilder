@tool
extends Container

@export var drag_bar_width:float = 10:
	set(v):
		drag_bar_width = v
#		queue_redraw()
#		queue_sort()
		#minimum_size_changed.emit()
		if is_node_ready():
			update_min_size()
		
@export var content_width:float = 100:
	set(v):
		content_width = v
		print("content_width ", content_width)
#		queue_redraw()
#		minimum_size_changed.emit()
#		queue_sort()
		if is_node_ready():
			update_min_size()

@export var active_tab_index:int = 0:
	set(v):
		active_tab_index = v
		
		if is_node_ready():
			update_active_child()

var h_drag_bar:ColorRect
var vert_tab_bar:VerticalTabBar

var dragging:bool = false
var drag_start:Vector2
#var start_min_size:Vector2
var drag_start_content_width:float

var v_scroll:float = 0
var v_scroll_increment:float = 10

func update_active_child():
	for i in get_child_count():
		var child = get_child(i)
		if "visible" in child:
			child.visible = i == active_tab_index

func _ready() -> void:
	h_drag_bar = ColorRect.new()
	h_drag_bar.color = Color.GREEN
	h_drag_bar.custom_minimum_size = Vector2(drag_bar_width, 0)
	add_child(h_drag_bar)
	h_drag_bar.mouse_default_cursor_shape = Control.CURSOR_HSIZE
	
	h_drag_bar.gui_input.connect(on_h_drag_bar_gui_input)
	
	vert_tab_bar = preload("res://new folder/vertical_tab_bar.tscn").instantiate()
	add_child(vert_tab_bar)

#	vert_tab_bar.add_item("george")
	
	build_tabs()


func on_h_drag_bar_gui_input(event:InputEvent):
	if event is InputEventMouseButton:
		var e:InputEventMouseButton = event
		
		if e.button_index == MOUSE_BUTTON_LEFT:
			if e.is_pressed():
				dragging = true
				drag_start = e.global_position
				#start_min_size = %foldout_base_panel.custom_minimum_size
				drag_start_content_width = content_width
				
			else:
				dragging = false
	
	if event is InputEventMouseMotion:
		var e:InputEventMouseMotion = event
		
		if dragging:
			var offset:Vector2 = e.global_position - drag_start
			print("drag offset ", offset)
			content_width = max(drag_start_content_width - offset.x, 0)
			#%foldout_base_panel.custom_minimum_size.x = start_min_size.x - offset.x

func get_active_child_size()->Vector2:
	if active_tab_index != -1 && active_tab_index < get_child_count():
		var active_child = get_child(active_tab_index)
		if active_child is Control:
			return active_child.get_minimum_size()
	return Vector2.ZERO
	

#func _get_minimum_size() -> Vector2:
	#var min_size = Vector2(drag_bar_width + content_width, 0)
	#print("min_siize ", min_size)
	#return min_size
func update_min_size():
	var middle:float = max(content_width, get_active_child_size().x)
	
	var min_size = Vector2(drag_bar_width + middle + vert_tab_bar.get_button_width(), 0)
	print("min_size ", min_size)
	custom_minimum_size = min_size

func get_min_combined_child_size()->Vector2:
	var children_size:Vector2
	for child in get_children():
		if child == h_drag_bar || child == vert_tab_bar:
			continue
		
		var min_size:Vector2 = child.get_minimum_size()
		
		if child.visible:
			children_size = Vector2(max(children_size.x, min_size.x), max(children_size.y, min_size.y))
	
#	print("child size ", children_size)
	return children_size

func reposition_children():
	var cur_size = size
	print("size ", size)
	
#	var min_child_size:Vector2 = get_min_combined_child_size()
	var min_child_size:Vector2 = get_active_child_size()
	
	var tab_width:float = vert_tab_bar.get_button_width()
	
	h_drag_bar.position = Vector2(0, 0)
	h_drag_bar.size = Vector2(drag_bar_width, min(cur_size.y, min_child_size.y))
	
	vert_tab_bar.position = Vector2(size.x - tab_width, 0)
	vert_tab_bar.size = Vector2(tab_width, cur_size.y)
	
	for child in get_children():
		if child == h_drag_bar || child == vert_tab_bar:
			continue
	
		var rect:Rect2 = Rect2(drag_bar_width, v_scroll, cur_size.x - drag_bar_width - tab_width, cur_size.y)
		fit_child_in_rect(child, rect)
		print("fit rect ", rect)
		#child.clip_contents = true
		#child.size = rect.size
	pass

func _notification(what: int) -> void:
	#if what == NOTIFICATION_ENTER_TREE:
		#reposition_children()
		#return
	#if what == NOTIFICATION_READY:
		#reposition_children()
		#return
	if what == NOTIFICATION_SORT_CHILDREN:
		reposition_children()
		return
		#var s:Vector2 = size


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var e:InputEventMouseButton = event
		
		if e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if e.is_pressed():
				v_scroll = min(0, v_scroll + v_scroll_increment)
				accept_event()
				reposition_children()
				pass
		
		if e.button_index == MOUSE_BUTTON_WHEEL_UP:
			if e.is_pressed():
				var child_size:Vector2 = get_active_child_size()
				var overflow:float = max(child_size.y - size.y, 0)
				
				v_scroll = max(-overflow, v_scroll - v_scroll_increment)
				accept_event()
				reposition_children()
				pass


func _on_resized() -> void:
	if !is_node_ready():
		return
		
	var child_size:Vector2 = get_active_child_size()
	var overflow:float = max(child_size.y - size.y, 0)
	v_scroll = max(-overflow, v_scroll)
	
	reposition_children()
	pass # Replace with function body.

func build_tabs():
	if !vert_tab_bar:
		return
	
	vert_tab_bar.clear()
	
	for child in get_children():
		if child == vert_tab_bar || child == h_drag_bar:
			continue
		vert_tab_bar.add_item(child.name)
	
	pass

func _on_child_entered_tree(node: Node) -> void:
	build_tabs()
	pass # Replace with function body.


func _on_child_exiting_tree(node: Node) -> void:
	build_tabs()
	pass # Replace with function body.


func _on_child_order_changed() -> void:
	build_tabs()
	pass # Replace with function body.
