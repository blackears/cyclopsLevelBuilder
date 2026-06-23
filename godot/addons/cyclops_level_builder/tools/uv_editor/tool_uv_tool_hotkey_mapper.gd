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
extends ToolUv
class_name ToolUvViewportToolHotkeyMapper

@export var tool_list:Node

#NodePath to hotkey
#@export var toolmap_list:Dictionary[Node, KeymapKeypress]:
	#set(v):
		#toolmap_list = v
		#update_mapping()
#
#var keymap_map:Dictionary[StringName, Node]

#func _ready():
	#update_mapping()

func _is_selectable()->bool:
	return false

#func update_mapping():
	#keymap_map.clear()
	#
	#for node in tool_list.get_children():
		#if node is ToolUv:
			#if node.default_hotkey:
				#var key:StringName = node.default_hotkey.to_hash_string()
				#keymap_map[key] = node
	#
	#for node in toolmap_list.keys():
		#if node is ToolUv:
			#var key:StringName = toolmap_list[node].to_hash_string()
			#keymap_map[key] = node
			

func _gui_input(viewport_camera:Camera3D, event:InputEvent)->bool:
	#var uv_ed:UvEditor = view_uv_editor.get_uv_editor()
	#var uv_to_view_xform:Transform2D = uv_ed.get_uv_to_viewport_xform()
	
	#if keymap_map.is_empty():
		#update_mapping()
	
	if event is InputEventKey:
		if event.is_pressed():
			var e:InputEventKey = event
			
			var keypress:KeymapKeypress = KeymapKeypress.new()
			keypress.keycode = event.keycode
			keypress.shift = event.shift_pressed
			keypress.ctrl = event.ctrl_pressed
			keypress.alt = event.alt_pressed
			keypress.meta = event.meta_pressed
			
			var tool_node:ToolUv = view_uv_editor.get_tool_from_keypress(keypress)
			if tool_node:
				#print("switching to ", tool_node)
				view_uv_editor.switch_to_tool(tool_node)
				
			#var key:StringName = keypress.to_hash_string()
			#if key in keymap_map:
				#var tool_node:ToolUv = keymap_map[key]
				#view_uv_editor.switch_to_tool(tool_node)
				
				return true
		
	return false
