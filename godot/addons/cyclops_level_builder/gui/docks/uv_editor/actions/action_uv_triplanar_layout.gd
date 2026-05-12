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
class_name ActionUvTriplanarLayout
extends CyclopsAction

var control:UvTriplanarLayoutPanel = preload("res://addons/cyclops_level_builder/gui/docks/uv_editor/actions/uv_triplanar_layout_panel.tscn").instantiate()
var window:Window

func _ready():
	control.canceled.connect(func(): window.hide())
	control.finished.connect(do_layout)
	
	pass

func do_layout():
	#window.hide()
	
	var uv_xform_x:Transform3D = control.get_uv_transform(MathUtil.Axis.X)
	var uv_xform_y:Transform3D = control.get_uv_transform(MathUtil.Axis.Y)
	var uv_xform_z:Transform3D = control.get_uv_transform(MathUtil.Axis.Z)
	#print("uv_xform ", uv_xform)
	
	var plugin:CyclopsLevelBuilder = control.plugin
	
	var selected_faces_only:bool = control.is_selected_faces_only()
#	print("selected_faces_only ", selected_faces_only)
	
	var cmd:CommandSetMeshFeatureData = CommandSetMeshFeatureData.new()
	cmd.builder = plugin
	var fc:CommandSetMeshFeatureData.FeatureChanges = CommandSetMeshFeatureData.FeatureChanges.new()

#	print("triplanar layout")

	for block in plugin.get_selected_blocks():
#		print("setting uvs ", block.name)
		
		var block_path:NodePath = block.get_path()
		var mvd:MeshVectorData = block.mesh_vector_data

		var uv_arr:DataVectorFloat = mvd.get_face_vertex_data(MeshVectorData.FV_UV0)
		var new_uv_arr:DataVectorFloat = uv_arr.duplicate_explicit()
		
		var cv:ConvexVolume = ConvexVolume.new()
		cv.init_from_mesh_vector_data(mvd)
#		print("<<0>>")
		for fi:ConvexVolume.FaceInfo in cv.faces:
#			print("<<1>>")
			if selected_faces_only && !fi.is_selected():
				continue
			
			var axis:MathUtil.Axis = MathUtil.get_longest_axis(fi.normal)
#			print("fi.normal ", fi.normal)
#			print("axis ", axis)
			
			for fv_i:int in fi.face_vertex_indices:
#				print("fv_i ", fv_i)
				var fv:ConvexVolume.FaceVertexInfo = cv.face_vertices[fv_i]
				var v:ConvexVolume.VertexInfo = cv.vertices[fv.vertex_index]
			
#				print("uvw ", uvw)
				match axis:
					MathUtil.Axis.X:
						var uvw:Vector3 = uv_xform_x * v.point
						new_uv_arr.set_value_vec2(Vector2(uvw.x, uvw.y), fv.index)
					MathUtil.Axis.Y:
						var uvw:Vector3 = uv_xform_y * v.point
						new_uv_arr.set_value_vec2(Vector2(uvw.x, uvw.y), fv.index)
					MathUtil.Axis.Z:
						var uvw:Vector3 = uv_xform_z * v.point
						new_uv_arr.set_value_vec2(Vector2(uvw.x, uvw.y), fv.index)
				
		var new_mvd:MeshVectorData = cv.to_mesh_vector_data()
		
		fc.new_data_values[MeshVectorData.FV_UV0] = new_uv_arr
		cmd.set_data(block_path, MeshVectorData.Feature.FACE_VERTEX, fc)

	if cmd.will_change_anything():
		var undo:EditorUndoRedoManager = plugin.get_undo_redo()
		cmd.add_to_undo_manager(undo)
		

func _execute(event:CyclopsActionEvent):
	var plugin:CyclopsLevelBuilder = event.plugin
	
	if !window:
		window = Window.new()
		window.title = "Uv Triplanar Layout"
		window.exclusive = true
#		window.always_on_top = true
		
		window.add_child(control)
		
		window.close_requested.connect(on_close_requested)
	
		var base_control:Node = plugin.get_editor_interface().get_base_control()
		base_control.add_child(window)
		
		window.min_size = control.get_minimum_size()
	
	control.plugin = plugin
	
	window.popup_centered()

func on_close_requested():
	window.hide()


#func _execute(event:CyclopsActionEvent):
	#var plugin:CyclopsLevelBuilder = event.plugin
	#if !wizard.get_parent():
		#var base_control:Node = plugin.get_editor_interface().get_base_control()
		#base_control.add_child(wizard)
	#
	#wizard.plugin = plugin
	#wizard.popup_centered()
	
