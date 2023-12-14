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
class_name FacePacker

class SpawnResult extends RefCounted:
	var point:Vector2
	var flip:bool
	
	func _init(point:Vector2, flip:bool):
		self.point = point
		self.flip = flip

class FaceTree extends RefCounted:
#	var root:FaceTreeNode
	var size:Vector2
	var spawn_points:PackedVector2Array = [Vector2.ZERO]
	var face_list:Array[FaceTracker]
	var bounds:Rect2

	func _to_string()->String:
		var res:String = ""
		for face in face_list:
			res += "%s,\n" % str(face)
		return res

	func is_collision(rect:Rect2)->bool:
		for face in face_list:
			if face.bounds.intersects(rect):
				return true
		return false

	func max_vec_dim(v:Vector2):
		return max(v.x, v.y)

	func get_best_spawn_point(face:FaceTracker)->SpawnResult:
		var started:bool = false
		var best_spawn_point:Vector2 = Vector2.INF
		var best_bounds:Rect2
		var best_flip:bool
		
		for s_idx in spawn_points.size():
			var spawn_point:Vector2 = spawn_points[s_idx]

			var placed_bounds:Rect2 = face.bounds
			placed_bounds.position += spawn_point

			if !is_collision(placed_bounds):
				var new_bounds:Rect2 = bounds.merge(placed_bounds)
				
				if new_bounds.is_equal_approx(bounds):
					return SpawnResult.new(spawn_point, false)
				else:
					if !started || max_vec_dim(best_bounds.size) > max_vec_dim(new_bounds.size):
						best_bounds = new_bounds
						best_flip = false
						best_spawn_point = spawn_point
						started = true
								
			var placed_bounds_flipped:Rect2 = face.bounds
			placed_bounds_flipped.size = Vector2(placed_bounds_flipped.size.y, placed_bounds_flipped.size.x)
			placed_bounds_flipped.position += spawn_point
			
			if !is_collision(placed_bounds_flipped):
				var new_bounds_flipped:Rect2 = bounds.merge(placed_bounds_flipped)
				
				if new_bounds_flipped.is_equal_approx(bounds):
					return SpawnResult.new(spawn_point, true)
				else:
					if !started || max_vec_dim(best_bounds.size) > max_vec_dim(new_bounds_flipped.size):
						best_bounds = new_bounds_flipped
						best_flip = true
						best_spawn_point = spawn_point
						started = true
	
		return SpawnResult.new(best_spawn_point, best_flip)		
	
	func add_face(face:FaceTracker):
		var spawn:SpawnResult = get_best_spawn_point(face)
		
		var idx = spawn_points.find(spawn.point)
		spawn_points.remove_at(idx)
		
		if spawn.flip:
			face.reflect_diagonal()
		
		face.translate(spawn.point)
		face_list.append(face)
		bounds = bounds.merge(face.bounds)
		
		var sp_0:Vector2 = face.bounds.position + Vector2(face.bounds.size.x, 0)
		var sp_1:Vector2 = face.bounds.position + Vector2(0, face.bounds.size.y)
		if !spawn_points.has(sp_0):
			spawn_points.append(sp_0)
		if !spawn_points.has(sp_1):
			spawn_points.append(sp_1)



