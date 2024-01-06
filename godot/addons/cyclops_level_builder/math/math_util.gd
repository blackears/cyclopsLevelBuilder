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
class_name  MathUtil

enum Axis { X, Y, Z }

static func square(value:float)->float:
	return value * value

static func snap_to_grid(pos:Vector3, cell_size:float)->Vector3:
#	return floor(pos / cell_size) * cell_size
	return floor((pos + Vector3(cell_size, cell_size, cell_size) / 2) / cell_size) * cell_size


#Returns intersection of line with point.  
# plane_perp_dir points in direction of plane's normal and does not need to be normalized
static func intersect_plane(ray_origin:Vector3, ray_dir:Vector3, plane_origin:Vector3, plane_perp_dir:Vector3)->Vector3:
	var s:float = (plane_origin - ray_origin).dot(plane_perp_dir) / ray_dir.dot(plane_perp_dir)
	return ray_origin + ray_dir * s

static func intersects_triangle(ray_origin:Vector3, ray_dir:Vector3, p0:Vector3, p1:Vector3, p2:Vector3)->bool:
	#Godot uses clockwise winding
	var tri_area_x2:Vector3 = MathUtil.triangle_area_x2(p0, p1, p2)
	
	var p_hit:Vector3 = MathUtil.intersect_plane(ray_origin, ray_dir, p0, tri_area_x2)
	if !p_hit.is_finite():
		return false
	
	if MathUtil.triangle_area_x2(p_hit, p0, p1).dot(tri_area_x2) < 0:
		return false
	if MathUtil.triangle_area_x2(p_hit, p1, p2).dot(tri_area_x2) < 0:
		return false
	if MathUtil.triangle_area_x2(p_hit, p2, p0).dot(tri_area_x2) < 0:
		return false
		
	return true

class IntersectTriangleResult:
	var position:Vector3
	var normal:Vector3

static func intersect_triangle(ray_origin:Vector3, ray_dir:Vector3, p0:Vector3, p1:Vector3, p2:Vector3)->IntersectTriangleResult:
	#Godot uses clockwise winding
	var tri_area_x2:Vector3 = MathUtil.triangle_area_x2(p0, p1, p2)
	
	var p_hit:Vector3 = MathUtil.intersect_plane(ray_origin, ray_dir, p0, tri_area_x2)
	if !p_hit.is_finite():
		return null
	
	if MathUtil.triangle_area_x2(p_hit, p0, p1).dot(tri_area_x2) < 0:
		return null
	if MathUtil.triangle_area_x2(p_hit, p1, p2).dot(tri_area_x2) < 0:
		return null
	if MathUtil.triangle_area_x2(p_hit, p2, p0).dot(tri_area_x2) < 0:
		return null
		
	var result:IntersectTriangleResult = IntersectTriangleResult.new()
	result.position = p_hit
	result.normal = tri_area_x2.normalized()
	return result
	
#Returns the closest point on the line to the ray
static func closest_point_on_line(ray_origin:Vector3, ray_dir:Vector3, line_origin:Vector3, line_dir:Vector3)->Vector3:
	var a:Vector3 = ray_dir.cross(line_dir)
	var w_perp:Vector3 = ray_dir.cross(a)
	return intersect_plane(line_origin, line_dir, ray_origin, w_perp)

static func closest_point_on_plane(point:Vector3, plane_origin:Vector3, plane_dir:Vector3)->Vector3:
	return point - (point - plane_origin).project(plane_dir)

static func closest_point_on_segment(ray_origin:Vector3, ray_dir:Vector3, seg_start:Vector3, seg_end:Vector3)->Vector3:
	var seg_span:Vector3 = seg_end - seg_start
	var p:Vector3 = closest_point_on_line(ray_origin, ray_dir, seg_start, seg_span)
	var offset:Vector3 = p - seg_start
	if offset.dot(seg_span) < 0:
		return seg_start
	if offset.length_squared() > seg_span.length_squared():
		return seg_end
	return p

