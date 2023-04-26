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
var collision_body:StaticBody3D
var collision_shape:CollisionShape3D

@export var block_data:ConvexBlockData:
	get:
		return block_data
	set(value):
		block_data = value
		build_from_block()


@export var materials:Array[Material]
var init:bool = false

var default_material:Material = preload("res://addons/cyclops_level_builder/materials/grid.tres")

# Called when the node enters the scene tree for the first time.
func _ready():
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	collision_body = StaticBody3D.new()
	add_child(collision_body)
	collision_shape = CollisionShape3D.new()
	collision_body.add_child(collision_shape)
	
#	collision_shape = ConvexPolygonShape3D.new()
	init = true
	build_from_block()

func build_from_block():
	if !init:
		return
	
	mesh_instance.mesh = null
	collision_shape.shape = null
	
#	print("block_data %s" % block_data)
#	print("vert points %s" % block_data.vertex_points)
	if !block_data:
		return
	
#	print("got block data")		
	
	var vol:ConvexVolume = ConvexVolume.new()
	vol.init_from_convex_block_data(block_data)
	
	#print("volume %s" % vol)
	
	var mesh:ImmediateMesh = ImmediateMesh.new()

	vol.append_mesh(mesh, materials, default_material)
	if Engine.is_editor_hint():
		var global_scene:CyclopsGlobalScene = get_node("/root/CyclopsAutoload")
		vol.append_mesh_wire(mesh, global_scene.outline_material)
	
	mesh_instance.mesh = mesh
	
	var shape:ConvexPolygonShape3D = ConvexPolygonShape3D.new()
	shape.points = vol.get_points()
	collision_shape.shape = shape
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
