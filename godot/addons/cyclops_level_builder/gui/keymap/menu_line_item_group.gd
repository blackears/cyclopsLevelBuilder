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
extends MenuLineItem
class_name MenuLineItemGroup

func create_popup_menu()->LineItemPopupMenu:
	var menu:LineItemPopupMenu = _build_menu_recursive(self)
	menu.name = name
	return menu
	

func _build_menu_recursive(group:MenuLineItemGroup)->LineItemPopupMenu:
	var menu:LineItemPopupMenu = preload("res://addons/cyclops_level_builder/gui/keymap/line_item_popup_menu.tscn").instantiate()
	
	for child in group.get_children():
		if child is MenuLineItemGroup:
			var submenu = _build_menu_recursive(child)
			menu.add_submenu_node_item(child.name, submenu)
			submenu.action_chosen.connect(func(action):menu.on_submenu_action_chosen(action))
			
		elif child is MenuLineItemAction:
			var item:MenuLineItemAction = child
			var id:int = menu.action_list.size()
			
			menu.add_item(child.name, id)
			menu.action_list.append(child.action)
			
		if child is MenuLineItemSeparator:
			menu.add_separator()

	return menu
