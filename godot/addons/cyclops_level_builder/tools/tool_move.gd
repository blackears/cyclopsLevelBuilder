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
extends CyclopsTool
class_name ToolMove

const TOOL_ID:String = "move"


enum ToolState { NONE, READY, MOVE_BLOCK, MOVE_BLOCK_CLICK, DRAG_SELECTION }
var tool_state:ToolState = ToolState.NONE

#enum MoveConstraint { NONE, AXIS_X, AXIS_Y, AXIS_Z, PLANE_XY, PLANE_XZ, PLANE_YZ, PLANE_VIEWPORT }
var move_constraint:MoveConstraint.Type = MoveConstraint.Type.NONE

#var viewport_camera_start:Camera3D
var event_start:InputEventMouseButton

var block_drag_cur:Vector3
var block_drag_p0:Vector3

var drag_select_start_pos:Vector2
var drag_select_to_pos:Vector2

var mouse_hover_pos:Vector2

#Keep a copy of move command here while we are building it
#var cmd_move_blocks:CommandMoveBlocks
var cmd_xform_blocks:CommandTransformBlocks

var base_points:PackedVector3Array

var gizmo_translate:GizmoTranslate

func _get_tool_id()->String:
	return TOOL_ID

func draw_gizmo(viewport_camera:Camera3D):
	var global_scene:CyclopsGlobalScene = builder.get_global_scene()
	if !gizmo_translate:
		gizmo_translate = preload("res://addons/cyclops_level_builder/tools/gizmos/gizmo_translate.tscn").instantiate()
	
	var blocks:Array[CyclopsBlock] = builder.get_selected_blocks()
	if blocks.is_empty():
		global_scene.set_custom_gizmo(null)
	else:
		var origin:Vector3
		for block in blocks:
			origin += block.global_transform.origin
		origin /= blocks.size()
		global_scene.set_custom_gizmo(gizmo_translate)
		gizmo_translate.global_transform.origin = origin


func _draw_tool(viewport_camera:Camera3D):
	var global_scene:CyclopsGlobalScene = builder.get_global_scene()
	global_scene.clear_tool_mesh()
	global_scene.draw_selected_blocks(viewport_camera)

	if tool_state == ToolState.DRAG_SELECTION:
		#print("draw sel %s " % drag_select_to_pos)
		global_scene.draw_screen_rect(viewport_camera, drag_select_start_pos, drag_select_to_pos, global_scene.selection_rect_material)

	draw_gizmo(viewport_camera)
	


func start_drag(viewport_camera:Camera3D, event:InputEvent):
	var blocks_root:Node = builder.get_block_add_parent()
	var e:InputEventMouseButton = event
	
	var origin:Vector3 = viewport_camera.project_ray_origin(e.position)
	var dir:Vector3 = viewport_camera.project_ray_normal(e.position)

	move_constraint = MoveConstraint.Type.NONE

	if gizmo_translate:
		var part_res:GizmoTranslate.IntersectResult = gizmo_translate.intersect(origin, dir, viewport_camera)
		if part_res:
			#print("Gizmo hit ", part_res.part)
			match part_res.part:
				GizmoTranslate.Part.AXIS_X:
					move_constraint = MoveConstraint.Type.AXIS_X
				GizmoTranslate.Part.AXIS_Y:
					move_constraint = MoveConstraint.Type.AXIS_Y
				GizmoTranslate.Part.AXIS_Z:
					move_constraint = MoveConstraint.Type.AXIS_Z
				GizmoTranslate.Part.PLANE_XY:
					move_constraint = MoveConstraint.Type.PLANE_XY
				GizmoTranslate.Part.PLANE_XZ:
					move_constraint = MoveConstraint.Type.PLANE_XZ
				GizmoTranslate.Part.PLANE_YZ:
					move_constraint = MoveConstraint.Type.PLANE_YZ
		
			var start_pos:Vector3 = part_res.pos_world
#			var grid_step_size:float = pow(2, builder.get_global_scene().grid_size)

			#block_drag_p0 = MathUtil.snap_to_grid(start_pos, grid_step_size)
			block_drag_p0 = builder.get_snapping_manager().snap_point(start_pos, SnappingQuery.new(viewport_camera))

	#		print("res obj %s" % result.object.get_path())
			var sel_blocks:Array[CyclopsBlock] = builder.get_selected_blocks()
			if !sel_blocks.is_empty():
				
				tool_state = ToolState.MOVE_BLOCK
				#print("Move block")
				
				cmd_xform_blocks = CommandTransformBlocks.new()
				cmd_xform_blocks.builder = builder
				cmd_xform_blocks.lock_uvs = builder.lock_uvs
				for child in sel_blocks:
					cmd_xform_blocks.add_block(child.get_path())

			return


	var result:IntersectResults = builder.intersect_ray_closest(origin, dir)
