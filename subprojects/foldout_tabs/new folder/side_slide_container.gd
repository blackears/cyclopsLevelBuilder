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

var h_drag_bar:ColorRect

var dragging:bool = false
var drag_start:Vector2
#var start_min_size:Vector2
var drag_start_content_width:float

var v_scroll:float = 0
var v_scroll_increment:float = 10

func _ready() -> void:
	h_drag_bar = ColorRect.new()
	h_drag_bar.color = Color.GREEN
	h_drag_bar.custom_minimum_size = Vector2(drag_bar_width, 0)
	add_child(h_drag_bar)
	
	h_drag_bar.gui_input.connect(on_h_drag_bar_gui_input)

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

#func _get_minimum_size() -> Vector2:
	#var min_size = Vector2(drag_bar_width + content_width, 0)
	#print("min_siize ", min_size)
	#return min_size
func update_min_size():
	var min_size = Vector2(drag_bar_width + content_width, 0)
	print("min_size ", min_size)
	custom_minimum_size = min_size

func get_min_combined_child_size()->Vector2:
	var children_size:Vector2
	for child in get_children():
		if child == h_drag_bar:
			continue
		
		var min_size:Vector2 = child.get_minimum_size()
		
		if child.visible:
			children_size = Vector2(max(children_size.x, min_size.x), max(children_size.y, min_size.y))
	
#	print("child size ", children_size)
	return children_size

func reposition_children():
	var cur_size = size
	print("size ", size)
	
	var min_child_size:Vector2 = get_min_combined_child_size()
	
	
	h_drag_bar.position = Vector2(0, 0)
	h_drag_bar.size = Vector2(drag_bar_width, min(cur_size.y, min_child_size.y))
	
	for child in get_children():
		if child == h_drag_bar:
			continue
	
		var rect:Rect2 = Rect2(drag_bar_width, 0, cur_size.x - drag_bar_width, cur_size.y)
		fit_child_in_rect(child, rect)
		print("fit rect ", rect)
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
				v_scroll -= v_scroll_increment
				accept_event()
				pass
		
		if e.button_index == MOUSE_BUTTON_WHEEL_UP:
			if e.is_pressed():
				v_scroll += v_scroll_increment
				accept_event()
				pass
