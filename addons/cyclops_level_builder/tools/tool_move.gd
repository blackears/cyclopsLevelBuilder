@tool
extends CyclopsTool
class_name ToolMove

enum DragStyle { NONE, CREATE_BLOCK }
var drag_style:DragStyle = DragStyle.NONE
#enum State { READY, DRAG_BASE }
var dragging:bool = false
var mouse_start:Vector2

var block_drag_start_local:Vector3

func _gui_input(viewport_camera:Camera3D, event:InputEvent)->bool:	
	var active_brushes:GeometryBrushes = self.builder.active_node
	
	if event is InputEventMouseButton:
		var e:InputEventMouseButton = event
		if e.is_pressed():
			dragging = true
			mouse_start = e.position
			
			var origin:Vector3 = viewport_camera.project_ray_origin(e.position)
			var dir:Vector3 = viewport_camera.project_ray_normal(e.position)

			#print("origin %s" % origin)
			#print("dir %s" % dir)
			
			var result = active_brushes.intersect_ray(origin, dir)
			if !result:
				drag_style = DragStyle.CREATE_BLOCK
				var start_pos:Vector3 = origin + builder.block_create_distance * dir
				var w2l = active_brushes.global_transform.inverse()
				var start_pos_local:Vector3 = w2l * start_pos

				#print("start_pos %s" % start_pos)
				#print("start_pos_local %s" % start_pos_local)
				
				var grid_step_size:float = pow(2, active_brushes.grid_size)

				
				#print("start_pos_local %s" % start_pos_local)
				block_drag_start_local = MathUtil.snap_to_grid(start_pos_local, grid_step_size)
				
				#print("block_drag_start_local %s" % block_drag_start_local)
			
		else:
			dragging = false
			mouse_start = e.position
			drag_style = DragStyle.NONE
			

		
		#print("pick origin %s " % origin)
			
		return  true
		
	elif event is InputEventMouseMotion:
		var e:InputEventMouseMotion = event
		
		if drag_style == DragStyle.CREATE_BLOCK:
			var origin:Vector3 = viewport_camera.project_ray_origin(e.position)
			var dir:Vector3 = viewport_camera.project_ray_normal(e.position)
			
			var start_pos:Vector3 = origin + builder.block_create_distance * dir
			var w2l = active_brushes.global_transform.inverse()
			var origin_local:Vector3 = w2l * origin
			var dir_local:Vector3 = w2l.basis * dir
			
			#print("origin %s" % origin)
			#print("origin_local %s" % origin_local)
			#print("dir %s" % dir)
			#print("dir_local %s" % dir_local)

			var drag_to_local = MathUtil.intersect_plane(origin_local, dir_local, block_drag_start_local, Vector3.UP)
			#print("drag_to_local %s" % drag_to_local)
			#print("start_pos_local %s" % start_pos_local)
			
			var grid_step_size:float = pow(2, active_brushes.grid_size)
			drag_to_local = MathUtil.snap_to_grid(drag_to_local, grid_step_size)
			
			var global_scene:CyclopsGlobalScene = builder.get_node("/root/CyclopsAutoload")
			global_scene.draw_rect(block_drag_start_local, drag_to_local)
	
	return false
	#return EditorPlugin.AFTER_GUI_INPUT_STOP if true else EditorPlugin.AFTER_GUI_INPUT_PASS


