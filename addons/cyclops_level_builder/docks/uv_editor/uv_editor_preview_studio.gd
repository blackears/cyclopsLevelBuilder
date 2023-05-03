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
class_name UvEditorPreviewStudio


@export var target_material:Material:
	get:
		return target_material
	set(value):
		target_material = value
		#$Node3D/MeshInstance3D.material_override = target_material
		dirty = true

@export var uv_transform:Transform2D = Transform2D.IDENTITY:
	get:
		return uv_transform
	set(value):
		if value == uv_transform:
			return 
		uv_transform = value
		dirty = true

var dirty:bool = true
var points:PackedVector3Array = [Vector3(-1, 1, 0), Vector3(1, 1, 0), Vector3(-1, -1, 0), Vector3(1, -1, 0)]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
#	print("_process")
	if dirty:
		var mesh:ImmediateMesh = ImmediateMesh.new()
		
		mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, target_material)

		mesh.surface_set_normal(Vector3(0, 0, 1))
		for p in points:		
			mesh.surface_set_uv(uv_transform * Vector2(p.x, -p.y))
			mesh.surface_add_vertex(p)
		
		mesh.surface_end()
		
#		print("Building preview mesh")
		$MeshInstance3D.mesh = mesh
		dirty = false
