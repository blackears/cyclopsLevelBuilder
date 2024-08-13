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
extends KeymapItem
class_name KeymapGroup

@export var name:String:
	set(value):
		if name == value:
			return
		name == value
		emit_changed()
		keymap_tree_changed.emit()
		
#@export var id:String
@export var subgroup:bool = false:
	set(value):
		if subgroup == value:
			return
		subgroup == value
		emit_changed()
		keymap_tree_changed.emit()

@export var children:Array[KeymapItem]:
	set(value):
		print("Adding children ", value.size())
		if children == value:
			return
		
		for child in children:
			child.keymap_tree_changed.disconnect(on_child_changed)
			
		children = value

		for child in children:
			child.keymap_tree_changed.connect(on_child_changed)
			print("child.name ", child.name)
		
		print("children ", children.size())
		
		emit_changed()
		keymap_tree_changed.emit()

func on_child_changed():
	keymap_tree_changed.emit()
	pass

func lookup_invoker(context:CyclopsOperatorContext, event:InputEvent)->KeymapActionMapper:
	for item:KeymapItem in children:
		
		var result:KeymapActionMapper = item.lookup_invoker(context, event)
		if result:
			return result
	
	return null

func add_child(new_group:KeymapItem, index:int = 0):
	children.insert(index, new_group)
	keymap_tree_changed.emit()
	emit_changed()
