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
class_name CyclopsGlobalScene

@export var tool_material:BaseMaterial3D
#@export var selected_material:Material

#var mesh:ImmediateMesh
#var dirty:bool = true

# Called when the node enters the scene tree for the first time.
func _ready():
	#mesh = ImmediateMesh.new()
	pass # Replace with function body.
	
#func rebuild_mesh():
##	var mat:StandardMaterial3D = StandardMaterial3D.new()
##	mat.emission = Color(1, 0, 1)
##	mat.emission_enabled = true
##	mat.albedo_color = Color(0, 0, 0)
#
#
#	if dirty:
#		var mesh:ImmediateMesh = ImmediateMesh.new()
#
##		mesh.clear_surfaces()
#
##		mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, vertex_material)
#		mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, tool_material)
##		mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, mat)
#
#		mesh.surface_add_vertex(Vector3(0, 0, 0))
#		mesh.surface_add_vertex(Vector3(0, 1, 0))
#		mesh.surface_add_vertex(Vector3(0, 1, 1))
#
#		mesh.surface_end()
#
#		$ToolInstance3D.mesh = mesh
#
#		dirty = false

func draw_rect(start:Vector3, end:Vector3):	
	#print ("draw_rect %s %s" % [start, end])
	
	var p0:Vector3 = start
	var p2:Vector3 = end
	var p1:Vector3 = Vector3(p0.x, p0.y, p2.z)
	var p3:Vector3 = Vector3(p2.x, p0.y, p0.z)
	
	
	var mesh:ImmediateMesh = ImmediateMesh.new()
	
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, tool_material)

	mesh.surface_add_vertex(p0)
	mesh.surface_add_vertex(p1)
	mesh.surface_add_vertex(p2)
	mesh.surface_add_vertex(p3)
	mesh.surface_add_vertex(p0)
	
	mesh.surface_end()
	
	$ToolInstance3D.mesh = mesh
	

func draw_cube(p0:Vector3, p1:Vector3, p2:Vector3):	
	print ("draw_cube %s %s %s" % [p0, p1, p2])
	
	var bounds:AABB = AABB(p0, Vector3.ZERO)
	bounds = bounds.expand(p1)
	bounds = bounds.expand(p2)
	
	var p000:Vector3 = bounds.position
	var p111:Vector3 = bounds.end
	var p001:Vector3 = Vector3(p000.x, p000.y, p111.z)
	var p010:Vector3 = Vector3(p000.x, p111.y, p000.z)
	var p011:Vector3 = Vector3(p000.x, p111.y, p111.z)
	var p100:Vector3 = Vector3(p111.x, p000.y, p000.z)
	var p101:Vector3 = Vector3(p111.x, p000.y, p111.z)
	var p110:Vector3 = Vector3(p111.x, p111.y, p000.z)
	
	
	var mesh:ImmediateMesh = ImmediateMesh.new()
	
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, tool_material)

	mesh.surface_add_vertex(p000)
	mesh.surface_add_vertex(p001)
	mesh.surface_add_vertex(p000)
	mesh.surface_add_vertex(p100)
	mesh.surface_add_vertex(p101)
	mesh.surface_add_vertex(p001)
	mesh.surface_add_vertex(p101)
	mesh.surface_add_vertex(p100)

	mesh.surface_add_vertex(p010)
	mesh.surface_add_vertex(p011)
	mesh.surface_add_vertex(p010)
	mesh.surface_add_vertex(p110)
	mesh.surface_add_vertex(p111)
	mesh.surface_add_vertex(p011)
	mesh.surface_add_vertex(p111)
	mesh.surface_add_vertex(p110)
	
	mesh.surface_add_vertex(p000)
	mesh.surface_add_vertex(p010)
	mesh.surface_add_vertex(p100)
	mesh.surface_add_vertex(p110)
	mesh.surface_add_vertex(p101)
	mesh.surface_add_vertex(p111)
	mesh.surface_add_vertex(p001)
	mesh.surface_add_vertex(p011)
	
	mesh.surface_end()
	
#$	$ControlMesh.mesh = mesh
	$ToolInstance3D.mesh = mesh

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
#	if Engine.is_editor_hint():
#		rebuild_mesh()
	pass