#Shortest distance from point to given ray.  Returns NAN if point is behind origin of ray.
static func distance_to_ray(ray_origin:Vector3, ray_dir:Vector3, point:Vector3):
	var offset = point - ray_origin
	var parallel:Vector3 = offset.project(ray_dir)
	if parallel.dot(ray_dir) < 0:
		return NAN
		
	var perp:Vector3 = offset - parallel	
	return perp.length()
	

static func trianglate_face(points:PackedVector3Array, normal:Vector3)->PackedVector3Array:
	var result:PackedVector3Array
	
	while (points.size() >= 3):
		var num_points:int = points.size()
		for i in range(0, num_points):
			var p0:Vector3 = points[i]
			var p1:Vector3 = points[wrap(i + 1, 0, num_points)]
			var p2:Vector3 = points[wrap(i + 2, 0, num_points)]
		
			#Godot uses clockwise winding
			var tri_norm_dir:Vector3 = (p2 - p0).cross(p1 - p0)
			if tri_norm_dir.dot(normal) > 0:
				result.append(p0)
				result.append(p1)
				result.append(p2)
				
				points.remove_at(i + 1)
				break
	
	return result
	
static func trianglate_face_indices(points:PackedVector3Array, indices:Array[int], normal:Vector3)->Array[int]:
	var result:Array[int] = []
	
#	print("trianglate_face_indices %s" % points)
	
	while (points.size() >= 3):
		var num_points:int = points.size()
		var added_point:bool = false

		for i in range(0, num_points):
			var idx0:int = i
			var idx1:int = wrap(i + 1, 0, num_points)
			var idx2:int = wrap(i + 2, 0, num_points)
			var p0:Vector3 = points[idx0]
			var p1:Vector3 = points[idx1]
			var p2:Vector3 = points[idx2]
		
			#Godot uses clockwise winding
			var tri_norm_dir:Vector3 = (p2 - p0).cross(p1 - p0)
			if tri_norm_dir.dot(normal) > 0:
				result.append(indices[idx0])
				result.append(indices[idx1])
				result.append(indices[idx2])
				
#				print("adding indices %s %s %s" % [indices[idx0], indices[idx1], indices[idx2]])
				
				points.remove_at(idx1)
				indices.remove_at(idx1)
				added_point = true
				break
		
		assert(added_point, "failed to add point in triangulation")
#	print("tri_done %s" % str(result))
	
	return result

static func trianglate_face_vertex_indices(points:PackedVector3Array, normal:Vector3)->Array[int]:
	var result:Array[int] = []
	var fv_indices:Array = range(0, points.size())
#	print("trianglate_face_indices %s" % points)
	
	while (points.size() >= 3):
		var num_points:int = points.size()
		var added_point:bool = false

		for i in range(0, num_points):
			var idx0:int = i
			var idx1:int = wrap(i + 1, 0, num_points)
			var idx2:int = wrap(i + 2, 0, num_points)
			var p0:Vector3 = points[idx0]
			var p1:Vector3 = points[idx1]
			var p2:Vector3 = points[idx2]
		
			#Godot uses clockwise winding
			var tri_norm_dir:Vector3 = (p2 - p0).cross(p1 - p0)
			if tri_norm_dir.dot(normal) > 0:
				result.append(fv_indices[idx0])
				result.append(fv_indices[idx1])
				result.append(fv_indices[idx2])
				
#				print("adding indices %s %s %s" % [indices[idx0], indices[idx1], indices[idx2]])
				
				points.remove_at(idx1)
				fv_indices.remove_at(idx1)
				added_point = true
				break
		
		assert(added_point, "failed to add point in triangulation")
#	print("tri_done %s" % str(result))
	
	return result

static func flip_plane(plane:Plane)->Plane:
	return Plane(-plane.normal, plane.get_center())

#Returns a vector pointing along the normal in the clockwise winding direction with a length equal to twice the area of the triangle
static func triangle_area_x2(p0:Vector3, p1:Vector3, p2:Vector3)->Vector3:
	return (p2 - p0).cross(p1 - p0)
	
