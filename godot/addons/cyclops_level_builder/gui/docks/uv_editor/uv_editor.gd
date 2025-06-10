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
extends Node2D
class_name UvEditor

#signal forward_input(event:InputEvent)
signal proj_transform_changed(xform:Transform2D)
signal subdivisions_changed(value:Vector2)
signal subdivisions_offset_changed(value:Vector2)

var subdivisions:Vector2 = Vector2(.1, .1):
	set(v):
		if v == subdivisions:
			return
		subdivisions = v
		
		subdivisions_changed.emit(v)
		queue_redraw()
		#property_changed.emit("subdivisions", v)

var subdivisions_offset:Vector2:
	set(v):
		if v == subdivisions_offset:
			return
		subdivisions_offset = v
		
		subdivisions_offset_changed.emit(v)
		queue_redraw()

@export var face_sel_color:Color = Color(1, .5, 0, .4):
	set(value):
		face_sel_color = value
		queue_redraw()
	
@export var face_unsel_color:Color = Color(.5, .5, .5, .4):
	set(value):
		face_sel_color = value
		queue_redraw()

@export var edge_sel_color:Color = Color(1, .5, 0, 1):
	set(value):
		edge_sel_color = value
		queue_redraw()
		
@export var edge_unsel_color:Color = Color(.5, .5, .5, 1):
	set(value):
		edge_unsel_color = value
		queue_redraw()
	
@export var outline_color:Color = Color(0, 0, 0, 1):
	set(value):
		outline_color = value
		queue_redraw()
		
@export var edge_width:float = 2:
	set(value):
		edge_width = value
		queue_redraw()
	
@export var vertex_radius:float = 2:
	set(value):
		vertex_radius = value
		queue_redraw()

@export var proj_transform:Transform2D = Transform2D(0, Vector2(100, 100), 0, Vector2.ZERO):
	set(value):
		proj_transform = value
		
		proj_transform_changed.emit(value)
		
		queue_redraw()

var pivot_cursor_position:Vector2
		
##Selecting a UV feature will also select the coresponding mesh 
## feature.  Also will display entire uv mesh instead of just 
## selected features
@export var sync_selection:bool:
	set(value):
		sync_selection = value
		queue_redraw()

@export var block_nodes:Array[CyclopsBlock]:
	set(value):
		#print("uv_editor setting block nodes ", value.size() )
		for node in block_nodes:
			if is_instance_valid(node):
				node.mesh_changed.disconnect(on_node_mesh_changed)
			
		block_nodes = value
		
		for node in block_nodes:
			if is_instance_valid(node):
				node.mesh_changed.connect(on_node_mesh_changed)
			
		if is_node_ready():
			rebuild_handles()
		queue_redraw()
		
var block_edit_handles:Dictionary #[nodePath, UvEditingState]

enum SelectFeature { VERTEX, EDGE, FACE }
@export var select_feature:SelectFeature = SelectFeature.VERTEX:
	set(value):
		select_feature = value
		queue_redraw()

enum StickyState { DISABLED, SHARED_LOCATION, SHARED_VERTEX }
@export var sticky_state:StickyState = StickyState.SHARED_LOCATION:
	set(value):
		sticky_state = value
		queue_redraw()

@export var uv_map:String:
	set(value):
		uv_map = value
		queue_redraw()

@export var select_margin:float = 4

@export var show_selection_rect:bool:
	set(value):
		show_selection_rect = value
		queue_redraw()

@export var selection_rect:Rect2:
	set(value):
		selection_rect = value
		queue_redraw()

@export var selection_rect_border_color:Color = Color(.5, .5, 1, 1)
@export var selection_rect_fill_color:Color = Color(.5, .5, 1, .2)

var gizmo_list:Array[Gizmo2D]

func _ready() -> void:
	rebuild_handles()
	pass

func _process(delta: float) -> void:
	var uv_to_vp_xform:Transform2D = get_uv_to_viewport_xform()
	%pivot_cursor.position = uv_to_vp_xform * pivot_cursor_position

func add_gizmo(gizmo:Gizmo2D):
	%gizmo_area.add_child(gizmo)
	gizmo_list.append(gizmo)

func on_node_mesh_changed(node:Node3D):
	block_edit_handles.clear()
	
	rebuild_block_handles(node)

func rebuild_handles():
	for block in block_nodes:
		rebuild_block_handles(block)

