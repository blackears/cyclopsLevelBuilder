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
extends RefCounted
class_name ConvexVolume


class VertexInfo extends RefCounted:
	var index:int
	var mesh:ConvexVolume
	var point:Vector3
	var normal:Vector3
	var edge_indices:Array[int] = []
	var selected:bool
	
	func _init(mesh:ConvexVolume, point:Vector3 = Vector3.ZERO):
		self.mesh = mesh
		self.point = point
		
	func _to_string():
		var s:String = "%s [" % [point]
		for i in edge_indices:
			s += "%s " %  i
		s += "]"
			
		return s

class EdgeInfo extends RefCounted:
	var index:int
	var mesh:ConvexVolume
	var start_index:int
	var end_index:int
	var face_indices:Array[int] = []
	var selected:bool
	var uv_seam:bool
	
	func _init(mesh:ConvexVolume, start:int = 0, end:int = 0):
		self.mesh = mesh
		start_index = start
		end_index = end

	func get_midpoint()->Vector3:
		var p0:Vector3 = mesh.vertices[start_index].point
		var p1:Vector3 = mesh.vertices[end_index].point
		return (p0 + p1) / 2
		
	func _to_string():
		var s:String = "%s %s [" % [start_index, end_index]
		for i in face_indices:
			s += "%s " % i
		s += "]"
		return s


class FaceInfo extends RefCounted:
	var index:int
	var mesh:ConvexVolume
	#@deprecated
	#var id:int
	var normal:Vector3 #Face normal points in direction of interior
	var material_id:int
	var uv_transform:Transform2D
	var color:Color
	var visible:bool
	var selected:bool
	#var selected_uv_face:bool
	var vertex_indices:Array[int]
	var face_vertex_indices:Array[int]
	var triangulation_indices:Array[int]
	var lightmap_uvs:PackedVector2Array
	
	func _init(mesh:ConvexVolume, normal:Vector3 = Vector3.UP, uv_transform:Transform2D = Transform2D.IDENTITY, material_id:int = 0, visible:bool = true, color:Color = Color.WHITE, selected:bool = false):
		self.mesh = mesh
		#self.id = id
		self.normal = normal
		self.material_id = material_id
		self.uv_transform = uv_transform
		self.selected = selected
		self.visible = visible
		self.color = color
	
	func is_selected():
		return selected
	
	func is_selected_uv_map():
		for fv_idx in face_vertex_indices:
			if !mesh.face_vertices[fv_idx].selected:
				return false
		return true
	
	func get_plane()->Plane:
		return Plane(normal, mesh.vertices[vertex_indices[0]].point)
	
	func get_edges()->Array[EdgeInfo]:
		var result:Array[EdgeInfo]
		for i:int in vertex_indices.size():
			var v0_idx:int = vertex_indices[i]
			var v1_idx:int = vertex_indices[wrap(i + 1, 0, vertex_indices.size())]
			
			var e = mesh.get_edge(v0_idx, v1_idx)
			result.append(e)
		return result
	
	func get_points()->PackedVector3Array:
		var result:PackedVector3Array
		for i in vertex_indices:
			result.append(mesh.vertices[i].point)
		return result
	
	func get_centroid()->Vector3:
		var points:PackedVector3Array = get_points()
		var center:Vector3
		for p in points:
			center += p
		center /= points.size()
		return center
	
	##Returns vector with magnitude equal to twice the area of the face and 
	## pointing along the face normal
	func get_area_vector_x2()->Vector3:
		var points:PackedVector3Array = get_points()
		return MathUtil.face_area_x2(points)
	
	func get_triangulation()->Array[int]:
		if triangulation_indices.is_empty():
			var points:PackedVector3Array
			for v_idx in vertex_indices:
				points.append(mesh.vertices[v_idx].point)

			triangulation_indices = MathUtil.trianglate_face_vertex_indices(points)

#			print("start points %s" % points)
				
#			var normal:Vector3 = MathUtil.face_area_x2(points).normalized()
#			print("normal %s" % normal)
#			triangulation_indices = MathUtil.trianglate_face_vertex_indices(points, normal)
#			print("triangulation %s" % str(triangulation_indices))
		
		return triangulation_indices
		
	func get_trianges()->PackedVector3Array:
		var indices:Array[int] = get_triangulation()
		var result:PackedVector3Array

		for fv_idx in indices:
			var v_idx:int = vertex_indices[fv_idx]
			result.append(mesh.vertices[v_idx].point)

		return result
		
	func get_trianges_v_idx()->PackedInt32Array:
		var indices:Array[int] = get_triangulation()
		var result:PackedInt32Array

		for fv_idx in indices:
			var v_idx:int = vertex_indices[fv_idx]
			result.append(v_idx)

		return result
	
	func reverse():
		normal = -normal
		vertex_indices.reverse()
		triangulation_indices.clear()
		
	#Vertex on face closest to given point
	func get_closest_vertex(point:Vector3)->int:
		var best_dist:float = -1
		var best_idx:int = -1
		for v_idx in vertex_indices:
			var v:VertexInfo = mesh.vertices[v_idx]
			var dist:float = v.point.distance_to(point)
			if best_idx == -1 || dist < best_dist:
				best_idx = v_idx
				best_dist = dist
				
		return best_idx
				
			

class FaceVertexInfo extends RefCounted:
	var index:int
	var mesh:ConvexVolume
	var face_index:int
	var vertex_index:int
	var vertex_local_index:int #Position of vertex within this face loop - eg, if this face has 5 verts, the local vert numbers are in order [0, 1, 2, 3, 4]
	var uv0:Vector2
	var color:Color = Color.WHITE
	var normal:Vector3
	var selected:bool
	#var selected_uv_edge:bool


var vertices:Array[VertexInfo] = []
var edges:Array[EdgeInfo] = []
var faces:Array[FaceInfo] = []
var face_vertices:Array[FaceVertexInfo] = []
var face_vertex_coord_map:Dictionary

var bounds:AABB

var lightmap_uvs_dirty = true

var active_vertex:int = -1
var active_edge:int = -1
var active_face:int = -1
var active_face_vertex:int = -1

func _to_string()->String:
	var result:String = ""
	for v in vertices:
		result += str(v.point) + ", "
	return result
	
func init_block(block_bounds:AABB, uv_transform:Transform2D = Transform2D.IDENTITY, material_id:int = -1, visible:bool = true, color:Color = Color.WHITE):
	var p000:Vector3 = block_bounds.position
	var p111:Vector3 = block_bounds.end
	var p001:Vector3 = Vector3(p000.x, p000.y, p111.z)
	var p010:Vector3 = Vector3(p000.x, p111.y, p000.z)
	var p011:Vector3 = Vector3(p000.x, p111.y, p111.z)
	var p100:Vector3 = Vector3(p111.x, p000.y, p000.z)
	var p101:Vector3 = Vector3(p111.x, p000.y, p111.z)
	var p110:Vector3 = Vector3(p111.x, p111.y, p000.z)
	
	init_prism([p000, p001, p011, p010], p100 - p000, uv_transform, material_id, visible, color)
	

func init_prism(base_points:Array[Vector3], extrude_dir:Vector3, uv_transform:Transform2D = Transform2D.IDENTITY, material_id:int = -1, visible:bool = true, color:Color = Color.WHITE):
	vertices = []
	edges = []
	faces = []
	face_vertices = []
	face_vertex_coord_map.clear()
	
	var base_normal = -extrude_dir.normalized()
	
	var face_area_x2:Vector3 = MathUtil.face_area_x2(base_points)
	if face_area_x2.dot(extrude_dir) > 0:
		base_points.reverse()
	
	for p in base_points:
		var v:VertexInfo = VertexInfo.new(self, p)
		v.index = vertices.size()
		vertices.append(v)
	for p in base_points:
		var v:VertexInfo = VertexInfo.new(self, p + extrude_dir)
		v.index = vertices.size()
		vertices.append(v)
	
	var f0:FaceInfo = FaceInfo.new(self, base_normal, uv_transform, material_id, visible, color)
	f0.index = faces.size()
	f0.vertex_indices = []
	f0.vertex_indices.append_array(range(base_points.size()))
	faces.append(f0)
	var f1:FaceInfo = FaceInfo.new(self, -base_normal, uv_transform, material_id, visible, color)
	f1.index = faces.size()
	f1.vertex_indices = []
	f1.vertex_indices.append_array(range(base_points.size(), base_points.size() * 2))
	f1.vertex_indices.reverse()
	faces.append(f1)
	

	for i in base_points.size():
		var p_idx0:int = i
		var p_idx1:int = wrap(i + 1, 0, base_points.size())
		
		var v0:VertexInfo = vertices[p_idx0]
		var v1:VertexInfo = vertices[p_idx1]
		
		var normal = base_normal.cross(v1.point - v0.point).normalized()
		var f:FaceInfo = FaceInfo.new(self, normal, uv_transform, material_id, visible, color)
		f.index = faces.size()
		f.vertex_indices = [p_idx1, p_idx0, p_idx0 + base_points.size(), p_idx1 + base_points.size()]
		faces.append(f)
	
	build_edges()
	build_face_vertices()
	calc_vertex_normals()
	
	bounds = calc_bounds()
	calc_lightmap_uvs()
	
