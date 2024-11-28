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

#@export var proj_transform:Transform2D = Transform2D.IDENTITY:
@export var proj_transform:Transform2D = Transform2D(0, Vector2(100, 100), 0, Vector2.ZERO):
	set(value):
		proj_transform = value
		queue_redraw()
		
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
			node.mesh_changed.disconnect(on_node_mesh_changed)
			
		block_nodes = value
		
		for node in block_nodes:
			node.mesh_changed.connect(on_node_mesh_changed)
			
		if is_node_ready():
			rebuild_handles()
		queue_redraw()
		
#var dirty:bool = true
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

#func _input(event: InputEvent) -> void:
	#print("uv_editor ", event)
	#forward_input.emit(event)
	#get_viewport().set_input_as_handled()
	#pass

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
			
		#for e_idx in f.edge_indices:
			#var h_e:HandleUvEdge = HandleUvEdge.new()
			#h_e.object_path = block.get_path()
			#h_e.face_index = f.index
			#h_e.edge_index = e_idx
			#
			#state.handle_edges.append(h_e)
		
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
#		for v_idx:int in f.vertex_indices:
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
			for fv_idx in f.face_vertex_indices.size():
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


func _ready() -> void:
	rebuild_handles()
	pass

func _draw() -> void:
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
	pass
