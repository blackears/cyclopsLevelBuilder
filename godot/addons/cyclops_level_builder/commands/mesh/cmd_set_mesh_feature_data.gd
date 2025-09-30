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

	var feature_change_deltas:Dictionary #MeshVectorData.Feature -> FeatureChanges
	
	func is_empty()->bool:
		for feature in feature_change_deltas.keys():
			if !feature_change_deltas[feature].is_empty():
				return false
		return true

class FeatureChanges extends RefCounted:
	var new_data_values:Dictionary = {} # String -> DataVector
	

class FeatureChangeDeltas extends RefCounted:
	var new_data_values:Dictionary = {} # String -> DataVector
	
	func is_empty():
		return new_data_values.is_empty()
	

#Private
var block_map:Dictionary = {}


func set_data(block_path:NodePath, feature:MeshVectorData.Feature,
		changes:FeatureChanges):
	
	var block_changes:BlockFeatureChanges
	
	var block:CyclopsBlock = builder.get_node(block_path)
	var mvd:MeshVectorData = block.mesh_vector_data
	
	if !block_map.has(block_path):
		block_changes = BlockFeatureChanges.new()
		block_map[block_path] = block_changes
		
		block_changes.block_path = block_path
		
	else:
		block_changes = block_map[block_path]
	
	var delta_changes:FeatureChangeDeltas = FeatureChangeDeltas.new()
	
	#Calulate deltas to reduce memory footprint
	for vector_name:String in changes.new_data_values.keys():
#		print("setting data for ", vector_name)
		var block_vec:DataVector = mvd.get_feature_data(feature, vector_name)
		if !block_vec:
			printerr("no vector layer in existing mesh: ", feature, " ", vector_name)
			continue
		
		var change_to_vec:DataVector = changes.new_data_values[vector_name]
		var delta_vec:DataVector = block_vec.subtract(change_to_vec)
		#print("delta_vec ", delta_vec)
		if delta_vec.is_zero():
			continue
		
		delta_changes.new_data_values[vector_name] = delta_vec
		
		#print("block_vec ", block_vec)
		#print("change_to_vec ", change_to_vec)
		#print("delta_vec ", delta_vec)
	
	if !delta_changes.is_empty():
		block_changes.feature_change_deltas[feature] = delta_changes


func _init():
	command_name = "Set Mesh Feature Data"

func will_change_anything()->bool:
#	print("will_change_anything()")
	for key:NodePath in block_map.keys():
		if !block_map[key].is_empty():
			return true
	
	return false
	
	#for block_path in block_map.keys():
		#var changes:BlockFeatureChanges = block_map[block_path]
		#var new_mvd:MeshVectorData = changes.old_block_data.duplicate(true)
		#
##		print("block_path ", block_path)
		#for feature:MeshVectorData.Feature in changes.feature_changes.keys():
			#var fc:FeatureChanges = changes.feature_changes[feature]
			#for layer_name:String in fc.new_data_values.keys():
				#var source_vector:DataVector = fc.new_data_values[layer_name]
				#var target_vector:DataVector = new_mvd.get_feature_data(feature, layer_name)
		#
##				print("source_vector ", source_vector.data)
##				print("target_vector ", target_vector.data)
				#
				#if target_vector && target_vector.data_type == source_vector.data_type:
					#if !target_vector.equals_data(source_vector):
						#return true
	#
	#return false

func do_it():
#	print("CommandSetMeshFeatureData do_it()")
	for block_path in block_map.keys():
		var changes:BlockFeatureChanges = block_map[block_path]
		var block:CyclopsBlock = builder.get_node(block_path)
		var block_mvd:MeshVectorData = block.mesh_vector_data.duplicate_explicit()
		
		for feature:MeshVectorData.Feature in changes.feature_change_deltas.keys():
			var fcd:FeatureChangeDeltas = changes.feature_change_deltas[feature]
			for vector_name:String in fcd.new_data_values.keys():
#				print("setting data vector_name ", vector_name)
				var delta_vector:DataVector = fcd.new_data_values[vector_name]
				var block_vector:DataVector = block_mvd.get_feature_data(feature, vector_name)
				
				var source_vector:DataVector = block_vector.subtract(delta_vector)
				
				#print("block_vector ", block_vector)
				#print("delta_vector ", delta_vector)
				#print("source_vector ", source_vector)
				
				
				if block_vector && block_vector.data_type == source_vector.data_type:
					#print("setting data ", layer_name, " ")
					#print("src ", source_vector.data)
					#print("tgt ", target_vector.data)
					block_vector.set_data(source_vector)

		block.mesh_vector_data = block_mvd
	
	

func undo_it():
#	print("CommandSetMeshFeatureData undo_it()")

	for block_path in block_map.keys():
		var changes:BlockFeatureChanges = block_map[block_path]
		var block:CyclopsBlock = builder.get_node(block_path)
		var block_mvd:MeshVectorData = block.mesh_vector_data.duplicate_explicit()
		
		for feature:MeshVectorData.Feature in changes.feature_change_deltas.keys():
			var fcd:FeatureChangeDeltas = changes.feature_change_deltas[feature]
			for vector_name:String in fcd.new_data_values.keys():
#				print("unsetting data vector_name ", vector_name)
				var delta_vector:DataVector = fcd.new_data_values[vector_name]
				var block_vector:DataVector = block_mvd.get_feature_data(feature, vector_name)
				
				var source_vector:DataVector = block_vector.add(delta_vector)

				#print("block_vector ", block_vector)
				#print("delta_vector ", delta_vector)
				#print("source_vector ", source_vector)
				
				if block_vector && block_vector.data_type == source_vector.data_type:
					#print("setting data ", layer_name, " ")
					#print("src ", source_vector.data)
					#print("tgt ", target_vector.data)
					block_vector.set_data(source_vector)
	
		block.mesh_vector_data = block_mvd
	
	
