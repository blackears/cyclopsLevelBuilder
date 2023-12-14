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
#extends RefCounted
class_name GeometryMesh

var coords:PackedVector3Array
var normals:PackedVector3Array
var uvs:PackedVector2Array

func transform(xform:Transform3D)->GeometryMesh:
	var result:GeometryMesh = GeometryMesh.new()
	
	var basis:Basis = xform.basis
	basis = basis.inverse()
	basis = basis.transposed()
	
	for i in coords.size():
		result.coords.append(xform * coords[i])
		result.uvs.append(uvs[i])
		result.normals.append(basis * normals[i])		
	
	return result
	
func append_to_immediate_mesh(mesh:ImmediateMesh, material:Material, xform:Transform3D = Transform3D.IDENTITY):
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material)

	var basis:Basis = xform.basis
	basis = basis.inverse()
	basis = basis.transposed()

	for i in coords.size():
		var normal:Vector3 = basis * normals[i]
		var coord:Vector3 = xform * coords[i]
		var uv:Vector2 = uvs[i]
		
		mesh.surface_set_normal(normal)
		mesh.surface_set_uv(uv)
		mesh.surface_add_vertex(coord)

	mesh.surface_end()	
	
