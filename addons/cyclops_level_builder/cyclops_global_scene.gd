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

@export var selection_color:Color = Color(1, .5, .5, 1)
@export var default_material:Material = preload("res://addons/cyclops_level_builder/materials/grid.tres")
@export var outline_material:Material = preload("res://addons/cyclops_level_builder/materials/block_outline_material.tres")

@export var tool_material:Material
@export var tool_selected_material:Material
#@export var selected_material:Material
var tool_mesh:ImmediateMesh
#var vertex_size:float = .05

var unit_sphere:GeometryMesh
var builder:CyclopsLevelBuilder

# Called when the node enters the scene tree for the first time.
func _ready():
	unit_sphere = MathGeometry.unit_sphere()
	
	tool_mesh = ImmediateMesh.new()
	$ToolInstance3D.mesh = tool_mesh


func draw_line(p0:Vector3, p1:Vector3):
	
	tool_mesh.surface_begin(Mesh.PRIMITIVE_LINES, tool_material)

	tool_mesh.surface_add_vertex(p0)
	tool_mesh.surface_add_vertex(p1)
	
	tool_mesh.surface_end()

func draw_loop(points:PackedVector3Array, closed:bool = true):
	for p in points:
		draw_vertex(p)
	
	tool_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, tool_material)

	for p in points:
		tool_mesh.surface_add_vertex(p)

	if closed:		
		tool_mesh.surface_add_vertex(points[0])
	
	tool_mesh.surface_end()
	

func draw_prism(points:PackedVector3Array, extrude:Vector3):
	for p in points:
		draw_vertex(p)
		draw_vertex(p + extrude)
	
	#Bottom loop	
	tool_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, tool_material)

	for p in points:
		tool_mesh.surface_add_vertex(p)

	tool_mesh.surface_add_vertex(points[0])
	
	tool_mesh.surface_end()

	#Top loop	
	tool_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, tool_material)

	for p in points:
		tool_mesh.surface_add_vertex(p + extrude)

	tool_mesh.surface_add_vertex(points[0] + extrude)
	
	tool_mesh.surface_end()
	
	#Sides
	tool_mesh.surface_begin(Mesh.PRIMITIVE_LINES, tool_material)

	for p in points:
		tool_mesh.surface_add_vertex(p)
		tool_mesh.surface_add_vertex(p + extrude)
	
	tool_mesh.surface_end()
	
	#$ToolInstance3D.mesh = mesh
		

func draw_rect(start:Vector3, end:Vector3):	
	
	var p0:Vector3 = start
	var p2:Vector3 = end
	var p1:Vector3 = Vector3(p0.x, p0.y, p2.z)
	var p3:Vector3 = Vector3(p2.x, p0.y, p0.z)
	
	draw_vertex(p0)
	draw_vertex(p1)
	draw_vertex(p2)
	draw_vertex(p3)
	
	tool_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, tool_material)

	tool_mesh.surface_add_vertex(p0)
	tool_mesh.surface_add_vertex(p1)
	tool_mesh.surface_add_vertex(p2)
	tool_mesh.surface_add_vertex(p3)
	tool_mesh.surface_add_vertex(p0)
	
	tool_mesh.surface_end()
	
	#$ToolInstance3D.mesh = tool_mesh

func clear_tool_mesh():
	#tool_mesh = ImmediateMesh.new()
	#$ToolInstance3D.mesh = tool_mesh
	tool_mesh.clear_surfaces()
	

func draw_cube(p0:Vector3, p1:Vector3, p2:Vector3):	
#	print ("draw_cube %s %s %s" % [p0, p1, p2])
	
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
	
	draw_vertex(p000)
	draw_vertex(p001)
	draw_vertex(p010)
	draw_vertex(p011)
	draw_vertex(p100)
	draw_vertex(p101)
	draw_vertex(p110)
	draw_vertex(p111)
	
	
	tool_mesh.surface_begin(Mesh.PRIMITIVE_LINES, tool_material)

	tool_mesh.surface_add_vertex(p000)
	tool_mesh.surface_add_vertex(p001)
	tool_mesh.surface_add_vertex(p000)
	tool_mesh.surface_add_vertex(p100)
	tool_mesh.surface_add_vertex(p101)
	tool_mesh.surface_add_vertex(p001)
	tool_mesh.surface_add_vertex(p101)
	tool_mesh.surface_add_vertex(p100)

	tool_mesh.surface_add_vertex(p010)
	tool_mesh.surface_add_vertex(p011)
	tool_mesh.surface_add_vertex(p010)
	tool_mesh.surface_add_vertex(p110)
	tool_mesh.surface_add_vertex(p111)
	tool_mesh.surface_add_vertex(p011)
	tool_mesh.surface_add_vertex(p111)
	tool_mesh.surface_add_vertex(p110)
	
	tool_mesh.surface_add_vertex(p000)
	tool_mesh.surface_add_vertex(p010)
	tool_mesh.surface_add_vertex(p100)
	tool_mesh.surface_add_vertex(p110)
	tool_mesh.surface_add_vertex(p101)
	tool_mesh.surface_add_vertex(p111)
	tool_mesh.surface_add_vertex(p001)
	tool_mesh.surface_add_vertex(p011)
	
	tool_mesh.surface_end()
	
	#$ToolInstance3D.mesh = mesh

func draw_vertex(position:Vector3):
	var xform:Transform3D = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * builder.handle_point_radius), position)
	draw_sphere(xform)

func draw_points(points:PackedVector3Array):
	for p in points:
		draw_vertex(p)

func draw_sphere(xform:Transform3D = Transform3D.IDENTITY, segs_lat:int = 6, segs_long:int = 8):
#	var geo_mesh:GeometryMesh = MathGeometry.unit_sphere()
#	geo_mesh = geo_mesh.transform(xform)
#	geo_mesh.append_to_immediate_mesh(tool_mesh, tool_material, xform)
	
	unit_sphere.append_to_immediate_mesh(tool_mesh, tool_material, xform)
	

func draw_selected_blocks(viewport_camera:Camera3D):
	var global_scene:CyclopsGlobalScene = builder.get_node("/root/CyclopsAutoload")
	#var mesh:ImmediateMesh = ImmediateMesh.new()
	
	var blocks_root:CyclopsBlocks = self.builder.active_node
	for child in blocks_root.get_children():
		if child is CyclopsConvexBlock:
			var block:CyclopsConvexBlock = child
			if block.selected:
				block.append_mesh_outline(tool_mesh, viewport_camera)
					

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
#	if Engine.is_editor_hint():
#		rebuild_mesh()
	pass
