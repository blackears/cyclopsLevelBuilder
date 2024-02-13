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
class_name SnappingSystemVertexPropertiesEditor

var snap_tool:SnappingSystemVertex:
	get:
		return snap_tool
	set(value):
		#print("setting SnappingSystemGridPropertiesEditor props")
		if value == snap_tool:
			return
		snap_tool = value
		update_ui_from_props()

#var settings:SnappingSystemVertexSettings:
	#get:
		#return settings
	#set(value):
		##print("setting SnappingSystemGridPropertiesEditor props")
		#if value == settings:
			#return
		#settings = value
		#update_ui_from_props()

func update_ui_from_props():
	if !snap_tool:
		return
	
	var settings = snap_tool.settings

	%snap_radius.value = settings.snap_radius

func _on_snap_radius_value_changed(value):
	if !snap_tool:
		return
	
	snap_tool.settings.snap_radius = value
	snap_tool.flush_cache()
		