func init_sphere(block_bounds:AABB, segments:int, rings:int, uv_transform:Transform2D = Transform2D.IDENTITY, material_id:int = -1, visible:bool = true, color:Color = Color.WHITE):
	vertices = []
	edges = []
	faces = []
	face_vertices = []
	face_vertex_coord_map.clear()
	
	var bounds_xform:Transform3D
	bounds_xform = bounds_xform.translated_local(block_bounds.position)
	bounds_xform = bounds_xform.scaled_local(block_bounds.size)
	bounds_xform = bounds_xform.translated_local(Vector3(.5, .5, .5))
	bounds_xform = bounds_xform.scaled_local(Vector3(.5, .5, .5))
	
	var angle_seg_increment:float = (PI * 2) / segments
	for r0_idx in range(1, rings):
#		print("r0_idx ", r0_idx)
		var latitude_angle:float = (float(r0_idx) / rings) * PI * 2 - PI
		var ring_height:float = sin(latitude_angle)
		var ring_radius:float= cos(latitude_angle)
		
#		var ring_height:float = (float(r0_idx) / rings) * 2 - 1
#		var ring_radius:float = sqrt(1 - ring_height * ring_height)
		
		for s0_idx in segments:
#			print("s0_idx ", s0_idx)

			var unit_sphere_pt:Vector3 = Vector3(
				sin(s0_idx * angle_seg_increment) * ring_radius, 
				ring_height, 
				cos(s0_idx * angle_seg_increment) * ring_radius)
			
			var v:VertexInfo = VertexInfo.new(self, bounds_xform * unit_sphere_pt)
			v.index = vertices.size()
			vertices.append(v)
			
	var v_bottom:VertexInfo = VertexInfo.new(self, bounds_xform * Vector3(0, -1, 0))
	v_bottom.index = vertices.size()
	vertices.append(v_bottom)

	var v_top:VertexInfo = VertexInfo.new(self, bounds_xform * Vector3(0, 1, 0))
	v_top.index = vertices.size()
	vertices.append(v_top)
	
#	print("added verts ", vertices.size())
	
	#Build middle rings
	for r0_idx in range(1, rings - 1):
		var r1_idx:int = r0_idx + 1
#		print("r0_idx ", r0_idx, " r1_idx ", r1_idx)
		
		for s0_idx in segments:
			var s1_idx:int = wrap(s0_idx + 1, 0, segments)
#			print("s0_idx ", s0_idx, " s1_idx ", s1_idx)
			
			var v00:VertexInfo = vertices[(r0_idx - 1) * segments + s0_idx]
			var v01:VertexInfo = vertices[(r0_idx - 1) * segments + s1_idx]
			var v10:VertexInfo = vertices[(r1_idx - 1) * segments + s0_idx]
			var v11:VertexInfo = vertices[(r1_idx - 1) * segments + s1_idx]
			
			var base_normal:Vector3 = (v01.point - v00.point).cross(v11.point - v00.point).normalized()
			var f:FaceInfo = FaceInfo.new(self, base_normal, uv_transform, material_id, visible, color)
			f.index = faces.size()
			f.vertex_indices = [
				v00.index,
				v10.index,
				v11.index,
				v01.index,
			]
#			print("f.vertex_indices ", f.vertex_indices)
			
			faces.append(f)

#	print("added face rings ", faces.size())
	
	#Bottom cap
	for s0_idx in segments:
		var s1_idx:int = wrap(s0_idx + 1, 0, segments)
		
		var v00:VertexInfo = vertices[s0_idx]
		var v01:VertexInfo = vertices[s1_idx]
		
		var base_normal:Vector3 = (v01.point - v_bottom.point).cross(v00.point - v_bottom.point).normalized()
		var f:FaceInfo = FaceInfo.new(self, base_normal, uv_transform, material_id, visible, color)
		f.index = faces.size()
		f.vertex_indices = [
			v_bottom.index,
			v00.index,
			v01.index,
		]

#		print("f.vertex_indices ", f.vertex_indices)
		faces.append(f)

#	print("added bottom cap ", faces.size())
	
	#Top cap
	for s0_idx in segments:
		var s1_idx:int = wrap(s0_idx + 1, 0, segments)
		
		var v00:VertexInfo = vertices[(rings - 2) * segments + s0_idx]
		var v01:VertexInfo = vertices[(rings - 2) * segments + s1_idx]
		
		var base_normal:Vector3 = (v00.point - v_top.point).cross(v01.point - v_top.point).normalized()
		var f:FaceInfo = FaceInfo.new(self, base_normal, uv_transform, material_id, visible, color)
		f.index = faces.size()
		f.vertex_indices = [
			v_top.index,
			v01.index,
			v00.index,
		]

#		print("f.vertex_indices ", f.vertex_indices)
		faces.append(f)

#	print("added top cap ", faces.size())

	build_edges()
	build_face_vertices()
	calc_vertex_normals()
	
#	print("extra calc")
	
	bounds = calc_bounds()

func init_from_convex_block_data(data:ConvexBlockData):
	#print("init_from_convex_block_data")
	#print(var_to_str(data))
	
	vertices = []
	edges = []
	faces = []
	face_vertices = []
	face_vertex_coord_map.clear()
	
	if !data:
		return
	#data.validate_arrays()

	active_vertex = data.active_vertex
	active_edge = data.active_edge
	active_face = data.active_face
	
	for i in data.vertex_points.size():
		var v:VertexInfo = VertexInfo.new(self, data.vertex_points[i])
		v.index = vertices.size()		
		vertices.append(v)
		v.selected = data.vertex_selected[i]

	var num_edges:int = data.edge_vertex_indices.size() / 2
	for i in num_edges:
		var edge:EdgeInfo = EdgeInfo.new(self, data.edge_vertex_indices[i * 2], data.edge_vertex_indices[i * 2 + 1])
		edge.index = edges.size()
		edges.append(edge)
		edge.face_indices.append(data.edge_face_indices[i * 2])
		edge.face_indices.append(data.edge_face_indices[i * 2 + 1])
		edge.selected = data.edge_selected[i]
		#edge.active = data.edge_active[i]
		
	#print("data.face_vertex_count ", data.face_vertex_count)
	var face_vertex_count:int = 0
	for face_idx in data.face_vertex_count.size():
		var num_verts:int = data.face_vertex_count[face_idx]
		var vert_indices:Array[int]
		var vert_points:PackedVector3Array
		for i in num_verts:
			var vert_idx:int = data.face_vertex_indices[face_vertex_count]
			vert_indices.append(vert_idx)
			vert_points.append(vertices[vert_idx].point)
			face_vertex_count += 1
		
		var normal = MathUtil.face_area_x2(vert_points).normalized()
		
		var face_uv_transform:Transform2D = data.face_uv_transform[face_idx]
		var face_mat_index:int = data.face_material_indices[face_idx]
		var face_visible:int = data.face_visible[face_idx]
		var face_color:Color = data.face_color[face_idx]
		var f:FaceInfo = FaceInfo.new(self, normal, face_uv_transform, face_mat_index, face_visible, face_color)
		f.index = faces.size()
		f.selected = data.face_selected[face_idx]
		#f.active = data.face_active[face_idx]
		f.vertex_indices = vert_indices
		
		faces.append(f)

	#print("faces buit ", faces.size())
	
	bounds = calc_bounds()
	calc_lightmap_uvs()
	
	#Rebuild face verticies if input data is erronious
	var all_zero:bool = true
	for f_idx in data.face_vertex_face_index:
		if f_idx != 0:
			all_zero = false
			break
	
	if data.face_vertex_face_index.size() == 0 || all_zero:
		#Face vertices not initialized - generate new ones
		build_face_vertices()
	else:
		for fv_idx in data.face_vertex_face_index.size():
			var f_idx:int = data.face_vertex_face_index[fv_idx]
			var v_idx:int = data.face_vertex_vertex_index[fv_idx]
			var fv:FaceVertexInfo = FaceVertexInfo.new()
			face_vertices.append(fv)
			#faces[f_idx].face_vertex_indices.append(fv_idx)
			
			var v:VertexInfo = vertices[v_idx]
			
			fv.face_index = f_idx
			fv.vertex_index = v_idx
			var coord:Vector2i = Vector2i(f_idx, v_idx)
			face_vertex_coord_map[coord] = fv
			
			var f:FaceInfo = faces[f_idx]
			fv.normal = data.face_vertex_normal[fv_idx] if data.face_vertex_normal.size() > fv_idx else f.normal
			fv.color = data.face_vertex_color[fv_idx] if data.face_vertex_color.size() > fv_idx else Color(1, 1, 1, 1)
			match (MathUtil.get_longest_axis(f.normal)):
				MathUtil.Axis.X:
					fv.uv0 = Vector2(-v.point.z, -v.point.y)
				MathUtil.Axis.Y:
					fv.uv0 = Vector2(-v.point.x, -v.point.z)
				MathUtil.Axis.Z:
					fv.uv0 = Vector2(-v.point.x, -v.point.y)
			fv.uv0 = data.face_uv_transform[f_idx] * fv.uv0
			
	#print("init_from_convex_block_data face_vertex_coord_map ", face_vertex_coord_map)
		for f_idx in faces.size():
			var face:FaceInfo = faces[f_idx]
			for v_idx in face.vertex_indices:
				face.face_vertex_indices.append(face_vertex_coord_map[Vector2i(f_idx, v_idx)].index)
				
	
	calc_vertex_normals()
	
	#print("init_from_convex_block_data %s" % format_faces_string())
	
