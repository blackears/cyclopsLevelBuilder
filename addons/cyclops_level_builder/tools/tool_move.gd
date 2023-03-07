@tool
extends CyclopsTool
class_name ToolMove

#enum State { READY, DRAG_BASE }
var dragging:bool = false
var mouse_start:Vector2

func _gui_input(viewport_camera:Camera3D, event:InputEvent)->bool:	
	if event is InputEventMouseButton:
		var e:InputEventMouseButton = event
		if e.is_pressed():
			dragging = true
			mouse_start = e.position
		else:
			dragging = false
			mouse_start = e.position
			

		var origin:Vector3 = viewport_camera.project_ray_origin(e.position)
		var dir:Vector3 = viewport_camera.project_ray_normal(e.position)
		
		print("pick origin %s " % origin)
			
		return  true
		
	elif event is InputEventMouseMotion:
		var e:InputEventMouseMotion = event
	
	return false
	#return EditorPlugin.AFTER_GUI_INPUT_STOP if true else EditorPlugin.AFTER_GUI_INPUT_PASS
