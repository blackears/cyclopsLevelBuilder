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
class_name CommandIntersectBlock
extends CyclopsCommand

class NewBlockInfo extends RefCounted:
	var data:ConvexBlockData
	var materials:Array[Material]
	var path:NodePath
	var centroid:Vector3

#Public 
var block_paths:Array[NodePath]
var main_block_path:NodePath
var block_name_prefix:String = "Block_"

#Private
var start_blocks:Array[TrackedBlock]
var main_block_cache:TrackedBlock
#var added_blocks:Array[NewBlockInfo]
var added_block:NewBlockInfo

func _init():
	command_name = "Intersect blocks"

func restore_tracked_block(tracked:TrackedBlock)->CyclopsBlock:
	var parent = builder.get_node(tracked.path_parent)
	
	var block:CyclopsBlock = preload("../nodes/cyclops_block.gd").new()
	block.block_data = tracked.data
	block.materials = tracked.materials
	block.name = tracked.name
	#block.selected = tracked.selected
	block.global_transform = tracked.world_xform
	
	parent.add_child(block)

	block.owner = builder.get_editor_interface().get_edited_scene_root()
	
	if tracked.selected:
		var selection:EditorSelection = builder.get_editor_interface().get_selection()
		selection.add_node(block)
	
	return block
	
func will_change_anything()->bool:
	var main_block:CyclopsBlock = builder.get_node(main_block_path)
	var main_vol:ConvexVolume = main_block.control_mesh
	main_vol = main_vol.transformed(main_block.global_transform)
	
	if block_paths.is_empty():
		return false
	
	for minuend_path in block_paths:
		var minuend_block:CyclopsBlock = builder.get_node(minuend_path)
		var minuend_vol:ConvexVolume = minuend_block.control_mesh
		minuend_vol = minuend_vol.transformed(minuend_block.global_transform)
		
		if minuend_vol.intersects_convex_volume(main_vol):
			return true
			
	return false

func do_it():
	var main_block:CyclopsBlock = builder.get_node(main_block_path)
	var snap_to_grid_util:SnapToGridUtil = CyclopsAutoload.calc_snap_to_grid_util()
	
	if start_blocks.is_empty():
		var main_vol:ConvexVolume = main_block.control_mesh
		main_block_cache = TrackedBlock.new(main_block)
		main_vol = main_vol.transformed(main_block.global_transform)
		
		for path in block_paths:
			var block:CyclopsBlock = builder.get_node(path)
			
			var minuend_vol:ConvexVolume = block.control_mesh
			minuend_vol = minuend_vol.transformed(block.global_transform)
			if !minuend_vol.intersects_convex_volume(main_vol):
				continue
			
			var tracker:TrackedBlock = TrackedBlock.new(block)
			start_blocks.append(tracker)
			
			main_vol = minuend_vol.intersect(main_vol)
			
			
		var block_info:NewBlockInfo = NewBlockInfo.new()
		block_info.data = main_vol.to_convex_block_data()
		block_info.materials = main_block.materials
		var centroid:Vector3 = main_vol.get_centroid()
		centroid = snap_to_grid_util.snap_point(centroid)
		main_vol.translate(-centroid)
		block_info.centroid = main_vol.get_centroid()
		added_block = block_info

	#Delete source blocks
	for block_info in start_blocks:
		var del_block:CyclopsBlock = builder.get_node(block_info.path)
		del_block.queue_free()

	main_block.queue_free()

	#Create blocks
#	for info in added_blocks:
	var block:CyclopsBlock = preload("../nodes/cyclops_block.gd").new()
	var parent:Node = builder.get_node(start_blocks[0].path_parent)
	parent.add_child(block)
	block.owner = builder.get_editor_interface().get_edited_scene_root()
	block.name = GeneralUtil.find_unique_name(parent, block_name_prefix)
	block.block_data = added_block.data
	block.materials = added_block.materials
	block.global_transform = Transform3D.IDENTITY.translated(added_block.centroid)
	
	added_block.path = block.get_path()

	

func undo_it():
	
	#for info in added_blocks:
	var added_block_node:CyclopsBlock = builder.get_node(added_block.path)
	added_block_node.queue_free()

	restore_tracked_block(main_block_cache)

	for tracked in start_blocks:
		restore_tracked_block(tracked)