func init_from_mesh_vector_data(mvd:MeshVectorData):
	vertices = []
	edges = []
	faces = []
	face_vertices = []
	face_vertex_coord_map.clear()
	bounds = AABB()
	
	if !mvd:
		return
	
	active_vertex = mvd.active_vertex
	active_edge = mvd.active_edge
	active_face = mvd.active_face
	active_face_vertex = mvd.active_face_vertex

	var v_pos:DataVectorFloat = mvd.get_vertex_data(MeshVectorData.V_POSITION)
	var vertex_points:PackedVector3Array = v_pos.to_vec3_array()

	bounds = MathUtil.calc_bounds(vertex_points)

	var v_normal:DataVectorFloat
	var vertex_normals:PackedVector3Array
	if mvd.has_vertex_data(MeshVectorData.V_NORMAL):
		v_normal = mvd.get_vertex_data(MeshVectorData.V_NORMAL)
		vertex_normals = v_normal.to_vec3_array()

	var v_sel:DataVectorByte = mvd.get_vertex_data(MeshVectorData.V_SELECTED)
	var vertex_selected:PackedByteArray = v_sel.data

	var e_sel:DataVectorByte = mvd.get_edge_data(MeshVectorData.E_SELECTED)
	var edge_selected:PackedByteArray = e_sel.data

	var e_uv_seam:DataVectorByte
	var edge_uv_seam:PackedByteArray
	if mvd.has_edge_data(MeshVectorData.E_UV_SEAM):
		e_uv_seam = mvd.get_edge_data(MeshVectorData.E_UV_SEAM)
		edge_uv_seam = e_uv_seam.data
	

	var f_mat:DataVectorInt = mvd.get_face_data(MeshVectorData.F_MATERIAL_INDEX)
	var face_material_indices:PackedInt32Array = f_mat.data
	
	var f_vis:DataVectorByte = mvd.get_face_data(MeshVectorData.F_VISIBLE)
	var face_visible:PackedByteArray = f_vis.data
	
	var f_sel:DataVectorByte = mvd.get_face_data(MeshVectorData.F_SELECTED)
	var face_selected:PackedByteArray = f_sel.data
	
	var f_normal:DataVectorFloat
	var face_normal:PackedVector3Array
	if mvd.has_face_data(MeshVectorData.F_NORMAL):
		f_normal = mvd.get_face_data(MeshVectorData.F_NORMAL)
		face_normal = f_normal.to_vec3_array()
	
	var f_uv_xform:DataVectorFloat
	var face_uv_transform:Array[Transform2D]
	if mvd.has_face_data(MeshVectorData.F_UV_XFORM):
		f_uv_xform = mvd.get_face_data(MeshVectorData.F_UV_XFORM)
		face_uv_transform = f_uv_xform.to_transform2d_array()
	
	var fv_fidx:DataVectorInt = mvd.get_face_vertex_data(MeshVectorData.FV_FACE_INDEX)
	var face_vertex_face_index:PackedInt32Array = fv_fidx.data
	
	var fv_vidx:DataVectorInt = mvd.get_face_vertex_data(MeshVectorData.FV_VERTEX_INDEX)
	var face_vertex_vertex_index:PackedInt32Array = fv_vidx.data
	
	var fv_norm:DataVectorFloat = mvd.get_face_vertex_data(MeshVectorData.FV_NORMAL)
	var face_vertex_normal:PackedVector3Array = fv_norm.to_vec3_array()
	
	var fv_col:DataVectorFloat = mvd.get_face_vertex_data(MeshVectorData.FV_COLOR)
	var face_vertex_color:PackedColorArray = fv_col.to_color_array()

	var fv_uv0:DataVectorFloat
	var face_vertex_uv0:PackedVector2Array
	if mvd.has_face_vertex_data(MeshVectorData.FV_UV0):	
		fv_uv0 = mvd.get_face_vertex_data(MeshVectorData.FV_UV0)
		face_vertex_uv0 = fv_uv0.to_vec2_array()

	var fv_selected:DataVectorByte
	var face_vertex_selected:PackedByteArray
	if mvd.has_face_vertex_data(MeshVectorData.FV_SELECTED):	
		fv_selected = mvd.get_face_vertex_data(MeshVectorData.FV_SELECTED)
		face_vertex_selected = fv_selected.data
	
	for i in mvd.num_vertices:
		var v:VertexInfo = VertexInfo.new(self)
		vertices.append(v)
		v.index = i
		
		v.point = vertex_points[i]
		v.selected = vertex_selected[i] != 0
		if v_normal:
			#Old models don't precalculate vertex normals
			v.normal = vertex_normals[i]
	
	for e_idx in mvd.num_edges:
		var edge:EdgeInfo = EdgeInfo.new(self, mvd.edge_vertex_indices[e_idx * 2], mvd.edge_vertex_indices[e_idx * 2 + 1])
		edges.append(edge)
		edge.index = edges.size()
		
		edge.face_indices.append(mvd.edge_face_indices[e_idx * 2])
		edge.face_indices.append(mvd.edge_face_indices[e_idx * 2 + 1])
		
		vertices[edge.start_index].edge_indices.append(e_idx)
		vertices[edge.end_index].edge_indices.append(e_idx)
		
		edge.selected = edge_selected[e_idx]
		if e_uv_seam:
			edge.uv_seam = edge_uv_seam[e_idx]
	
	#var fv_face_indices:PackedInt32Array
	#var fv_vertex_indices:PackedInt32Array
	var face_vertex_index_offset:int = 0
	for face_idx in mvd.num_faces:
		var num_verts:int = mvd.face_vertex_count[face_idx]
		var vert_indices:Array[int]
		for i in num_verts:
			var vert_idx:int = mvd.face_vertex_indices[face_vertex_index_offset + i]
			vert_indices.append(vert_idx)
			
			#fv_face_indices.append(face_idx)
			#fv_vertex_indices.append(vert_idx)
			
		face_vertex_index_offset += num_verts

		var f:FaceInfo = FaceInfo.new(self)
		faces.append(f)
		f.index = face_idx
		f.vertex_indices = vert_indices
		
		if !f_normal:
			#Older models don't have precomputed normals
			var vert_points:PackedVector3Array
			for vert_idx in vert_indices:
				vert_points.append(vertices[vert_idx].point)
			
			f.normal = MathUtil.face_area_x2(vert_points).normalized()
		else:
			f.normal = face_normal[face_idx]
		
		if f_uv_xform:
			#For now, save the transform from the older uv layout system
			f.uv_transform = face_uv_transform[face_idx]

		f.material_id = face_material_indices[face_idx]
		f.selected = face_selected[face_idx]
		f.visible = face_visible[face_idx]
		
		
	for fv_idx in mvd.num_face_vertices:
		var fv:FaceVertexInfo = FaceVertexInfo.new()
		face_vertices.append(fv)
		fv.index = fv_idx
		
		#fv.face_index = fv_face_indices[fv_idx]
		#fv.vertex_index = fv_vertex_indices[fv_idx]
		fv.face_index = face_vertex_face_index[fv_idx]
		fv.vertex_index = face_vertex_vertex_index[fv_idx]
#		fv.vertex_local_index = 
		
		var coord:Vector2i = Vector2i(fv.face_index, fv.vertex_index)
		face_vertex_coord_map[coord] = fv
		
		if face_vertex_normal.size() > 0:
			fv.normal = face_vertex_normal[fv_idx]

		if face_vertex_selected.size() > 0:
			fv.selected = face_vertex_selected[fv_idx]
			
		fv.color = face_vertex_color[fv_idx]
		if fv_uv0:
			fv.uv0 = face_vertex_uv0[fv_idx]
		else:
			#Old models need to be converted from uv_transform system
			var f:FaceInfo = faces[fv.face_index]
			var v:VertexInfo = vertices[fv.vertex_index]
			match (MathUtil.get_longest_axis(f.normal)):
				MathUtil.Axis.X:
					fv.uv0 = Vector2(-v.point.z, -v.point.y)
				MathUtil.Axis.Y:
					fv.uv0 = Vector2(-v.point.x, -v.point.z)
				MathUtil.Axis.Z:
					fv.uv0 = Vector2(-v.point.x, -v.point.y)
			fv.uv0 = f.uv_transform * fv.uv0

	
	for f_idx in faces.size():
		var face:FaceInfo = faces[f_idx]
		for v_idx in face.vertex_indices:
			face.face_vertex_indices.append(face_vertex_coord_map[Vector2i(f_idx, v_idx)].index)

	if !v_normal || face_vertex_normal.size() == 0:
		calc_vertex_normals()
	
	#Calculate edge -> neighbor faces map
	

#Calc convex hull bouding points
func init_from_points(points:PackedVector3Array, uv_transform:Transform2D = Transform2D.IDENTITY, material_id:int = -1, visible:bool = true, color:Color = Color.WHITE):
	vertices = []
	edges = []
	faces = []
	face_vertices = []
	face_vertex_coord_map.clear()

	#print("init_from_points %s" % points)
	var hull:QuickHull.Hull = QuickHull.quickhull(points)
	#print("hull %s" % hull.format_points())
	
	var hull_points:Array[Vector3] = hull.get_points()
	
	for p in hull_points:
		var v:VertexInfo = VertexInfo.new(self, p)
		v.index = vertices.size()
		vertices.append(v)
	
	for facet in hull.facets:
		var plane:Plane = facet.plane
		var vert_indices:Array[int] = []
		
		for p in facet.points:
			var vert_idx:int = hull_points.find(p)
			vert_indices.append(vert_idx)
		
		var f:FaceInfo = FaceInfo.new(self, plane.normal, uv_transform, material_id, visible, color)
		f.index = faces.size()
		f.vertex_indices = vert_indices
		faces.append(f)
	

	build_edges()
	build_face_vertices()
	calc_vertex_normals()
	
	bounds = calc_bounds()
	calc_lightmap_uvs()
	
