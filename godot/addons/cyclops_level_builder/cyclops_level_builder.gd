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
signal tool_changed(tool:CyclopsTool)
signal keymap_updated
signal keymap_changed
signal config_changed

const AUTOLOAD_NAME = "CyclopsAutoload"
const CYCLOPS_HUD_NAME = "CyclopsGlobalHud"

var config:CyclopsConfig = preload("res://addons/cyclops_level_builder/data/configuration.tres")
@export_file("*.json") var config_file:String = "res://addons/cyclops_level_builder/data/cyclops_config.json"

var logger:CyclopsLogger = CyclopsLogger.new()

#For now, use a single keymap for all operations
const default_keymap_path:String = "res://addons/cyclops_level_builder/data/default_keymap.tres"
const user_keymap_path:String = "user://keymap.tres"
var keymap:KeymapGroup:
	set(value):
		if keymap == value:
			return
		
		#print("setting cyclops keymap")
		if keymap:
			keymap.keymap_tree_changed.disconnect(on_keymap_changed)
		
		keymap = value
		
		if keymap:
			keymap.keymap_tree_changed.connect(on_keymap_changed)
		
		keymap_changed.emit()

func on_keymap_changed():
	#print("on_keymap_changed() ", keymap.children.size())
	ResourceSaver.save(keymap, user_keymap_path)
	keymap_updated.emit()
	
var material_dock:MaterialPaletteViewport
var overlays_dock:OverlaysDock
var view_uv_editor:ViewUvEditor
var convex_face_editor_dock:ConvexFaceEdtiorViewport
var tool_properties_dock:ToolPropertiesDock
var snapping_properties_dock:SnappingPropertiesDock
var cyclops_console_dock:CyclopsConsole
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
var snapping_system:CyclopsSnappingSystem = null
var lock_uvs:bool = false
var tool_overlay_extrude:float = .01

var tool_uv_transform:Transform2D
var tool_material_path:String

var handle_screen_radius:float = 6

var drag_start_radius:float = 6

var active_tool:CyclopsTool = null
var tool_list:Array[CyclopsTool]

var action_list:Array[CyclopsAction]

var overlay_list:Array[CyclopsOverlayObject]

const config_scene_path:String = "res://addons/cyclops_level_builder/gui/configuration.tscn"
var config_scene:Node

enum Mode { OBJECT, EDIT }
var mode:Mode = Mode.OBJECT
enum EditMode { VERTEX, EDGE, FACE }
var edit_mode:CyclopsLevelBuilder.EditMode = CyclopsLevelBuilder.EditMode.VERTEX

signal xray_mode_changed(value:bool)

@export var xray_mode:bool = false:
	get:
		return xray_mode
	set(value):
		if xray_mode != value:		
			xray_mode = value
			xray_mode_changed.emit(value)

var display_mode:DisplayMode.Type = DisplayMode.Type.MATERIAL


var editor_cache:Dictionary
var editor_cache_file:String = "user://cyclops_editor_cache.json"

var viewport_3d_manager:Viewport3DManager = preload("res://addons/cyclops_level_builder/util/viewport_3d_manager.tscn").instantiate()

func get_action(action_id:String)->CyclopsAction:
	for action in action_list:
		if action._get_action_id() == action_id:
			return action
	return null

func get_overlay(name:String)->CyclopsOverlayObject:
	for overlay:CyclopsOverlayObject in overlay_list:
		if overlay.name == name:
			return overlay
	return null
	
func get_snapping_manager()->SnappingManager:
	var mgr:SnappingManager = SnappingManager.new()
	mgr.snap_enabled = true
	mgr.snap_tool = snapping_system
	
	return mgr

func _ready():
	#config_scene = preload(config_scene_path).instantiate()
	#print("adding config scene")
#
	#add_child(config_scene)
	pass

func _get_plugin_name()->String:
	return "CyclopsLevelBuilder"

func _get_plugin_icon()->Texture2D:
	return preload("res://addons/cyclops_level_builder/art/cyclops.svg")


