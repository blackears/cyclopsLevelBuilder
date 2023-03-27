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


class PlaneInfo extends RefCounted:
	var index:int
	var plane:Plane #Face normal points in direction of interior
	var material_index:int
	var uv_transform:Transform2D
	var selected:bool
	
	func _init(index:int, plane:Plane, uv_transform:Transform2D = Transform2D.IDENTITY, material_index:int = 0, selected:bool = false):
		self.index = index
		self.plane = plane
		self.material_index = material_index
		self.uv_transform = uv_transform
		self.selected = selected
		

var faces:Array[PlaneInfo] = []

#func get_face_indices()->PackedInt32Array:
#	var result:PackedInt32Array
#	for f in faces:
#		result.append(f.index)
#	return result

func init_block(block_bounds:AABB):
	var p000:Vector3 = block_bounds.position
	var p111:Vector3 = block_bounds.end
	var p001:Vector3 = Vector3(p000.x, p000.y, p111.z)
	var p010:Vector3 = Vector3(p000.x, p111.y, p000.z)
	var p011:Vector3 = Vector3(p000.x, p111.y, p111.z)
	var p100:Vector3 = Vector3(p111.x, p000.y, p000.z)
	var p101:Vector3 = Vector3(p111.x, p000.y, p111.z)
	var p110:Vector3 = Vector3(p111.x, p111.y, p000.z)
	
	init_prisim([p000, p001, p011, p010], p100 - p000)
	

func init_prisim(base_points:Array[Vector3], extrude_dir:Vector3):
	faces = []
	var base_normal = extrude_dir.normalized()
	faces.append(PlaneInfo.new(0, Plane(base_normal, base_points[0]), Transform2D.IDENTITY, 0))
	faces.append(PlaneInfo.new(1, Plane(-base_normal, base_points[0] + extrude_dir), Transform2D.IDENTITY, 0))
	
	var face_area_x2:Vector3 = MathUtil.face_area_x2(base_points)
	#Flip normal if face winding clockwise relative to extrude direction
#	var normal_flip:float = 1 if face_area_x2.dot(base_normal) < 0 else -1
	
	for i in base_points.size():
		var p0:Vector3 = base_points[i]
		var p1:Vector3 = base_points[wrap(i + 1, 0, base_points.size())]
		
#		var normal = (p1 - p0).cross(base_normal).normalized() * normal_flip
		var normal = (p1 - p0).cross(face_area_x2).normalized()
		faces.append(PlaneInfo.new(faces.size(), Plane(normal, p0), Transform2D.IDENTITY, 0))


func init_from_convex_block_data(data:ConvexBlockData):
	faces = []
	
	for i in data.face_planes.size():
		faces.append(PlaneInfo.new(i, data.face_planes[i], data.face_uv_transform[i], data.face_material_indices[i]))

func to_convex_block_data()->ConvexBlockData:
	var result:ConvexBlockData
	
	for face in faces:
		result.face_material_indices.append(face.material_index)
		result.face_planes.append(face.plane)
		result.face_uv_transform.append(face.uv_transform)
	
	return result

func unused_index()->int:
	var idx = 0
	for p in faces:
		idx = max(idx, p.index)
	return idx + 1

func append_mesh(mesh:ImmediateMesh, material:Material, color:Color = Color.WHITE):
	var convex_mesh:ConvexMesh = ConvexMesh.new()
	convex_mesh.init_cube_huge()
	
	for plane in faces:
		var new_mesh:ConvexMesh = convex_mesh.cut_with_plane(plane.plane, unused_index(), plane.uv_transform, plane.material_index, plane.selected)
		convex_mesh = new_mesh
	
	convex_mesh.append_mesh(mesh, material, color)
	
