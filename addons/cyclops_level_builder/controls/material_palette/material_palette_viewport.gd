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
extends Control
class_name MaterialPaletteViewport

@export var material_list:Array[String] = []

@export var thumbnail_group:ThumbnailGroup

# Called when the node enters the scene tree for the first time.
func _ready():
	print("MaterialPaletteViewport")
	update_thumbnails()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _can_drop_data(at_position:Vector2, data:Variant):
#	print("_can_drop_data %s" % data)
	return typeof(data) == TYPE_DICTIONARY and data.has("type") and data["type"] == "files"


func _drop_data(at_position, data):
	var files = data["files"]
	#print("--drop")
	for f in files:
#		print("Dropping %s" % f)
		var res:Resource = load(f)
		if res is Material:
			if !material_list.has(f):
				material_list.append(f)
	update_thumbnails()
		
func update_thumbnails():
	var cur_sel:String
	
	for child in $ScrollContainer/HFlowContainer.get_children():
		if child.selected:
			cur_sel = child.material_path
			break

	for child in $ScrollContainer/HFlowContainer.get_children():
		remove_child(child)
		child.queue_free()

	for path in material_list:
		var res:Resource = preload("res://addons/cyclops_level_builder/controls/material_palette/material_thumbnail.tscn")
		var thumbnail:MaterialThumbnail = res.instantiate()
		thumbnail.material_path = path
		thumbnail.group = thumbnail_group
		
		$ScrollContainer/HFlowContainer.add_child(thumbnail)
		thumbnail.owner = self
	
	if cur_sel:
		for child in get_children():
			if child.material_path == cur_sel:
				child.grab_focus()