#Returns a vector pointing along the normal in the clockwise winding direction with a lengh equal to twice the area of the face
static func face_area_x2(points:PackedVector3Array)->Vector3:
	if points.size() <= 1:
		return Vector3.ZERO
	
	var result:Vector3
	var p0:Vector3 = points[0]
	
	for i in range(1, points.size() - 1):
		var p1:Vector3 = points[i]
		var p2:Vector3 = points[i + 1]
		
		result += (p2 - p0).cross(p1 - p0)
	
	return result

static func face_area_x2_2d(points:PackedVector2Array)->float:
	if points.size() <= 1:
		return 0
	
	var result:float
	var p0:Vector2 = points[0]
	
	for i in range(1, points.size() - 1):
		var p1:Vector2 = points[i]
		var p2:Vector2 = points[i + 1]
		
		result += triange_area_2x_2d(p1 - p0, p2 - p0)
	
	return result

static func fit_plane(points:PackedVector3Array)->Plane:
	var normal:Vector3 = face_area_x2(points).normalized()
	return Plane(normal, points[0])

static func snap_to_best_axis_normal(vector:Vector3)->Vector3:
	if abs(vector.x) > abs(vector.y) and abs(vector.x) > abs(vector.z):
		return Vector3(1, 0, 0) if vector.x > 0 else Vector3(-1, 0, 0)
	elif abs(vector.y) > abs(vector.z):
		return Vector3(0, 1, 0) if vector.y > 0 else Vector3(0, -1, 0)
	else:
		return Vector3(0, 0, 1) if vector.z > 0 else Vector3(0, 0, -1)

static func get_longest_axis(vector:Vector3)->Axis:
	if abs(vector.x) > abs(vector.y) and abs(vector.x) > abs(vector.z):
		return Axis.X
	elif abs(vector.y) > abs(vector.z):
		return Axis.Y
	else:
		return Axis.Z
		
static func calc_bounds(points:PackedVector3Array)->AABB:
	if points.is_empty():
		return AABB(Vector3.ZERO, Vector3.ZERO)
	
	var result:AABB = AABB(points[0], Vector3.ZERO)
	for i in range(1, points.size()):
		result = result.expand(points[i])
	return result

#Returns value equal to twise the area between the two vectors.  Clockwise windings have negative area
static func triange_area_2x_2d(a:Vector2, b:Vector2)->float:
	return a.x * b.y - a.y * b.x

#Finds the bouding polygons of this set of points with a clockwise winding
static func bounding_polygon_2d(base_points:PackedVector2Array)->PackedVector2Array:
	if base_points.size() <= 2:
		return base_points

	
	#Start with leftmost vertex, topmost if more than one
	var p_init:Vector2 = base_points[0]
	for p in base_points:
		if p.x < p_init.x or (p.x == p_init.x and p.y > p_init.y):
			p_init = p


	var p_cur:Vector2 = p_init
	var last_segment_dir = Vector2(0, 1)
	
	var polygon:PackedVector2Array

	while true:	
		var best_point:Vector2
		var best_dir:Vector2
		var best_angle:float = 0
		
		for p in base_points:
			if p.is_equal_approx(p_cur):
				continue
				
			var point_dir:Vector2 = (p - p_cur).normalized()
			var angle:float = acos(-last_segment_dir.dot(point_dir))
			
			if angle > best_angle or (angle == best_angle and p_cur.distance_squared_to(p) > p_cur.distance_squared_to(best_point)):
				best_point = p
				best_dir = point_dir
				best_angle = angle
		
		p_cur = best_point
		last_segment_dir = best_dir
		polygon.append(best_point)
		
		if best_point.is_equal_approx(p_init):
			break
		
	return polygon		
		
#static func bounding_polygon(base_points:PackedVector3Array, plane:Plane)->PackedVector3Array:
static func bounding_polygon_3d(base_points:PackedVector3Array, normal:Vector3)->PackedVector3Array:
	if base_points.size() <= 2:
		return base_points
	
	var quat:Quaternion = Quaternion(normal, Vector3.FORWARD)
	
