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
signal snapping_tool_changed

const AUTOLOAD_NAME = "CyclopsAutoload"
const CYCLOPS_HUD_NAME = "CyclopsGlobalHud"

var config:CyclopsConfig = preload("res://addons/cyclops_level_builder/data/configuration.tres")

var logger:Logger = Logger.new()

var material_dock:MaterialPaletteViewport
var convex_face_editor_dock:ConvexFaceEdtiorViewport
var tool_properties_dock:ToolPropertiesDock
var snapping_properties_dock:SnappingPropertiesDock
var cyclops_console_dock:CyclopsConsole
#var sticky_toolbar:StickyToolbar
var editor_toolbar:EditorToolbar
var upgrade_cyclops_blocks_toolbar:UpgradeCyclopsBlocksToolbar
var activated:bool = false

var always_on:bool = false:
	get:
		return always_on
	set(value):
		always_on = value
		#print("always_on %s" % always_on)
		update_activation()

var block_create_distance:float = 10
var tool:CyclopsTool = null
var snapping_system:CyclopsSnappingSystem = null
var lock_uvs:bool = false
var tool_overlay_extrude:float = .01

var tool_uv_transform:Transform2D
var tool_material_path:String

var handle_screen_radius:float = 6

var drag_start_radius:float = 6

enum Mode { OBJECT, EDIT }
var mode:Mode = Mode.OBJECT
enum EditMode { VERTEX, EDGE, FACE }
var edit_mode:EditMode = EditMode.VERTEX

var display_mode:DisplayMode.Type = DisplayMode.Type.MATERIAL

var cached_viewport_camera:Camera3D

var editor_cache:Dictionary
var editor_cache_file:String = "editor_cache.json"

func get_snapping_manager()->SnappingManager:
	var mgr:SnappingManager = SnappingManager.new()
	mgr.snap_enabled = CyclopsAutoload.settings.get_property(CyclopsGlobalScene.SNAPPING_ENABLED)
	mgr.snap_tool = snapping_system
	
	return mgr

func _get_plugin_name()->String:
	return "CyclopsLevelBuilder"

func _get_plugin_icon()->Texture2D:
	return preload("res://addons/cyclops_level_builder/art/cyclops.svg")

func _enter_tree():
	if FileAccess.file_exists(editor_cache_file):
		#print(">> _enter_tree")
		var text:String = FileAccess.get_file_as_string(editor_cache_file)
		#print("load text:", text)
		editor_cache = JSON.parse_string(text)
		
	
	add_custom_type("CyclopsBlock", "Node3D", preload("nodes/cyclops_block.gd"), preload("nodes/cyclops_blocks_icon.png"))
	add_custom_type("CyclopsBlocks", "Node3D", preload("nodes/cyclops_blocks.gd"), preload("nodes/cyclops_blocks_icon.png"))
	add_custom_type("CyclopsConvexBlock", "Node", preload("nodes/cyclops_convex_block.gd"), preload("nodes/cyclops_blocks_icon.png"))
	add_custom_type("CyclopsConvexBlockBody", "Node", preload("nodes/cyclops_convex_block_body.gd"), preload("nodes/cyclops_blocks_icon.png"))

	add_autoload_singleton(AUTOLOAD_NAME, "res://addons/cyclops_level_builder/cyclops_global_scene.tscn")
	#add_autoload_singleton(CYCLOPS_HUD_NAME, "res://addons/cyclops_level_builder/cyclops_global_hud.tscn")
	
	material_dock = preload("res://addons/cyclops_level_builder/docks/material_palette/material_palette_viewport.tscn").instantiate()
	material_dock.builder = self
	
	convex_face_editor_dock = preload("res://addons/cyclops_level_builder/docks/convex_face_editor/convex_face_editor_viewport.tscn").instantiate()
	convex_face_editor_dock.builder = self
	
	tool_properties_dock = preload("res://addons/cyclops_level_builder/docks/tool_properties/tool_properties_dock.tscn").instantiate()
	tool_properties_dock.builder = self
	
	snapping_properties_dock = preload("res://addons/cyclops_level_builder/docks/snapping_properties/snapping_properties_dock.tscn").instantiate()
	snapping_properties_dock.builder = self
	
	cyclops_console_dock = preload("res://addons/cyclops_level_builder/docks/cyclops_console/cyclops_console.tscn").instantiate()
	cyclops_console_dock.editor_plugin = self
	
	editor_toolbar = preload("menu/editor_toolbar.tscn").instantiate()
	editor_toolbar.editor_plugin = self

	upgrade_cyclops_blocks_toolbar = preload("res://addons/cyclops_level_builder/menu/upgrade_cyclops_blocks_toolbar.tscn").instantiate()
	upgrade_cyclops_blocks_toolbar.editor_plugin = self

