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
	var mesh:ConvexVolume
	#var index:int
	var point:Vector3
	var normal:Vector3
	var edge_indices:Array[int] = []
	var selected:bool
	#var active:bool
	
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
	var mesh:ConvexVolume
	var start_index:int
	var end_index:int
	var face_indices:Array[int] = []
	var selected:bool
	#var active:bool
	
	func _init(mesh:ConvexVolume, start:int = 0, end:int = 0):
		self.mesh = mesh
		start_index = start
		end_index = end

	func _to_string():
		var s:String = "%s %s [" % [start_index, end_index]
		for i in face_indices:
			s += "%s " % i
		s += "]"
		return s


class FaceInfo extends RefCounted:
	var mesh:ConvexVolume
	var id:int
	var normal:Vector3 #Face normal points in direction of interior
	var material_id:int
	var uv_transform:Transform2D
	var selected:bool
	#var active:bool
	var vertex_indices:Array[int]
	var triangulation_indices:Array[int]
	var lightmap_uvs:PackedVector2Array
	
	func _init(mesh:ConvexVolume, id:int, normal:Vector3, uv_transform:Transform2D = Transform2D.IDENTITY, material_id:int = 0, selected:bool = false):
		self.mesh = mesh
		self.id = id
		self.normal = normal
		self.material_id = material_id
		self.uv_transform = uv_transform
		self.selected = selected
	
	func get_plane()->Plane:
		return Plane(normal, mesh.vertices[vertex_indices[0]].point)
	
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
	
#	func get_triangulation()->Array[int]:		
#		if triangulation_indices.is_empty():
#			var points:PackedVector3Array
#			var indices:Array[int]
#			for v_idx in vertex_indices:
#				points.append(mesh.vertices[v_idx].point)
#				indices.append(v_idx)
#
##			print("start points %s" % points)
#
#			var normal:Vector3 = MathUtil.face_area_x2(points).normalized()
##			print("normal %s" % normal)
#			triangulation_indices = MathUtil.trianglate_face_indices(points, indices, normal)
##			print("triangulation %s" % str(triangulation_indices))
#
#		return triangulation_indices
	
	func get_triangulation()->Array[int]:		
		if triangulation_indices.is_empty():
			var points:PackedVector3Array
			for v_idx in vertex_indices:
				points.append(mesh.vertices[v_idx].point)

#			print("start points %s" % points)
				
			var normal:Vector3 = MathUtil.face_area_x2(points).normalized()
#			print("normal %s" % normal)
			triangulation_indices = MathUtil.trianglate_face_vertex_indices(points, normal)
#			print("triangulation %s" % str(triangulation_indices))
		
		return triangulation_indices
		
	func get_trianges()->PackedVector3Array:
		var indices:Array[int] = get_triangulation()
		var result:PackedVector3Array

		for fv_idx in indices:
			var v_idx:int = vertex_indices[fv_idx]
			result.append(mesh.vertices[v_idx].point)

#		print("triangules %s" % result)

		return result
	
	func reverse():
		normal = -normal
		vertex_indices.reverse()
		triangulation_indices.clear()

#class FaceVertexInfo extends RefCounted:
#	var vert_idx:int
#	var face_idx:int
	


var vertices:Array[VertexInfo] = []
var edges:Array[EdgeInfo] = []
var faces:Array[FaceInfo] = []
var bounds:AABB

var lightmap_uvs_dirty = true

var active_vertex:int = -1
var active_edge:int = -1
var active_face:int = -1

func _to_string()->String:
	var result:String = ""
	for v in vertices:
		result += str(v.point) + ", "
	return result
	

func init_block(block_bounds:AABB, uv_transform:Transform2D = Transform2D.IDENTITY, material_id:int = -1):
	var p000:Vector3 = block_bounds.position
	var p111:Vector3 = block_bounds.end
	var p001:Vector3 = Vector3(p000.x, p000.y, p111.z)
	var p010:Vector3 = Vector3(p000.x, p111.y, p000.z)
	var p011:Vector3 = Vector3(p000.x, p111.y, p111.z)
	var p100:Vector3 = Vector3(p111.x, p000.y, p000.z)
	var p101:Vector3 = Vector3(p111.x, p000.y, p111.z)
	var p110:Vector3 = Vector3(p111.x, p111.y, p000.z)
	
	init_prism([p000, p001, p011, p010], p100 - p000, uv_transform, material_id)
	