#	var xform:Transform3D = Transform3D(Basis(quat), -base_points[0])
	var xform:Transform3D = Transform3D(Basis(quat))
	xform = xform.translated_local(-base_points[0])
	var xform_inv = xform.inverse()
	
	#print("xform %s" % xform)
	
	var points_local:PackedVector2Array
	
	for p in base_points:
		var p_local = xform * p
		points_local.append(Vector2(p_local.x, p_local.y))
		
	var points_bounds:PackedVector2Array = bounding_polygon_2d(points_local)
		
	var result:PackedVector3Array
	for p in points_bounds:
		var p_result = xform_inv * Vector3(p.x, p.y, 0)
		result.append(p_result)
	
	return result
	
static func points_are_colinear(points:PackedVector3Array)->bool:
	if points.size() <= 2:
		return true
		
	var p0:Vector3 = points[0]
	var p1:Vector3 = p0
	var index:int = 0
	for i in range(1, points.size()):
		if !points[i].is_equal_approx(p0):
			p1 = points[i]
			index = i
			break
		
	if index == 0:
		return true
	
	var v10:Vector3 = p1 - p0
	for i in range(index + 1, points.size()):
		if !triangle_area_x2(p0, p1, points[i]).is_zero_approx():
			return false
			
	return  true
	

static func furthest_point_from_line(line_origin:Vector3, line_dir:Vector3, points:PackedVector3Array)->Vector3:
	var best_point:Vector3
	var best_dist:float = 0
	
	for p in points:
		var offset:Vector3 = p - line_origin
		var along:Vector3 = offset.project(line_dir)
		var perp:Vector3 = offset - along
		var dist:float = perp.length_squared()
		if dist > best_dist:
			best_dist = dist
			best_point = p
		
	return best_point

static func furthest_point_from_plane(plane:Plane, points:PackedVector3Array)->Vector3:
	var best_point:Vector3
	var best_distance:float = 0
	
	for p in points:
		var dist = abs(plane.distance_to(p))
		if dist > best_distance:
			best_point = p
			best_distance = dist
			
	return best_point

static func planar_volume_contains_point(planes:Array[Plane], point:Vector3)->bool:
#	print("candidate %s" % point)
	
	for p in planes:
		var is_over:bool = p.is_point_over(point)
		var is_on:bool = p.has_point(point)
		if !is_over && !is_on:
#			print("reject by %s" % p)
			return false
#	print("passed %s" % point)
	return true
	
static func get_convex_hull_points_from_planes(planes:Array[Plane])->Array[Vector3]:
	#Check for overlapping planes
	for i0 in range(0, planes.size()):
		for i1 in range(i0 + 1, planes.size()):
			var p0:Plane = planes[i0]
			var p1:Plane = flip_plane(planes[i1])
			if p0.is_equal_approx(p1):
				return []
	
	var points:Array[Vector3]
	
	for i0 in range(0, planes.size()):
		for i1 in range(i0 + 1, planes.size()):
			for i2 in range(i1 + 1, planes.size()):
				var result = planes[i0].intersect_3(planes[i1], planes[i2])

				if result == null:
					continue
				#print("candidate %s" % result)
				if !planar_volume_contains_point(planes, result):
					continue
				if points.any(func(p):return p.is_equal_approx(result)):
					continue
				#print("adding %s" % result)
				points.append(result)
	
	return points

static func dist_to_segment_squared_2d(point:Vector2, seg_start:Vector2, seg_end:Vector2)->float:
	if seg_start.is_equal_approx(seg_end):
		return point.distance_squared_to(seg_start)
	
	var dist_sq_p0:float = point.distance_squared_to(seg_start)
	var dist_sq_p1:float = point.distance_squared_to(seg_end)
	var seg_span:Vector2 = seg_end - seg_start
	
	var offset:Vector2 = point - seg_start
	var offset_proj:Vector2 = offset.project(seg_span)
	var perp_dist_sq:float = (offset - offset_proj).length_squared()
	
	if seg_span.dot(offset) < 0:
		return dist_sq_p0
	elif offset_proj.length_squared() > seg_span.length_squared():
		return dist_sq_p1
	return perp_dist_sq
	