func calc_vertex_normals(smooth:bool = false):
	#print("calc_vertex_normals ", _to_string())
	#print("calc_vertex_normals face_vertex_coord_map ", face_vertex_coord_map)
	
	for v_idx in vertices.size():
		var v:VertexInfo = vertices[v_idx]
		var weighted_normal:Vector3
		
		for face in faces:
			if face.vertex_indices.has(v_idx):
				weighted_normal += MathUtil.face_area_x2(face.get_points())
		
		v.normal = weighted_normal.normalized()

		#Calc face vertices
		for f_idx in faces.size():
			var face:FaceInfo = faces[f_idx]
			if face.vertex_indices.has(v_idx):
				var fv:FaceVertexInfo = face_vertex_coord_map[Vector2i(f_idx, v_idx)]
				fv.normal = v.normal if smooth else face.normal

func get_vertices_in_sphere(center:Vector3, radius:float)->Array[VertexInfo]:
	var result:Array[VertexInfo]
	for v in vertices:
		var dist2 = v.point.distance_squared_to(center)
		if dist2 <= radius * radius:
			result.append(v)
		
	return result

func get_edge(vert_idx0:int, vert_idx1:int)->EdgeInfo:
	for e in edges:
		if e.start_index == vert_idx0 && e.end_index == vert_idx1:
			return e
		if e.start_index == vert_idx1 && e.end_index == vert_idx0:
			return e
	return null

func get_face_vertex(face_idx:int, vertex_idx:int)->FaceVertexInfo:
	var coord:Vector2i = Vector2i(face_idx, vertex_idx)
	return face_vertex_coord_map[coord]

func build_face_vertices():
	#print("build_face_vertices")
	for f_idx in faces.size():
		var face:FaceInfo = faces[f_idx]
		for v_local_idx in face.vertex_indices.size():
			var v_idx = face.vertex_indices[v_local_idx]
			var vert:VertexInfo = vertices[v_idx]
			
			var fv:FaceVertexInfo = FaceVertexInfo.new()
			var fv_idx:int = face_vertices.size()
			face_vertices.append(fv)
			var coord:Vector2i = Vector2i(f_idx, v_idx)
			#print("Storing fv ", coord)
			face_vertex_coord_map[coord] = fv
			fv.index = fv_idx
			fv.mesh = self
			fv.face_index = f_idx
			fv.vertex_index = v_idx
			fv.vertex_local_index = v_local_idx
			fv.color = face.color
			
			match (MathUtil.get_longest_axis(face.normal)):
				MathUtil.Axis.X:
					fv.uv0 = Vector2(-vert.point.z, -vert.point.y)
				MathUtil.Axis.Y:
					fv.uv0 = Vector2(-vert.point.x, -vert.point.z)
				MathUtil.Axis.Z:
					fv.uv0 = Vector2(-vert.point.x, -vert.point.y)
			fv.uv0 = face.uv_transform * fv.uv0
			
			face.face_vertex_indices.append(fv_idx)

func build_edges():
	
#	print("build_edges()")
			
	#Calculate edges
	for face in faces:
#		print("face idx ", face.index)
		
		var num_corners = face.vertex_indices.size()
		for i0 in num_corners:
			var i1:int = wrap(i0 + 1, 0, num_corners)
			var v0_idx:int = face.vertex_indices[i0]
			var v1_idx:int = face.vertex_indices[i1]
	
#			print("v0_idx ", v0_idx, " v1_idx ", v1_idx)
			
			var edge:EdgeInfo = get_edge(v0_idx, v1_idx)
			if !edge:
#				print("miss")
				var edge_idx = edges.size()
				edge = EdgeInfo.new(self, v0_idx, v1_idx)
				edge.index = edges.size()
				edges.append(edge)
			
				var v0:VertexInfo = vertices[v0_idx]
				v0.edge_indices.append(edge_idx)
				
				var v1:VertexInfo = vertices[v1_idx]
				v1.edge_indices.append(edge_idx)

			edge.face_indices.append(face.index)

func get_face_coincident_with_plane(plane:Plane)->FaceInfo:
	for f in faces:
		var p:Plane = f.get_plane()
		if p.is_equal_approx(plane):
			return f
	return null

func get_face_indices(selected_only:bool = false)->PackedInt32Array:
	var result:PackedInt32Array
	for f_idx in faces.size():
		var f:FaceInfo = faces[f_idx]
		if !selected_only || f.selected:
			result.append(f_idx)
	return result

func get_trimesh_indices()->PackedInt32Array:
	var result:PackedInt32Array
	
	for f in faces:
		for fv_idx in f.get_triangulation():
			var v_idx:int = f.vertex_indices[fv_idx]
			result.append(v_idx)
	
	return result

func get_face_most_similar_to_plane(plane:Plane)->FaceInfo:
	var best_dot:float = -1
	var best_face:FaceInfo
	
	for f in faces:
		var p:Plane = f.get_plane()
		var dot = p.normal.dot(plane.normal)
		if dot >= best_dot:
			best_dot = dot
			best_face = f
	return best_face

func get_vertex_at_position(point:Vector3)->VertexInfo:
	for v in vertices:
		if v.point.is_equal_approx(point):
			return v
	return null

func get_edge_at_position(point:Vector3)->EdgeInfo:
	for e in edges:
		if e.get_midpoint().is_equal_approx(point):
			return e
	return null

func get_face_at_position(point:Vector3)->FaceInfo:
	for f in faces:
		if f.get_centroid().is_equal_approx(point):
			return f
	return null

func copy_vertex_attributes(ref_vol:ConvexVolume):
	for v_idx in vertices.size():
		var v:VertexInfo = vertices[v_idx]
		var ref_v:VertexInfo = ref_vol.get_vertex_at_position(v.point)
		if ref_v:
			v.selected = ref_v.selected

func copy_face_attributes(ref_vol:ConvexVolume):
	for f_idx in faces.size():
		var f:FaceInfo = faces[f_idx]
		var ref_face:FaceInfo = ref_vol.get_face_most_similar_to_plane(f.get_plane())
		
		f.material_id = ref_face.material_id
		f.uv_transform = ref_face.uv_transform
		f.visible = ref_face.visible
		f.color = ref_face.color
		f.selected = ref_face.selected

		#Copy face vertex values	
		for v_local_idx in f.vertex_indices.size():
			var v_idx:int = f.vertex_indices[v_local_idx]
			var v:VertexInfo = vertices[v_idx]
			var fv:FaceVertexInfo = face_vertex_coord_map[Vector2i(f_idx, v_idx)]

			var v_idx_ref:int = ref_face.get_closest_vertex(v.point)

			var fv_ref:FaceVertexInfo = ref_vol.face_vertex_coord_map[Vector2i(ref_face.index, v_idx_ref)]
			
			fv.normal = fv_ref.normal
			fv.color = fv_ref.color
			fv.uv0 = fv_ref.uv0

func to_convex_block_data()->ConvexBlockData:
	var result:ConvexBlockData = ConvexBlockData.new()
	
	result.active_vertex = active_vertex
	result.active_edge = active_edge
	result.active_face = active_face
	result.active_face_vertex = active_face_vertex
	
	for v in vertices:
		result.vertex_points.append(v.point)
		result.vertex_selected.append(v.selected)
		#result.vertex_active.append(v.active)

	for e in edges:
		result.edge_vertex_indices.append_array([e.start_index, e.end_index])
		result.edge_face_indices.append_array([e.face_indices[0], e.face_indices[1]])
		result.edge_selected.append(e.selected)
		#result.edge_active.append(e.active)
	
	for face in faces:
		var num_verts:int = face.vertex_indices.size()
		result.face_vertex_count.append(num_verts)
		result.face_vertex_indices.append_array(face.vertex_indices)
		#result.face_ids.append(face.id)
		result.face_selected.append(face.selected)
		#result.face_active.append(face.active)
		result.face_material_indices.append(face.material_id)
		result.face_uv_transform.append(face.uv_transform)
		result.face_visible.append(face.visible)
		result.face_color.append(face.color)
	
	for fv_idx in face_vertices.size():
		var fv:FaceVertexInfo = face_vertices[fv_idx]
		#print("to_convex_block_data fv ", fv.face_index, " ", fv.vertex_index)
		result.face_vertex_face_index.append(fv.face_index)
		result.face_vertex_vertex_index.append(fv.vertex_index)
		result.face_vertex_normal.append(fv.normal)
		result.face_vertex_color.append(fv.color)
	
	return result

