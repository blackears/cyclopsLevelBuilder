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

static func snap_to_grid(pos:Vector3, cell_size:float)->Vector3:
#	return floor(pos / cell_size) * cell_size
	return floor((pos + Vector3(cell_size, cell_size, cell_size) / 2) / cell_size) * cell_size

#Returns intersection of line with point.  
# plane_perp_dir points in direction of plane's normal and does not need to be normalized
static func intersect_plane(ray_origin:Vector3, ray_dir:Vector3, plane_origin:Vector3, plane_perp_dir:Vector3)->Vector3:
	var s:float = (plane_origin - ray_origin).dot(plane_perp_dir) / ray_dir.dot(plane_perp_dir)
	return ray_origin + ray_dir * s

#Returns the closest point on the line to the ray
static func closest_point_on_line(ray_origin:Vector3, ray_dir:Vector3, line_origin:Vector3, line_dir:Vector3)->Vector3:
	var a:Vector3 = ray_dir.cross(line_dir)
	var w_perp:Vector3 = ray_dir.cross(a)
	return intersect_plane(line_origin, line_dir, ray_origin, w_perp)

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

#Returns a vector pointing along the normal in the clockwise winding direction with a length equal to twice the area of the triangle
static func triangle_area_x2(p0:Vector3, p1:Vector3, p2:Vector3)->Vector3:
	return (p2 - p0).cross(p1 - p0)
	
#Returns a vector poitning along the normal in the clockwise winding direction with a lengh equal to twice the area of the face
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
	
	#var quat:Quaternion = Quaternion()
#	var basis:Basis = Basis.IDENTITY
	#Rotation to point along Z axis
#	var axis = Vector3.FORWARD.cross(normal)
#	if !axis.is_zero_approx():
#		#Roy=tate normal onto forward axis
#		quat.x = axis.x
#		quat.y = axis.y
#		quat.z = axis.z
#		quat.w = 1 + Vector3.FORWARD.dot(normal)
		
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
		var dist = plane.distance_to(p)
		if dist > best_distance:
			best_point = p
			best_distance = dist
			
	return best_point

	