class FaceTracker extends RefCounted:
	var points:PackedVector2Array
	var indices:PackedInt32Array
	var bounds:Rect2
	var face_index:int

	func _to_string()->String:
		var res:String = "["
		for p in points:
			res += "%s, " % str(p)
		res += "]"
		return res

	func max_dim()->float:
		return max(bounds.size.x, bounds.size.y)

	func reflect_diagonal():
		for p_idx in points.size():
			var p:Vector2 = points[p_idx]
			points[p_idx] = Vector2(p.y, p.x)
		bounds.size = Vector2(bounds.size.y, bounds.size.x)

	func translate(offset:Vector2):
		for p_idx in points.size():
			points[p_idx] += offset
		bounds.position += offset

	func fit_initial_rect():
		bounds = Rect2(points[0], Vector2.ZERO)
		for i in range(1, points.size()):
			bounds = bounds.expand(points[i])
			
		#Move so corner of bounds is at (0, 0)
		for i in points.size():
			points[i] -= bounds.position
		bounds.position = Vector2.ZERO

	func get_best_base_index()->int:
		var best_index:int = -1
		var best_height:float = INF
		
		for i0 in points.size():
			var i1:int = wrap(i0 + 1, 0, points.size())
			
			var base_dir:Vector2 = points[i1] - points[i0]
			var base_origin:Vector2 = points[i0]
			var base_dir_perp:Vector2 = Vector2(-base_dir.y, base_dir.x)
			
			var max_height:float = 0
			
			for j in range(2, points.size()):
				var p_idx:int = wrap(j + i0, 0, points.size())
				var p:Vector2 = points[p_idx]
				var offset:Vector2 = p - base_origin
				var offset_proj:Vector2 = offset.project(base_dir_perp)
				
				max_height = max(max_height, offset_proj.length_squared())
				
			if max_height < best_height:
				best_height = max_height
				best_index = i0

		return best_index

	func rotate_to_best_fit():
		var i0:int = get_best_base_index()
		var i1:int = wrap(i0 + 1, 0, points.size())
		
		var base_dir:Vector2 = (points[i1] - points[i0]).normalized()
		var base_dir_perp:Vector2 = Vector2(-base_dir.y, base_dir.x)
		
		var xform:Transform2D = Transform2D(base_dir, base_dir_perp, Vector2.ZERO)
		var xform_inv:Transform2D = xform.affine_inverse()
		
		for p_idx in points.size():
			var p:Vector2 = xform_inv * points[p_idx]
			points[p_idx] = p


func pack_faces(faces:Array[FaceTracker])->FaceTree:
	faces.sort_custom(func (a:FaceTracker, b:FaceTracker): return a.max_dim() > b.max_dim())

	var tree:FaceTree = FaceTree.new()
	for f in faces:
		tree.add_face(f)
	
	#print(tree)
	return tree

func build_faces(vol:ConvexVolume, margin:float)->FaceTree:
	var faces:Array[FaceTracker]
	
	for f_idx in vol.faces.size():
		var face:ConvexVolume.FaceInfo = vol.faces[f_idx]
		var axis:MathUtil.Axis = MathUtil.get_longest_axis(face.normal)
		
		var cross_vec:Vector3
		if axis == MathUtil.Axis.Y:
			cross_vec = Vector3.FORWARD
		else:
			cross_vec = Vector3.UP
		
		var u_axis:Vector3 = face.normal.cross(cross_vec)
		var v_axis:Vector3 = u_axis.cross(face.normal)
		var basis:Basis = Basis(u_axis, face.normal, v_axis)
		
		var xform:Transform3D = Transform3D(basis, face.get_centroid())
		var xz_xform:Transform3D = xform.affine_inverse()
		
		var tracker:FaceTracker = FaceTracker.new()
		tracker.face_index = f_idx
		faces.append(tracker)
		
		for v_idx in face.vertex_indices:
			var v:ConvexVolume.VertexInfo = vol.vertices[v_idx]
			var proj:Vector3 = xz_xform * v.point
			tracker.points.append(Vector2(proj.x, proj.z))
			tracker.indices.append(v_idx)
		
		#print("face init points %s" % tracker.points)
		
		tracker.rotate_to_best_fit()
		#print("after rot %s" % tracker.points)
		tracker.fit_initial_rect()
		#print("after fit %s" % tracker.points)
		for p_idx in tracker.points.size():
			tracker.points[p_idx] += Vector2(margin, margin)
		tracker.bounds.size += Vector2(margin, margin) * 2
	
	return pack_faces(faces)
	
	
