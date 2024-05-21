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
extends Window
class_name ImporterCyclopsFileWizard

#var _text_path:LineEdit
var default_material:Material = preload("res://addons/cyclops_level_builder/materials/grid.tres")

var file_dialog:FileDialog
var file_path:String

var plugin:CyclopsLevelBuilder

# Called when the node enters the scene tree for the first time.
func _ready():
	file_dialog = FileDialog.new()
	add_child(file_dialog)
	file_dialog.size = Vector2(600, 400)
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.set_access(FileDialog.ACCESS_RESOURCES)
	file_dialog.title = "Import scene..."
	file_dialog.filters = PackedStringArray(["*.cyclops; Cyclops files"])
	file_dialog.current_file = file_path
	file_dialog.file_selected.connect(on_open_file)

	%lineEdit_path.text = file_path

func on_open_file(path:String):
	file_path = path
	%lineEdit_path.text = path
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_bn_browse_pressed():
	file_dialog.popup_centered()


func _on_close_requested():
	hide()


func _on_bn_cancel_pressed():
	hide()

func _on_bn_okay_pressed():
	var editor_scene_root:Node = plugin.get_editor_interface().get_edited_scene_root()

	var cmd:CommandImportCyclopsFile = CommandImportCyclopsFile.new()
	cmd.builder = plugin
	cmd.file_path = file_path
	cmd.target_parent = editor_scene_root.get_path()
	
	var undo:EditorUndoRedoManager = plugin.get_undo_redo()
	cmd.add_to_undo_manager(undo)
	
	
	hide()
