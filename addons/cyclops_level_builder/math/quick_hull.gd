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
			var dist = plane.distance_to(p)
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
		
	func format_points()->String:
		var result:String = ""
		for f in facets:
			result += "%s,\n" % f.points
		return result		

static func determinate_3(v0:Vector3, v1:Vector3, v2:Vector3)->float:
	return v0.x * v1.y * v2.z \
		- v0.x * v1.z * v2.y \
		+ v0.z * v1.x * v2.y \
		- v0.y * v1.x * v2.z \
		+ v0.y * v1.z * v2.x \
		- v0.z * v1.y * v2.x;

static func create_initial_simplex(points:PackedVector3Array)->Hull:
	#Find initial simplex
	var p0:Vector3 = points[0]
	var p1:Vector3 = points[1]
	var p2:Vector3 = Vector3.INF
	var p3:Vector3 = Vector3.INF
	
	var p10:Vector3 = p1 - p0
	var p20:Vector3
	var p30:Vector3
	
	var idx:int = 2
	while true:
		p2 = points[idx]
		idx += 1
		p20 = p2 - p0
		if !p10.cross(p20).is_zero_approx():
			break
		if idx == points.size():
			return null

	while true:
		p3 = points[idx]
		idx += 1
		p30 = p3 - p0
		var det = determinate_3(p10, p20, p30)
		if !is_zero_approx(det):
			break
			
		if idx == points.size():
			return null

	
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
	
	#print("initial simplex %s" % hull)
	
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
						print("adding edge to search set %s" % e)
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
		
	return hull

	
	
