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

extends CyclopsSnappingSystem
class_name SnappintSystemVertex

@export var max_radius:float = .2


#Point is in world space
func _snap_point(point:Vector3, move_constraint:MoveConstraint)->Vector3:
	var blocks:Array[CyclopsBlock] = plugin.get_blocks()
	
	var best_vertex:Vector3 = Vector3.INF
	var best_dist:float = INF
	
	for block in blocks:
		var ctrl_mesh:ConvexVolume = block.control_mesh
		for v_idx in ctrl_mesh.vertices.size():
			var v:ConvexVolume.VertexInfo = ctrl_mesh.vertices[v_idx]
			var v_point_world:Vector3 = block.global_transform * v.point
		
			var dist:float = (v_point_world - point).length_squared()
			if dist < best_dist && dist <= max_radius * max_radius:
				best_vertex = v_point_world
	
	return constrain_point(point, best_vertex, move_constraint) \
		if is_finite(best_dist) else point