func init_prism(base_points:Array[Vector3], extrude_dir:Vector3, uv_transform:Transform2D = Transform2D.IDENTITY, material_id:int = -1):
	vertices = []
	edges = []
	faces = []
	var base_normal = -extrude_dir.normalized()
	
	var face_area_x2:Vector3 = MathUtil.face_area_x2(base_points)
	if face_area_x2.dot(extrude_dir) > 0:
		base_points.reverse()
	
	for p in base_points:
		var v:VertexInfo = VertexInfo.new(self, p)
		vertices.append(v)
	for p in base_points:
		var v:VertexInfo = VertexInfo.new(self, p + extrude_dir)
		vertices.append(v)
	
	var f0:FaceInfo = FaceInfo.new(self, faces.size(), base_normal, uv_transform, material_id)
	f0.vertex_indices = []
	f0.vertex_indices.append_array(range(base_points.size()))
	faces.append(f0)
	var f1:FaceInfo = FaceInfo.new(self, faces.size(), -base_normal, uv_transform, material_id)
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
		var f:FaceInfo = FaceInfo.new(self, faces.size(), normal, uv_transform, material_id)
		f.vertex_indices = [p_idx1, p_idx0, p_idx0 + base_points.size(), p_idx1 + base_points.size()]
		faces.append(f)
	
	build_edges()
	calc_vertex_normals()
	
	bounds = calc_bounds()
	calc_lightmap_uvs()

func init_from_convex_block_data(data:ConvexBlockData):
	vertices = []
	edges = []
	faces = []

	active_vertex = data.active_vertex
	active_edge = data.active_edge
	active_face = data.active_face
	
	for i in data.vertex_points.size():
		var v:VertexInfo = VertexInfo.new(self, data.vertex_points[i])
		vertices.append(v)
		v.selected = data.vertex_selected[i]
		#v.active = data.vertex_active[i]

	var num_edges:int = data.edge_vertex_indices.size() / 2
	for i in num_edges:
		var edge:EdgeInfo = EdgeInfo.new(self, data.edge_vertex_indices[i * 2], data.edge_vertex_indices[i * 2 + 1])
		edges.append(edge)
		edge.face_indices.append(data.edge_face_indices[i * 2])
		edge.face_indices.append(data.edge_face_indices[i * 2 + 1])
		edge.selected = data.edge_selected[i]
		#edge.active = data.edge_active[i]
		
	var face_vertex_count:int = 0
	for face_idx in data.face_vertex_count.size():
		var num_verts:int = data.face_vertex_count[face_idx]
		var vert_indices:Array[int]
		var vert_points:PackedVector3Array
		for i in num_verts:
			var vert_idx:int = data.face_vertex_indices[face_vertex_count]
			vert_indices.append(vert_idx)
			vert_points.append(vertices[vert_idx].point)
#			var v_idx:int = data.face_vertex_indices[count]
			face_vertex_count += 1
		
		var normal = MathUtil.face_area_x2(vert_points).normalized()
		var f:FaceInfo = FaceInfo.new(self, data.face_ids[face_idx], normal, data.face_uv_transform[face_idx], data.face_material_indices[face_idx])
		f.selected = data.face_selected[face_idx]
		#f.active = data.face_active[face_idx]
		f.vertex_indices = vert_indices
		
		faces.append(f)

	
	calc_vertex_normals()
	
	bounds = calc_bounds()
	calc_lightmap_uvs()
	#print("init_from_convex_block_data %s" % format_faces_string())
	

#Calc convex hull bouding points
func init_from_points(points:PackedVector3Array, uv_transform:Transform2D = Transform2D.IDENTITY, material_id:int = -1):
	vertices = []
	edges = []
	faces = []

	#print("init_from_points %s" % points)
	var hull:QuickHull.Hull = QuickHull.quickhull(points)
	#print("hull %s" % hull.format_points())
	
	var hull_points:Array[Vector3] = hull.get_points()
	
	for p in hull_points:
		vertices.append(VertexInfo.new(self, p))
	
	for facet in hull.facets:
		var plane:Plane = facet.plane
		var vert_indices:Array[int] = []
		
		for p in facet.points:
			var vert_idx:int = hull_points.find(p)
			vert_indices.append(vert_idx)
		
		var f:FaceInfo = FaceInfo.new(self, faces.size(), plane.normal, uv_transform, material_id)
		f.vertex_indices = vert_indices
		faces.append(f)
	

	build_edges()
	calc_vertex_normals()
	
	bounds = calc_bounds()
	calc_lightmap_uvs()
	
func calc_vertex_normals():
	for v_idx in vertices.size():
		var v:VertexInfo = vertices[v_idx]
		var weighted_normal:Vector3
		
		for face in faces:
			if face.vertex_indices.has(v_idx):
				weighted_normal += MathUtil.face_area_x2(face.get_points())
		
		v.normal = weighted_normal.normalized()
				

func get_edge(vert_idx0:int, vert_idx1:int)->EdgeInfo:
	for e in edges:
		if e.start_index == vert_idx0 && e.end_index == vert_idx1:
			return e
		if e.start_index == vert_idx1 && e.end_index == vert_idx0:
			return e
	return null


