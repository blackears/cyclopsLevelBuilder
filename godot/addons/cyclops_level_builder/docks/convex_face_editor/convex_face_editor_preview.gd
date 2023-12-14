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
extends SubViewport
class_name ConvexFaceEditorPreview



@export var target_material:Material:
	get:
		return target_material
	set(value):
		target_material = value
		dirty = true

@export var uv_transform:Transform2D = Transform2D.IDENTITY:
	get:
		return uv_transform
	set(value):
		if value == uv_transform:
			return 
		uv_transform = value
		dirty = true

@export var color:Color = Color.WHITE:
	get:
		return color
	set(value):
		if value == color:
			return 
		color = value
		dirty = true

var dirty:bool = true
#var points:PackedVector3Array = [Vector3(0, 0, 0), Vector3(1, 1, 0), Vector3(1, 0, 0), Vector3(0, 1, 0)]

func take_snapshot()->ImageTexture:
	#print ("pre-grabbing image %s" % target_material.resource_path)
	await RenderingServer.frame_post_draw
	#print ("grabbing image %s" % target_material.resource_path)
	var image:Image = get_viewport().get_texture().get_image()
	var tex:ImageTexture = ImageTexture.create_from_image(image)
	return tex
	
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _process(delta):
	if dirty:
		$UvPreviewStudio.target_material = target_material
		$UvPreviewStudio.uv_transform = uv_transform
		$UvPreviewStudio.color = color
		dirty = false
	

