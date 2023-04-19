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

var builder:CyclopsLevelBuilder:
	get:
		return builder
	set(value):
		if builder:
			builder.selection_changed.disconnect(on_selection_changed)
			
		builder = value
		
		if builder:
			builder.selection_changed.connect(on_selection_changed)

# Called when the node enters the scene tree for the first time.
func _ready():
	empty_material = StandardMaterial3D.new()
	empty_material.albedo_color = Color.BLACK


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):

	if material_thumbnail_dirty:
		material_thumbnail_dirty = false

		$UvPreview.target_material = target_material

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
			if vol.active_face != -1:
				var f:ConvexVolume.FaceInfo = vol.get_face(block.control_mesh.active_face)
				if f.material_id != -1:
					var mat:Material = block.materials[f.material_id]
					target_material = mat
					
		

func save_state(state:Dictionary):
	var substate:Dictionary = {}
	state["uv_editor_dock"] = substate
	
#	substate["materials"] = material_list.duplicate()

func load_state(state:Dictionary):
	if state == null || !state.has("uv_editor_dock"):
		return
	
	var substate:Dictionary = state["uv_editor_dock"]

#	material_list = []	
#	if substate.has("materials"):
#		for mat_path in substate["materials"]:
#			if ResourceLoader.exists(mat_path):
#				material_list.append(mat_path)
#
#	update_thumbnails()
