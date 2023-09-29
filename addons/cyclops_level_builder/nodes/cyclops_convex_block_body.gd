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
class_name CyclopsConvexBlockBody

var mesh_instance:MeshInstance3D
var mesh_wire:MeshInstance3D
var collision_body:StaticBody3D
var collision_shape:CollisionShape3D
var occluder:OccluderInstance3D

var dirty:bool = true

@export var block_data:ConvexBlockData:
	get:
		return block_data
	set(value):
		block_data = value
		dirty = true


@export var materials:Array[Material]

var default_material:Material = preload("res://addons/cyclops_level_builder/materials/grid.tres")
var display_mode:DisplayMode.Type = DisplayMode.Type.MATERIAL

# Called when the node enters the scene tree for the first time.
func _ready():
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	mesh_instance.gi_mode = GeometryInstance3D.GI_MODE_STATIC

	if Engine.is_editor_hint():
		mesh_wire = MeshInstance3D.new()
		add_child(mesh_wire)
	
	collision_body = StaticBody3D.new()
	add_child(collision_body)
	collision_shape = CollisionShape3D.new()
	collision_body.add_child(collision_shape)

	occluder = OccluderInstance3D.new()
	add_child(occluder)
	
	build_from_block()


func build_from_block():
		
	dirty = false
	
	mesh_instance.mesh = null
	collision_shape.shape = null

	if Engine.is_editor_hint():
#		var global_scene:CyclopsGlobalScene = get_node("/root/CyclopsAutoload")
		var global_scene = get_node("/root/CyclopsAutoload")
		display_mode = global_scene.builder.display_mode
	
#	print("block_data %s" % block_data)
#	print("vert points %s" % block_data.vertex_points)
	if !block_data:
		return
	
#	print("got block data")		
	
	var vol:ConvexVolume = ConvexVolume.new()
	vol.init_from_convex_block_data(block_data)
	
	#print("volume %s" % vol)
	
#	var mesh:ImmediateMesh = ImmediateMesh.new()
	var mesh:ArrayMesh

	if Engine.is_editor_hint():
#		var global_scene:CyclopsGlobalScene = get_node("/root/CyclopsAutoload")
		var global_scene = get_node("/root/CyclopsAutoload")
		mesh_wire.mesh = vol.create_mesh_wire(global_scene.outline_material)

		if display_mode == DisplayMode.Type.MATERIAL:
			mesh = vol.create_mesh(materials, default_material)
		elif display_mode == DisplayMode.Type.MESH:
			mesh = vol.create_mesh(materials, default_material, true)
			#print ("added faces")
	else:
		mesh = vol.create_mesh(materials, default_material)
#	vol.append_mesh(mesh, materials, default_material)
	
	mesh_instance.mesh = mesh
	
#	print("===============")
#	GeneralUtil.dump_properties(mesh_instance)
#	print("---------------")
#	GeneralUtil.dump_properties(mesh_instance.mesh)
	
	var shape:ConvexPolygonShape3D = ConvexPolygonShape3D.new()
	shape.points = vol.get_points()
	collision_shape.shape = shape
	
	if !Engine.is_editor_hint():
		#Disabling this in the editor for now since this is causing slowdown
		var occluder_object:ArrayOccluder3D = ArrayOccluder3D.new()
		occluder_object.vertices = vol.get_points()
		occluder_object.indices = vol.get_trimesh_indices()
		occluder.occluder = occluder_object
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if dirty:
		build_from_block()

		
	if Engine.is_editor_hint():
#		var global_scene:CyclopsGlobalScene = get_node("/root/CyclopsAutoload")
		var global_scene = get_node("/root/CyclopsAutoload")

		if display_mode != global_scene.builder.display_mode:
			dirty = true
			return
		
