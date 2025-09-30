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
extends PanelContainer

@export var uv_editor:UvEditor:
	set(v):
		if uv_editor == v:
			return
		uv_editor = v

		if is_node_ready():
			update_editor_link()

@onready var vec_ed_subdiv = %vectorEdit_subdiv
@onready var vec_ed_subdiv_offset = %vectorEdit_offset

func update_editor_link():
	if !is_node_ready() || !uv_editor:
		return
		
	vec_ed_subdiv.set_value_no_signal(uv_editor.subdivisions)
	uv_editor.subdivisions_changed.connect(on_subdivisions_changed)
		
	vec_ed_subdiv_offset.set_value_no_signal(uv_editor.subdivisions_offset)
	uv_editor.subdivisions_offset_changed.connect(on_subdivisions_offset_changed)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_editor_link()
#	update_editor_link()
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func on_subdivisions_changed(v:Vector2):
	print("on_subdivisions_changed ", v)
	vec_ed_subdiv.set_value_no_signal(v)

func on_subdivisions_offset_changed(v:Vector2):
	print("on_subdivisions_offset_changed ", v)
	vec_ed_subdiv_offset.set_value_no_signal(v)

func _on_vector_edit_subdiv_value_changed(value: Vector2) -> void:
	print("_on_vector_edit_subdiv_value_changed ", value)
	uv_editor.subdivisions = value
	pass # Replace with function body.


func _on_vector_edit_offset_value_changed(value: Vector2) -> void:
	print("_on_vector_edit_offset_value_changed ", value)
	uv_editor.subdivisions_offset = value
	pass # Replace with function body.


func _on_scroll_underlay_opacity_value_changed(value: float) -> void:
	uv_editor.underlay_opacity = value
	pass # Replace with function body.