func rebuild_block_handles(block:CyclopsBlock):
	var mvd:MeshVectorData = block.mesh_vector_data
	var cv:ConvexVolume = ConvexVolume.new()
	cv.init_from_mesh_vector_data(mvd)
	
	var state:UvEditingState = UvEditingState.new()
	
	for f:ConvexVolume.FaceInfo in cv.faces:
		var h_f:HandleUvFace = HandleUvFace.new()
		h_f.object_path = block.get_path()
		h_f.face_index = f.index
		
		state.handle_faces.append(h_f)
		
		for e in f.get_edges():
			var h_e:HandleUvEdge = HandleUvEdge.new()
			h_e.object_path = block.get_path()
			h_e.face_index = f.index
			h_e.edge_index = e.index
			
			state.handle_edges.append(h_e)
		
		for v_idx in f.vertex_indices:
			var h_v:HandleUvVertex = HandleUvVertex.new()
			h_v.object_path = block.get_path()
			h_v.face_index = f.index
			h_v.vertex_index = v_idx
			
			state.handle_vertices.append(h_v)
	
	block_edit_handles[block.get_path()] = state
	
	queue_redraw()

func pick_uv_vertices(cv:ConvexVolume, region:Rect2, uv_map_name:String)->PackedInt32Array:
	var result:PackedInt32Array
	
	for f:ConvexVolume.FaceInfo in cv.faces:
		for fv_idx:int in f.face_vertex_indices:
			var fv:ConvexVolume.FaceVertexInfo = cv.face_vertices[fv_idx]
			if region.has_point(fv.uv0):
				result.append(fv_idx)
				
	return result

func pick_uv_edges(cv:ConvexVolume, region:Rect2, uv_map_name:String)->Array[HandleUvEdge]:
	var result:Array[HandleUvEdge]
	
	for f:ConvexVolume.FaceInfo in cv.faces:
		var edges = f.get_edges()
		for e:ConvexVolume.EdgeInfo in edges:
			var v0_idx:int = e.start_index
			var v1_idx:int = e.end_index
			
			var fv0:ConvexVolume.FaceVertexInfo = cv.get_face_vertex(f.index, v0_idx)
			var fv1:ConvexVolume.FaceVertexInfo = cv.get_face_vertex(f.index, v1_idx)
			
			if MathUtil.intersects_2d_segment_region(fv0.uv0, fv1.uv1, region):
				var h:HandleUvEdge = HandleUvEdge.new()
				h.edge_index = e.index
				h.face_index = f.index
				
			pass
			
	return result


func draw_vertex(p0:Vector2, selected:bool):
	var fill_color = edge_sel_color if selected else edge_unsel_color
	
	draw_circle(p0, vertex_radius, fill_color, true)
	draw_circle(p0, vertex_radius, outline_color, false)

func draw_edge(p0:Vector2, p1:Vector2, selected:bool):
	var fill_color = edge_sel_color if selected else edge_unsel_color
	
	var span:Vector2 = p1 - p0
	var perp:Vector2 = Vector2(span.y, -span.x).normalized() * edge_width / 2

	var points:PackedVector2Array = [
		p0 + perp, p1 + perp, p1 - perp, p0 - perp, p0 + perp
		]

	draw_colored_polygon(points, fill_color)
	draw_polyline(points, outline_color)

func get_view_transform()->Transform2D:
	var view_rect:Rect2 = get_viewport_rect()
	return Transform2D(0, Vector2(1, -1), 0, view_rect.get_center())

func get_uv_to_viewport_xform()->Transform2D:
	return get_view_transform() * proj_transform

func set_uv_to_viewport_xform(xform:Transform2D):
	var v:Transform2D = get_view_transform()
	v = v.affine_inverse()

	proj_transform = v * xform

