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
extends Button
class_name ToolButton

var plugin:CyclopsLevelBuilder:
	set(value):
		#if plugin:
			#plugin.tool_changed.disconnect(on_tool_changed)
			
		plugin = value
#		update_selection()

		#if plugin:
			#plugin.tool_changed.connect(on_tool_changed)

var tool_owner:Node:
	set(v):
		if tool_owner:
			tool_owner.tool_changed.disconnect(on_tool_changed)
		
		tool_owner = v
		update_selection()

		if tool_owner:
			tool_owner.tool_changed.connect(on_tool_changed)

#var tool_id:String
var tool_path:NodePath

func on_tool_changed(tool:CyclopsTool):
	update_selection()

func update_selection():
	if tool_owner && tool_owner.active_tool:
		if tool_owner.active_tool.get_path() == tool_path:
			%hilight.visible = true
			return
		
	%hilight.visible = false

# Called when the node enters the scene tree for the first time.
func _ready():
	update_selection()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_pressed():
	#print("click ", tool_id)
	var target = tool_owner if tool_owner else plugin
	
	
	if target:
#		if plugin.active_tool:
#			print("cur tool id ", plugin.active_tool._get_tool_id())
			
		if target.active_tool && target.active_tool.get_path() == tool_path:
#			print("unclick ", tool_id)
			target.switch_to_tool(null)
			return
			
		var tool:CyclopsTool = get_node(tool_path)
		target.switch_to_tool(tool)