#	sticky_toolbar = preload("menu/sticky_toolbar.tscn").instantiate()
#	sticky_toolbar.plugin = self
#	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, sticky_toolbar)
	add_control_to_bottom_panel(cyclops_console_dock, "Cyclops")
	
	var editor:EditorInterface = get_editor_interface()
	var selection:EditorSelection = editor.get_selection()
	selection.selection_changed.connect(on_selection_changed)
	
	update_activation()


	#Wait until everything is loaded	
	await get_tree().process_frame
	
	var global_scene:CyclopsGlobalScene = get_node("/root/CyclopsAutoload")
	global_scene.builder = self
	
	switch_to_snapping_system(SnappingSystemGrid.new())
	switch_to_tool(ToolBlock.new())


func _exit_tree():
	var file:FileAccess = FileAccess.open(editor_cache_file, FileAccess.WRITE)
	#var text:String = JSON.stringify(editor_cache, "  ")
	#print("saving cache:", text)
	file.store_string(JSON.stringify(editor_cache, "    "))
	file.close()
		
	# Clean-up of the plugin goes here.
	remove_autoload_singleton(AUTOLOAD_NAME)
	#remove_autoload_singleton(CYCLOPS_HUD_NAME)
	
	remove_custom_type("CyclopsBlock")
	remove_custom_type("CyclopsBlocks")
	remove_custom_type("CyclopsConvexBlock")
	remove_custom_type("CyclopsConvexBlockBody")
	
#	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, sticky_toolbar)
	remove_control_from_bottom_panel(cyclops_console_dock)
	
	if activated:
		remove_control_from_docks(material_dock)
		remove_control_from_docks(convex_face_editor_dock)
		remove_control_from_docks(tool_properties_dock)
		remove_control_from_docks(snapping_properties_dock)
		remove_control_from_docks(cyclops_console_dock)
		remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, editor_toolbar)

	if upgrade_cyclops_blocks_toolbar.activated:		
		remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, upgrade_cyclops_blocks_toolbar)

	material_dock.queue_free()
	convex_face_editor_dock.queue_free()
	tool_properties_dock.queue_free()
	snapping_properties_dock.queue_free()
	cyclops_console_dock.queue_free()
	editor_toolbar.queue_free()
	upgrade_cyclops_blocks_toolbar.queue_free()

func log(message:String, level:Logger.Level = Logger.Level.ERROR):
	logger.log(message, level)

func get_blocks()->Array[CyclopsBlock]:
	return get_blocks_recursive(get_editor_interface().get_edited_scene_root())

func get_blocks_recursive(node:Node)->Array[CyclopsBlock]:
	var result:Array[CyclopsBlock]
	
	if node is CyclopsBlock:
		result.append(node)
	for child in node.get_children():
		result.append_array(get_blocks_recursive(child))
	return result

func is_selected(node:Node)->bool:
	var selection:EditorSelection = get_editor_interface().get_selection()
	for n in selection.get_selected_nodes():
		if n == node:
			return true
	return false
	

func is_active_block(block:CyclopsBlock)->bool:
	var selection:EditorSelection = get_editor_interface().get_selection()
	var nodes:Array[Node] = selection.get_selected_nodes()
	
	return !nodes.is_empty() && nodes.back() == block
	
