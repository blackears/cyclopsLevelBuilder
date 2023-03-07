@tool
extends Node
class_name CyclopsTool

var editorPlugin:EditorPlugin

#func _init(_editorPlugin:EditorPlugin):
#	editorPlugin = _editorPlugin
	
func _activate(builder:CyclopsLevelBuilder):
	editorPlugin = builder
	
func _deactivate():
	pass

func _gui_input(viewport_camera:Camera3D, event:InputEvent)->bool:
	return true
