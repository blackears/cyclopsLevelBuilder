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
class_name CyclopsBlocks

@export var grid_size:int = 0
@export var selection_color:Color = Color(1, .5, .5, 1)
#@export var default_material:Material = StandardMaterial3D.new()
@export var default_material:Material = preload("res://addons/cyclops_level_builder/art/materials/grid.tres")

var mesh_instance:MeshInstance3D
var dirty:bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	child_entered_tree.connect(on_child_entered_tree)
	child_exiting_tree.connect(on_child_exiting_tree)
	
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)

	for node in get_children():
		if node is CyclopsBlock:
			var block:CyclopsBlock = node
			block.mesh_changed.connect(on_child_mesh_changed)
			
#			print("adding child %s" % node.name)
	
	
func on_child_mesh_changed():
	dirty = true
	

func on_child_entered_tree(node:Node):
	if node is CyclopsBlock:
		var block:CyclopsBlock = node
		block.mesh_changed.connect(on_child_mesh_changed)
		
#		print("on_child_entered_tree %s" % node.name)
		dirty = true
	
func on_child_exiting_tree(node:Node):
	if node is CyclopsBlock:
		var block:CyclopsBlock = node
		block.mesh_changed.disconnect(on_child_mesh_changed)

#		print("on_child_exited_tree %s" % node.name)
		
		dirty = true
	
func rebuild_mesh():
	var mesh:ImmediateMesh = ImmediateMesh.new()
	
	for child in get_children():
		if child is CyclopsBlock:
			var block:CyclopsBlock = child
			if block.control_mesh:
				var color:Color = selection_color if block.selected else Color.WHITE
				#var color = Color.RED if block.selected else Color.WHITE
				block.control_mesh.append_mesh(mesh, default_material, color)
	
	mesh_instance.mesh = mesh
	dirty = false
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if dirty:
		rebuild_mesh()

func _input(event):
	if Engine.is_editor_hint():
		pass
		
	#print(event.as_text())
	pass

func intersect_ray_closest(origin:Vector3, dir:Vector3)->IntersectResults:
	var best_result:IntersectResults
		
	for child in get_children():
		if child is CyclopsBlock:
			var result:IntersectResults = child.intersect_ray_closest(origin, dir)
			if result:
				if !best_result or result.distance_squared < best_result.distance_squared:
					best_result = result			
		
	return best_result
