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
extends Node3D
class_name GizmoBase


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func intersect_part(ray_origin:Vector3, ray_dir:Vector3, viewport_camera:Camera3D, mesh_inst:MeshInstance3D)->MathUtil.IntersectTriangleResult:
	var proj:Projection = viewport_camera.get_camera_projection()
	
	#Calc modelview matrix
	var view_inv_matrix:Transform3D = viewport_camera.global_transform.affine_inverse()
	var mv:Projection = Projection(view_inv_matrix * mesh_inst.global_transform)
	#Static size adjustment
	if proj[3][3] != 0:
		var h:float = abs(1 / (2 * proj[1][1]))
		var sc = h * 2
		mv[0] *= sc
		mv[1] *= sc
		mv[2] *= sc
	else:
		var sc:float = -mv[3].z
		mv[0] *= sc
		mv[1] *= sc
		mv[2] *= sc
	
	var model_mtx:Projection = Projection(viewport_camera.global_transform) * mv

	var mesh:Mesh = mesh_inst.mesh
	var tris:PackedVector3Array = mesh.get_faces()
	for i in range(0, tris.size(), 3):
		var p0:Vector3 = tris[i]
		var p1:Vector3 = tris[i + 1]
		var p2:Vector3 = tris[i + 2]
		
		var p0_t:Vector3 = proj_mul_point(model_mtx, p0)
		var p1_t:Vector3 = proj_mul_point(model_mtx, p1)
		var p2_t:Vector3 = proj_mul_point(model_mtx, p2)
		
		#print("tri world %s %s %s" % [p0_t, p1_t, p2_t])
		var res = MathUtil.intersect_triangle(ray_origin, ray_dir, p0_t, p1_t, p2_t)
		
		if res:
			return res
		
	return null
	

func proj_mul_point(m:Projection, p:Vector3)->Vector3:
	var p4:Vector4 = Vector4(p.x, p.y, p.z, 1)
	var p4_t = m * p4
	p4_t /= p4_t.w
	return Vector3(p4_t.x, p4_t.y, p4_t.z)


func proj_mul_vec(m:Projection, p:Vector3)->Vector3:
	var p4:Vector4 = Vector4(p.x, p.y, p.z, 0)
	var p4_t = m * p4
	p4_t /= p4_t.w
	return Vector3(p4_t.x, p4_t.y, p4_t.z)
