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
class_name QuickHull

class DirectedEdge extends RefCounted:
	var p0:Vector3
	var p1:Vector3
	
	func _init(p0:Vector3, p1:Vector3):
		self.p0 = p0
		self.p1 = p1
		
	func _to_string()->String:
		return "%s %s" % [p0, p1]
		
	func reverse()->DirectedEdge:
		return DirectedEdge.new(p1, p0)
	
	func equals(e:DirectedEdge)->bool:
		return p0 == e.p0 && p1 == e.p1

class Facet extends RefCounted:
	var plane:Plane
	var points:PackedVector3Array  #Clockwise winding faces out
	var over_points:PackedVector3Array
	
	func _to_string():
		var result:String = "plane %s\ncentroid %s\npoints %s\nover %s" % [plane, (points[0] + points[1] + points[2])/3, points, over_points]
		
		return result
	
	func has_edge(e:DirectedEdge)->bool:
		return (points[0] == e.p0 && points[1] == e.p1) || \
			(points[1] == e.p0 && points[2] == e.p1) || \
			(points[2] == e.p0 && points[0] == e.p1)
	
	func get_edges()->Array[DirectedEdge]:
		var result:Array[DirectedEdge] = []
		
		result.append(DirectedEdge.new(points[0], points[1]))
		result.append(DirectedEdge.new(points[1], points[2]))
		result.append(DirectedEdge.new(points[2], points[0]))
		return result

	func init_from_points(p0:Vector3, p1:Vector3, p2:Vector3):
		#Facet normal points to outside
		plane = Plane(p0, p1, p2)
		points = [p0, p1, p2]
	
	#Create a facet with vertices at p0, p1, p2 and winding such that under_ref 
	# is on the under side of the plane
	func init_from_points_under(p0:Vector3, p1:Vector3, p2:Vector3, under_ref:Vector3):
		#Facet normal points to outside
		plane = Plane(p0, p1, p2)
		if plane.is_point_over(under_ref):
			plane = Plane(p0, p2, p1)
			points = [p0, p2, p1]
		else:
			points = [p0, p1, p2]
			
	func get_furthest_point()->Vector3:
		var best_point:Vector3
		var best_distance:float = 0
		
		for p in over_points:
			var dist = abs(plane.distance_to(p))
			if dist > best_distance:
				best_point = p
				best_distance = dist
				
		return best_point
	
class Hull extends RefCounted:
	var facets:Array[Facet] = []
	
	func get_non_empty_facet()->Facet:
		for f in facets:
			if !f.over_points.is_empty():
				return f
		return null
		
	func get_facet_with_edge(e:DirectedEdge)->Facet:
		for f in facets:
			if f.has_edge(e):
				return f
		return null
	
	func _to_string():
		var result:String = ""
		for f in facets:
			result += "%s\n" % f
		return result


	func get_points()->Array[Vector3]:
		var result:Array[Vector3]	
		
		for f in facets:
			for p in f.points:
				if !result.any(func(pl):return pl.is_equal_approx(p)):
					result.append(p)
		
		return result
				
	func format_points()->String:
		var result:String = ""
		for f in facets:
			result += "%s,\n" % f.points
		return result		


static func form_loop(edges:Array[DirectedEdge])->PackedVector3Array:
	var sorted:Array[DirectedEdge] = []
	
	var cur_edge:DirectedEdge = edges.pop_back()
	sorted.append(cur_edge)
	
	while !edges.is_empty():
		var found_edge:bool = false
		for i in edges.size():
			var e:DirectedEdge = edges[i]
			if e.p0.is_equal_approx(cur_edge.p1):
				edges.remove_at(i)
				cur_edge = e
				sorted.append(e)
				found_edge = true
				break
		
		if !found_edge:
			assert(found_edge, "Unable to complete loop")
			pass
#		if !found_edge:
#			assert(false, "Unable to complete loop")
#			return PackedVector3Array()
	
	var result:PackedVector3Array
	for e in sorted:
		result.append(e.p0)
	return result

static func merge_coplanar_facets(hull:Hull)->Hull:
#	print("hull %s " % hull)
	#print("hull %s " % hull.format_points())
	
	var new_hull:Hull = Hull.new()
	var already_seen:Array[Facet] = []
	
	for facet_idx in hull.facets.size():
		var facet:Facet = hull.facets[facet_idx]
		if already_seen.has(facet):
			continue
		already_seen.append(facet)
		
		#print("merging facet %s" % facet)

		var neighbor_set:Array[Facet] = []
		neighbor_set.append(facet)
		var boundary:Array[DirectedEdge] = []
		
		while !neighbor_set.is_empty():
			var cur_facet:Facet = neighbor_set.pop_back()			
			var edges:Array[DirectedEdge] = cur_facet.get_edges()
			
			for e in edges:
				var neighbor:Facet = hull.get_facet_with_edge(e.reverse())
				if neighbor.plane.is_equal_approx(facet.plane):
					if !already_seen.has(neighbor):
						already_seen.append(neighbor)
						neighbor_set.append(neighbor)
				else:
					boundary.append(e)
		
		
		var points:PackedVector3Array = form_loop(boundary)
				
		var nf:Facet = Facet.new()
		nf.plane = facet.plane
		nf.points = points
		new_hull.facets.append(nf)
	
	return new_hull
	

