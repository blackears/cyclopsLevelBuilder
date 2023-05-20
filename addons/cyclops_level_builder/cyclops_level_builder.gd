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
signal selection_changed

const AUTOLOAD_NAME = "CyclopsAutoload"

var config:CyclopsConfig = preload("res://addons/cyclops_level_builder/data/configuration.tres")

var material_dock:Control
var uv_editor_dock:Control
var tool_properties_dock:Control
#var sticky_toolbar:StickyToolbar
var editor_toolbar:EditorToolbar
var activated:bool = false


var block_create_distance:float = 10
var tool:CyclopsTool = null
var lock_uvs:bool = false
var tool_overlay_extrude:float = .01

var tool_uv_transform:Transform2D
var tool_material_path:String

var handle_point_radius:float = .05
var handle_screen_radius:float = 6

var drag_start_radius:float = 6

enum Mode { OBJECT, EDIT }
var mode:Mode = Mode.OBJECT
enum EditMode { VERTEX, EDGE, FACE }
var edit_mode:EditMode = EditMode.VERTEX

var display_mode:DisplayMode.Type = DisplayMode.Type.TEXTURED

#var _active_node:GeometryBrush
#var active_node:CyclopsBlocks:
#	get:
#		return active_node
#	set(value):
#		if active_node != value:
#			active_node = value
#			active_node_changed.emit()
#
#func get_selected_blocks()->Array[CyclopsConvexBlock]:
#	var result:Array[CyclopsConvexBlock]
#
#	if active_node:
#		for child in active_node.get_children():
#			if child is CyclopsConvexBlock:
#				var block:CyclopsConvexBlock = child
#				if child.selected:
#					result.append(child)
#
#	return result

func _get_plugin_name()->String:
	return "CyclopsLevelBuilder"

func _get_plugin_icon()->Texture2D:
	return preload("res://addons/cyclops_level_builder/art/cyclops.svg")

func _enter_tree():
	add_custom_type("CyclopsBlock", "Node3D", preload("nodes/cyclops_block.gd"), preload("nodes/cyclops_blocks_icon.png"))
	add_custom_type("CyclopsBlocks", "Node3D", preload("nodes/cyclops_blocks.gd"), preload("nodes/cyclops_blocks_icon.png"))
	add_custom_type("CyclopsConvexBlock", "Node", preload("nodes/cyclops_convex_block.gd"), preload("nodes/cyclops_blocks_icon.png"))
	add_custom_type("CyclopsConvexBlockBody", "Node", preload("nodes/cyclops_convex_block_body.gd"), preload("nodes/cyclops_blocks_icon.png"))

	add_autoload_singleton(AUTOLOAD_NAME, "res://addons/cyclops_level_builder/cyclops_global_scene.tscn")
	
	material_dock = preload("res://addons/cyclops_level_builder/docks/material_palette/material_palette_viewport.tscn").instantiate()
	material_dock.builder = self
	
	uv_editor_dock = preload("res://addons/cyclops_level_builder/docks/uv_editor/uv_editor_viewport.tscn").instantiate()
	uv_editor_dock.builder = self
	
	tool_properties_dock = preload("res://addons/cyclops_level_builder/docks/tool_properties/tool_properties_dock.tscn").instantiate()
	tool_properties_dock.builder = self
	
	editor_toolbar = preload("menu/editor_toolbar.tscn").instantiate()
	editor_toolbar.editor_plugin = self

#	sticky_toolbar = preload("menu/sticky_toolbar.tscn").instantiate()
#	sticky_toolbar.plugin = self
#	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, sticky_toolbar)
	
	var editor:EditorInterface = get_editor_interface()
	var selection:EditorSelection = editor.get_selection()
	selection.selection_changed.connect(on_selection_changed)
	
	update_activation()


	#Wait until everything is loaded	
	await get_tree().process_frame
	var global_scene:CyclopsGlobalScene = get_node("/root/CyclopsAutoload")
	global_scene.builder = self
	
	switch_to_tool(ToolBlock.new())