func draw_uv_mesh(mesh_face_selection_only:bool, draw_vertices:bool, draw_face_centers:bool):
	#Edges and faces are considered selected if all member vertices are selected
	var xform:Transform2D = get_uv_to_viewport_xform()
	
	var verts_sel:PackedVector2Array
	var verts_unsel:PackedVector2Array
	var edges_sel:PackedVector2Array
	var edges_unsel:PackedVector2Array
	
	for block in block_nodes:
		var mvd:MeshVectorData = block.mesh_vector_data
		var cv:ConvexVolume = ConvexVolume.new()
		cv.init_from_mesh_vector_data(mvd)
		
		for f:ConvexVolume.FaceInfo in cv.faces:
			if mesh_face_selection_only:
				if !f.is_selected():
					continue
			
			var face_points:PackedVector2Array
			var face_center:Vector2
			for fv_local_idx in f.face_vertex_indices.size():
				var fv_idx:int = f.face_vertex_indices[fv_local_idx]
				var fv:ConvexVolume.FaceVertexInfo = cv.face_vertices[fv_idx]
				var uv:Vector2 = xform * fv.uv0
				face_points.append(uv)
				face_center += uv
				
				if fv.selected:
					verts_sel.append(uv)
				else:
					verts_unsel.append(uv)
			
			face_center /= f.face_vertex_indices.size()
			
			for i in f.face_vertex_indices.size():
				var fv0_idx:int = f.face_vertex_indices[i]
				var fv1_idx:int = f.face_vertex_indices[wrap(i + 1, 0, f.face_vertex_indices.size())]
				var fv0:ConvexVolume.FaceVertexInfo = cv.face_vertices[fv0_idx]
				var fv1:ConvexVolume.FaceVertexInfo = cv.face_vertices[fv1_idx]

				var uv0:Vector2 = xform * fv0.uv0
				var uv1:Vector2 = xform * fv1.uv0
				
				if fv0.selected && fv1.selected:
					edges_sel.append(uv0)
					edges_sel.append(uv1)
				else:
					edges_unsel.append(uv0)
					edges_unsel.append(uv1)
			
			if f.is_selected_uv_map():
				draw_colored_polygon(face_points, face_sel_color)
				if draw_face_centers: 
					draw_vertex(face_center, true)
			else:
				draw_colored_polygon(face_points, face_unsel_color)
				if draw_face_centers:
					draw_vertex(face_center, false)

	for i in range(0, edges_unsel.size(), 2):
		draw_edge(edges_unsel[i], edges_unsel[i + 1], false)
	for i in range(0, edges_sel.size(), 2):
		draw_edge(edges_sel[i], edges_sel[i + 1], true)

	if draw_vertices:
		for uv in verts_unsel:
#			print("unsel vert ", uv)
			draw_vertex(uv, false)
		for uv in verts_sel:
#			print("sel vert ", uv)
			draw_vertex(uv, true)

func draw_image_underlay(tex:Texture2D):
	var view_rect:Rect2 = get_viewport_rect()
	var uv_to_view_xform:Transform2D = get_uv_to_viewport_xform()
	var view_to_uv_xform:Transform2D = uv_to_view_xform.affine_inverse()
	
	var p00_uv = view_to_uv_xform * view_rect.position
	var p11_uv = view_to_uv_xform * view_rect.end
	
	var points:PackedVector2Array = [
		view_rect.position,
		Vector2(view_rect.position.x, view_rect.end.y),
		view_rect.end,
		Vector2(view_rect.end.x, view_rect.position.y),
		]
	var colors:PackedColorArray = [Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE]
	var uvs:PackedVector2Array = [
		p00_uv,
		Vector2(p00_uv.x, p11_uv.y),
		p11_uv,
		Vector2(p11_uv.x, p00_uv.y),
	]
	draw_polygon(points, colors, uvs, tex)
	
func draw_material_underlay():
	if block_nodes.is_empty():
		return
	
	var mvd:MeshVectorData = block_nodes[0].mesh_vector_data
	if mvd.active_face != -1:
		var vec:DataVectorInt = mvd.get_face_data(MeshVectorData.F_MATERIAL_INDEX)
		var mat_idx:int = vec.get_value(mvd.active_face)
		if mat_idx != -1 && mat_idx < block_nodes[0].materials.size():
			var mat:Material = block_nodes[0].materials[mat_idx]
			if mat is StandardMaterial3D:
				if mat.albedo_texture:
					draw_image_underlay(mat.albedo_texture)
	
		

@export var min_grid_spacing:float = 16
@export var grid_color_major_axis:Color = Color.WHITE
@export var grid_width_major_axis:float = 2
@export var grid_color_major:Color = Color.GRAY
@export var grid_width_major:float = 1
@export var grid_color_minor:Color = Color(.7, .7, .7, .5)
@export var grid_width_minor:float = 1

@export var grid_font:Font = preload("res://addons/cyclops_level_builder/art/fonts/Roboto/Roboto-Regular.ttf")
@export var grid_font_size:float = 10

func draw_subdiv_grid():
#	var minor_grid_xform = Transform2D(0, Vector2(1 / subdivisions.x, 1 / subdivisions.y), 0, subdivisions_offset)
	var minor_grid_xform = Transform2D(0, subdivisions, 0, subdivisions_offset)
	
	var view_rect:Rect2 = get_viewport_rect()
	var uv_to_view_xform:Transform2D = get_uv_to_viewport_xform() * minor_grid_xform
	var view_to_uv_xform:Transform2D = uv_to_view_xform.affine_inverse()
	
	var p00_uv = view_to_uv_xform * view_rect.position
	var p11_uv = view_to_uv_xform * view_rect.end
	
	var view_to_uv_vector_xform = view_to_uv_xform
	view_to_uv_vector_xform.origin = Vector2.ZERO
	
	var min_uv_grid_spacing:Vector2 = view_to_uv_vector_xform * Vector2(min_grid_spacing, min_grid_spacing) * subdivisions
	