static func create_initial_simplex(points:PackedVector3Array)->Hull:
	if points.size() < 4:
		return null
		
	#For first two points, pick furthest apart along one of the axes
	var max_x:Vector3 = points[0]
	var min_x:Vector3 = points[0]
	var max_y:Vector3 = points[0]
	var min_y:Vector3 = points[0]
	var max_z:Vector3 = points[0]
	var min_z:Vector3 = points[0]
	
	for idx in range(1, points.size()):
		var p:Vector3 = points[idx]
		if p.x > max_x.x:
			max_x = p
		if p.x < min_x.x:
			min_x = p
		if p.y > max_y.y:
			max_y = p
		if p.y < min_y.y:
			min_y = p
		if p.z > max_z.z:
			max_z = p
		if p.z < min_z.z:
			min_z = p
	
	var p0:Vector3
	var p1:Vector3
	var dx:float = max_x.distance_squared_to(min_x)
	var dy:float = max_y.distance_squared_to(min_y)
	var dz:float = max_z.distance_squared_to(min_z)
	
	if dx > dy and dx > dz:
		p0 = max_x
		p1 = min_x
	elif dy > dz:
		p0 = max_y
		p1 = min_y
	else:
		p0 = max_z
		p1 = min_z
	
	#Find furthest point from line for second point
	var p2:Vector3 = MathUtil.furthest_point_from_line(p0, p1 - p0, points)
	var p3:Vector3 = MathUtil.furthest_point_from_plane(Plane(p0, p1, p2), points)
	
	#Make simplex
	var hull:Hull = Hull.new()
	
	var f0:Facet = Facet.new()
	f0.init_from_points_under(p1, p2, p3, p0)
	var f1:Facet = Facet.new()
	f1.init_from_points_under(p2, p3, p0, p1)
	var f2:Facet = Facet.new()
	f2.init_from_points_under(p3, p0, p1, p2)
	var f3:Facet = Facet.new()
	f3.init_from_points_under(p0, p1, p2, p3)
	
	hull.facets.append(f0)
	hull.facets.append(f1)
	hull.facets.append(f2)
	hull.facets.append(f3)
	
	for p in points:
		for f in hull.facets:
			if f.plane.is_point_over(p) && !f.plane.has_point(p):
				f.over_points.append(p)
	
	return hull


static func quickhull(points:PackedVector3Array)->Hull:
	if points.size() < 4:
		return null
		
	var hull:Hull = create_initial_simplex(points)
	if !hull:
		return null
	
	#print("initial points %s" % points)
	#print("initial simplex %s" % hull.format_points())
	
	while true:
		var facet:Facet = hull.get_non_empty_facet()
		if facet == null:
			break

		#print("-facet %s" % facet)

		var p_over:Vector3 = facet.get_furthest_point()
		#print("over point %s" % p_over)
		
		#print("hull %s" % hull.format_points())
		
		var visibile_faces:Array[Facet] = [facet]
		var edges:Array[DirectedEdge] = facet.get_edges()
		var visited_edges:Array[DirectedEdge] = []
		var boundary_edges:Array[DirectedEdge] = []
		
#		for e in edges:
#			print("init edge search set %s" % e)
			
		
		#Find set of edges that form the boundary of faces visible to point 
		# being added.  We're basically flood filling from central facet until 
		# we hit faces pointing away from reference point.
		while !edges.is_empty():
			var edge:DirectedEdge = edges.pop_back()
			visited_edges.append(edge)
			var edge_inv:DirectedEdge = edge.reverse()
			
			var neighbor_facet:Facet = hull.get_facet_with_edge(edge_inv)
			if neighbor_facet.plane.is_point_over(p_over):
				visibile_faces.append(neighbor_facet)
				visited_edges.append(edge_inv)
				var neighbor_edges:Array[DirectedEdge] = neighbor_facet.get_edges()
				for e in neighbor_edges:
					if !visited_edges.any(func(edge): return edge.equals(e)):
						#print("adding edge to search set %s" % e)
						edges.append(e)
			else:
				boundary_edges.append(edge)
				#print("adding edge to boundary set %s" % edge)
		
		var remaining_over_points:PackedVector3Array
		for f in visibile_faces:
			for pf in f.over_points:
				if pf == p_over:
					continue
				if !remaining_over_points.has(pf):
					remaining_over_points.append(pf)
					#print("over point for test %s" % pf)
					
			hull.facets.remove_at(hull.facets.find(f))
		
		for e in boundary_edges:
			var f:Facet = Facet.new()
			f.init_from_points(e.p0, e.p1, p_over)
			hull.facets.append(f)

			#print("adding facet %s" % f)

			for p in remaining_over_points:
				if f.plane.is_point_over(p) && !f.plane.has_point(p):
					f.over_points.append(p)
				
		#print("hull %s" % hull.format_points())
	
	hull = merge_coplanar_facets(hull)
	return hull

	
	
