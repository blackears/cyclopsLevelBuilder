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
extends Resource
class_name ToolMaterialBrushSettings

@export var paint_materials:bool = true
@export var paint_color:bool = false
@export var paint_visibility:bool = false


@export var individual_faces:bool = false
@export var erase_material:bool = false

@export var color:Color = Color.WHITE

@export var visibility:bool = true

func load_from_cache(cache:Dictionary):
	paint_materials = cache.get("paint_materials", true)
	paint_color = cache.get("paint_color", false)
	paint_visibility = cache.get("paint_visibility", false)
	individual_faces = cache.get("individual_faces", false)
	erase_material = cache.get("erase_material", false)
	color = cache.get("color", Color.WHITE)
	visibility = cache.get("visibility", false)
	
func save_to_cache():
	return {
		"paint_materials": paint_materials,
		"paint_color": paint_color,
		"paint_visibility": paint_visibility,
		"individual_faces": individual_faces,
		"erase_material": erase_material,
		"color": color,
		"visibility": visibility,
	}