func to_mesh_vector_data()->MeshVectorData:
	#var mvd:MeshVectorData = MeshVectorData.new()
	#var block_data:ConvexBlockData = to_convex_block_data()
	#mvd.create_from_convex_block(block_data)
	#return mvd

	var mvd:MeshVectorData = MeshVectorData.new()
	
	mvd.active_vertex = active_vertex
	mvd.active_edge = active_edge
	mvd.active_face = active_face
	mvd.active_face_vertex = active_face_vertex
	
	mvd.num_vertices = vertices.size()
	mvd.num_edges = edges.size()
	mvd.num_faces = faces.size()
	mvd.num_face_vertices = face_vertices.size()
	
	var vertex_points:PackedVector3Array
	var vertex_normals:PackedVector3Array
	var vertex_selected:PackedByteArray
	for v:VertexInfo in vertices:
		vertex_points.append(v.point)
		vertex_normals.append(v.normal)
		vertex_selected.append(v.selected)
		
	mvd.set_vertex_data(MeshVectorData.V_POSITION, DataVectorFloat.new(
		vertex_points.to_byte_array().to_float32_array(), 
		DataVector.DataType.VECTOR3))
	mvd.set_vertex_data(MeshVectorData.V_NORMAL, DataVectorFloat.new(
		vertex_normals.to_byte_array().to_float32_array(),
		DataVector.DataType.VECTOR3))
	mvd.set_vertex_data(MeshVectorData.V_SELECTED, DataVectorByte.new(
		vertex_selected,
		DataVector.DataType.BOOL))
	
	var edge_selected:PackedByteArray
	var edge_uv_seam:PackedByteArray
	var edge_vertex_indices:PackedInt32Array
	var edge_face_indices:PackedInt32Array
	for e:EdgeInfo in edges:
		edge_selected.append(e.selected)
		edge_uv_seam.append(e.uv_seam)
		
		edge_vertex_indices.append(e.start_index)
		edge_vertex_indices.append(e.end_index)
		edge_face_indices.append(e.face_indices[0])
		edge_face_indices.append(e.face_indices[1])
		
	mvd.set_edge_data(MeshVectorData.E_SELECTED, DataVectorByte.new(
		edge_selected,
		DataVector.DataType.BOOL))
	mvd.set_edge_data(MeshVectorData.E_UV_SEAM, DataVectorByte.new(
		edge_uv_seam,
		DataVector.DataType.BOOL))
	mvd.edge_vertex_indices = edge_vertex_indices
	mvd.edge_face_indices = edge_face_indices
		
	var face_selected:PackedByteArray
	var face_visible:PackedByteArray
	var face_mat_id:PackedInt32Array
	var face_normal:PackedVector3Array
	var face_vertex_count:PackedInt32Array
	var face_vertex_indices:PackedInt32Array

#@export var face_vertex_count:PackedInt32Array #Number of verts in each face
#@export var face_vertex_indices:PackedInt32Array #Vertex index per face
	
	for f:FaceInfo in faces:
		face_selected.append(f.selected)
		face_visible.append(f.visible)
		face_mat_id.append(f.material_id)
		face_normal.append(f.normal)
		
		face_vertex_count.append(f.vertex_indices.size())
		face_vertex_indices.append_array(f.vertex_indices)

	mvd.face_vertex_count = face_vertex_count
	mvd.face_vertex_indices = face_vertex_indices

	mvd.set_face_data(MeshVectorData.F_SELECTED, DataVectorByte.new(
		face_selected,
		DataVector.DataType.BOOL))
	mvd.set_face_data(MeshVectorData.F_VISIBLE, DataVectorByte.new(
		face_visible,
		DataVector.DataType.BOOL))
	mvd.set_face_data(MeshVectorData.F_NORMAL, DataVectorFloat.new(
		face_normal.to_byte_array().to_float32_array(),
		DataVector.DataType.VECTOR3))
	mvd.set_face_data(MeshVectorData.F_MATERIAL_INDEX, DataVectorInt.new(
		face_mat_id.to_byte_array().to_int32_array(),
		DataVector.DataType.INT))
	
	var face_vertex_face_index:PackedInt32Array
	var face_vertex_vertex_index:PackedInt32Array
	var face_vertex_normal:PackedVector3Array
	var face_vertex_selected:PackedByteArray
	var face_vertex_color:PackedFloat32Array
	var face_vertex_uv0:PackedVector2Array
	for fv:FaceVertexInfo in face_vertices:
		face_vertex_face_index.append(fv.face_index)
		face_vertex_vertex_index.append(fv.vertex_index)
		face_vertex_normal.append(fv.normal)
		face_vertex_selected.append(fv.selected)
		face_vertex_color.append(fv.color.r)
		face_vertex_color.append(fv.color.g)
		face_vertex_color.append(fv.color.b)
		face_vertex_color.append(fv.color.a)
		face_vertex_uv0.append(fv.uv0)
	
	mvd.set_face_vertex_data(MeshVectorData.FV_FACE_INDEX, DataVectorInt.new(
		face_vertex_face_index.to_byte_array().to_int32_array(),
		DataVector.DataType.INT))
	mvd.set_face_vertex_data(MeshVectorData.FV_VERTEX_INDEX, DataVectorInt.new(
		face_vertex_vertex_index.to_byte_array().to_int32_array(),
		DataVector.DataType.INT))
	mvd.set_face_vertex_data(MeshVectorData.FV_NORMAL, DataVectorFloat.new(
		face_vertex_normal.to_byte_array().to_float32_array(),
		DataVector.DataType.VECTOR3))
	mvd.set_face_vertex_data(MeshVectorData.FV_SELECTED, DataVectorByte.new(
		face_vertex_selected,
		DataVector.DataType.BOOL))
	mvd.set_face_vertex_data(MeshVectorData.FV_COLOR, DataVectorFloat.new(
		face_vertex_color.to_byte_array().to_float32_array(),
		DataVector.DataType.COLOR))
	mvd.set_face_vertex_data(MeshVectorData.FV_UV0, DataVectorFloat.new(
		face_vertex_uv0.to_byte_array().to_float32_array(),
		DataVector.DataType.VECTOR2))
	
	return mvd

func get_face(face_index:int)->FaceInfo:
	return faces[face_index]

func get_centroid()->Vector3:
	var points:PackedVector3Array = get_points()
	var sum:Vector3
	for p in points:
		sum += p
	return sum / points.size()

# Creates a new volume that is equal to the portion of this volume on the top 
# side of the passed plane.  Does not modify the geometry of this volume.
func cut_with_plane(plane:Plane, uv_transform:Transform2D = Transform2D.IDENTITY, material_id:int = 0)->ConvexVolume:
#
	var planes:Array[Plane]
	for f in faces:
		#Top of planr should point toward interior
		planes.append(MathUtil.flip_plane(f.get_plane()))
	planes.append(plane)
	
	#print("planes %s" % GeneralUtil.format_planes_string(planes))
	
	var hull_points:Array[Vector3] = MathUtil.get_convex_hull_points_from_planes(planes)
	if hull_points.is_empty():
		return null
		
	var new_vol:ConvexVolume = ConvexVolume.new()
	new_vol.init_from_points(hull_points)
	
	new_vol.copy_face_attributes(self)
			
	for f in new_vol.faces:
		var f_plane:Plane = MathUtil.flip_plane(f.get_plane())
		if f_plane.is_equal_approx(plane):
			f.uv_transform = uv_transform
			f.material_id = material_id
			break

	return new_vol

func is_empty():
	return bounds.size.is_zero_approx()

# Returns a new ConvexVolume equal to this volume after the plane of the 
# indicated face has been translated the given offset.  Does not modify the
# geometry of this volume.
func translate_face_plane(face_index:int, offset:Vector3, lock_uvs:bool = false)->ConvexVolume:
	var xform:Transform3D = Transform3D(Basis.IDENTITY, -offset)

	var source_face:FaceInfo
	var transformed_plane:Plane

	var planes:Array[Plane] = []
	for f in faces:
		if f.index == face_index:
			transformed_plane = MathUtil.flip_plane(f.get_plane()) * xform
			planes.append(transformed_plane)
			source_face = f
		else:
			planes.append(MathUtil.flip_plane(f.get_plane()))

	#print("planes %s" % str(planes))
	var hull_points:Array[Vector3] = MathUtil.get_convex_hull_points_from_planes(planes)
	if hull_points.is_empty():
		return null
	
	var new_vol:ConvexVolume = ConvexVolume.new()
	new_vol.init_from_points(hull_points)
	new_vol.copy_face_attributes(self)
	
	return new_vol

func translated(offset:Vector3, lock_uvs:bool = false)->ConvexVolume:
	return transformed(Transform3D(Basis.IDENTITY, offset), lock_uvs)

func translate(offset:Vector3, lock_uvs:bool = false):
	transform(Transform3D(Basis.IDENTITY, offset), lock_uvs)
	
func transformed(xform:Transform3D, lock_uvs:bool = false)->ConvexVolume:
	var new_vol:ConvexVolume = ConvexVolume.new()
	new_vol.init_from_convex_block_data(to_convex_block_data())
	new_vol.transform(xform)
	return new_vol


