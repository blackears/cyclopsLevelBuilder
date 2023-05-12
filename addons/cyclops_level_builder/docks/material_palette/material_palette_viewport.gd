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
extends Control
class_name MaterialPaletteViewport

@export var material_list:Array[String] = []

@export var thumbnail_group:ThumbnailGroup

var builder:CyclopsLevelBuilder
#var undo_manager:UndoRedo

var has_mouse_focus:bool = false

var drag_pressed:bool = false
var drag_start_pos:Vector2
var drag_start_scroll_value_y:float


# Called when the node enters the scene tree for the first time.
func _ready():
#	print("MaterialPaletteViewport")
	#undo_manager = UndoRedo.new()
	
	update_thumbnails()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _can_drop_data(at_position:Vector2, data:Variant):
#	print("_can_drop_data %s" % data)
	return typeof(data) == TYPE_DICTIONARY and data.has("type") and data["type"] == "files"

func _gui_input(event):
	if event is InputEventMouseButton:
		var e:InputEventMouseButton = event
		
		if e.button_index == MOUSE_BUTTON_MIDDLE:
			var v_scroll:VScrollBar = $VBoxContainer/ScrollContainer.get_v_scroll_bar()
			
			drag_pressed = e.pressed
			drag_start_pos = e.position
			drag_start_scroll_value_y = v_scroll.value

	elif event is InputEventMouseMotion:
		if drag_pressed:
			var e:InputEventMouseMotion = event
			var offset:Vector2 = e.position - drag_start_pos
			
			var win_size:Vector2 = $VBoxContainer/ScrollContainer.size
			
			var v_scroll:VScrollBar = $VBoxContainer/ScrollContainer.get_v_scroll_bar()
			v_scroll.value = clamp(drag_start_scroll_value_y - (offset.y / win_size.y) * v_scroll.max_value, v_scroll.min_value, v_scroll.max_value)
#			print("v min max %s %s" % [v_scroll.min_value, v_scroll.max_value])
		
		

func _unhandled_input(event):
	if !has_mouse_focus:
		return
	
	if event is InputEventKey:
		#print("key event %s" % str(event))
		var e:InputEventKey = event
#			if e.keycode == KEY_DELETE:
		if e.keycode == KEY_X:
			if e.pressed:
#				print("mat pal X")
				remove_selected_material()

			accept_event()

func remove_selected_material():
	var cmd:CommandMaterialDockRemoveMaterials = CommandMaterialDockRemoveMaterials.new()
	cmd.builder = builder
	
	for child in $VBoxContainer/ScrollContainer/HFlowContainer.get_children():
		if child.selected:
			cmd.res_path_list.append(child.material_path)

	var undo_manager:EditorUndoRedoManager = builder.get_undo_redo()
	cmd.add_to_undo_manager(undo_manager)

func set_materials(res_path_list:Array[String]):
	material_list = res_path_list
#	print("set mat list %s" % str(material_list))
	update_thumbnails()
	

func save_state(state:Dictionary):
	var substate:Dictionary = {}
	state["material_palette"] = substate
	
	substate["materials"] = material_list.duplicate()

func load_state(state:Dictionary):
	if state == null || !state.has("material_palette"):
		return
	
	var substate:Dictionary = state["material_palette"]

#	print("load_state()")
	material_list = []
	if substate.has("materials"):
		for mat_path in substate["materials"]:
			if ResourceLoader.exists(mat_path):
				material_list.append(mat_path)
	
	update_thumbnails()

func _drop_data(at_position, data):
	var files = data["files"]
	#print("--drop")
	var add_list:Array[String]
	for f in files:
#		print("Dropping %s" % f)
		var res:Resource = load(f)
		if res is Material:
			if !material_list.has(f):
				add_list.append(f)
	
	
	var cmd:CommandMaterialDockAddMaterials = CommandMaterialDockAddMaterials.new()
	cmd.builder = builder
	
	cmd.res_path_list = add_list

	var undo_manager:EditorUndoRedoManager = builder.get_undo_redo()
	cmd.add_to_undo_manager(undo_manager)
	
	#print("drop data clear")
	#material_list.clear()
		
func update_thumbnails():
#	print("update_thumbnails()")
	var cur_sel:String
	
	for child in $VBoxContainer/ScrollContainer/HFlowContainer.get_children():
		if child.selected:
			cur_sel = child.material_path
			break

	for child in $VBoxContainer/ScrollContainer/HFlowContainer.get_children():
		#print("removing %s" % child.get_class())
		child.group = null
		$VBoxContainer/ScrollContainer/HFlowContainer.remove_child(child)
		child.queue_free()

	for path in material_list:
		var res:Resource = preload("res://addons/cyclops_level_builder/docks/material_palette/material_thumbnail.tscn")
		var thumbnail:MaterialThumbnail = res.instantiate()
		thumbnail.builder = builder
		thumbnail.material_path = path
		thumbnail.group = thumbnail_group
#		print("adding mat %s" % path)
		
		
		$VBoxContainer/ScrollContainer/HFlowContainer.add_child(thumbnail)
		thumbnail.owner = self
	
	if cur_sel:
		for child in $VBoxContainer/ScrollContainer/HFlowContainer.get_children():
			if child.material_path == cur_sel:
				child.selected = true
				break


func _on_visibility_changed():
	#Control freezes for some reason when hidden and then shown, so just regenereate it
	if visible:
		update_thumbnails()



func _on_remove_all_materials_pressed():
	var cmd:CommandMaterialDockRemoveMaterials = CommandMaterialDockRemoveMaterials.new()
	cmd.builder = builder
	
	cmd.res_path_list = material_list.duplicate()

	var undo_manager:EditorUndoRedoManager = builder.get_undo_redo()
	cmd.add_to_undo_manager(undo_manager)
	


func _on_remove_sel_pressed():
	remove_selected_material()


func _on_h_flow_container_mouse_entered():
	has_mouse_focus = true
#	print("_on_h_flow_container_mouse_entered()")


func _on_h_flow_container_mouse_exited():
	has_mouse_focus = false
#	print("_on_h_flow_container_mouse_exited()")
