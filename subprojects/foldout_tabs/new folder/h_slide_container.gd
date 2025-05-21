@tool
extends Container
class_name HSlideContainer

@onready var slide_bar:ColorRect = %slide_bar

var dragging:bool = false
var drag_mouse_pos_start:Vector2
#var drag_start_size:Vector2
var drag_start_container_width:float
var drag_start_position:Vector2
var drag_start_size:Vector2

@export var bar_width:float = 6: set = set_bar_width
#@export var container_width:float = 100:set = set_container_width
#@export var container_width:float = 100: set = set_container_width

#func set_container_width(v:float):
	#if v == container_width:
		#return
	#container_width = v
	#
	#queue_sort()
	#
	##update_minimum_size()

func set_bar_width(v:float):
	if v == bar_width:
		return
	bar_width = v
	
	update_minimum_size()
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	slide_bar.mouse_default_cursor_shape = Control.CURSOR_HSIZE
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_slide_bar_gui_input(event: InputEvent) -> void:

	if event is InputEventMouseButton:
		var e:InputEventMouseButton = event
		
		if e.button_index == MOUSE_BUTTON_LEFT:
			if e.is_pressed():
				dragging = true
				drag_mouse_pos_start = e.global_position
				#drag_start_container_width = container_width
				drag_start_position = position
				drag_start_size = size
				#start_min_size = %foldout_base_panel.custom_minimum_size
				
			else:
				dragging = false
	
	if event is InputEventMouseMotion:
		var e:InputEventMouseMotion = event
		
		if dragging:
			var min_size:Vector2 = get_minimum_size()
			
			var offset_x:float = e.global_position.x - drag_mouse_pos_start.x
			#size = drag_start_size + Vector2(offset.x, 0)
			#container_width = drag_start_container_width + offset.x
			offset_x
			
			var new_position = drag_start_position + Vector2(offset_x, 0)
			var new_size = drag_start_size - Vector2(offset_x, 0)
			
			if new_size.x < min_size.x:
				
			#max(new_size.x, min_size.x)
				new_position = Vector2(drag_start_position.x + drag_start_size.x - min_size.x, drag_start_position.y)
				new_size.x = min_size.x
			
			position = new_position
			size = new_size
			queue_sort()
			#%foldout_base_panel.custom_minimum_size.x = start_min_size.x - offset.x
			
func _get_minimum_size() -> Vector2:
#	var children_size:Vector2 = Vector2(container_width, 0)
	var children_size:Vector2 = Vector2(0, 0)
	
	for child in get_children():
		if child == slide_bar:
			continue
			
		var min_size:Vector2 = child.get_minimum_size()
		
		if child.visible:
			children_size.x = max(children_size.x, min_size.x)
			children_size.y = max(children_size.y, min_size.y)
	
#	print("child size ", children_size)
	return children_size + Vector2(bar_width, 0)

func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		var s:Vector2 = size
#		print("s ", s)
		
		for child in get_children():
			if child == slide_bar:
				slide_bar.position = Vector2(0, 0)
				slide_bar.size = Vector2(bar_width, s.y)
				#fit_child_in_rect(slide_bar, Rect2(Vector2.ZERO, Vector2(bar_width, s.y)))
				pass
			else:
				child.position = Vector2(bar_width, 0)
				child.size = Vector2(s.x - bar_width, s.y)
				#fit_child_in_rect(slide_bar, Rect2(Vector2(bar_width, 0), Vector2(s.x - bar_width, s.y)))
			
			#print("set rot ", child.name)
			#print("rot ", child.rotation)

	if what == NOTIFICATION_THEME_CHANGED:
		update_minimum_size()

		
