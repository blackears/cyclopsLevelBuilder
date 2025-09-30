# MIT License
#
# Copyright (c) 2023 Mark McKay
# https://github.com/blackears/cyclopsLevelBuilder
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

@tool
extends Container
class_name HSlideTabContainer

@onready var slide_bar:ColorRect = %slide_bar
@onready var tab_bar:TabBar = %TabBar
@onready var tab_rot_bar:RotationContainer = %RotationContainer


var dragging:bool = false
var drag_mouse_pos_start:Vector2
var drag_start_container_width:float
var drag_start_position:Vector2
var drag_start_size:Vector2

@export var bar_width:float = 6: set = set_bar_width
@export var view_width:float = 100: set = set_view_width
@export var active_tab:int = -1: set = set_active_tab

var tab_min_size:Vector2
#var suspend_tabs:bool = false

func set_active_tab(v:float):
	if v == active_tab:
		return
	active_tab = v
	
	update_minimum_size()
	#if !suspend_tabs:
		#update_tab_layout()

func set_view_width(v:float):
	if v == view_width:
		return
	view_width = v
	
	update_minimum_size()

func set_bar_width(v:float):
	if v == bar_width:
		return
	bar_width = v
	
	update_minimum_size()
	pass

func update_tab_layout():
	#suspend_tabs = true
	if !tab_bar:
		return
		
	tab_bar.clear_tabs()
	
	#var child_count:int = 0
	for child in get_children():
		if child == tab_rot_bar || child == slide_bar:
			continue
		
		tab_bar.add_tab(child.name)
		
	tab_bar.current_tab = active_tab
	
	#suspend_tabs = false
	
	update_minimum_size()	

func update_child_visibility():
	if !is_node_ready():
		return
	
	var child_count:int = 0
	for child in get_children():
		if child == tab_rot_bar || child == slide_bar:
			continue
		
		child.visible = child_count == active_tab
		child_count += 1
	
	slide_bar.visible = active_tab != -1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	slide_bar.mouse_default_cursor_shape = Control.CURSOR_HSIZE
	update_tab_layout()
	update_child_visibility()
	

func _on_slide_bar_gui_input(event: InputEvent) -> void:

	if event is InputEventMouseButton:
		var e:InputEventMouseButton = event
		
		if e.button_index == MOUSE_BUTTON_LEFT:
			if e.is_pressed():
				dragging = true
				drag_mouse_pos_start = e.global_position
				drag_start_position = position
				drag_start_size = size
				
			else:
				dragging = false
	
	if event is InputEventMouseMotion:
		var e:InputEventMouseMotion = event
		
		if dragging:
			var min_size:Vector2 = get_minimum_size()
			
			var offset_x:float = e.global_position.x - drag_mouse_pos_start.x
			
			var new_position = drag_start_position + Vector2(offset_x, 0)
			var new_size = drag_start_size - Vector2(offset_x, 0)
			
			view_width = new_size.x
			
			queue_sort()
			
func _get_minimum_size() -> Vector2:
	if active_tab == -1:
		if tab_rot_bar:
			return tab_rot_bar.get_minimum_size()
		else:
			return Vector2.ZERO
		
	else:
		#print("--calc min size")
		var children_size:Vector2 = Vector2(view_width, 0)
		
		for child in get_children():
			if child == slide_bar || child == tab_rot_bar:
				continue
			
			if child.visible:
				var child_min_size:Vector2 = child.get_minimum_size()
				#print("child min size ", child_min_size)
				children_size.x = max(children_size.x, child_min_size.x)
				children_size.y = max(children_size.y, child_min_size.y)
		
		#print("children_size ", children_size)
		
		if tab_rot_bar:
			tab_min_size = tab_rot_bar.get_minimum_size()
		
		var total_size:Vector2 = children_size + Vector2(bar_width + tab_min_size.x, tab_min_size.y)
		#print("total_size ", total_size)
		return total_size

func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		var s:Vector2 = size

		if active_tab == -1:
			tab_rot_bar.position = Vector2(0, 0)
			tab_rot_bar.size = Vector2(tab_min_size.x, s.y)
			
		else:
			tab_min_size = tab_rot_bar.get_minimum_size()
			
			for child in get_children():
				if child is CanvasItem:
					if child == tab_rot_bar:
						tab_rot_bar.position = Vector2(0, 0)
						tab_rot_bar.size = Vector2(tab_min_size.x, s.y)

						#print("placing tab_rot_bar pos ", tab_rot_bar.position)
						#print("placing tab_rot_bar size ", tab_rot_bar.size)

					elif child == slide_bar:
						slide_bar.position = Vector2(tab_min_size.x, 0)
						slide_bar.size = Vector2(bar_width, s.y)

						#print("placing slide bar pos ", slide_bar.position)
						#print("placing slide bar size ", slide_bar.size)

					else:
						var min_size:Vector2 = child.get_minimum_size()
						child.position = Vector2(tab_min_size.x + bar_width, 0)
	#					child.size = Vector2(min(s.x - bar_width - tab_min_size.x, min_size.x), min(s.y, min_size.y))
						child.size = Vector2(s.x - bar_width - tab_min_size.x, s.y)
						
						#print("placing child  pos ", child.position)
						#print("placing child size ", child.size)

	if what == NOTIFICATION_THEME_CHANGED:
		update_minimum_size()



func _on_tab_bar_tab_selected(tab: int) -> void:
	if tab == active_tab:
		active_tab = -1
	else:
		active_tab = tab
	
	update_child_visibility()


func _on_child_entered_tree(node: Node) -> void:
	update_tab_layout()
	update_child_visibility()


func _on_child_exiting_tree(node: Node) -> void:
	update_tab_layout()
	update_child_visibility()