#	print("min_uv_grid_spacing  ", min_uv_grid_spacing)
	
	var grid_min_x:int = floor(p00_uv.x)
	var grid_max_x:int = ceil(p11_uv.x)
	var grid_min_y:int = floor(p11_uv.y) #xform flipped on vertical axis
	var grid_max_y:int = ceil(p00_uv.y) #xform flipped on vertical axis

	var skip_x:int = ceil(abs(min_uv_grid_spacing.x))
	var skip_y:int = ceil(abs(min_uv_grid_spacing.y))

	grid_min_x = floor(float(grid_min_x) / skip_x) * skip_x
	grid_min_y = floor(float(grid_min_y) / skip_y) * skip_y


	for line_idx:int in range(grid_min_x, grid_max_x + 1, max(skip_x, 1)):
		var pl0 = Vector2(line_idx, p00_uv.y)
		var pl1 = Vector2(line_idx, p11_uv.y)
		
		var plv0 = uv_to_view_xform * pl0
		var plv1 = uv_to_view_xform * pl1
		
		draw_dashed_line(plv0, plv1, grid_color_minor, grid_width_minor)

	for line_idx:int in range(grid_min_y, grid_max_y + 1, max(skip_y, 1)):
		var pl0 = Vector2(p00_uv.x, line_idx)
		var pl1 = Vector2(p11_uv.x, line_idx)
		
		var plv0 = uv_to_view_xform * pl0
		var plv1 = uv_to_view_xform * pl1

		draw_dashed_line(plv0, plv1, grid_color_minor, grid_width_minor)


func draw_grid():
	var view_rect:Rect2 = get_viewport_rect()
	var uv_to_view_xform:Transform2D = get_uv_to_viewport_xform()
	var view_to_uv_xform:Transform2D = uv_to_view_xform.affine_inverse()
	
	var p00_uv = view_to_uv_xform * view_rect.position
	var p11_uv = view_to_uv_xform * view_rect.end
	
	#print("p00_uv  ", p00_uv)
	#print("p11_uv  ", p11_uv)
	
	var view_to_uv_vector_xform = view_to_uv_xform
	view_to_uv_vector_xform.origin = Vector2.ZERO
	
	var min_uv_grid_spacing:Vector2 = view_to_uv_vector_xform * Vector2(min_grid_spacing, min_grid_spacing)
	
#	print("min_uv_grid_spacing  ", min_uv_grid_spacing)
	
	var grid_min_x:int = floor(p00_uv.x)
	var grid_max_x:int = ceil(p11_uv.x)
	var grid_min_y:int = floor(p11_uv.y) #xform flipped on vertical axis
	var grid_max_y:int = ceil(p00_uv.y) #xform flipped on vertical axis

	var skip_x:int = ceil(abs(min_uv_grid_spacing.x))
	var skip_y:int = ceil(abs(min_uv_grid_spacing.y))

	grid_min_x = floor(float(grid_min_x) / skip_x) * skip_x
	grid_min_y = floor(float(grid_min_y) / skip_y) * skip_y

	#print("grid_min_x ", grid_min_x)
	#print("grid_max_x ", grid_max_x)
	#print("grid_min_y ", grid_min_y)
	#print("grid_max_y ", grid_max_y)
	

	for line_idx:int in range(grid_min_x, grid_max_x + 1, max(skip_x, 1)):
		var pl0 = Vector2(line_idx, p00_uv.y)
		var pl1 = Vector2(line_idx, p11_uv.y)
		
		var plv0 = uv_to_view_xform * pl0
		var plv1 = uv_to_view_xform * pl1
		
		draw_line(plv0, 
			plv1, 
			grid_color_major_axis if line_idx == 0 else grid_color_major, 
			grid_width_major_axis if line_idx == 0 else grid_width_major)
			
		draw_string(grid_font, plv0 + Vector2(2, grid_font_size), str(line_idx), HORIZONTAL_ALIGNMENT_LEFT, 
			-1, grid_font_size)

	for line_idx:int in range(grid_min_y, grid_max_y + 1, max(skip_y, 1)):
		var pl0 = Vector2(p00_uv.x, line_idx)
		var pl1 = Vector2(p11_uv.x, line_idx)
		
		var plv0 = uv_to_view_xform * pl0
		var plv1 = uv_to_view_xform * pl1

		draw_line(plv0, 
			plv1, 
			grid_color_major_axis if line_idx == 0 else grid_color_major, 
			grid_width_major_axis if line_idx == 0 else grid_width_major)

		draw_string(grid_font, plv0 + Vector2(2, grid_font_size), str(line_idx), HORIZONTAL_ALIGNMENT_LEFT, 
			-1, grid_font_size)