class Segment2d extends RefCounted:
	var p0:Vector2
	var p1:Vector2
	
	func _init(p0:Vector2, p1:Vector2):
		self.p0 = p0
		self.p1 = p1
		
	func reverse()->Segment2d:
		return Segment2d.new(p1, p0)
		
	func _to_string():
		return "[%s %s]" % [p0, p1]
		
static func extract_loop_2d(seg_stack:Array[Segment2d])->Loop2D:
	var segs_sorted:Array[Segment2d] = []
	var seg_tail = seg_stack.pop_back()
	segs_sorted.append(seg_tail)
	var seg_head = seg_tail
	
	while !seg_stack.is_empty():
		var found_seg:bool = false
		for s_idx in seg_stack.size():
			var cur_seg:Segment2d = seg_stack[s_idx]
			
			if cur_seg.p0.is_equal_approx(seg_tail.p1):
				#print("matching %s with %s" % [seg_tail, cur_seg])
				segs_sorted.append(cur_seg)
				seg_stack.remove_at(s_idx)
				seg_tail = cur_seg
				found_seg = true
				break
			elif cur_seg.p1.is_equal_approx(seg_tail.p1):
				#print("matching %s with %s" % [seg_tail, cur_seg])
				cur_seg = cur_seg.reverse()
				segs_sorted.append(cur_seg)
				seg_stack.remove_at(s_idx)
				seg_tail = cur_seg
				found_seg = true
				break
			elif cur_seg.p1.is_equal_approx(seg_head.p0):
				#print("matching %s with %s" % [seg_head, cur_seg])
				segs_sorted.insert(0, cur_seg)
				seg_stack.remove_at(s_idx)
				seg_head = cur_seg
				found_seg = true
				break
			elif cur_seg.p0.is_equal_approx(seg_head.p0):
				#print("matching %s with %s" % [seg_head, cur_seg])
				cur_seg = cur_seg.reverse()
				segs_sorted.insert(0, cur_seg)
				seg_stack.remove_at(s_idx)
				seg_head = cur_seg
				found_seg = true
				break

		if !found_seg:
#			push_warning("loop not continuous")
			break

	#print("segs_sorted %s" % str(segs_sorted))
	
	var result:Loop2D = Loop2D.new()
	result.closed = true
	for s in segs_sorted:
		result.points.append(s.p0)
	
	if seg_head.p0 != seg_tail.p1:
		result.points.append(seg_tail.p1)
		result.closed = false
	
	if face_area_x2_2d(result.points) < 0:
		result.reverse()

	#print("loop %s" % str(result))
		
	return result
	
static func get_loops_from_segments_2d(segments:PackedVector2Array)->Array[Loop2D]:
	#print("segments %s" % segments)
	var loops:Array[Loop2D] = []

	var seg_stack:Array[Segment2d] = []
	for i in range(0, segments.size(), 2):
		seg_stack.append(Segment2d.new(segments[i], segments[i + 1]))
	
#	print("segs %s" % str(seg_stack))
	
	while !seg_stack.is_empty():
		var loop:Loop2D = extract_loop_2d(seg_stack)
		loops.append(loop)
	
	#print("result %s" % str(loops))
	return loops

static func create_transform(translation:Vector3, rotation_axis:Vector3, rotation_angle:float, scale:Vector3, pivot:Vector3)->Transform3D:
	var xform:Transform3D = Transform3D.IDENTITY
	
	xform = xform.translated_local(pivot + translation)
	xform = xform.rotated_local(rotation_axis, rotation_angle)
	xform = xform.scaled_local(scale)
	xform = xform.translated_local(-pivot)
	
	return xform
	
static func create_circle_points(center:Vector3, normal:Vector3, radius:float, num_segments:int)->PackedVector3Array:
	var result:PackedVector3Array
	
	var axis:Axis = get_longest_axis(normal)
	var perp_normal:Vector3
	match axis:
		Axis.X:
			perp_normal = normal.cross(Vector3.UP)
		Axis.Y:
			perp_normal = normal.cross(Vector3.FORWARD)
		Axis.Z:
			perp_normal = normal.cross(Vector3.UP)

	var angle_incrment = (PI * 2 / num_segments)
	for i in num_segments:
		var offset:Vector3 = perp_normal.rotated(normal, i * angle_incrment)
		result.append(offset * radius + center)
	
	return result
	