func _enter_tree():
	config_scene = preload(config_scene_path).instantiate()
	add_child(config_scene)
	
	if FileAccess.file_exists(editor_cache_file):
		#print(">> _enter_tree")
		var text:String = FileAccess.get_file_as_string(editor_cache_file)
		#print("load text:", text)
		editor_cache = JSON.parse_string(text)
	
	if FileAccess.file_exists(user_keymap_path):
		#print("keymap = load(user_keymap_path)")
		keymap = load(user_keymap_path)
	elif FileAccess.file_exists(default_keymap_path):
		#print("var km:KeymapGroup = load(default_keymap_path)")
		var km:KeymapGroup = load(default_keymap_path)
		keymap = km.duplicate(true)
	else:
		#print("keymap = KeymapGroup.new()")
		keymap = KeymapGroup.new()

	#EditorInterface.get_resource_filesystem().filesystem_changed.connect(on_filesystem_changed)
	
	add_child(viewport_3d_manager)
	viewport_3d_manager.plugin = self
		
	set_input_event_forwarding_always_enabled()
	
	add_custom_type("CyclopsScene", "Node3D", preload("nodes/cyclops_scene.gd"), preload("nodes/cyclops_blocks_icon.png"))
	
	add_custom_type("CyclopsBlock", "Node3D", preload("nodes/cyclops_block.gd"), preload("nodes/cyclops_blocks_icon.png"))
	add_custom_type("CyclopsBlocks", "Node3D", preload("nodes/cyclops_blocks.gd"), preload("nodes/cyclops_blocks_icon.png"))
	add_custom_type("CyclopsConvexBlock", "Node", preload("nodes/cyclops_convex_block.gd"), preload("nodes/cyclops_blocks_icon.png"))
	add_custom_type("CyclopsConvexBlockBody", "Node", preload("nodes/cyclops_convex_block_body.gd"), preload("nodes/cyclops_blocks_icon.png"))

	add_autoload_singleton(AUTOLOAD_NAME, "res://addons/cyclops_level_builder/cyclops_global_scene.tscn")

	var overlay:ObjectInfoOverlay = ObjectInfoOverlay.new()
	overlay.plugin = self
	overlay_list.append(overlay)
	
	material_dock = preload("res://addons/cyclops_level_builder/gui/docks/material_palette/material_palette_viewport.tscn").instantiate()
	material_dock.builder = self

	view_uv_editor = preload("res://addons/cyclops_level_builder/gui/docks/uv_editor/view_uv_editor.tscn").instantiate()
	view_uv_editor.plugin = self
#	view_uv_editor.forward_input.connect(on_uv_editor_forward_input)
	
	overlays_dock = preload("res://addons/cyclops_level_builder/gui/docks/overlays/overlays_dock.tscn").instantiate()
	overlays_dock.plugin = self
	
	convex_face_editor_dock = preload("res://addons/cyclops_level_builder/gui/docks/convex_face_editor/convex_face_editor_viewport.tscn").instantiate()
	convex_face_editor_dock.builder = self
	
	tool_properties_dock = preload("res://addons/cyclops_level_builder/gui/docks/tool_properties/tool_properties_dock.tscn").instantiate()
	tool_properties_dock.builder = self
	
	snapping_properties_dock = preload("res://addons/cyclops_level_builder/gui/docks/snapping_properties/snapping_properties_dock.tscn").instantiate()
	snapping_properties_dock.builder = self
	
	cyclops_console_dock = preload("res://addons/cyclops_level_builder/gui/docks/cyclops_console/cyclops_console.tscn").instantiate()
	cyclops_console_dock.editor_plugin = self
	
	editor_toolbar = preload("gui/menu/editor_toolbar.tscn").instantiate()
	editor_toolbar.editor_plugin = self

	upgrade_cyclops_blocks_toolbar = preload("res://addons/cyclops_level_builder/gui/menu/upgrade_cyclops_blocks_toolbar.tscn").instantiate()
	upgrade_cyclops_blocks_toolbar.editor_plugin = self

	add_control_to_bottom_panel(cyclops_console_dock, "Cyclops")
	
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, editor_toolbar)
	add_control_to_bottom_panel(material_dock, "Materials")
	add_control_to_bottom_panel(view_uv_editor, "UV Editor")
	
	var editor:EditorInterface = get_editor_interface()
	var selection:EditorSelection = editor.get_selection()
	selection.selection_changed.connect(on_selection_changed)
	
	#load_config()
	#load_tools()
	update_activation()


	#Wait until everything is loaded	
	await get_tree().process_frame
	
	var global_scene:CyclopsGlobalScene = get_node("/root/CyclopsAutoload")
	global_scene.builder = self
	
	switch_to_snapping_system(SnappingSystemGrid.new())