func build_edges():
			
	#Calculate edges
	for face in faces:
		var num_corners = face.vertex_indices.size()
		for i0 in num_corners:
			var i1:int = wrap(i0 + 1, 0, num_corners)
			var v0_idx:int = face.vertex_indices[i0]
			var v1_idx:int = face.vertex_indices[i1]
			
			var edge:EdgeInfo = get_edge(v0_idx, v1_idx)
			if !edge:
				var edge_idx = edges.size()
				edge = EdgeInfo.new(self, v0_idx, v1_idx)
				edges.append(edge)
			
				var v0:VertexInfo = vertices[v0_idx]
				v0.edge_indices.append(edge_idx)
				
				var v1:VertexInfo = vertices[v1_idx]
				v1.edge_indices.append(edge_idx)

			edge.face_indices.append(face.id)

func get_face_coincident_with_plane(plane:Plane)->FaceInfo:
	for f in faces:
		var p:Plane = f.get_plane()
		if p.is_equal_approx(plane):
			return f
	return null


func get_face_ids(selected_only:bool = false)->PackedInt32Array:
	var result:PackedInt32Array
	for f in faces:
		if !selected_only || f.selected:
			result.append(f.id)
	return result

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

func copy_face_attributes(ref_vol:ConvexVolume):
	for fl in faces:
		var ref_face:FaceInfo = ref_vol.get_face_most_similar_to_plane(fl.get_plane())
		
		fl.material_id = ref_face.material_id
		fl.uv_transform = ref_face.uv_transform
		fl.selected = ref_face.selected

func to_convex_block_data()->ConvexBlockData:
	var result:ConvexBlockData = ConvexBlockData.new()
	
	result.active_vertex = active_vertex
	result.active_edge = active_edge
	result.active_face = active_face
	
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
		result.face_ids.append(face.id)
		result.face_selected.append(face.selected)
		#result.face_active.append(face.active)
		result.face_material_indices.append(face.material_id)
		result.face_uv_transform.append(face.uv_transform)
	
	return result

func get_face(face_id:int)->FaceInfo:
	for face in faces:
		if face.id == face_id:
			return face
	return null

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
func translate_face_plane(face_id:int, offset:Vector3, lock_uvs:bool = false)->ConvexVolume:
	var xform:Transform3D = Transform3D(Basis.IDENTITY, -offset)

	var source_face:FaceInfo
	var transformed_plane:Plane

	var planes:Array[Plane] = []
	for f in faces:
		if f.id == face_id:
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

func translate(offset:Vector3, lock_uvs:bool = false):
	transform(Transform3D(Basis.IDENTITY, offset), lock_uvs)
	

func transform(xform:Transform3D, lock_uvs:bool = false):
	for v in vertices:
		v.point = xform * v.point
	
	if xform.basis.determinant() < 0:
		for f in faces:
			f.reverse()

	if lock_uvs:
#		var xform_inv:Transform3D = xform.affine_inverse()
		#var xform_inv:Transform3D = xform
		#print("--xform %s" % xform)
		
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
		
	#calc_lightmap_uvs()

func unused_face_id()->int:
	var idx = 0
	for p in faces:
		idx = max(idx, p.id)
	return idx + 1

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
	var xform_inv = xform.affine_inverse()

	for ft in tree.face_list:
		var face:FaceInfo = faces[ft.face_index]
		face.lightmap_uvs = xform_inv * ft.points

func create_mesh(material_list:Array[Material], default_material:Material)->ArrayMesh:
#	if Engine.is_editor_hint():
#		return
#	print("num faces %s" % faces.size())
#	print("-creating mesh")

	var mesh:ArrayMesh = ArrayMesh.new()
	mesh.blend_shape_mode = Mesh.BLEND_SHAPE_MODE_NORMALIZED
	mesh.lightmap_size_hint = Vector2(1000, 1000)

	var shadow_mesh:ArrayMesh = ArrayMesh.new()
	shadow_mesh.blend_shape_mode = Mesh.BLEND_SHAPE_MODE_NORMALIZED

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
		var uv1s:PackedVector2Array
		var uv2s:PackedVector2Array

		var material = default_material		
		if mat_id >= 0 && mat_id < material_list.size():
			material = material_list[mat_id]
		
		for f_idx in face_dict[mat_id]:
