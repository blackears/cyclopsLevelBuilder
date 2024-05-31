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
class_name ToolEditEdgeSettingsEditor

var settings:ToolEditEdgeSettings:
	get:
		return settings
	set(value):
		settings = value
		dirty = true

var dirty:bool = true


func _ready():
	%transform_space.clear()
	for text in TransformSpace.Type.keys():
		%transform_space.add_item(text)

func _process(delta):
	if dirty:
		update()
		dirty = false

func update():
	%transform_space.selected = settings.transform_space
	%check_correct_uvs.button_pressed = settings.triplanar_lock_uvs
	
	pass


func _on_transform_space_item_selected(index):
	settings.transform_space = index


func _on_check_correct_uvs_toggled(toggled_on):
	settings.triplanar_lock_uvs = toggled_on
