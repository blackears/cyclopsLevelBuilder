@tool
extends EditorPlugin
class_name CyclopsLevelBuilder

const AUTOLOAD_NAME = "CyclopsAutoload"

#var dock:Control
var toolbar:EditorToolbar
var activated:bool = false

var block_create_distance:float = 5
var tool:CyclopsTool = null

var current_node:GeometryBrush

func _enter_tree():
	add_custom_type("GeometryBrush", "Node3D", preload("controls/geometry_brush.gd"), preload("controls/geometryBrushIcon.png"))

	add_autoload_singleton(AUTOLOAD_NAME, "res://addons/cyclops_level_builder/cyclops_global_scene.tscn")
	
#	dock = preload("menu/cyclops_control_panel.tscn").instantiate()
	
	toolbar = preload("menu/editor_toolbar.tscn").instantiate()
	toolbar.editorPlugin = self
	
	var editor:EditorInterface = get_editor_interface()
	var selection:EditorSelection = editor.get_selection()
	selection.selection_changed.connect(on_selection_changed)
	
	var undo:EditorUndoRedoManager = get_undo_redo()
	
	update_activation()
	
	switch_to_tool(ToolMove.new())

func update_activation():
	var editor:EditorInterface = get_editor_interface()
	var selection:EditorSelection = editor.get_selection()
	var nodes:Array[Node] = selection.get_selected_nodes()
	if !nodes.is_empty():
		var node:Node = nodes[0]
		
		if node is GeometryBrush:
			current_node = node
			if !activated:
				add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, toolbar)
				activated = true
		else:
			if activated:
				remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, toolbar)
				activated = false
	else:
		current_node = null

func on_selection_changed():
	update_activation()

func _exit_tree():
	# Clean-up of the plugin goes here.
	remove_autoload_singleton(AUTOLOAD_NAME)
	
	remove_custom_type("GeometryBrush")
	
	
	if activated:
#		remove_control_from_docks(dock)
		remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, toolbar)

#	dock.queue_free()
	toolbar.queue_free()

func _handles(object:Object):
	return object is GeometryBrush

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
	