func _draw() -> void:
	draw_material_underlay()
	
	draw_subdiv_grid()
	draw_grid()

	
	match select_feature:
		SelectFeature.VERTEX:
			if sync_selection:
				draw_uv_mesh(false, true, false)
			else:
				draw_uv_mesh(true, true, false)
		SelectFeature.EDGE:
			if sync_selection:
				draw_uv_mesh(false, false, false)
			else:
				draw_uv_mesh(true, false, false)
		SelectFeature.FACE:
			if sync_selection:
				draw_uv_mesh(false, true, true)
			else:
				draw_uv_mesh(true, true, true)
	
	if show_selection_rect:
		draw_rect(selection_rect, selection_rect_fill_color, true)
		draw_rect(selection_rect, selection_rect_border_color, false)

func get_uv_indices_in_region(region:Rect2, best_only:bool = false)->Dictionary:
	var result_blocks:Dictionary #NodePath-> PackedInt32Array
	
	var viewport_xform = get_uv_to_viewport_xform()
	
	for block in block_nodes:
		var result:PackedInt32Array
		var mvd:MeshVectorData = block.mesh_vector_data
		var cv:ConvexVolume = ConvexVolume.new()
		cv.init_from_mesh_vector_data(mvd)
		
		var best_dist:float = INF
		var pick_center:Vector2 = region.get_center()
		
		for f:ConvexVolume.FaceInfo in cv.faces:
			if !sync_selection:
				if !f.is_selected():
					continue
			
				match select_feature:
					SelectFeature.VERTEX:
						for fv_local_idx in f.face_vertex_indices.size():
							var fv_idx:int = f.face_vertex_indices[fv_local_idx]
							var fv:ConvexVolume.FaceVertexInfo = cv.face_vertices[fv_idx]
							var uv_screen:Vector2 = viewport_xform * fv.uv0
							
							if region.has_point(uv_screen):
								if best_only:
									var dist:float = uv_screen.distance_squared_to(pick_center)
									if dist < best_dist:
										best_dist = dist
										result.clear()
										result.append(fv.index)
								else:
									result.append(fv.index)
								
					SelectFeature.EDGE:
						for fv0_local_idx in f.face_vertex_indices.size():
							var fv1_local_idx:int = wrap(fv0_local_idx + 1, 0, f.face_vertex_indices.size())
							var fv0_idx:int = f.face_vertex_indices[fv0_local_idx]
							var fv1_idx:int = f.face_vertex_indices[fv1_local_idx]
							var fv0:ConvexVolume.FaceVertexInfo = cv.face_vertices[fv0_idx]
							var fv1:ConvexVolume.FaceVertexInfo = cv.face_vertices[fv1_idx]
							var uv0_screen:Vector2 = viewport_xform * fv0.uv0
							var uv1_screen:Vector2 = viewport_xform * fv1.uv0
							
							if MathUtil.intersects_2d_segment_region(uv0_screen, uv1_screen, region):
								if best_only:
									var dist:float = MathUtil.dist_to_segment_squared_2d(pick_center, uv0_screen, uv1_screen)
									if dist < best_dist:
										best_dist = dist
										result.clear()
										result.append(fv0.index)
										result.append(fv1.index)
										
								else:
									if !result.has(fv0.index):
										result.append(fv0.index)
									if !result.has(fv1.index):
										result.append(fv1.index)
					
					SelectFeature.FACE:
						var points:PackedVector2Array
						var uv_center:Vector2
						for fv_local_idx in f.face_vertex_indices.size():
							var fv_idx:int = f.face_vertex_indices[fv_local_idx]
							var fv:ConvexVolume.FaceVertexInfo = cv.face_vertices[fv_idx]
							var uv_screen:Vector2 = viewport_xform * fv.uv0
							uv_center += uv_screen
							points.append(uv_screen)
						
						uv_center /= f.face_vertex_indices.size()
						
						if MathUtil.intersects_2d_region_polygon(region, points):
							if best_only:
								var dist:float = uv_center.distance_squared_to(pick_center)
								if dist < best_dist:
									best_dist = dist
									result.clear()
									result.append_array(f.face_vertex_indices)
								
							else:
								result.append_array(f.face_vertex_indices)
		
		if !result.is_empty():
			result_blocks[block.get_path()] = result

	return result_blocks

	
	
