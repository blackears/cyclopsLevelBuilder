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
extends Node
class_name Viewport3DViewManager

var viewport:Viewport:
	set(value):
		#if viewport:
			#viewport.remove_child(display_node)
			
		viewport = value
		
		#if viewport:
			#viewport.add_child(display_node)
		
var viewport_editor_index:int:
	set(value):
		viewport_editor_index = value
		#print("setting index ", viewport_editor_index)
		#m.rotation = Vector3(deg_to_rad(viewport_editor_index * 15), 0, 0)
		
var plugin:CyclopsLevelBuilder

#var m:MeshInstance3D = MeshInstance3D.new()

#var inst_rid:RID
#var mesh_rid:RID

#var display_node:Node3D = Node3D.new()

func _ready():
	#display_node = Node3D.new()
#	var m:MeshInstance3D = MeshInstance3D.new()
	#m.mesh = TorusMesh.new()
	#display_node.add_child(m)
	
	pass
	
func clear_tool_display():
	#for child:Node in display_node.get_children():
		#display_node.remove_child(child)
		#child.queue_free()
	pass



func _enter_tree():
	#print("Viewport3DViewManager _enter_tree ", viewport_editor_index)
	#if viewport:
		#viewport.add_child(display_node)
	
	pass
	
func _exit_tree():
	#print("Viewport3DViewManager _exit_tree ", viewport_editor_index)
	#if viewport:
		#viewport.remove_child(display_node)
	pass
	
#func set_up_mesh():
	#inst_rid = RenderingServer.instance_create()
	#mesh_rid = RenderingServer.mesh_create()
	#RenderingServer.instance_set_base(inst_rid, mesh_rid)
	#
	#RenderingServer.instance_set_scenario(inst_rid, viewport.world_3d.scenario)
	#
	#
	#pass
#
#func delete_mesh():
	#RenderingServer.free_rid(inst_rid)
	#RenderingServer.free_rid(mesh_rid)
	#
#func dispose():
	#if inst_rid.is_valid():
		#delete_mesh()
