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
class_name CommandVertexPaintStroke
extends CyclopsCommand

@export var color:Color = Color.WHITE
@export var strength:float = 1
@export var radius:float = 1
@export var falloff_curve:Curve

enum MaskType { NONE, VERTICES, FACES }
@export var mask:MaskType = MaskType.NONE

#Private
var block_map:Dictionary = {}
#var block_tgt_map:Dictionary = {}


var pen_stroke:PenStroke = PenStroke.new()

func append_block(block_path:NodePath):
	if block_map.has(block_path):
		return
	
	var block:CyclopsBlock = builder.get_node(block_path)

	#print("stroing block faces ", block.block_data.face_vertex_face_index)
	
	block_map[block_path] = block.mesh_vector_data.duplicate(true)
	#print("stroing block faces ", block.block_data.face_vertex_face_index)
#	block_tgt_map[block_path] = block.block_data.duplicate(true)
	
func append_stroke_point(position:Vector3, pressure:float = 1):
	pen_stroke.append_stroke_point(position, pressure)
	#print("--pen_stroke ", pen_stroke.stroke_points)

func _init():
	command_name = "Paint Vertex Color Stroke"

func will_change_anything()->bool:
	return !(block_map.is_empty() || pen_stroke.is_empty())

func do_it():
	#print("sel verts do_it")
#	print("sel uv_transform do_it()")

	#print("stroke pts  ", str(pen_stroke.stroke_points))
	var stroke_resamp:PenStroke = pen_stroke.resample_points(radius * .1)
	#print("stroke resamp pts ", str(stroke_resamp.stroke_points))
		
	for block_path in block_map.keys():

		var block:CyclopsBlock = builder.get_node(block_path)
		var w2l:Transform3D = block.global_transform.affine_inverse()
		#print("painting block ", block.name)

		var block_data:MeshVectorData = block_map[block_path]
		#print("block_data raw faces ", block_data.face_vertex_face_index)
		
		var vol:ConvexVolume = ConvexVolume.new()
		vol.init_from_mesh_vector_data(block_data)
		
		#Apply stroke
		for stroke_pt in stroke_resamp.stroke_points:
			var pos_local:Vector3 = w2l * stroke_pt.position
			for fv in vol.face_vertices:
				var v:ConvexVolume.VertexInfo = vol.vertices[fv.vertex_index]
				var f:ConvexVolume.FaceInfo = vol.faces[fv.face_index]
				
				if mask == MaskType.FACES:
					if !f.selected:
						continue
				elif mask == MaskType.VERTICES:
					if !v.selected:
						continue
				
				var dist:float = v.point.distance_to(pos_local)
				
				if dist > radius:
					continue
				
				var falloff_frac:float = 1 - (dist / radius)
				var falloff:float = falloff_curve.sample(falloff_frac) \
					if falloff_curve else 1
				
				fv.color = MathUtil.blend_colors_ignore_alpha(\
					color, fv.color, strength * stroke_pt.pressure * falloff)

				#print("fv_idx ", fv.index)
				#print("fv color ", fv.color)
				
		var new_block_data:MeshVectorData = vol.to_mesh_vector_data()
		#print("new_block_data faces ", block.block_data.face_vertex_face_index)
		block.mesh_vector_data = new_block_data
					
	builder.selection_changed.emit()

func undo_it():
#	print("undo_it() select faces")
	for block_path in block_map.keys():
		var block:CyclopsBlock = builder.get_node(block_path)

		var block_data:MeshVectorData = block_map[block_path]
		
		block.mesh_vector_data = block_data

	builder.selection_changed.emit()

