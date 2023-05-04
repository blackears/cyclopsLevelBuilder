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

signal blocks_changed

@export var occluder_vertex_offset:float = 0:
	get:
		return occluder_vertex_offset
	set(value):
		occluder_vertex_offset = value
		dirty = true

var dirty:bool = true

var block_bodies:Node3D

# Called when the node enters the scene tree for the first time.
func _ready():
	
	child_entered_tree.connect(on_child_entered_tree)
	child_exiting_tree.connect(on_child_exiting_tree)
	
	block_bodies = Node3D.new()
	block_bodies.name = "block_bodies"
	add_child(block_bodies)

	for node in get_children():
		if node is CyclopsConvexBlock:
			var block:CyclopsConvexBlock = node
			block.mesh_changed.connect(on_child_mesh_changed)
			
	
	
func on_child_mesh_changed():
	dirty = true
	blocks_changed.emit()
	

func on_child_entered_tree(node:Node):
	if node is CyclopsConvexBlock:
		var block:CyclopsConvexBlock = node
		block.mesh_changed.connect(on_child_mesh_changed)
		
#		print("on_child_entered_tree %s" % node.name)
		dirty = true
	
func on_child_exiting_tree(node:Node):
	if node is CyclopsConvexBlock:
		var block:CyclopsConvexBlock = node
		block.mesh_changed.disconnect(on_child_mesh_changed)

#		print("on_child_exited_tree %s" % node.name)
		
		dirty = true

func has_selected_blocks()->bool:
	for child in get_children():
		if child is CyclopsConvexBlock and child.selected:
			return true
	return false


func rebuild_mesh():
	for child in block_bodies.get_children():
		child.queue_free()

	for child in get_children():
		if child is CyclopsConvexBlock:
			var block:CyclopsConvexBlock = child
			
#			var block_body:CyclopsConvexBlockBody = preload("res://addons/cyclops_level_builder/nodes/cyclops_convex_block_body.gd").instantiate()
			var block_body:CyclopsConvexBlockBody = CyclopsConvexBlockBody.new()
			block_body.materials = block.materials
			block_body.block_data = block.block_data
			block_bodies.add_child(block_body)

		
	dirty = false
	
func get_active_block()->CyclopsConvexBlock:
	for child in get_children():
		if child is CyclopsConvexBlock:
			var block:CyclopsConvexBlock = child
			if block.active:
				return block
	return null
	
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
	return intersect_ray_closest_filtered(origin, dir, func(block:CyclopsConvexBlock): return true)
	
func intersect_ray_closest_selected_only(origin:Vector3, dir:Vector3)->IntersectResults:
	return intersect_ray_closest_filtered(origin, dir, func(block:CyclopsConvexBlock): return block.selected)
	
func intersect_ray_closest_filtered(origin:Vector3, dir:Vector3, filter:Callable)->IntersectResults:
	var best_result:IntersectResults
		
	for child in get_children():
		if child is CyclopsConvexBlock:
			var result:IntersectResults = child.intersect_ray_closest(origin, dir)
			if result:
				if !filter.call(result.object):
					continue
				
				if !best_result or result.distance_squared < best_result.distance_squared:
					best_result = result			
		
	return best_result
