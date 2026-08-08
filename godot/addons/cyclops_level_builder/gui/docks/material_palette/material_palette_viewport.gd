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
class_name MaterialPaletteViewport

@onready var material_viewer:MaterialViewer = %MaterialViewer


var builder:CyclopsLevelBuilder:
	get:
		return builder
	set(value):
		if builder == value:
			return
			
		builder = value
		
		if is_node_ready():
			material_viewer.builder = builder

	

# Called when the node enters the scene tree for the first time.
func _ready():
	material_viewer.builder = builder

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func save_state(state:Dictionary):
	var substate:Dictionary = {}
	material_viewer.save_state(substate)
	state["material_palette"] = substate
	

func load_state(state:Dictionary):
#	if state == null || !state.has("material_palette"):
	if state == null:
		return
	
#	var substate:Dictionary = state["material_palette"]
	material_viewer.load_state(state.get("material_palette", {}))
		
