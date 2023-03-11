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
class_name GeometryBrush

signal control_mesh_changed

@export var material:Material
var dirty:bool = true

#var control_mesh:ControlMesh
@export var control_mesh:ControlMesh:
	get:
		return control_mesh
	set(value):
		if control_mesh != value:
			control_mesh = value
			control_mesh_changed.emit()
			dirty = true

var mesh_instance:MeshInstance3D

# Called when the node enters the scene tree for the first time.
func _ready():
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if dirty:
		rebuild()
	
func rebuild():
	if !control_mesh:
		mesh_instance.mesh = null
		return
		
	
	var mesh:ImmediateMesh = ImmediateMesh.new()
	
	
	for face in control_mesh.faces:
		mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, material)
		print("face %s" % face.index)
		
		var num_corners:int = face.face_corner_indices.size()
		for i in num_corners:
#			var idx = ((i + 1) >> 1) if i & 1 else wrap(num_corners - (i >> 1), 0, num_corners)
#			var idx = num_corners - (i + 1) / 2 if i & 1 else i / 2
			var idx = (i + 1) / 2 if i & 1 else wrap(num_corners - (i / 2), 0, num_corners)
			var fc:ControlMesh.FaceCornerInfo = control_mesh.face_corners[face.face_corner_indices[idx]]
#			if i == 0:
#				idx = 0
			mesh.surface_add_vertex(control_mesh.vertices[fc.vertex_index].point)
			print ("%s %s %s" % [idx, fc.vertex_index, control_mesh.vertices[fc.vertex_index].point])
	
		mesh.surface_end()
	
	
	mesh_instance.mesh = mesh
	dirty = false