#	print("result %s" % result)
	
	if result:

		if e.alt_pressed:
			move_constraint = MoveConstraint.Type.AXIS_Y
		else:
			move_constraint = MoveConstraint.Type.PLANE_XZ

		var start_pos:Vector3 = result.get_world_position()			
		#var grid_step_size:float = pow(2, builder.get_global_scene().grid_size)

		#block_drag_p0 = MathUtil.snap_to_grid(start_pos, grid_step_size)
		block_drag_p0 = builder.get_snapping_manager().snap_point(start_pos, SnappingQuery.new(viewport_camera))
		
		#print("block_drag_p0 %s" % block_drag_p0)

#		print("res obj %s" % result.object.get_path())
		if builder.is_selected(result.object):
			
			tool_state = ToolState.MOVE_BLOCK
			
			cmd_xform_blocks = CommandTransformBlocks.new()
			cmd_xform_blocks.builder = builder
			cmd_xform_blocks.lock_uvs = builder.lock_uvs
			for child in builder.get_selected_blocks():
				cmd_xform_blocks.add_block(child.get_path())
			
			return
	
	tool_state = ToolState.DRAG_SELECTION
	drag_select_start_pos = e.position
	drag_select_to_pos = e.position
	

func _gui_input(viewport_camera:Camera3D, event:InputEvent)->bool:

	if event is InputEventKey:
		var e:InputEventKey = event
		
		if e.keycode == KEY_ESCAPE:
			if e.is_pressed():
				tool_state = ToolState.NONE
				if cmd_xform_blocks:
					cmd_xform_blocks.undo_it()
					cmd_xform_blocks = null
					
			return true

		elif e.keycode == KEY_G:
			if e.is_pressed() && tool_state == ToolState.NONE:
				tool_state = ToolState.MOVE_BLOCK_CLICK
				move_constraint = MoveConstraint.Type.PLANE_VIEWPORT
