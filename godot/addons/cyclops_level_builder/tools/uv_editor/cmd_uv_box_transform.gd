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
class_name CommandUvBoxTransform
extends CyclopsCommand

@export var tool_path:NodePath
@export var tool_xform_old:Transform2D
@export var tool_xform_new:Transform2D
@export var tool_visible:bool

func _init():
	command_name = "UV Box Transform"


func do_it():

	var tool:ToolUvBoxTransform = builder.get_node(tool_path)
	
	tool.tool_xform_start = tool_xform_new
	tool.tool_xform_cur = tool_xform_new
	tool.update_uv_handles()
	print("CommandUvBoxTransform::do_it()")
#	tool._draw_tool(null)

func undo_it():

	var tool:ToolUvBoxTransform = builder.get_node(tool_path)
	
	tool.tool_xform_start = tool_xform_old
	tool.tool_xform_cur = tool_xform_old
	tool.update_uv_handles()
	print("CommandUvBoxTransform::undo_it()")
#	tool._draw_tool(null)
