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
class_name SnappingPropertiesDock


var builder:CyclopsLevelBuilder:
	get:
		return builder
	set(value):
		if builder == value:
			return
			
		if builder:
			builder.snapping_tool_changed.disconnect(on_snapping_tool_changed)
		
		builder = value

		if builder:
			builder.snapping_tool_changed.connect(on_snapping_tool_changed)

func on_snapping_tool_changed():
	update_ui()

func update_ui():
	if builder:
		var snap_tool:CyclopsSnappingSystem = builder.snapping_system
	
		var ed = snap_tool._get_properties_editor()
		
		#print("Clearing editor")
		
		for child in %ScrollContainer.get_children():
			%ScrollContainer.remove_child(child)
			child.queue_free()
			
		#print("Setting editor")
		if ed:
			%ScrollContainer.add_child(ed)
	pass

# Called when the node enters the scene tree for the first time.
func _ready():
	update_ui()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func set_editor(control:Control):
	for child in $ScrollContainer.get_children():
		$ScrollContainer.remove_child(child)
	
	if control:
		$ScrollContainer.add_child(control)

func save_state(state:Dictionary):
	var substate:Dictionary = {}
	state["snapping_properties"] = substate
	
	#substate["materials"] = material_list.duplicate()

func load_state(state:Dictionary):
	if state == null || !state.has("snapping_properties"):
		return
	
	var substate:Dictionary = state["snapping_properties"]
