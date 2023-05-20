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
extends Node
class_name CyclopsConvexBlock

signal mesh_changed

@export var materials:Array[Material]

var control_mesh:ConvexVolume

var selected:bool = false:
	get:
		return selected
	set(value):
		if value == selected:
			return
		selected = value
		mesh_changed.emit()

var active:bool:
	get:
		return active
	set(value):
		if value == active:
			return
		active = value
		mesh_changed.emit()


var default_material:Material = preload("res://addons/cyclops_level_builder/materials/grid.tres")

@export var block_data:ConvexBlockData:
	get:
		return block_data
	set(value):
		if block_data != value:
			block_data = value
			control_mesh = ConvexVolume.new()
			control_mesh.init_from_convex_block_data(block_data)
			
			mesh_changed.emit()
	

func intersect_ray_closest(origin:Vector3, dir:Vector3)->IntersectResults:
	if !block_data:
		return null
	
	var result:IntersectResults = control_mesh.intersect_ray_closest(origin, dir)
	if result:
#		result.object = self
		result.object = null
		
	return result


func select_face(face_idx:int, select_type:Selection.Type = Selection.Type.REPLACE):
	if select_type == Selection.Type.REPLACE:
		for f in control_mesh.faces:
			f.selected = f.index == face_idx
	elif select_type == Selection.Type.ADD:
		control_mesh.faces[face_idx].selected = true
	elif select_type == Selection.Type.SUBTRACT:
		control_mesh.faces[face_idx].selected = true
	elif select_type == Selection.Type.TOGGLE:
		control_mesh.faces[face_idx].selected = !control_mesh.faces[face_idx].selected

	mesh_changed.emit()

func append_mesh(mesh:ImmediateMesh):
#	print("adding block mesh %s" % name)
	#var global_scene:CyclopsGlobalScene = get_node("/root/CyclopsAutoload")

	control_mesh.append_mesh(mesh, materials, default_material)

func append_mesh_wire(mesh:ImmediateMesh):
	var global_scene:CyclopsGlobalScene = get_node("/root/CyclopsAutoload")
	
	var mat:Material = global_scene.outline_material
	control_mesh.append_mesh_wire(mesh, mat)

func append_mesh_backfacing(mesh:ImmediateMesh):
	var global_scene:CyclopsGlobalScene = get_node("/root/CyclopsAutoload")
	
	var mat:Material = global_scene.tool_object_selected_material
	control_mesh.append_mesh_backfacing(mesh, mat)

func append_mesh_outline(mesh:ImmediateMesh, viewport_camera:Camera3D, local_to_world:Transform3D):
	var global_scene:CyclopsGlobalScene = get_node("/root/CyclopsAutoload")
	
	var mat:Material = global_scene.tool_object_active_material if active else global_scene.tool_object_selected_material
	control_mesh.append_mesh_outline(mesh, viewport_camera, local_to_world, mat)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

