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

extends Resource
class_name ViewportRenderings

var viewport:Viewport
var viewport_editor_index:int

var inst_rid:RID
var mesh_rid:RID

func set_up_mesh():
	inst_rid = RenderingServer.instance_create()
	mesh_rid = RenderingServer.mesh_create()
	RenderingServer.instance_set_base(inst_rid, mesh_rid)
	
	RenderingServer.instance_set_scenario(inst_rid, viewport.world_3d.scenario)
	
	
	pass

func delete_mesh():
	RenderingServer.free_rid(inst_rid)
	RenderingServer.free_rid(mesh_rid)
	
func dispose():
	if inst_rid.is_valid():
		delete_mesh()