func transform_uvs(xform:Transform3D):
#	var xform:Transform3D = obj_xform.affine_inverse()
	
	#deprecated
	#Old face matrix setup
	for f in faces:
		var axis:MathUtil.Axis = MathUtil.get_longest_axis(f.normal)
		
		match axis:
			MathUtil.Axis.X:
				var orig_p:Vector3 = xform.origin
				var u_p:Vector3 = xform * Vector3(0, 0, 1) - orig_p
				var v_p:Vector3 = xform * Vector3(0, 1, 0) - orig_p
				var move_xform:Transform2D = Transform2D(Vector2(u_p.z, u_p.y), \
					Vector2(v_p.z, v_p.y), \
					Vector2(orig_p.z, orig_p.y))
				
				f.uv_transform = f.uv_transform * move_xform
				
			MathUtil.Axis.Y:
				var orig_p:Vector3 = xform.origin
				var u_p:Vector3 = xform * Vector3(1, 0, 0) - orig_p
				var v_p:Vector3 = xform * Vector3(0, 0, 1) - orig_p
				var move_xform:Transform2D = Transform2D(Vector2(u_p.x, u_p.z), \
					Vector2(v_p.x, v_p.z), \
					Vector2(orig_p.x, orig_p.z))
				
				f.uv_transform = f.uv_transform * move_xform
				
			MathUtil.Axis.Z:
				#var xform_inv = xform.affine_inverse()
				var orig_p:Vector3 = xform.origin
				var u_p:Vector3 = xform * Vector3(1, 0, 0) - orig_p
				var v_p:Vector3 = xform * Vector3(0, 1, 0) - orig_p
				var move_xform:Transform2D = Transform2D(Vector2(u_p.x, u_p.y), \
					Vector2(v_p.x, v_p.y), \
					Vector2(orig_p.x, orig_p.y))
				
				f.uv_transform = f.uv_transform * move_xform

	#####################
	#New Face-vertex uv setup
	for f in faces:
		var axis:MathUtil.Axis = MathUtil.get_longest_axis(f.normal)
		
		for fv_idx in f.face_vertex_indices:
			var fv:FaceVertexInfo = face_vertices[fv_idx]
			var v_idx:int = fv.vertex_index
			var v:VertexInfo = vertices[v_idx]
			
			var new_point:Vector3 = xform * v.point
			var offset:Vector3 = new_point - v.point
			
			match axis:
				MathUtil.Axis.X:
					fv.uv0 += Vector2(-offset.z, -offset.y)
					
				MathUtil.Axis.Y:
					fv.uv0 += Vector2(-offset.x, -offset.z)
					
				MathUtil.Axis.Z:
					fv.uv0 += Vector2(-offset.x, -offset.y)

func transform(xform:Transform3D, lock_uvs:bool = false):
	for v in vertices:
		v.point = xform * v.point
	
	if xform.basis.determinant() < 0:
		for f in faces:
			f.reverse()

	if lock_uvs:
		#@deprecated
		#Old matrix based uv system
		for f in faces:
			var axis:MathUtil.Axis = MathUtil.get_longest_axis(f.normal)
			
			match axis:
				MathUtil.Axis.X:
					var orig_p:Vector3 = xform.origin
					var u_p:Vector3 = xform * Vector3(0, 0, 1) - orig_p
					var v_p:Vector3 = xform * Vector3(0, 1, 0) - orig_p
					var move_xform:Transform2D = Transform2D(Vector2(u_p.z, u_p.y), \
						Vector2(v_p.z, v_p.y), \
						Vector2(orig_p.z, orig_p.y))
					
					f.uv_transform = f.uv_transform * move_xform
					
				MathUtil.Axis.Y:
					var orig_p:Vector3 = xform.origin
					var u_p:Vector3 = xform * Vector3(1, 0, 0) - orig_p
					var v_p:Vector3 = xform * Vector3(0, 0, 1) - orig_p
					var move_xform:Transform2D = Transform2D(Vector2(u_p.x, u_p.z), \
						Vector2(v_p.x, v_p.z), \
						Vector2(orig_p.x, orig_p.z))
					
					f.uv_transform = f.uv_transform * move_xform
					
				MathUtil.Axis.Z:
					#var xform_inv = xform.affine_inverse()
					var orig_p:Vector3 = xform.origin
					var u_p:Vector3 = xform * Vector3(1, 0, 0) - orig_p
					var v_p:Vector3 = xform * Vector3(0, 1, 0) - orig_p
					var move_xform:Transform2D = Transform2D(Vector2(u_p.x, u_p.y), \
						Vector2(v_p.x, v_p.y), \
						Vector2(orig_p.x, orig_p.y))
					
					f.uv_transform = f.uv_transform * move_xform

		#####################
		#New Face-vertex uv setup
		for f in faces:
			var axis:MathUtil.Axis = MathUtil.get_longest_axis(f.normal)
			
			for fv_idx in f.face_vertex_indices:
				var fv:FaceVertexInfo = face_vertices[fv_idx]
				var v_idx:int = fv.vertex_index
				var v:VertexInfo = vertices[v_idx]
				
				var new_point:Vector3 = xform * v.point
				var offset:Vector3 = new_point - v.point
				
				match axis:
					MathUtil.Axis.X:
						fv.uv0 += Vector2(-offset.z, -offset.y)
						
					MathUtil.Axis.Y:
						fv.uv0 += Vector2(-offset.x, -offset.z)
						
					MathUtil.Axis.Z:
						fv.uv0 += Vector2(-offset.x, -offset.y)

func contains_point(point:Vector3)->bool:
	for f in faces:
		var plane:Plane = f.get_plane()
		if !plane.has_point(point) && !plane.is_point_over(point):
			return false
	return true


func get_points()->PackedVector3Array:
	var points:PackedVector3Array
	
	for v in vertices:
		points.append(v.point)
	
	return points

func calc_bounds()->AABB:
	if vertices.is_empty():
		return AABB()
		
	var result:AABB = AABB(vertices[0].point, Vector3.ZERO)
	
	for v_idx in range(1, vertices.size()):
		result = result.expand(vertices[v_idx].point)
		
	return result

func calc_bounds_xform(xform:Transform3D)->AABB:
	if vertices.is_empty():
		return AABB()
		
	var result:AABB = AABB(xform * vertices[0].point, Vector3.ZERO)
	
	for v_idx in range(1, vertices.size()):
		result = result.expand(xform * vertices[v_idx].point)
		
	return result


func tristrip_vertex_range(num_verts:int)->PackedInt32Array:
	var result:PackedInt32Array
	
	result.append(0)
	result.append(1)
	for i in range(2, num_verts):
		if (i & 1) == 0:
			result.append(num_verts - (i >> 1))
		else:
			result.append((i >> 1) + 1)
	
	return result

func tristrip_vertex_range_reverse(num_verts:int)->PackedInt32Array:
	var result:PackedInt32Array
	
	result.append(1)
	result.append(0)
	for i in range(2, num_verts):
		if (i & 1) == 0:
			result.append((i >> 1) + 1)
		else:
			result.append(num_verts - (i >> 1))
	
	return result

func calc_lightmap_uvs():
	var packer:FacePacker = FacePacker.new()
	var max_dim:float = max(bounds.size.x, bounds.size.y, bounds.size.z)
	var tree:FacePacker.FaceTree = packer.build_faces(self, max_dim * .1)

	var xform:Transform2D = Transform2D.IDENTITY
	xform = xform.scaled(tree.bounds.size)
	if is_zero_approx(xform.determinant()):
		return		
	var xform_inv = xform.affine_inverse()

	for ft in tree.face_list:
		var face:FaceInfo = faces[ft.face_index]
		face.lightmap_uvs = xform_inv * ft.points

#func create_mesh_wire_old(material:Material)->ImmediateMesh:
##	if Engine.is_editor_hint():
##		return
	#var mesh:ImmediateMesh = ImmediateMesh.new()
#
	#mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
#
	#for e in edges:
		#var v0:VertexInfo = vertices[e.start_index]
		#var v1:VertexInfo = vertices[e.end_index]
#
		#mesh.surface_add_vertex(v0.point)
		#mesh.surface_add_vertex(v1.point)
#
	#mesh.surface_end()
	#
	#return mesh


func create_mesh_wire(material:Material)->ArrayMesh:

	var mesh:ArrayMesh = ArrayMesh.new()

	var indices:PackedInt32Array
	var points_indexed:PackedVector3Array

	for v in vertices:
		points_indexed.append(v.point)
		
	for e in edges:
		indices.append(e.start_index)
		indices.append(e.end_index)
		
	var arrays:Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points_indexed
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	mesh.surface_set_material(0, material)
	
	return mesh


func create_mesh(material_list:Array[Material], default_material:Material, override_with_default_material:bool = false)->ArrayMesh:

	var mesh:ArrayMesh = ArrayMesh.new()
	mesh.blend_shape_mode = Mesh.BLEND_SHAPE_MODE_NORMALIZED
	mesh.lightmap_size_hint = Vector2(1000, 1000)

	var shadow_mesh:ArrayMesh = ArrayMesh.new()
	shadow_mesh.blend_shape_mode = Mesh.BLEND_SHAPE_MODE_NORMALIZED

	#print("create_mesh")
	#print("faces.size() ", faces.size())

	var face_dict:Dictionary = {}
	for f_idx in faces.size():
#		print("check F_idx %s" % f_idx)
		var face:FaceInfo = faces[f_idx]
		if face_dict.has(face.material_id):
			var arr = face_dict[face.material_id]
			arr.append(f_idx)
#			print("arr %s" % [arr])
			face_dict[face.material_id] = arr
#			print("append %s to %s" % [f_idx, face.material_id])
		else:
			face_dict[face.material_id] = [f_idx]
#			print("starting %s to %s" % [f_idx, face.material_id])

	var surface_idx:int = 0
	for mat_id in face_dict.keys():
