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
extends EditorPlugin
class_name CyclopsLevelBuilder

signal active_node_changed

const AUTOLOAD_NAME = "CyclopsAutoload"

#var dock:Control
var top_toolbar:TopToolbar
var toolbar:EditorToolbar
var activated:bool = false


var block_create_distance:float = 20
var tool:CyclopsTool = null
var lock_uvs:bool = false

var tool_uv_transform:Transform2D
var tool_material_id:int

var handle_point_radius:float = .05

#var _active_node:GeometryBrush
var active_node:CyclopsBlocks:
	get:
		return active_node
	set(value):
		if active_node != value:
			active_node = value
			active_node_changed.emit()

func _enter_tree():
	add_custom_type("CyclopsBlocks", "Node3D", preload("controls/cyclops_blocks.gd"), preload("controls/cyclops_blocks_icon.png"))
	add_custom_type("CyclopsBlock", "Node", preload("controls/cyclops_block.gd"), preload("controls/cyclops_blocks_icon.png"))
	#add_custom_type("GeometryBrush", "Node3D", preload("controls/geometry_brush.tscn"), preload("controls/geometryBrushIcon.png"))

	add_autoload_singleton(AUTOLOAD_NAME, "res://addons/cyclops_level_builder/cyclops_global_scene.tscn")
	
#	dock = preload("menu/cyclops_control_panel.tscn").instantiate()
	
	toolbar = preload("menu/editor_toolbar.tscn").instantiate()
	toolbar.editor_plugin = self

#	top_toolbar = preload("menu/top_toolbar.tscn").instantiate()
#	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, top_toolbar)
	
	var editor:EditorInterface = get_editor_interface()
	var selection:EditorSelection = editor.get_selection()
	selection.selection_changed.connect(on_selection_changed)
	
	var undo:EditorUndoRedoManager = get_undo_redo()
	
	update_activation()

	#Wait until everything is loaded	
	await get_tree().process_frame
	var global_scene:CyclopsGlobalScene = get_node("/root/CyclopsAutoload")
	global_scene.builder = self
	
	switch_to_tool(ToolBlock.new())

func find_blocks_root(node:Node)->CyclopsBlocks:
	if node is CyclopsBlocks:
		return node
	if node is CyclopsBlock:
		return find_blocks_root(node.get_parent())
	return null

func update_activation():
	var editor:EditorInterface = get_editor_interface()
	var selection:EditorSelection = editor.get_selection()
	var nodes:Array[Node] = selection.get_selected_nodes()
	if !nodes.is_empty():
		var node:Node = nodes[0]
		
		var blocks_root:CyclopsBlocks = find_blocks_root(node)
		
		if blocks_root:
			active_node = blocks_root
			if !activated:
				add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, toolbar)
				activated = true
		else:
			if activated:
				remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, toolbar)
				activated = false
	else:
		active_node = null

func on_selection_changed():
	update_activation()

func _exit_tree():
	# Clean-up of the plugin goes here.
	remove_autoload_singleton(AUTOLOAD_NAME)
	
	remove_custom_type("CyclopsBlocks")
	remove_custom_type("CyclopsBlock")
	
	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, top_toolbar)
	
	if activated:
#		remove_control_from_docks(dock)
		remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, toolbar)

#	dock.queue_free()
	toolbar.queue_free()

func _handles(object:Object):
	return object is CyclopsBlocks or object is CyclopsBlock

func _forward_3d_draw_over_viewport(viewport_control:Control):
	#Draw on top of viweport here
	pass

func _forward_3d_gui_input(viewport_camera:Camera3D, event:InputEvent):
	#print("plugin: " + event.as_text())
	
	if tool:
		var result:bool = tool._gui_input(viewport_camera, event)
		return EditorPlugin.AFTER_GUI_INPUT_STOP if result else EditorPlugin.AFTER_GUI_INPUT_PASS
	
	return EditorPlugin.AFTER_GUI_INPUT_PASS

func switch_to_tool(_tool:CyclopsTool):
	if tool:
		tool._deactivate()
	
	tool = _tool

	if tool:
		tool._activate(self)
	