#				block_drag_p0 = MathUtil.intersect_plane(origin, dir, block_drag_p0, viewport_camera.global_transform.basis.z)
#				block_drag_p0 = origin + dir * 20
				block_drag_p0 = Vector3.INF
				
				cmd_xform_blocks = CommandTransformBlocks.new()
				cmd_xform_blocks.builder = builder
				cmd_xform_blocks.lock_uvs = builder.lock_uvs
				for child in builder.get_selected_blocks():
					cmd_xform_blocks.add_block(child.get_path())
					
			return true

		elif e.keycode == KEY_X:
			if tool_state == ToolState.MOVE_BLOCK_CLICK:
				if e.shift_pressed:
					move_constraint = MoveConstraint.Type.PLANE_YZ
				else:
					move_constraint = MoveConstraint.Type.AXIS_X
			return true

		elif e.keycode == KEY_Y:
			if tool_state == ToolState.MOVE_BLOCK_CLICK:
				if e.shift_pressed:
					move_constraint = MoveConstraint.Type.PLANE_XZ
				else:
					move_constraint = MoveConstraint.Type.AXIS_Y
			return true

		elif e.keycode == KEY_Z:
			if tool_state == ToolState.MOVE_BLOCK_CLICK:
				if e.shift_pressed:
					move_constraint = MoveConstraint.Type.PLANE_XY
				else:
					move_constraint = MoveConstraint.Type.AXIS_Z
			return true

		if e.keycode == KEY_Q && e.alt_pressed:
			if e.is_pressed():
				var origin:Vector3 = viewport_camera.project_ray_origin(mouse_hover_pos)
				var dir:Vector3 = viewport_camera.project_ray_normal(mouse_hover_pos)
			
				var result:IntersectResults = builder.intersect_ray_closest(origin, dir)
				if result:
					var cmd:CommandSelectBlocks = CommandSelectBlocks.new()
					cmd.builder = builder
					cmd.block_paths.append(result.object.get_path())
					
					if cmd.will_change_anything():
						var undo:EditorUndoRedoManager = builder.get_undo_redo()
						cmd.add_to_undo_manager(undo)
						
						_deactivate()
						_activate(builder)
				
			return true
				
	elif event is InputEventMouseButton:
		
		var e:InputEventMouseButton = event
		if e.button_index == MOUSE_BUTTON_LEFT:

			if e.is_pressed():
				if tool_state == ToolState.NONE:
					event_start = event
					
					tool_state = ToolState.READY

				elif tool_state == ToolState.MOVE_BLOCK_CLICK:
					var undo:EditorUndoRedoManager = builder.get_undo_redo()
					cmd_xform_blocks.add_to_undo_manager(undo)
					
					tool_state = ToolState.NONE
				
			else:
				if tool_state == ToolState.READY:
					
					#We just clicked with the mouse
					var origin:Vector3 = viewport_camera.project_ray_origin(e.position)
					var dir:Vector3 = viewport_camera.project_ray_normal(e.position)

					var result:IntersectResults = builder.intersect_ray_closest(origin, dir)
					
					#print("Invokke select %s" % result)
					var cmd:CommandSelectBlocks = CommandSelectBlocks.new()
					cmd.builder = builder
					cmd.selection_type = Selection.choose_type(e.shift_pressed, e.ctrl_pressed)

					if result:
						cmd.block_paths.append(result.object.get_path())
						
					if cmd.will_change_anything():
						var undo:EditorUndoRedoManager = builder.get_undo_redo()
						cmd.add_to_undo_manager(undo)
					
					tool_state = ToolState.NONE

				elif tool_state == ToolState.MOVE_BLOCK:
					
					#Finish moving blocks
					var undo:EditorUndoRedoManager = builder.get_undo_redo()
					cmd_xform_blocks.add_to_undo_manager(undo)
					
					tool_state = ToolState.NONE

				elif tool_state == ToolState.DRAG_SELECTION:
					
					var frustum:Array[Plane] = MathUtil.calc_frustum_camera_rect(viewport_camera, drag_select_start_pos, drag_select_to_pos)
					
					var result:Array[CyclopsBlock] = builder.intersect_frustum_all(frustum)
					
					if !result.is_empty():
						
						var cmd:CommandSelectBlocks = CommandSelectBlocks.new()
						cmd.builder = builder
						cmd.selection_type = Selection.choose_type(e.shift_pressed, e.ctrl_pressed)

						for r in result:
							cmd.block_paths.append(r.get_path())
							
						if cmd.will_change_anything():
							var undo:EditorUndoRedoManager = builder.get_undo_redo()
							cmd.add_to_undo_manager(undo)
					
					tool_state = ToolState.NONE
				
			return true

		elif e.button_index == MOUSE_BUTTON_RIGHT:
			if e.is_pressed():
				#Right click cancel
				tool_state = ToolState.NONE
				if cmd_xform_blocks:
					cmd_xform_blocks.undo_it()
					cmd_xform_blocks = null
			
	elif event is InputEventMouseMotion:
		var e:InputEventMouseMotion = event
		
		mouse_hover_pos = e.position

		if (e.button_mask & MOUSE_BUTTON_MASK_MIDDLE):
			return super._gui_input(viewport_camera, event)

		var origin:Vector3 = viewport_camera.project_ray_origin(e.position)
		var dir:Vector3 = viewport_camera.project_ray_normal(e.position)
		
		#print("tool_state %s" % tool_state)
				
		if tool_state == ToolState.READY:
			var offset:Vector2 = e.position - event_start.position
			if offset.length_squared() > MathUtil.square(builder.drag_start_radius):
				start_drag(viewport_camera, event_start)

			return true
			
		elif tool_state == ToolState.MOVE_BLOCK || tool_state == ToolState.MOVE_BLOCK_CLICK:
			if !block_drag_p0.is_finite():
				block_drag_p0 = origin + dir * 20
			
			match move_constraint:
				MoveConstraint.Type.AXIS_X:
					block_drag_cur = MathUtil.closest_point_on_line(origin, dir, block_drag_p0, Vector3.RIGHT)
				MoveConstraint.Type.AXIS_Y:
					block_drag_cur = MathUtil.closest_point_on_line(origin, dir, block_drag_p0, Vector3.UP)
				MoveConstraint.Type.AXIS_Z:
					block_drag_cur = MathUtil.closest_point_on_line(origin, dir, block_drag_p0, Vector3.BACK)
				MoveConstraint.Type.PLANE_XY:
					block_drag_cur = MathUtil.intersect_plane(origin, dir, block_drag_p0, Vector3.BACK)
				MoveConstraint.Type.PLANE_XZ:
					block_drag_cur = MathUtil.intersect_plane(origin, dir, block_drag_p0, Vector3.UP)
				MoveConstraint.Type.PLANE_YZ:
					block_drag_cur = MathUtil.intersect_plane(origin, dir, block_drag_p0, Vector3.RIGHT)
				MoveConstraint.Type.PLANE_VIEWPORT:
					block_drag_cur = MathUtil.intersect_plane(origin, dir, block_drag_p0, viewport_camera.global_transform.basis.z)
					
			#print("dragging move_constraint %s block_drag_cur %s" % [move_constraint, block_drag_cur])

			#var grid_step_size:float = pow(2, builder.get_global_scene().grid_size)
			#block_drag_cur = MathUtil.snap_to_grid(block_drag_cur, grid_step_size)
			block_drag_cur = builder.get_snapping_manager().snap_point(block_drag_cur, SnappingQuery.new(viewport_camera))
			
			#cmd_move_blocks.move_offset = block_drag_cur - block_drag_p0
			cmd_xform_blocks.transform = Transform3D(Basis.IDENTITY, block_drag_cur - block_drag_p0)
			#print("cmd_move_blocks.move_offset %s" % cmd_move_blocks.move_offset)
			cmd_xform_blocks.do_it()

			return true

		elif tool_state == ToolState.DRAG_SELECTION:
			drag_select_to_pos = e.position
			return true
			
	
	return super._gui_input(viewport_camera, event)		


func _activate(builder:CyclopsLevelBuilder):
	super._activate(builder)
	
	builder.mode = CyclopsLevelBuilder.Mode.OBJECT
	var global_scene:CyclopsGlobalScene = builder.get_global_scene()
	global_scene.clear_tool_mesh()

func _deactivate():
	var global_scene:CyclopsGlobalScene = builder.get_global_scene()
	global_scene.set_custom_gizmo(null)

