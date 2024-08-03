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

var plugin:CyclopsLevelBuilder:
	set(value):
		plugin = value
		rebuild_display()

func rebuild_display():
	for child:Node in %keymap_list.get_children():
		%keymap_list.remove_child(child)
		child.queue_free()
	
	if !plugin:
		return
	
	var grp:KeymapGroup = plugin.keymap
	for invoker:KeymapActionMapper in grp.keymaps:
		var ctl:KeymapInvokerEditor = preload("res://addons/cyclops_level_builder/gui/docks/cyclops_console/keymap_editor/keymap_invoker_editor.tscn").instantiate()
		ctl.plugin = plugin
		#ctl.invoker = invoker
		%keymap_list.add_child(ctl)
		#ctl.delete_invoker.connect(on_delete_invoker)
	

func on_delete_invoker(invoker:KeymapActionMapper):
	var grp:KeymapGroup = plugin.keymap
	grp.keymaps.erase(invoker)
	rebuild_display()
	

# Called when the node enters the scene tree for the first time.
func _ready():
	pass



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_bn_add_keymap_pressed():
	var grp:KeymapGroup = plugin.keymap
	var invoker:KeymapActionMapper = KeymapActionMapper.new()
	invoker.input_event = KeymapKeypress.new()
	grp.keymaps.append(invoker)
	
	rebuild_display()
	pass # Replace with function body.
