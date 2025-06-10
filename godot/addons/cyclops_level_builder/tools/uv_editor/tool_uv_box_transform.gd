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
extends CyclopsTool
class_name ToolUvBoxTransform

enum ToolState { NONE, READY, DRAG_VIEW, DRAG_SELECTION, DRAG_UVS }
var tool_state:ToolState = ToolState.NONE

@export var tool_name:String = "Box Transform UVs"
@export var tool_icon:Texture2D = preload("res://addons/cyclops_level_builder/art/icons/box_transform.svg")
@export_multiline var tool_tooltip:String = "Box Transform UVs"

@export var view:ViewUvEditor

func _get_tool_name()->String:
	return tool_name

func _get_tool_icon()->Texture2D:
	return tool_icon

func _get_tool_tooltip()->String:
	return tool_tooltip

func _get_tool_properties_editor()->Control:
	return null

func _can_handle_object(node:Node)->bool:
	#print("_can_handle_object -- uv move")
	#return node is CyclopsBlock
	return true


func _draw_tool(viewport_camera:Camera3D):
	var uv_ed:UvEditor = view.get_uv_editor()
	
func _gui_input(viewport_camera:Camera3D, event:InputEvent)->bool:
	if !builder:
		return false
	
	return true
	
func _activate(tool_owner:Node):
	super._activate(tool_owner)

func _deactivate():
	super._deactivate()