#		print("surface mat grp %s" % mat_id)

		var points:PackedVector3Array
		var normals:PackedVector3Array
		var tangents:PackedFloat32Array
		var colors:PackedColorArray
		var uv1s:PackedVector2Array
#		var uv2s:PackedVector2Array

		var material = default_material
		if !override_with_default_material:
			if mat_id >= 0 && mat_id < material_list.size():
				material = material_list[mat_id]

		for f_idx in face_dict[mat_id]:
#			print("f_idx %s" % f_idx)

			var face:FaceInfo = faces[f_idx]
			if !face.visible:
				continue

			var axis:MathUtil.Axis = MathUtil.get_longest_axis(face.normal)

			var fv_trianglation:Array[int] = face.get_triangulation()

			for v_local_idx in fv_trianglation:

				var v_idx:int = face.vertex_indices[v_local_idx]
				var fv:FaceVertexInfo = face_vertex_coord_map[Vector2i(f_idx, v_idx)]
	
				var p:Vector3 = vertices[v_idx].point

				uv1s.append(fv.uv0)
#				uv2s.append(face.lightmap_uvs[v_local_idx])

				normals.append(fv.normal)
				colors.append(fv.color)

				points.append(p)

		#Calculate tangents
		#http://foundationsofgameenginedev.com/FGED2-sample.pdf
		for i in range(0, points.size(), 3):
			var p0:Vector3 = points[i]
			var p1:Vector3 = points[i + 1]
			var p2:Vector3 = points[i + 2]

			var uv0:Vector2 = uv1s[i]
			var uv1:Vector2 = uv1s[i + 1]
			var uv2:Vector2 = uv1s[i + 2]
			
			var n:Vector3 = normals[i]
			
			var e1:Vector3 = p1 - p0
			var e2:Vector3 = p2 - p0
			
			var duv1:Vector2 = uv1 - uv0
			var duv2:Vector2 = uv2 - uv0
			
			var r:float = 1.0 / (duv1.x * duv2.y - duv2.x * duv1.y)
			var t:Vector3 = (e1 * duv2.y - e2 * duv1.y) * r
			var b:Vector3 = (e2 * duv1.x - e1 * duv2.x) * r
			
			t = t.normalized()
			
			for j in 3:
				tangents.append(t.x)
				tangents.append(t.y)
				tangents.append(t.z)
				tangents.append(-1.0 if t.cross(b).dot(n) > 0 else 1.0)
		
#		var arrays:Array = create_indexed_vertex_array(points, normals, tangents, colors, uv1s, uv2s)
		var arrays:Array = create_indexed_vertex_array(points, normals, tangents, colors, uv1s)
		
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mesh.surface_set_material(surface_idx, material)

		var shadow_arrays:Array = []
		shadow_arrays.resize(Mesh.ARRAY_MAX)
		shadow_arrays[Mesh.ARRAY_VERTEX] = points

		shadow_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, shadow_arrays)
		shadow_mesh.surface_set_material(surface_idx, material)

		surface_idx += 1

	mesh.shadow_mesh = shadow_mesh
#	var err = mesh.lightmap_unwrap(Transform3D.IDENTITY, 10)
#	print("Lightmap unwrap Error: %s" % err)
	return mesh



#func create_indexed_vertex_array(points:PackedVector3Array, normals:PackedVector3Array, tangents:PackedFloat32Array, colors:PackedColorArray, uv1s:PackedVector2Array, uv2s:PackedVector2Array)->Array:
func create_indexed_vertex_array(points:PackedVector3Array, normals:PackedVector3Array, tangents:PackedFloat32Array, colors:PackedColorArray, uv1s:PackedVector2Array)->Array:
	var vert_idx_map:Dictionary
	var indices:PackedInt32Array
	var points_indexed:PackedVector3Array
	var normals_indexed:PackedVector3Array
	var tangents_indexed:PackedFloat32Array
	var colors_indexed:PackedColorArray
	var uv1s_indexed:PackedVector2Array
#	var uv2s_indexed:PackedVector2Array
	
	for v_idx in points.size():
		var vertex:PackedFloat32Array
		vertex.append(points[v_idx].x)
		vertex.append(points[v_idx].y)
		vertex.append(points[v_idx].z)

		vertex.append(normals[v_idx].x)
		vertex.append(normals[v_idx].y)
		vertex.append(normals[v_idx].z)

		vertex.append(tangents[v_idx * 4])
		vertex.append(tangents[v_idx * 4 + 1])
		vertex.append(tangents[v_idx * 4 + 2])
		vertex.append(tangents[v_idx * 4 + 3])

		vertex.append(colors[v_idx].r)
		vertex.append(colors[v_idx].g)
		vertex.append(colors[v_idx].b)
		vertex.append(colors[v_idx].a)

		vertex.append(uv1s[v_idx].x)
		vertex.append(uv1s[v_idx].y)

		#vertex.append(uv2s[v_idx].x)
		#vertex.append(uv2s[v_idx].y)

		var new_index:int
		if !vert_idx_map.has(vertex):
			#print("alloc vtx ", vertex)
			
			new_index = vert_idx_map.size()
			vert_idx_map[vertex] = new_index
			points_indexed.append(points[v_idx])
			normals_indexed.append(normals[v_idx])
			tangents_indexed.append(tangents[v_idx * 4])
			tangents_indexed.append(tangents[v_idx * 4 + 1])
			tangents_indexed.append(tangents[v_idx * 4 + 2])
			tangents_indexed.append(tangents[v_idx * 4 + 3])
			colors_indexed.append(colors[v_idx])
			uv1s_indexed.append(uv1s[v_idx])
#			uv2s_indexed.append(uv2s[v_idx])
		else:
			new_index = vert_idx_map[vertex]
		
		#print("index ", new_index)
		indices.append(new_index)

	#print("indices ", indices)

	var arrays:Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points_indexed
	arrays[Mesh.ARRAY_NORMAL] = normals_indexed
	arrays[Mesh.ARRAY_TANGENT] = tangents_indexed
	arrays[Mesh.ARRAY_TEX_UV] = uv1s_indexed
#	arrays[Mesh.ARRAY_TEX_UV2] = uv2s_indexed
	arrays[Mesh.ARRAY_COLOR] = colors_indexed
	arrays[Mesh.ARRAY_INDEX] = indices

	return arrays


func append_mesh_backfacing(mesh:ImmediateMesh, material:Material, offset:float = .2):
#	if Engine.is_editor_hint():
#		return

	for face in faces:
		
		mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, material)
#		print("face %s" % face.index)
		
		mesh.surface_set_normal(face.normal)
		
#		for i in tristrip_vertex_range_reverse(face.vertex_indices.size()):
		for i in tristrip_vertex_range_reverse(face.vertex_indices.size()):
			var v_idx:int = face.vertex_indices[i]
			var v:VertexInfo = vertices[v_idx]
			var p:Vector3 = v.point + v.normal * offset
			#var p:Vector3 = v.point + Vector3(.1, .1, .1)
			
			mesh.surface_add_vertex(p)
	
		mesh.surface_end()
		
func append_mesh_outline(mesh:ImmediateMesh, viewport_camera:Camera3D, local_to_world:Transform3D, material:Material, thickness:float = 4):
	var cam_orig:Vector3 = viewport_camera.global_transform.origin

	var segments:PackedVector2Array
	
	#print("--append_mesh_outline")
	#var view_plane:Plane = Plane(-viewport_camera.global_basis.z, 
		#viewport_camera.global_position 
		#- viewport_camera.global_basis.z * viewport_camera.near * 1)
	
	var frustum:Array[Plane] = viewport_camera.get_frustum()
	
	for edge in edges:
		var v0:VertexInfo = vertices[edge.start_index]
		var v1:VertexInfo = vertices[edge.end_index]
		var p0_world:Vector3 = local_to_world * v0.point
		var p1_world:Vector3 = local_to_world * v1.point
		
		var frustum_culled:bool = false
		for p in frustum:
			var p_flip:Plane = MathUtil.flip_plane(p)
			var result:PackedVector3Array = MathUtil.clip_segment_to_plane_3d(p_flip, p0_world, p1_world)
			if result.is_empty():
				frustum_culled = true
				break
			p0_world = result[0]
			p1_world = result[1]
		
		if frustum_culled:
			continue
		
		var has_front:bool = false
		var has_back:bool = false
		
		for f_idx in edge.face_indices:
			var face = faces[f_idx]
			
			var plane = face.get_plane()
			plane = local_to_world * plane
			
			if plane.is_point_over(cam_orig):
				has_front = true
			else:
				has_back = true

		#print("front %s back %s" % [has_front, has_back])
		
		if has_front && has_back:
			#Draw edge			
			var p0_screen:Vector2 = viewport_camera.unproject_position(p0_world)
			var p1_screen:Vector2 = viewport_camera.unproject_position(p1_world)
			segments.append(p0_screen)
			segments.append(p1_screen)
			#print("seg %s %s" % [p0_screen, p1_screen])

	#print("segments ", segments)
			
	var loops:Array[Loop2D] = MathUtil.get_loops_from_segments_2d(segments)
	for loop in loops:
		var out_dirs:PackedVector2Array
		
		#print("loop ", loop)
		for v_idx in loop.points.size():
			var p0_screen:Vector2 = loop.points[wrap(v_idx - 1, 0, loop.points.size())]
			var p1_screen:Vector2 = loop.points[v_idx]
			var p2_screen:Vector2 = loop.points[wrap(v_idx + + 1, 0, loop.points.size())]
			#var span:Vector2 = p2_screen - p1_screen
			
			var norm01:Vector2 = (p1_screen - p0_screen).normalized()
			var norm12:Vector2 = (p2_screen - p1_screen).normalized()
			
			var out_dir1:Vector2 = (-norm01 + norm12).normalized()
			var perp:Vector2 = out_dir1 - out_dir1.project(norm12)
			#Check winding
			if perp.x * norm12.y - perp.y * norm12.x < 0:
				out_dir1 = -out_dir1
			
			out_dirs.append(out_dir1)
				
		
		mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, material)
		for v_idx in loop.points.size() + (1 if loop.closed else 0):
			var p_screen:Vector2 = loop.points[wrap(v_idx, 0, loop.points.size())]
			var p_out_dir:Vector2 = out_dirs[wrap(v_idx, 0, loop.points.size())]
			
			var z_pos:float = (viewport_camera.near + viewport_camera.far) / 2
			var p0:Vector3 = viewport_camera.project_position(p_screen, z_pos)
			var p1:Vector3 = viewport_camera.project_position(p_screen + p_out_dir * thickness, z_pos)
			
			mesh.surface_add_vertex(p0)
			mesh.surface_add_vertex(p1)
			
		mesh.surface_end()
		