#	switch_to_tool(ToolBlock.new())
	switch_to_tool(get_tool_by_id(ToolBlock.TOOL_ID))


func _exit_tree():
	
	var file:FileAccess = FileAccess.open(editor_cache_file, FileAccess.WRITE)
	#var text:String = JSON.stringify(editor_cache, "  ")
	#print("saving cache:", text)
	file.store_string(JSON.stringify(editor_cache, "    "))
	file.close()

	remove_child(viewport_3d_manager)
	
	
	# Clean-up of the plugin goes here.
	remove_autoload_singleton(AUTOLOAD_NAME)
	
	remove_custom_type("CyclopsScene")
	
	remove_custom_type("CyclopsBlock")
	remove_custom_type("CyclopsBlocks")
	remove_custom_type("CyclopsConvexBlock")
	remove_custom_type("CyclopsConvexBlockBody")
	
	remove_control_from_bottom_panel(cyclops_console_dock)
	remove_control_from_bottom_panel(material_dock)
	remove_control_from_bottom_panel(view_uv_editor)
	
	if activated:
		remove_control_from_docks(convex_face_editor_dock)
		remove_control_from_docks(tool_properties_dock)
		remove_control_from_docks(snapping_properties_dock)
		remove_control_from_docks(overlays_dock)
		remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, editor_toolbar)

	if upgrade_cyclops_blocks_toolbar.activated:
		remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, upgrade_cyclops_blocks_toolbar)

#	view_uv_editor.forward_input.disconnect(on_uv_editor_forward_input)

	material_dock.queue_free()
	view_uv_editor.queue_free()
	convex_face_editor_dock.queue_free()
	tool_properties_dock.queue_free()
	overlays_dock.queue_free()
	snapping_properties_dock.queue_free()
	cyclops_console_dock.queue_free()
	editor_toolbar.queue_free()
	upgrade_cyclops_blocks_toolbar.queue_free()

	remove_child(config_scene)
	config_scene.queue_free()

#@deprecated
#func load_config():
	##load_actions()
	#var text:String = FileAccess.get_file_as_string(config_file)
	#var config_dict:Dictionary = JSON.parse_string(text)
		#
	##Load tools
	#tool_list.clear()
#
	#for path in config_dict["tools"]:
		##print("Loading tool ", path)
		#var script:Script = load(path)
#
		#var tool:CyclopsTool = script.new()
		#tool.builder = self
		#tool_list.append(tool)
#
	#for tool in tool_list:
		#tool._ready()

func log(message:String, level:CyclopsLogger.LogLevel = CyclopsLogger.LogLevel.ERROR):
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
	var selection:EditorSelection = EditorInterface.get_selection()
	var nodes:Array[Node] = selection.get_selected_nodes()
	
	if nodes.is_empty():
		return null
		
	var back:Node = nodes.back()
	if back is CyclopsBlock:
		return back
	return null
	

#Blocks listed in order of selection with last block being the most recent (ie, active) one
func get_selected_blocks()->Array[CyclopsBlock]:
	var result:Array[CyclopsBlock]

	var selection:EditorSelection = EditorInterface.get_selection()
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
			add_control_to_dock(DOCK_SLOT_RIGHT_BL, convex_face_editor_dock)
			add_control_to_dock(DOCK_SLOT_RIGHT_BL, tool_properties_dock)
			add_control_to_dock(DOCK_SLOT_RIGHT_BL, snapping_properties_dock)
			add_control_to_dock(DOCK_SLOT_RIGHT_BL, overlays_dock)
			activated = true
	else:
		if activated:
			remove_control_from_docks(convex_face_editor_dock)
			remove_control_from_docks(tool_properties_dock)
			remove_control_from_docks(snapping_properties_dock)
			remove_control_from_docks(overlays_dock)
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
	
	var view_cam:Camera3D = EditorInterface.get_editor_viewport_3d().get_camera_3d()
	
	if active_tool:
		active_tool._draw_tool(view_cam)
	#if cached_viewport_camera:
		#active_tool._draw_tool(cached_viewport_camera)

func _handles(object:Object):
#	return object is CyclopsBlocks or object is CyclopsConvexBlock
	return object is CyclopsBlock or object is CyclopsBlocks or always_on

