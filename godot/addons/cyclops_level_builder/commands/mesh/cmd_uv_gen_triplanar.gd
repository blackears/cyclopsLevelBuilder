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
class_name CommandUvGenTriplanar
extends CyclopsCommand

@export var block_paths:Array[NodePath]
@export var selected_faces_only:bool = false
@export var transform:Transform3D = Transform3D.IDENTITY

var cached_data:Dictionary

func _init():
	command_name = "Generate UVs Triplanar"

func do_it():
	cached_data.clear()
	
	for block_path in block_paths:
		var block:CyclopsBlock = builder.get_node(block_path)
		var mvd:MeshVectorData = block.mesh_vector_data
		
		var block_xform:Transform3D = block.global_transform
		
		cached_data[block_path] = mvd
		
		var cv:ConvexVolume = ConvexVolume.new()
		cv.init_from_mesh_vector_data(mvd)
		cv.generate_uv_triplanar(selected_faces_only, transform * block_xform)
		
		var new_mvd:MeshVectorData = cv.to_mesh_vector_data()
		block.mesh_vector_data = new_mvd

func undo_it():
	for block_path in block_paths:
		var block:CyclopsBlock = builder.get_node(block_path)
		var mvd:MeshVectorData = cached_data[block_path]
		block.mesh_vector_data = mvd
		
	cached_data.clear()