func intersect_ray_closest(origin:Vector3, dir:Vector3)->IntersectResults:
	if bounds.intersects_ray(origin, dir) == null:
		return null
	
	
	var best_result:IntersectResults
	
	for f_idx in faces.size():
		var face:FaceInfo = faces[f_idx]
#
		#var local_fv_indices:Array[int] = face.get_triangulation()
#
##		var tris:PackedVector3Array
		#var tri_verts:Array[VertexInfo]
		#for local_fv_idx in local_fv_indices:
			#var v_idx:int = face.vertex_indices[local_fv_idx]
			#tri_verts.append(vertices[v_idx])
##			tris.append(vertices[v_idx].point)

#		var tris:PackedVector3Array = face.get_trianges()
		var tris_v_idx:PackedInt32Array = face.get_trianges_v_idx()
		
		for i in range(0, tris_v_idx.size(), 3):
			var p0:Vector3 = vertices[tris_v_idx[i]].point
			var p1:Vector3 = vertices[tris_v_idx[i + 1]].point
			var p2:Vector3 = vertices[tris_v_idx[i + 2]].point
			
			#Godot uses clockwise winding
			var tri_area_x2:Vector3 = MathUtil.triangle_area_x2(p0, p1, p2)
			
			var p_hit:Vector3 = MathUtil.intersect_plane(origin, dir, p0, tri_area_x2)
			if !p_hit.is_finite():
				continue
			
			if MathUtil.triangle_area_x2(p_hit, p0, p1).dot(tri_area_x2) < 0:
				continue
			if MathUtil.triangle_area_x2(p_hit, p1, p2).dot(tri_area_x2) < 0:
				continue
			if MathUtil.triangle_area_x2(p_hit, p2, p0).dot(tri_area_x2) < 0:
				continue
			
			#Intersection
			var dist_sq:float = (origin - p_hit).length_squared()
			if !best_result || best_result.distance_squared > dist_sq:
			
				var result:IntersectResults = IntersectResults.new()
				#result.face_id = face.id
				result.face_index = f_idx
				result.normal = face.normal
				result.position = p_hit
				result.distance_squared = dist_sq
				result.tessellated_vertex_indices_of_hit = [
					tris_v_idx[i], 
					tris_v_idx[i + 1], 
					tris_v_idx[i + 2]
					]
				
				best_result = result
					
	return best_result

func format_faces_string()->String:
	var s:String = ""
	for f in faces:
		s = s + "["
		for v_idx in f.vertex_indices:
			s += "%s, " % vertices[v_idx].point
		s = s + "],\n"
	return s
			
func update_edge_and_face_selection_from_vertices():
	for e in edges:
		e.selected = vertices[e.start_index].selected && vertices[e.end_index].selected

	for f in faces:
		var all_sel:bool = true
		for v_idx in f.vertex_indices:
			if !vertices[v_idx].selected:
				all_sel = false
				break
		f.selected = all_sel


func intersects_plane(plane:Plane)->bool:
	
	var is_over:bool = false
	var is_under:bool = false
	
	for v in vertices:
		var p:Vector3 = v.point
		
		if plane.has_point(p):
			continue
		
		if plane.is_point_over(p):
			is_over = true
		else:
			is_under = true
			
		if is_over && is_under:
			return true
			
	return false

func subtract(subtrahend:ConvexVolume)->Array[ConvexVolume]:
	var result_list:Array[ConvexVolume]
	
	var split_vol:ConvexVolume = self
	
	for face in subtrahend.faces:
		var p:Plane = face.get_plane()
		
		if !split_vol.intersects_plane(p):
			continue
			
		var vol_over:ConvexVolume = split_vol.cut_with_plane(p)
		var vol_under:ConvexVolume = split_vol.cut_with_plane(MathUtil.flip_plane(p))
		
		result_list.append(vol_over)
		split_vol = vol_under

#	result_list.append(split_vol)
	
	return result_list


func intersect(subtrahend:ConvexVolume)->ConvexVolume:
	var result_list:Array[ConvexVolume]
	
	var split_vol:ConvexVolume = self
	
	for face in subtrahend.faces:
		var p:Plane = face.get_plane()
		
		if !split_vol.intersects_plane(p):
			continue
			
		var vol_over:ConvexVolume = split_vol.cut_with_plane(p)
		var vol_under:ConvexVolume = split_vol.cut_with_plane(MathUtil.flip_plane(p))
		
		result_list.append(vol_over)
		split_vol = vol_under

	return split_vol
	

func is_over_or_on_plane(plane:Plane)->bool:
	for v in vertices:
		if !plane.is_point_over(v.point) && !plane.has_point(v.point):
			return false
	
	return true

func intersects_convex_volume(vol:ConvexVolume)->bool:
	#Look for plane of separtion between two volumes
	for f in vol.faces:
		var p:Plane = f.get_plane()
		if is_over_or_on_plane(p):
			return false
	
	return true
	

func intersects_frustum(frustum:Array[Plane])->bool:

	for face in faces:
		var points:PackedVector3Array = face.get_points()
		if MathUtil.polygon_intersects_frustum(points, frustum):
			return true
		
	return false

func make_convex():
	var selected_points:PackedVector3Array
	var new_points:PackedVector3Array
	
	for v in vertices:
		new_points.append(v.point)

	var new_vol:ConvexVolume = ConvexVolume.new()
	new_vol.init_from_points(new_points)
	
	new_vol.copy_vertex_attributes(self)
	new_vol.copy_face_attributes(self)
	
	if active_vertex != -1:
		var v:VertexInfo = vertices[active_vertex]
		var new_v:VertexInfo = new_vol.get_vertex_at_position(v.point)
		if new_v:
			new_vol.active_vertex = new_v.index
	
	if active_edge != -1:
		var e:EdgeInfo = edges[active_edge]
		var mp:Vector3 = e.get_midpoint()
		var new_e:EdgeInfo = new_vol.get_edge_at_position(mp)
		if new_e:
			new_vol.active_edge = new_e.index
	
	if active_face != -1:
		var f:FaceInfo = faces[active_face]
		var centroid:Vector3 = f.get_centroid()
		var new_f:FaceInfo = new_vol.get_face_at_position(centroid)
		if new_f:
			new_vol.active_face = new_f.index
			
	
func get_camera_facing_edges(viewport_camera:Camera3D, local_to_world:Transform3D)->Array[EdgeInfo]:
	var result:Array[EdgeInfo]
	
	var pick_origin:Vector3 = viewport_camera.global_position
	
	for e_idx in edges.size():
		var e:ConvexVolume.EdgeInfo = edges[e_idx]
		var focus:Vector3 = local_to_world * e.get_midpoint()
		if viewport_camera.is_position_behind(focus):
			continue
		
		var pick_dir:Vector3 = focus - pick_origin	
		var res:IntersectResults = intersect_ray_closest(pick_origin, pick_dir)
		
		if res:
			var hit:bool = false
			for f_idx in e.face_indices:
				if f_idx == res.face_index:
					hit = true
					break
					
			if !hit:
				continue

		result.append(e)
	
	return result

func generate_uv_triplanar(selected_faces_only:bool = false, point_transform:Transform3D = Transform3D.IDENTITY):
	for face:FaceInfo in faces:
		if selected_faces_only && !face.selected:
			continue
		
		for v_idx in face.vertex_indices:
			var vert:VertexInfo = vertices[v_idx]
			var pt:Vector3 = point_transform * vert.point
			
			var uv:Vector2
			match (MathUtil.get_longest_axis(face.normal)):
				MathUtil.Axis.X:
					uv = Vector2(-pt.z, -pt.y)
				MathUtil.Axis.Y:
					uv = Vector2(-pt.x, -pt.z)
				MathUtil.Axis.Z:
					uv = Vector2(-pt.x, -pt.y)
			
			var fv:FaceVertexInfo = get_face_vertex(face.index, v_idx)
			fv.uv0 = uv