static func get_axis_aligned_tangent_and_binormal(normal:Vector3)->Array[Vector3]:
	var axis:MathUtil.Axis = MathUtil.get_longest_axis(normal)
	#calc tangent and binormal
	var u_normal:Vector3
	var v_normal:Vector3
	match axis:
		MathUtil.Axis.Y:
			u_normal = normal.cross(Vector3.FORWARD)
			v_normal = u_normal.cross(normal)
			return [u_normal, v_normal]
		MathUtil.Axis.X:
			u_normal = normal.cross(Vector3.UP)
			v_normal = u_normal.cross(normal)
			return [u_normal, v_normal]
		MathUtil.Axis.Z:
			u_normal = normal.cross(Vector3.UP)
			v_normal = u_normal.cross(normal)
			return [u_normal, v_normal]

	return []
			
#Returns the planes of a frustum for the rectangular region on the camera's near 
# plane with all planes pointing toward the interior of the frustum
static func calc_frustum_camera_rect(cam:Camera3D, p0:Vector2, p1:Vector2)->Array[Plane]:
	
	var x0 = min(p0.x, p1.x)
	var x1 = max(p0.x, p1.x)
	var y0 = min(p0.y, p1.y)
	var y1 = max(p0.y, p1.y)
	
	var p00:Vector2 = Vector2(x0, y0)
	var p01:Vector2 = Vector2(x0, y1)
	var p10:Vector2 = Vector2(x1, y0)
	var p11:Vector2 = Vector2(x1, y1)
	
#	print("cam rect %s" % str([p00, p11]))
	
	#Cam project_position does not work if we set distance to far plane, so back off a bit
	var far_scalar:float = .95
	
	var p000:Vector3 = cam.project_position(p00, cam.near)
	var p100:Vector3 = cam.project_position(p10, cam.near)
	var p010:Vector3 = cam.project_position(p01, cam.near)
	var p110:Vector3 = cam.project_position(p11, cam.near)
	var p001:Vector3 = cam.project_position(p00, cam.far * far_scalar)
	var p101:Vector3 = cam.project_position(p10, cam.far * far_scalar)
	var p011:Vector3 = cam.project_position(p01, cam.far * far_scalar)
	var p111:Vector3 = cam.project_position(p11, cam.far * far_scalar)
	
#	print("points %s" % str([p000, p100, p010, p110, p001, p101, p011, p111, ]))
	
	var plane_left:Plane = Plane(p001, p011, p010)
	var plane_right:Plane = Plane(p101, p110, p111)
	var plane_top:Plane = Plane(p011, p111, p110)
	var plane_bottom:Plane = Plane(p001, p100, p101)
	var plane_near:Plane = Plane(p000, p110, p100)
	var plane_far:Plane = Plane(p001, p111, p011)
	
	return [plane_left, plane_right, plane_top, plane_bottom, plane_near, plane_far]

static func clip_polygon(points:PackedVector3Array, plane:Plane)->PackedVector3Array:
	var result:PackedVector3Array

	#Cut at planr intersection
	var points_on_or_over:PackedVector3Array
	
	for p_idx0 in points.size():
		var p_idx1:int = wrap(p_idx0 + 1, 0, points.size())
		
		var p0:Vector3 = points[p_idx0]
		var p1:Vector3 = points[p_idx1]
		
		var on0:bool = plane.has_point(p0)
		var over0:bool = plane.is_point_over(p0)
		var under0:bool = !on0 && !over0
		var on1:bool = plane.has_point(p1)
		var over1:bool = plane.is_point_over(p1)
		var under1:bool = !on1 && !over1
		
		if on0 || over0:
			points_on_or_over.append(p0)
		
		if (under0 && over1) || (over0 && under1):
			points_on_or_over.append(plane.intersects_segment(p0, p1))

	return points_on_or_over


#Snaps point to a point appearing in the list if distance to it is <= radius. Otherwise appends 
# point to point list
static func snap_point_to_point_list_or_append(point:Vector3, list:PackedVector3Array, radius:float = .005):
	for p in list:
		if p.distance_squared_to(point) < radius * radius:
			return p
	list.append(point)
	return point
	