#func find_blocks_root(node:Node)->CyclopsBlocks:
#	if node is CyclopsBlocks:
#		return node
#	if node is CyclopsConvexBlock:
#		return find_blocks_root(node.get_parent())
#	return null

func get_active_block()->CyclopsBlock:
	var selection:EditorSelection = get_editor_interface().get_selection()
	var nodes:Array = selection.get_selected_nodes()
	for n in nodes:
		if n is CyclopsBlock:
			return n
	return null

func get_selected_blocks()->Array[CyclopsBlock]:
	var result:Array[CyclopsBlock]
	
	var selection:EditorSelection = get_editor_interface().get_selection()
	var nodes:Array = selection.get_selected_nodes()
	for n in nodes:
		if n is CyclopsBlock:
			result.append(n)
	
	return result

func get_block_add_parent()->Node:
	var selection:EditorSelection = get_editor_interface().get_selection()
	var nodes:Array = selection.get_selected_nodes()
	if nodes.is_empty():
		return get_editor_interface().get_edited_scene_root()
	
	if nodes[0] is CyclopsBlock:
		return nodes[0].get_parent()
	return nodes[0]

func update_activation():
	var editor:EditorInterface = get_editor_interface()
	var selection:EditorSelection = editor.get_selection()
	var nodes:Array[Node] = selection.get_selected_nodes()
	if !nodes.is_empty():
		var node:Node = nodes[0]
		
#		var blocks_root:CyclopsBlocks = find_blocks_root(node)
		
#		if blocks_root:
		if nodes[0] is CyclopsBlock:
#			active_node = blocks_root
			if !activated:
				add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, editor_toolbar)
				add_control_to_dock(DOCK_SLOT_RIGHT_BL, material_dock)
				add_control_to_dock(DOCK_SLOT_RIGHT_BL, uv_editor_dock)
				add_control_to_dock(DOCK_SLOT_RIGHT_BL, tool_properties_dock)
				activated = true
		else:
			if activated:
				remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, editor_toolbar)
				remove_control_from_docks(material_dock)
				remove_control_from_docks(uv_editor_dock)
				remove_control_from_docks(tool_properties_dock)
				activated = false
#	else:
#		active_node = null

func on_selection_changed():
	update_activation()

func _exit_tree():
	# Clean-up of the plugin goes here.
	remove_autoload_singleton(AUTOLOAD_NAME)
	
	remove_custom_type("CyclopsBlock")
	remove_custom_type("CyclopsBlocks")
	remove_custom_type("CyclopsConvexBlock")
	remove_custom_type("CyclopsConvexBlockBody")
	
#	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, sticky_toolbar)
	
	if activated:
		remove_control_from_docks(material_dock)
		remove_control_from_docks(uv_editor_dock)
		remove_control_from_docks(tool_properties_dock)
		remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, editor_toolbar)

	material_dock.queue_free()
	uv_editor_dock.queue_free()
	tool_properties_dock.queue_free()
	editor_toolbar.queue_free()	

func _handles(object:Object):
#	return object is CyclopsBlocks or object is CyclopsConvexBlock
	return object is CyclopsBlock

func _forward_3d_draw_over_viewport(viewport_control:Control):
	#Draw on top of viweport here
	pass

func _forward_3d_gui_input(viewport_camera:Camera3D, event:InputEvent):
	#print("plugin: " + event.as_text())
	
	if tool:
		var result:bool = tool._gui_input(viewport_camera, event)
		tool._draw_tool(viewport_camera)
		return EditorPlugin.AFTER_GUI_INPUT_STOP if result else EditorPlugin.AFTER_GUI_INPUT_PASS
	
	return EditorPlugin.AFTER_GUI_INPUT_PASS

