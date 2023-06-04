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
class_name CommandAddStairs
extends CyclopsCommand

#var blocks_root_inst_id:int
var blocks_root_path:NodePath
var block_name_prefix:String
var floor_normal:Vector3
var drag_origin:Vector3
var base_drag_cur:Vector3
var block_drag_cur:Vector3
var step_height:float = .25
var step_depth:float = .5
var direction:int = 0

var uv_transform:Transform2D
var material_path:String

#Private data
var block_paths:Array[NodePath]

func _init():
	command_name = "Add stairs"

func create_block(blocks_root:Node, mat:Material)->CyclopsBlock:
	var block:CyclopsBlock = preload("../nodes/cyclops_block.gd").new()
	blocks_root.add_child(block)
	block.owner = builder.get_editor_interface().get_edited_scene_root()
	block.name = GeneralUtil.find_unique_name(blocks_root, block_name_prefix)

	if mat:
		block.materials.append(mat)
			
	return block


func do_it():
	var blocks_root:Node = builder.get_node(blocks_root_path)
	
	var material:Material
	var material_id:int = -1
	if ResourceLoader.exists(material_path):
		var mat = load(material_path)
		if mat is Material:
			material_id = 0
			material = mat
	
	var tan_bi:Array[Vector3] = MathUtil.get_axis_aligned_tangent_and_binormal(floor_normal)
	var u_normal:Vector3 = tan_bi[0]
	var v_normal:Vector3 = tan_bi[1]

	#Rotate ccw by 90 degree increments
	match direction:
		1:
			var tmp:Vector3 = u_normal
			u_normal = -v_normal
			v_normal = tmp
		2:
			u_normal = -u_normal
			v_normal = -v_normal
		3:
			var tmp:Vector3 = -u_normal
			u_normal = v_normal
			v_normal = tmp
	
	var u_span:Vector3 = (base_drag_cur - drag_origin).project(u_normal)
	var v_span:Vector3 = (base_drag_cur - drag_origin).project(v_normal)
	
	var stairs_origin:Vector3 = drag_origin
	if u_span.dot(u_normal) < 0:
		stairs_origin += u_span
		u_span = -u_span
	if v_span.dot(v_normal) < 0:
		stairs_origin += v_span
		v_span = -v_span
	
	#Stairs should ascend along v axis
	var height_offset = block_drag_cur - base_drag_cur
	if height_offset.dot(floor_normal) < 0:
		return
	var num_steps:int = min(v_span.length() / step_depth, height_offset.length() / step_height)

	var max_height:float = floor(height_offset.length() / step_height) * step_height

	var step_span:Vector3 = v_normal * step_depth
	for i in num_steps:
		var base_points:PackedVector3Array = [stairs_origin + step_span * i, \
			stairs_origin + u_span + step_span * i, \
			stairs_origin + u_span + step_span * (i + 1), \
			stairs_origin + step_span * (i + 1)]
		
		var pivot_xform:Transform3D = Transform3D(Basis.IDENTITY, -base_points[0])
		
		var mesh:ConvexVolume = ConvexVolume.new()
		mesh.init_prism(base_points, \
			floor_normal * (max_height - step_height * i), \
			uv_transform, material_id)
		mesh.transform(pivot_xform)

		var block:CyclopsBlock = create_block(blocks_root, material)

		block.block_data = mesh.to_convex_block_data()
		block.global_transform = pivot_xform.affine_inverse()
		block_paths.append(block.get_path())
		

func undo_it():
	for path in block_paths:
		var block:CyclopsBlock = builder.get_node(path)
		block.queue_free()
