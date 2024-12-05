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
class_name CommandSetMeshFeatureData
extends CyclopsCommand

class BlockFeatureChanges extends RefCounted:
	var block_path:NodePath
	var old_block_data:MeshVectorData

	var feature_changes:Dictionary #MeshVectorData.Feature -> FeatureChanges

class FeatureChanges extends RefCounted:
#	var indices:PackedInt32Array
	var new_data_values:Dictionary = {} # String -> DataVector
	

#Private
var block_map:Dictionary = {}

func set_data(block_path:NodePath, feature:MeshVectorData.Feature,
		changes:FeatureChanges):
			
	var block_changes:BlockFeatureChanges
	
	if !block_map.has(block_path):
		block_changes = BlockFeatureChanges.new()
		block_changes.block_path = block_path
		
		var block:CyclopsBlock = builder.get_node(block_path)
		block_changes.old_block_data = block.mesh_vector_data
		
		block_map[block_path] = block_changes
	else:
		block_changes = block_map[block_path]
	
	block_changes.feature_changes[feature] = changes
	

func _init():
	command_name = "Set Mesh Feature Data"

func will_change_anything()->bool:
#	print("will_change_anything()")
	
	for block_path in block_map.keys():
		var changes:BlockFeatureChanges = block_map[block_path]
		var new_mvd:MeshVectorData = changes.old_block_data.duplicate(true)
		
#		print("block_path ", block_path)
		for feature:MeshVectorData.Feature in changes.feature_changes.keys():
			var fc:FeatureChanges = changes.feature_changes[feature]
			for layer_name:String in fc.new_data_values.keys():
				var source_vector:DataVector = fc.new_data_values[layer_name]
				var target_vector:DataVector = new_mvd.get_feature_data(feature, layer_name)
		
#				print("source_vector ", source_vector.data)
#				print("target_vector ", target_vector.data)
				
				if target_vector && target_vector.data_type == source_vector.data_type:
#					if !target_vector.equals_data_at_indices(source_vector, fc.indices):
					if !target_vector.equals_data(source_vector):
						return true
	
	return false

func do_it():
	print("CommandSetMeshFeatureData do_it()")
	for block_path in block_map.keys():
		var changes:BlockFeatureChanges = block_map[block_path]
		#var new_mvd:MeshVectorData = changes.old_block_data.duplicate(true)
		var new_mvd:MeshVectorData = changes.old_block_data.duplicate_explicit()
		
		for feature:MeshVectorData.Feature in changes.feature_changes.keys():
			var fc:FeatureChanges = changes.feature_changes[feature]
			for layer_name:String in fc.new_data_values.keys():
				var source_vector:DataVector = fc.new_data_values[layer_name]
				var target_vector:DataVector = new_mvd.get_feature_data(feature, layer_name)
				
				if target_vector && target_vector.data_type == source_vector.data_type:
#					target_vector.set_data_at_indices(source_vector, fc.indices)
					#print("setting data ", layer_name, " ")
					#print("src ", source_vector.data)
					#print("tgt ", target_vector.data)
					target_vector.set_data(source_vector)
	
		var block:CyclopsBlock = builder.get_node(changes.block_path)
		block.mesh_vector_data = new_mvd
	
	builder.selection_changed.emit()
	

func undo_it():
	print("CommandSetMeshFeatureData undo_it()")
	for block_path in block_map.keys():
		var changes:BlockFeatureChanges = block_map[block_path]
	
		var block:CyclopsBlock = builder.get_node(changes.block_path)
		block.mesh_vector_data = changes.old_block_data
	
	builder.selection_changed.emit()
	