func _get_state()->Dictionary:
	var state:Dictionary = {}
	material_dock.save_state(state)
	uv_editor_dock.save_state(state)
	tool_properties_dock.save_state(state)
	return state
	
func _set_state(state):
	material_dock.load_state(state)
	uv_editor_dock.load_state(state)
	tool_properties_dock.load_state(state)

func switch_to_tool(_tool:CyclopsTool):
	if tool:
		tool._deactivate()
	
	tool = _tool

	if tool:
		tool._activate(self)
		var control:Control = tool._get_tool_properties_editor()
		tool_properties_dock.set_editor(control)

func get_global_scene()->CyclopsGlobalScene:
	var scene:CyclopsGlobalScene = get_node("/root/CyclopsAutoload")
	return scene


var ray_best_result:IntersectResults

func intersect_ray_closest(origin:Vector3, dir:Vector3)->IntersectResults:
	ray_best_result = null
	return intersect_ray_closest_recursive(get_editor_interface().get_edited_scene_root(), origin, dir)
	
func intersect_ray_closest_recursive(node:Node, origin:Vector3, dir:Vector3)->IntersectResults:
	#var best_result:IntersectResults

#	TreeVisitor.visit(get_editor_interface().get_edited_scene_root(), func(): pass)
	TreeVisitor.visit(get_editor_interface().get_edited_scene_root(), func(node:Node): 
#		print("visiting %s" % node.name)
		if node is CyclopsBlock:
			var result:IntersectResults = node.intersect_ray_closest(origin, dir)
#			print("isect %s %s" % [node.name, result])
			if result:
				if !ray_best_result or result.distance_squared < ray_best_result.distance_squared:
					print("setting best result %s" % node.name)
					ray_best_result = result
					print("best_result %s" % ray_best_result)
		)
		
	print("returning best result %s" % ray_best_result)
	return ray_best_result

#func intersect_ray_closest(origin:Vector3, dir:Vector3)->IntersectResults:
#	return intersect_ray_closest_filtered(origin, dir, func(block:CyclopsBlock): return true)
	
func intersect_ray_closest_selected_only(origin:Vector3, dir:Vector3)->IntersectResults:
	var best_result:IntersectResults

	var blocks:Array[CyclopsBlock] = get_selected_blocks()
	for block in blocks:
		var result:IntersectResults = block.intersect_ray_closest(origin, dir)
		if result:
			if !best_result or result.distance_squared < best_result.distance_squared:
				best_result = result			
	
	return best_result		
	
#	return intersect_ray_closest_filtered(origin, dir, func(block:CyclopsBlock): return block.selected)
	
#func intersect_ray_closest_filtered(origin:Vector3, dir:Vector3, filter:Callable)->IntersectResults:
#	TreeVisitor.visit(get_editor_interface().get_edited_scene_root(), )
#	var best_result:IntersectResults
#
#	var root:Node = get_editor_interface().get_edited_scene_root()
#	for child in root.get_children():
#		if child is CyclopsBlock:
#			var result:IntersectResults = child.intersect_ray_closest(origin, dir)
#			if result:
#				if !filter.call(result.object):
#					continue
#
#				if !best_result or result.distance_squared < best_result.distance_squared:
#					best_result = result			
#
#	return best_result


func intersect_frustum_all(frustum:Array[Plane])->Array[CyclopsBlock]:
	var result:Array[CyclopsBlock] = []
	
	TreeVisitor.visit(get_editor_interface().get_edited_scene_root(), func(node:Node): 
		if node is CyclopsBlock:
			var block:CyclopsBlock = node
			var vol:ConvexVolume = block.control_mesh
			if vol.intersects_frustum(frustum):
				result.append(block)
		)
	
#	for child in get_children():
#		if child is CyclopsBlock:
#			var block:CyclopsBlock = child
#			var vol:ConvexVolume = block.control_mesh
#			if vol.intersects_frustum(frustum):
#				result.append(block)
	
	return result

