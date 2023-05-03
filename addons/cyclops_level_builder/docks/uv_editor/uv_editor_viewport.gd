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
extends Control
class_name UvEdtiorViewport

var material_thumbnail_dirty:bool = true

var target_material:Material
var empty_material:Material

var uv_transform:Transform2D = Transform2D.IDENTITY

var builder:CyclopsLevelBuilder:
	get:
		return builder
	set(value):
		if builder:
			builder.selection_changed.disconnect(on_selection_changed)
			
		builder = value
		
		if builder:
			builder.selection_changed.connect(on_selection_changed)

var spin_offset_x:NumbericLineEdit
var spin_offset_y:NumbericLineEdit
var spin_scale_x:NumbericLineEdit
var spin_scale_y:NumbericLineEdit
var spin_rotation:NumbericLineEdit
var spin_skew:NumbericLineEdit

#var  test_slider:EditorSpinSlider

# Called when the node enters the scene tree for the first time.
func _ready():
	empty_material = StandardMaterial3D.new()
	empty_material.albedo_color = Color.BLACK

	spin_offset_x = $VBoxContainer/GridContainer2/HBoxContainer2/offset_x
	spin_offset_y = $VBoxContainer/GridContainer2/HBoxContainer/offset_y
	spin_scale_x = $VBoxContainer/GridContainer3/HBoxContainer2/scale_x
	spin_scale_y = $VBoxContainer/GridContainer3/HBoxContainer/scale_y
	spin_rotation = $VBoxContainer/GridContainer4/HBoxContainer2/rotation
	spin_skew = $VBoxContainer/GridContainer4/HBoxContainer/skew

#	test_slider = EditorSpinSlider.new()
#	test_slider.size_flags_horizontal = Control.SIZE_EXPAND
#	$VBoxContainer.add_child(test_slider)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):

	if material_thumbnail_dirty:
		material_thumbnail_dirty = false

		$UvPreview.target_material = target_material
		$UvPreview.uv_transform = uv_transform

		var tex:ImageTexture = await $UvPreview.take_snapshot()
		$VBoxContainer/Preview.texture = tex	
	pass

func on_selection_changed():
	material_thumbnail_dirty = true
	target_material = empty_material
	
	if builder.active_node:
		var block:CyclopsConvexBlock = builder.active_node.get_active_block()
		if block:
			var vol:ConvexVolume = block.control_mesh
			var face_idx = vol.active_face if vol.active_face != -1 else 0
			
			var f:ConvexVolume.FaceInfo = vol.get_face(face_idx)
			
			
			spin_offset_x.value = f.uv_transform.origin.x
			spin_offset_y.value = f.uv_transform.origin.y
			spin_scale_x.value = f.uv_transform.get_scale().x
			spin_scale_y.value = f.uv_transform.get_scale().y
			spin_rotation.value = rad_to_deg(f.uv_transform.get_rotation())
			spin_skew.value = rad_to_deg(f.uv_transform.get_skew())
			
			if f.material_id != -1:
				var mat:Material = block.materials[f.material_id]
				target_material = mat
			else:
				target_material = null
			
			uv_transform = f.uv_transform
					
		

func save_state(state:Dictionary):
	var substate:Dictionary = {}
	state["uv_editor_dock"] = substate
	
#	substate["materials"] = material_list.duplicate()

func load_state(state:Dictionary):
	if state == null || !state.has("uv_editor_dock"):
		return
	
	var substate:Dictionary = state["uv_editor_dock"]


func apply_uv_transform():
	var xform:Transform2D = Transform2D(deg_to_rad(spin_rotation.value), \
		Vector2(spin_scale_x.value, spin_scale_y.value), \
		deg_to_rad(spin_skew.value), \
		Vector2(spin_offset_x.value, spin_offset_y.value))
		
	uv_transform = xform
		
	var cmd:CommandSetUvTransform = CommandSetUvTransform.new()
	cmd.builder = builder
	cmd.uv_transform = xform
	
#	print("setting xform %s " % xform)
	
	if builder.active_node:
		for child in builder.active_node.get_children():
			if child is CyclopsConvexBlock:
				var block:CyclopsConvexBlock = child
				if block.selected:
					var vol:ConvexVolume = block.control_mesh
					for f_idx in vol.faces.size():
						var f:ConvexVolume.FaceInfo = vol.faces[f_idx]
						if f.selected:
							cmd.add_face(block.get_path(), f_idx)
	
	
	if cmd.will_change_anything():
		var undo:EditorUndoRedoManager = builder.get_undo_redo()
		cmd.add_to_undo_manager(undo)
	

func _on_offset_x_value_changed(value):
	apply_uv_transform()


func _on_offset_y_value_changed(value):
	apply_uv_transform()


func _on_scale_x_value_changed(value):
	apply_uv_transform()


func _on_scale_y_value_changed(value):
	apply_uv_transform()


func _on_rotation_value_changed(value):
	apply_uv_transform()


func _on_skew_value_changed(value):
	apply_uv_transform()