static func create_loop_from_directed_segments(segs:Array[Segment3], snap_radius:float = .005)->PackedVector3Array:
	var snap_list:PackedVector3Array
	for seg in segs:
		seg.p0 = snap_point_to_point_list_or_append(seg.p0, snap_list, snap_radius)
		seg.p1 = snap_point_to_point_list_or_append(seg.p1, snap_list, snap_radius)
		
	
	var seg_stack:Array[Segment3]
	var sorted_segs:Array[Segment3]
	
	for s in segs:
		if !is_zero_approx(s.length_squared()):
			seg_stack.append(s)

	
	sorted_segs.append(seg_stack.pop_back())
	while !seg_stack.is_empty():
		var found_seg:bool = false
		var min_dist:float = 10000
		for i in seg_stack.size():
			var s:Segment3 = seg_stack[i]
			
#			if s.p0.is_equal_approx(sorted_segs.back().p1):
			var dist:float = s.p0.distance_to(sorted_segs.back().p1)
			min_dist = min(min_dist, dist)
			
			if dist < .005:
#			if s.p0.is_equal_approx(sorted_segs.back().p1):
				sorted_segs.append(s)
				seg_stack.remove_at(i)
				found_seg = true
				break
#			if s.p1.is_equal_approx(sorted_segs.back().p1):
#				sorted_segs.append(s.reversed())
#				seg_stack.remove_at(i)
#				found_seg = true
#				break

		if !found_seg:
			print("Error: could not form loop")
			return []
	
	var result:PackedVector3Array
	for s in sorted_segs:
		result.append(s.p0)
		
	return result

static func clip_polygon_separate(points:PackedVector3Array, plane:Plane)->ClipPolyResult:
	
	#Clip points to plane.
	var clipped_points:PackedVector3Array = clip_polygon(points, plane)
	
	#Every point should now be on or above the plane
	var is_over:Array[bool]
	var all_over:bool = true
	var none_over:bool = true
	for p in clipped_points:
		var is_on:bool = plane.has_point(p)
		if is_on:
			all_over = false
		else:
			none_over = false
			
		is_over.append(!is_on)
	
	if all_over:
		return ClipPolyResult.new([clipped_points])
		
	if none_over:
		return ClipPolyResult.new()
	
	var start_idx:int = -1
	for p_idx0 in clipped_points.size():
		var p_idx1:int = wrap(p_idx0 + 1, 0, clipped_points.size())
		
		var over0:bool = is_over[p_idx0]
		var over1:bool = is_over[p_idx1]
		
		if !over0 && over1:
			start_idx = p_idx0
			break

	#If you think of the clipped_points as a string where every point on the plane is
	# represented by the character 'n' and every point over the plane is the character 
	# 'v', then every sub polygon will be a string that can be represented by the 
	# regular expression "(nv+n)"
	var results:Array[PackedVector3Array]= []
	var cut_segments:Array[Segment3]
	
	var writing_shape:bool = true
	var sub_poly:PackedVector3Array
	for i in clipped_points.size():
		var p_idx0:int = wrap(i + start_idx, 0, clipped_points.size())
		var p_idx1:int = wrap(i + start_idx + 1, 0, clipped_points.size())
		
		if is_over[p_idx1]:
			sub_poly.append(clipped_points[p_idx0])
			
		elif is_over[p_idx0]:
			sub_poly.append(clipped_points[p_idx0])
			sub_poly.append(clipped_points[p_idx1])
			
			cut_segments.append(Segment3.new(sub_poly[sub_poly.size() - 1], sub_poly[0]))
			results.append(sub_poly.duplicate())
			sub_poly.clear()
	
	return ClipPolyResult.new(results, cut_segments)

	

static func polygon_intersects_frustum(points:PackedVector3Array, frustum:Array[Plane])->bool:
	var points_i:PackedVector3Array = points
	
	for plane in frustum:
		points_i = clip_polygon(points_i, plane)
		if points_i.is_empty():
			return false
	
	return true
	

