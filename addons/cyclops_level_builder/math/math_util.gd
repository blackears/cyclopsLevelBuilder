extends Node
class_name  MathUtil

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
