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
class_name ExporterCyclopsWizard

var file_dialog:FileDialog
var save_path:String

var plugin:CyclopsLevelBuilder

# Called when the node enters the scene tree for the first time.
func _ready():
	file_dialog = FileDialog.new()
	add_child(file_dialog)
	file_dialog.size = Vector2(600, 400)
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.set_access(FileDialog.ACCESS_RESOURCES)
	file_dialog.title = "Save file..."
	file_dialog.filters = PackedStringArray(["*.cyclops; Cyclops files"])
	file_dialog.current_file = save_path
	file_dialog.file_selected.connect(on_save_file)

	%lineEdit_path.text = save_path
	#_text_path = %lineEdit_path
	#_text_path.text = save_path


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func on_save_file(path:String):
	save_path = path
	%lineEdit_path.text = path

func _on_bn_browse_pressed():
	file_dialog.popup_centered()


func _on_bn_cancel_pressed():
	hide()


func _on_close_requested():
	hide()


func _on_bn_okay_pressed():
	var path:String = save_path
	if !save_path.to_lower().ends_with(".cyclops"):
		path = save_path + ".cyclops"

	var cyclops_file_builder:CyclopsFileBuilder = CyclopsFileBuilder.new(plugin)

	cyclops_file_builder.build_file()
	
	var text = JSON.stringify(cyclops_file_builder.document, "    ", false)

	var file:FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)

	hide()