static func frustum_contians_point(planes:Array[Plane], point:Vector3)->bool:
	for plane in planes:
		if !plane.is_point_over(point) && !plane.has_point(point):
			return false
	return true

static func frustum_intersects_sphere(planes:Array[Plane], center:Vector3, radius:float)->bool:
	for plane in planes:
		var dist:float = plane.distance_to(center)
		
		if dist < -radius:
			return false
			
	return true
	

func plane_intesects_point_cloud(points:PackedVector3Array, plane:Plane)->bool:
	
	var is_over:bool = false
	var is_under:bool = false
	for p in points:
		if plane.has_point(p):
			continue
		
		if plane.is_point_over(p):
			is_over = true
		else:
			is_under = true
		if is_over && is_under:
			return true
			
	return false

#Returns vector with [R, Q] where R is the orthogonal basis 
# and Q is a triangular matrix such that basis = R * Q
static func gram_schmidt_decomposition(basis:Basis)->Array[Basis]:
	#https://en.wikipedia.org/wiki/Gram%E2%80%93Schmidt_process
	var v0:Vector3 = basis.x
	var v1:Vector3 = basis.y
	var v2:Vector3 = basis.z
	
	var u0:Vector3 = v0
	var u1:Vector3 = v1 - v1.project(u0)
	var u2:Vector3 = v2 - v2.project(u0) - v2.project(u1)
	
	var R:Basis = Basis(u0.normalized(), u1.normalized(), u2.normalized())
	var R_inv:Basis = R.inverse()
	var Q:Basis = R_inv * basis
	
	return [R, Q]

#Decomposes matrix into translate, rotate, scale and shear vectors where
# M = T * R * Sh * S
# where:
#	T - translate matrix
#	R - rotate matrix
#	Sh - shear matrix
#	S - scale matrix
#
# Shear matrix for vector (x, y, z) is
# [1 x y]
# [0 1 z]
# [0 0 1]
static func decompose_matrix_3d(m:Transform3D, order:EulerOrder = EULER_ORDER_YXZ)->Dictionary:
	
	if is_zero_approx(m.basis.determinant()):
		return {"valid": false}
	
	var basis:Basis = m.basis
	var gram_schmidt = gram_schmidt_decomposition(basis)
	var rot_mtx = gram_schmidt[0]
	var euler:Vector3 = rot_mtx.get_euler(order)
	
	var scale_shear = gram_schmidt[1]
	var scale:Vector3 = Vector3(scale_shear.x.x, scale_shear.y.y, scale_shear.z.z)
	var scale_mat:Basis = Basis.from_scale(scale)
	var shear:Basis = scale_shear * scale_mat.inverse()
	
	#print(shear)
	
	return {
		"valid": true,
		"translate": m.origin,
		"rotate": euler,
		"scale": scale,
		"shear": Vector3(shear.y.x, shear.z.x, shear.z.y)
	}
 
static func compose_matrix_3d(translate:Vector3, rotate:Vector3 = Vector3.ZERO, order:EulerOrder = EULER_ORDER_YXZ, shear:Vector3 = Vector3.ZERO, scale:Vector3 = Vector3.ONE)->Transform3D:
	var scale_mat:Basis = Basis.from_scale(scale)
	var shear_mat:Basis = Basis( 
		Vector3(1, 0, 0),
		Vector3(shear.x, 1, 0),
		Vector3(shear.y, shear.z, 1))
	var rot_mat:Basis = Basis.from_euler(rotate, order)
	var basis:Basis = rot_mat * shear_mat * scale_mat
	
	return Transform3D(basis, translate)
	
static func clip_segment_to_plane_3d(p:Plane, v0:Vector3, v1:Vector3)->PackedVector3Array:
	var clip_v0:bool = !p.is_point_over(v0)
	var clip_v1:bool = !p.is_point_over(v1)
	if clip_v0 && clip_v1:
		return []
	
	if clip_v0:
		v0 = p.intersects_segment(v0, v1)
	elif clip_v1:
		v1 = p.intersects_segment(v0, v1)
	
	return [v0, v1]
	
