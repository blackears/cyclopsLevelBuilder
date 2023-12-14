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
class_name CommandMaterialDockAddMaterials
extends CyclopsCommand

#Public
var res_path_list:Array[String]

#Private
var old_res_path_list:Array[String]


func _init():
	command_name = "Add materials"

func do_it():
#	print("Add Materials do_it")
	var mat_dock:MaterialPaletteViewport = builder.material_dock
	old_res_path_list = mat_dock.material_list.duplicate()

#	print("old mat list %s" % str(old_res_path_list))

	var new_list:Array[String] = old_res_path_list.duplicate()
	for mat in res_path_list:
		if !new_list.has(mat):
			new_list.append(mat)

#	print("new mat list %s" % str(new_list))
			
	mat_dock.set_materials(new_list)

func undo_it():
	var mat_dock:MaterialPaletteViewport = builder.material_dock
	mat_dock.set_materials(old_res_path_list)