func get_active_block()->CyclopsBlock:
	var selection:EditorSelection = get_editor_interface().get_selection()
	var nodes:Array[Node] = selection.get_selected_nodes()
	
	var back:Node = nodes.back()
	if back is CyclopsBlock:
		return back
	return null
	

#Blocks listed in order of selection with last block being the most recent (ie, active) one
func get_selected_blocks()->Array[CyclopsBlock]:
	var result:Array[CyclopsBlock]

	var selection:EditorSelection = get_editor_interface().get_selection()
	for node in selection.get_selected_nodes():
		if node is CyclopsBlock:
			result.append(node)

	return result

func get_block_add_parent()->Node:
	var selection:EditorSelection = get_editor_interface().get_selection()
	var nodes:Array = selection.get_selected_nodes()
	if nodes.is_empty():
		return get_editor_interface().get_edited_scene_root()
	
	if nodes[0] is CyclopsBlock:
		#print("getting parent of ", nodes[0].name)
		return nodes[0].get_parent()
	return nodes[0]

func update_activation():
	var editor:EditorInterface = get_editor_interface()
	var selection:EditorSelection = editor.get_selection()
	var nodes:Array[Node] = selection.get_selected_nodes()
	
	#Node list ordered in order of selection with most recently sdelected at end
	var node:Node = null
	if !nodes.is_empty():
		node = nodes[0]
		
	if node is CyclopsBlock || always_on:
		#print("updarting activation")
		if !activated:
			add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, editor_toolbar)
			add_control_to_bottom_panel(material_dock, "Materials")
			add_control_to_dock(DOCK_SLOT_RIGHT_BL, convex_face_editor_dock)
			add_control_to_dock(DOCK_SLOT_RIGHT_BL, tool_properties_dock)
			add_control_to_dock(DOCK_SLOT_RIGHT_BL, snapping_properties_dock)
			activated = true
	else:
		if activated:
			remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, editor_toolbar)
			remove_control_from_bottom_panel(material_dock)
			remove_control_from_docks(convex_face_editor_dock)
			remove_control_from_docks(tool_properties_dock)
			remove_control_from_docks(snapping_properties_dock)
			activated = false
	
	if node is CyclopsBlocks:
		if !upgrade_cyclops_blocks_toolbar.activated:
			add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, upgrade_cyclops_blocks_toolbar)
			upgrade_cyclops_blocks_toolbar.activated = true
	else:
		if upgrade_cyclops_blocks_toolbar.activated:
			remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, upgrade_cyclops_blocks_toolbar)
			upgrade_cyclops_blocks_toolbar.activated = false

func on_selection_changed():
	update_activation()
	
	if cached_viewport_camera:
		tool._draw_tool(cached_viewport_camera)

func _handles(object:Object):
#	return object is CyclopsBlocks or object is CyclopsConvexBlock
	return object is CyclopsBlock or object is CyclopsBlocks or always_on

func _forward_3d_draw_over_viewport(viewport_control:Control):
	var global_scene:CyclopsGlobalScene = get_global_scene()
	global_scene.draw_over_viewport(viewport_control)
	#Draw on top of viweport here

func _forward_3d_gui_input(viewport_camera:Camera3D, event:InputEvent):
	#print("plugin: " + event.as_text())
	cached_viewport_camera = viewport_camera
	
	if tool:
		var result:bool = tool._gui_input(viewport_camera, event)
		tool._draw_tool(viewport_camera)
		return EditorPlugin.AFTER_GUI_INPUT_STOP if result else EditorPlugin.AFTER_GUI_INPUT_PASS
	
	return EditorPlugin.AFTER_GUI_INPUT_PASS

func _get_state()->Dictionary:
	var state:Dictionary = {}
	
	#print("ed cache ", str(editor_cache))
	#state["editor_cache"] = editor_cache.duplicate()
	
	material_dock.save_state(state)
	convex_face_editor_dock.save_state(state)
	tool_properties_dock.save_state(state)
	snapping_properties_dock.save_state(state)
	cyclops_console_dock.save_state(state)
	
	return state
	