#			print("f_idx %s" % f_idx)

			var face:FaceInfo = faces[f_idx]
			
			
			var axis:MathUtil.Axis = MathUtil.get_longest_axis(face.normal)
			
			var fv_trianglation:Array[int] = face.get_triangulation()
			
			for fv_idx in fv_trianglation:
				
				var v_idx:int = face.vertex_indices[fv_idx]
	#			var p:Vector3 = triangles[i]
				var p:Vector3 = vertices[v_idx].point
							
				var uv:Vector2
				if axis == MathUtil.Axis.X:
					uv = Vector2(-p.z, -p.y)
				elif axis == MathUtil.Axis.Y:
					uv = Vector2(-p.x, -p.z)
				elif axis == MathUtil.Axis.Z:
					uv = Vector2(-p.x, -p.y)
					
				uv = face.uv_transform * uv
				uv1s.append(uv)
				uv2s.append(face.lightmap_uvs[fv_idx])
				
				normals.append(face.normal)
				
				points.append(p)
		
		var arrays:Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = points
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_TEX_UV] = uv1s
		arrays[Mesh.ARRAY_TEX_UV2] = uv2s
			
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
#	var cam_dir:Vector3 = viewport_camera.global_transform.basis.z
	var cam_orig:Vector3 = viewport_camera.global_transform.origin

#	print("append_mesh_outline %s" % cam_dir)
	#points along Z
#	var cylinder:GeometryMesh = MathGeometry.unit_cylinder(4, thickness, thickness, 0, -1)

	var segments:PackedVector2Array
	
	for edge in edges:
		var has_front:bool = false
		var has_back:bool = false
		
		for f_idx in edge.face_indices:
			var face = faces[f_idx]
			#print("face norm %s" % face.normal)
			var point_on_plane:Vector3 = vertices[face.vertex_indices[0]].point
			var to_plane:Vector3 = cam_orig - point_on_plane
			
			if face.normal.dot(to_plane) > 0:
				has_front = true
			elif face.normal.dot(to_plane) < 0:
				has_back = true

		#print("front %s back %s" % [has_front, has_back])
		
		if has_front && has_back:
			#print("drawing edge %s %s" % [edge.start_index, edge.end_index])
			#Draw edge
			var v0:VertexInfo = vertices[edge.start_index]
			var v1:VertexInfo = vertices[edge.end_index]
			var p0_world:Vector3 = local_to_world * v0.point
			var p1_world:Vector3 = local_to_world * v1.point
			var p0_screen:Vector2 = viewport_camera.unproject_position(p0_world)
			var p1_screen:Vector2 = viewport_camera.unproject_position(p1_world)
			segments.append(p0_screen)
			segments.append(p1_screen)
			
	var loops:Array[PackedVector2Array] = MathUtil.get_loops_from_segments_2d(segments)
	for loop_points in loops:
		var out_dirs:PackedVector2Array
		
		for v_idx in loop_points.size():
			var p0_screen:Vector2 = loop_points[wrap(v_idx - 1, 0, loop_points.size())]
			var p1_screen:Vector2 = loop_points[v_idx]
			var p2_screen:Vector2 = loop_points[wrap(v_idx + + 1, 0, loop_points.size())]
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
		for v_idx in loop_points.size() + 1:
			var p_screen:Vector2 = loop_points[wrap(v_idx, 0, loop_points.size())]
			var p_out_dir:Vector2 = out_dirs[wrap(v_idx, 0, loop_points.size())]
			
			var z_pos:float = (viewport_camera.near + viewport_camera.far) / 2
			var p0:Vector3 = viewport_camera.project_position(p_screen, z_pos)
			var p1:Vector3 = viewport_camera.project_position(p_screen + p_out_dir * thickness, z_pos)
			
			mesh.surface_add_vertex(p0)
			mesh.surface_add_vertex(p1)
			
		mesh.surface_end()
		
		
		
func create_mesh_wire(material:Material)->ImmediateMesh:
#	if Engine.is_editor_hint():
#		return
	var mesh:ImmediateMesh = ImmediateMesh.new()

	mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)

	for e in edges:
		var v0:VertexInfo = vertices[e.start_index]
		var v1:VertexInfo = vertices[e.end_index]

		mesh.surface_add_vertex(v0.point)
		mesh.surface_add_vertex(v1.point)

	mesh.surface_end()
	
	return mesh


func intersect_ray_closest(origin:Vector3, dir:Vector3)->IntersectResults:
	if bounds.intersects_ray(origin, dir) == null:
		return null
	
	var best_result:IntersectResults
	
	for face in faces:
#		var tris:PackedVector3Array = MathUtil.trianglate_face(face.get_points(), face.normal)
		var tris:PackedVector3Array = face.get_trianges()
		for i in range(0, tris.size(), 3):
			var p0:Vector3 = tris[i]
			var p1:Vector3 = tris[i + 1]
			var p2:Vector3 = tris[i + 2]
			
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
				result.face_id = face.id
				result.normal = face.normal
				result.position = p_hit
				result.distance_squared = dist_sq
				
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

			
