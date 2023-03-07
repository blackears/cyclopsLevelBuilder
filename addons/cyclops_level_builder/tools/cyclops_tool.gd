@tool
extends Node
class_name CyclopsTool

var builder:EditorPlugin

#func _init(_editorPlugin:EditorPlugin):
#	editorPlugin = _editorPlugin
	
func _activate(_builder:CyclopsLevelBuilder):
	builder = _builder
	
func _deactivate():
	pass

func _gui_input(viewport_camera:Camera3D, event:InputEvent)->bool:
	return true
	