func _forward_3d_draw_over_viewport(viewport_control:Control):
	viewport_3d_manager.draw_over_viewport(viewport_control)
	
	for overlay in overlay_list:
		overlay._draw_overlay(viewport_control, 0)
	#Draw on top of viweport here

func _forward_3d_gui_input(viewport_camera:Camera3D, event:InputEvent)->int:
	
	if event is InputEventMouse || event is InputEventMouseButton:
		update_overlays()
	
	#Pass to active tool
	var sel_nodes:Array[Node] = EditorInterface.get_selection().get_selected_nodes()
	var active_node:Node = null if sel_nodes.is_empty() else sel_nodes.back()
	
	#if event is InputEventKey:
		#print("processing key ", event)
	
	if active_tool && active_tool._can_handle_object(active_node)\
		&& !active_tool.is_uv_tool():
		
		var result:bool = active_tool._gui_input(viewport_camera, event)
		active_tool._draw_tool(viewport_camera)
		if result:
			return EditorPlugin.AFTER_GUI_INPUT_STOP

	return EditorPlugin.AFTER_GUI_INPUT_PASS

#func on_uv_editor_forward_input(event:InputEvent):
	#var sel_nodes:Array[Node] = EditorInterface.get_selection().get_selected_nodes()
	#var active_node:Node = null if sel_nodes.is_empty() else sel_nodes.back()
	#
	#if active_tool && active_tool._can_handle_object(active_node)\
		#&& active_tool.is_uv_tool():
			#
		#var result:bool = active_tool._gui_input(null, event)
	#pass


func _get_state()->Dictionary:
	var state:Dictionary = {}
	
	#print("ed cache ", str(editor_cache))
	#state["editor_cache"] = editor_cache.duplicate()
	
	material_dock.save_state(state)
	view_uv_editor.save_state(state)
	convex_face_editor_dock.save_state(state)
	tool_properties_dock.save_state(state)
	snapping_properties_dock.save_state(state)
	overlays_dock.save_state(state)
	cyclops_console_dock.save_state(state)
	
	return state
	
func _set_state(state):
	#print("ed set_state ", str(state))
	
	#editor_cache = state.get("editor_cache", {}).duplicate()
	
	material_dock.load_state(state)
	view_uv_editor.load_state(state)
	convex_face_editor_dock.load_state(state)
	tool_properties_dock.load_state(state)
	snapping_properties_dock.load_state(state)
	overlays_dock.load_state(state)
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

func get_tool_by_id(tool_id:String)->CyclopsTool:
	for tool:CyclopsTool in tool_list:
		if tool._get_tool_id() == tool_id:
			return tool
	return null

#func switch_to_tool_id(tool_id:String):
	#var next_tool:CyclopsTool = get_tool_by_id(tool_id)
	#
	#if active_tool:
		#if active_tool._get_tool_id() == tool_id:
			#return
		#
		#active_tool._deactivate()
		#tool_properties_dock.set_editor(null)
	##print("switching to ", tool_id)
	#active_tool = next_tool
#
	#if active_tool:
		#active_tool._activate(self)
		#var control:Control = active_tool._get_tool_properties_editor()
		#tool_properties_dock.set_editor(control)
	#
	##print("emittng ", tool_id)
	#tool_changed.emit(active_tool)

func switch_to_tool(_tool:CyclopsTool):
	#print(">> switch to tool")
	
	if active_tool:
		active_tool._deactivate()
	
	active_tool = _tool

	if active_tool:
		active_tool._activate(self)
		var control:Control = active_tool._get_tool_properties_editor()
		tool_properties_dock.set_editor(control)
	
	tool_changed.emit(active_tool)

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
	if !has_node("/root/CyclopsAutoload"):
		return null
	var scene:CyclopsGlobalScene = get_node("/root/CyclopsAutoload")
	return scene



func intersect_ray_closest(origin:Vector3, dir:Vector3)->IntersectResults:
	var best_result:IntersectResults

	var blocks:Array[CyclopsBlock] = get_blocks()

	for block in blocks:
		if !block.is_visible_in_tree():
			continue
		
		var result:IntersectResults = block.intersect_ray_closest(origin, dir)
#		print("isect %s %s" % [block.name, result])
		if result:
			if !best_result or result.distance_squared < best_result.distance_squared:
#				print("setting best result %s" % block.name)
				best_result = result
#				print("best_result ", best_result)
		
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
