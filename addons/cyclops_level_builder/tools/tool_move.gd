@tool
extends CyclopsTool
class_name ToolMove

enum DragStyle { NONE, BLOCK_BASE, BLOCK_HEIGHT }
var drag_style:DragStyle = DragStyle.NONE
#enum State { READY, DRAG_BASE }
#var dragging:bool = false
var mouse_start:Vector2

var block_drag_cur:Vector3
var block_drag_p0_local:Vector3
var block_drag_p1_local:Vector3
var block_drag_p2_local:Vector3

func _gui_input(viewport_camera:Camera3D, event:InputEvent)->bool:	
	var active_brushes:GeometryBrushes = self.builder.active_node
	
	if event is InputEventMouseButton:
		var e:InputEventMouseButton = event
		if e.is_pressed():
			if drag_style == DragStyle.NONE:
				mouse_start = e.position
				
				var origin:Vector3 = viewport_camera.project_ray_origin(e.position)
				var dir:Vector3 = viewport_camera.project_ray_normal(e.position)

				var result = active_brushes.intersect_ray(origin, dir)
				if !result:
					drag_style = DragStyle.BLOCK_BASE
					var start_pos:Vector3 = origin + builder.block_create_distance * dir
					var w2l = active_brushes.global_transform.inverse()
					var start_pos_local:Vector3 = w2l * start_pos

					#print("start_pos %s" % start_pos)
					#print("start_pos_local %s" % start_pos_local)
					
					var grid_step_size:float = pow(2, active_brushes.grid_size)

					
					#print("start_pos_local %s" % start_pos_local)
					block_drag_p0_local = MathUtil.snap_to_grid(start_pos_local, grid_step_size)
					
					#print("block_drag_start_local %s" % block_drag_start_local)
				print("set 1 drag_style %s" % drag_style)
			
		else:
			if drag_style == DragStyle.BLOCK_BASE:
				block_drag_p1_local = block_drag_cur
				drag_style = DragStyle.BLOCK_HEIGHT
				
				print("set 2 drag_style %s" % drag_style)
				
			elif drag_style == DragStyle.BLOCK_HEIGHT:
				block_drag_p2_local = block_drag_cur
				drag_style = DragStyle.NONE
			
				print("set 3 drag_style %s" % drag_style)

		
		#print("pick origin %s " % origin)
			
		return  true
		
	elif event is InputEventMouseMotion:
		var e:InputEventMouseMotion = event

		var origin:Vector3 = viewport_camera.project_ray_origin(e.position)
		var dir:Vector3 = viewport_camera.project_ray_normal(e.position)
		
		var start_pos:Vector3 = origin + builder.block_create_distance * dir
		var w2l = active_brushes.global_transform.inverse()
		var origin_local:Vector3 = w2l * origin
		var dir_local:Vector3 = w2l.basis * dir
		
		print("drag_style %s" % drag_style)
		
		if drag_style == DragStyle.BLOCK_BASE:

			block_drag_cur = MathUtil.intersect_plane(origin_local, dir_local, block_drag_p0_local, Vector3.UP)
			
			var grid_step_size:float = pow(2, active_brushes.grid_size)
			block_drag_cur = MathUtil.snap_to_grid(block_drag_cur, grid_step_size)
			
			var global_scene:CyclopsGlobalScene = builder.get_node("/root/CyclopsAutoload")
			global_scene.draw_rect(block_drag_p0_local, block_drag_cur)

		elif drag_style == DragStyle.BLOCK_HEIGHT:
#			block_drag_cur = MathUtil.intersect_plane(origin_local, dir_local, block_drag_p0_local, Vector3.UP)
			block_drag_cur = MathUtil.closest_point_on_line(origin_local, dir_local, block_drag_p1_local, Vector3.UP)
			
			var grid_step_size:float = pow(2, active_brushes.grid_size)
			block_drag_cur = MathUtil.snap_to_grid(block_drag_cur, grid_step_size)
			
			var global_scene:CyclopsGlobalScene = builder.get_node("/root/CyclopsAutoload")
			global_scene.draw_cube(block_drag_p0_local, block_drag_p0_local, block_drag_cur)
	
	return false
	#return EditorPlugin.AFTER_GUI_INPUT_STOP if true else EditorPlugin.AFTER_GUI_INPUT_PASS


