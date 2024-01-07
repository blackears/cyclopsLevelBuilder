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
class_name UpgradeCyclopsBlocksToolbar

var editor_plugin:CyclopsLevelBuilder

var activated:bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_bn_upgrade_pressed():
	var ed_iface:EditorInterface = editor_plugin.get_editor_interface()
	var nodes:Array = ed_iface.get_selection().get_selected_nodes()
	
	if nodes.is_empty():
		return
		
	if !(nodes[0] is CyclopsBlocks):
		return
		
		
	var root:CyclopsBlocks = nodes[0]
	var parent:Node = root.get_parent()
	var index:int = root.get_index()
	
	var new_root:Node3D = Node3D.new()
	root.add_sibling(new_root)
	new_root.name = root.name + "_upgraded"
	new_root.owner = ed_iface.get_edited_scene_root()
	
	root.visible = false

	#var grid_step_size:float = pow(2, editor_plugin.get_global_scene().grid_size)
	
	for child in root.get_children():
		if child is CyclopsConvexBlock:
			var old_block:CyclopsConvexBlock = child

			var vol:ConvexVolume = ConvexVolume.new()
			vol.init_from_convex_block_data(old_block.block_data)
			var centroid:Vector3 = vol.get_centroid()
			#centroid = MathUtil.snap_to_grid(centroid, grid_step_size)
			vol.translate(-centroid)

			var new_block:CyclopsBlock = CyclopsBlock.new()
			new_root.add_child(new_block)
			new_block.owner = ed_iface.get_edited_scene_root()

			new_block.name = old_block.name
			new_block.materials = old_block.materials
			new_block.block_data = vol.to_convex_block_data()
			new_block.global_transform = Transform3D.IDENTITY.translated(centroid)
	