func _set_state(state):
	#print("ed set_state ", str(state))
	
	#editor_cache = state.get("editor_cache", {}).duplicate()
	
	material_dock.load_state(state)
	convex_face_editor_dock.load_state(state)
	tool_properties_dock.load_state(state)
	snapping_properties_dock.load_state(state)
	cyclops_console_dock.load_state(state)


func get_tool_cache(tool_id:String):
	if !editor_cache.has("tool"):
		return {}
	
	if !editor_cache.tool.has(tool_id):
		return {}
	
	return editor_cache.tool[tool_id]

func set_tool_cache(tool_id:String, cache:Dictionary):
	if !editor_cache.has("tool"):
		editor_cache["tool"] = {}
	
	editor_cache.tool[tool_id] = cache

func get_snapping_cache(tool_id:String):
	if !editor_cache.has("snapping"):
		return {}
	
	if !editor_cache.snapping.has(tool_id):
		return {}
	
	return editor_cache.snapping[tool_id]

func set_snapping_cache(tool_id:String, cache:Dictionary):
	if !editor_cache.has("snapping"):
		editor_cache["snapping"] = {}
	
	editor_cache.snapping[tool_id] = cache

func switch_to_tool(_tool:CyclopsTool):
	#print(">> switch to tool")
	
	if tool:
		tool._deactivate()
	
	tool = _tool

	if tool:
		tool._activate(self)
		var control:Control = tool._get_tool_properties_editor()
		tool_properties_dock.set_editor(control)

func switch_to_snapping_system(_snapping_system:CyclopsSnappingSystem):
	if snapping_system:
		snapping_system._deactivate()
		
	snapping_system = _snapping_system
	
	if snapping_system:
		snapping_system._activate(self)
		var control:Control = snapping_system._get_properties_editor()
		snapping_properties_dock.set_editor(control)
	
	snapping_tool_changed.emit()

func get_global_scene()->CyclopsGlobalScene:
	var scene:CyclopsGlobalScene = get_node("/root/CyclopsAutoload")
	return scene



func intersect_ray_closest(origin:Vector3, dir:Vector3)->IntersectResults:
	var best_result:IntersectResults

	var blocks:Array[CyclopsBlock] = get_blocks()

	for block in blocks:
		if !block.is_visible_in_tree():
			continue
		
		var result:IntersectResults = block.intersect_ray_closest(origin, dir)
#			print("isect %s %s" % [node.name, result])
		if result:
			if !best_result or result.distance_squared < best_result.distance_squared:
#				print("setting best result %s" % node.name)
				best_result = result
#				print("best_result %s" % ray_best_result)
		
#	print("returning best result %s" % ray_best_result)
	return best_result

func intersect_ray_closest_selected_only(origin:Vector3, dir:Vector3)->IntersectResults:
	var best_result:IntersectResults

	var blocks:Array[CyclopsBlock] = get_selected_blocks()
	for block in blocks:
		var result:IntersectResults = block.intersect_ray_closest(origin, dir)
		if result:
			if !best_result or result.distance_squared < best_result.distance_squared:
				best_result = result			
	
	return best_result		
	

func intersect_frustum_all(frustum:Array[Plane])->Array[CyclopsBlock]:
	var result:Array[CyclopsBlock] = []
	
	var blocks:Array[CyclopsBlock] = get_blocks()
	for block in blocks:
		var xform:Transform3D = block.global_transform.affine_inverse()
		
		var frustum_local:Array[Plane]
		for p in frustum:
			frustum_local.append(xform * p)
		
		#print("intersect_frustum_all block %s" % block.get_path())
		var vol:ConvexVolume = block.control_mesh
#		if !vol:
#			print("nil vol %s" % block.get_path())
		if vol && vol.intersects_frustum(frustum_local):
			result.append(block)
	
	return result

