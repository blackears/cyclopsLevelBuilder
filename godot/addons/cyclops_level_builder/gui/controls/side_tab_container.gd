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
extends HBoxContainer
class_name SideTabContainer

@export var active_tab:int = -1:
	set(v):
		active_tab = v
		
		if is_node_ready():
			update_visibility()

#var 

func add_control(control:Control):
	control.visible = false
	%ScrollContainer.add_child(control)
	
	update_tabs()
	update_visibility()

func update_tabs():
	%TabBar.clear_tabs()
	
	for i in %ScrollContainer.get_child_count():
		var child = %ScrollContainer.get_child(i)
		
		%TabBar.add_tab(child.name)
	%TabBar.current_tab = active_tab

func update_visibility():
	for i in %ScrollContainer.get_child_count():
		var child = %ScrollContainer.get_child(i)
		
		if "visible" in child:
			child.visible = i == active_tab
	

func _on_tab_bar_tab_selected(tab: int) -> void:
	if tab == active_tab:
		active_tab = -1
	else:
		active_tab = tab
