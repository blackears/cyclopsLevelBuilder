@tool
extends PanelContainer
class_name EditorToolbar

var editorPlugin:CyclopsLevelBuilder

#enum Tool { MOVE, DRAW, CLIP, VERTEX, EDGE, FACE }
#var tool:Tool = Tool.MOVE

# Called when the node enters the scene tree for the first time.
func _ready():
	$HBoxContainer/grid_size.clear()
	$HBoxContainer/grid_size.add_item("1/16", 0)
	$HBoxContainer/grid_size.add_item("1/8", 1)
	$HBoxContainer/grid_size.add_item("1/4", 2)
	$HBoxContainer/grid_size.add_item("1/2", 3)
	$HBoxContainer/grid_size.add_item("1", 4)
	$HBoxContainer/grid_size.add_item("2", 5)
	$HBoxContainer/grid_size.add_item("4", 6)
	$HBoxContainer/grid_size.add_item("8", 7)
	$HBoxContainer/grid_size.add_item("16", 8)
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_grid_size_item_selected(index):
#	if Engine.is_editor_hint():
	print("_on_grid_size_item_selected " + str(index))

	var iface:EditorInterface = editorPlugin.get_editor_interface()
	var settings:EditorSettings = iface.get_editor_settings()
	
	settings.set_setting("editors/3d/grid_size", index)
	
	pass # Replace with function body.


func _on_bn_move_pressed():
	editorPlugin.switch_to_tool(ToolMove.new())


func _on_bn_draw_pressed():
	pass


func _on_bn_clip_pressed():
	pass


func _on_bn_vertex_pressed():
	pass


func _on_bn_edge_pressed():
	pass


func _on_bn_face_pressed():
	pass
