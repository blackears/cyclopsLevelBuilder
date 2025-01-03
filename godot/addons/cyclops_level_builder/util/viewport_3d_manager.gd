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
class_name Viewport3DManager

var plugin:CyclopsLevelBuilder:
	set(value):
		plugin = value
		for v in viewport_views:
			v.plugin = value
	
var viewport_views:Array[Viewport3DViewManager]
var unit_sphere:GeometryMesh = MathGeometry.unit_sphere()
#var tool_mesh:ImmediateMesh

# Called when the node enters the scene tree for the first time.
func _ready():
	#tool_mesh = ImmediateMesh.new()
	#$ToolInstance3D.mesh = tool_mesh
	
	#var m:MeshInstance3D = MeshInstance3D.new()
	#m.mesh = SphereMesh.new()
	#add_child(m)
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func draw_line(p0:Vector3, p1:Vector3, mat:Material):
	var mesh:MeshInstance3D = MeshInstance3D.new()
	%tool_display.add_child(mesh)
	
	var mesh_shape:ImmediateMesh = ImmediateMesh.new()
	mesh.mesh = mesh_shape
	
	mesh_shape.surface_begin(Mesh.PRIMITIVE_LINES, mat)

	mesh_shape.surface_add_vertex(p0)
	mesh_shape.surface_add_vertex(p1)
	
	mesh_shape.surface_end()

func draw_line_strip(points:PackedVector3Array, mat:Material, closed:bool = true):
	if points.is_empty():
		return

	var mesh:MeshInstance3D = MeshInstance3D.new()
	%tool_display.add_child(mesh)
	
	var mesh_shape:ImmediateMesh = ImmediateMesh.new()
	mesh.mesh = mesh_shape
	
	mesh_shape.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, mat)

	for p in points:
		mesh_shape.surface_add_vertex(p)

	if closed && !points[0].is_equal_approx(points[-1]):
		mesh_shape.surface_add_vertex(points[0])
	
	mesh_shape.surface_end()


func draw_wireframe(points:PackedVector3Array, edges:PackedInt32Array, mat:Material = null):
	var mesh:MeshInstance3D = MeshInstance3D.new()
	%tool_display.add_child(mesh)
	
	#for p in points:
		#draw_vertex(p, vertex_mat)

	var mesh_shape:ImmediateMesh = ImmediateMesh.new()
	mesh.mesh = mesh_shape

	mesh_shape.surface_begin(Mesh.PRIMITIVE_LINES, mat)

	for e_idx in edges:
		mesh_shape.surface_add_vertex(points[e_idx])
	
	mesh_shape.surface_end()


#func draw_points(points:PackedVector3Array, vertex_mat:Material = null):
	#draw_vertices(points, vertex_mat)

func draw_vertex(position:Vector3, mat:Material = null):
	draw_vertices([position], mat)
	
func draw_vertices(vertices:PackedVector3Array, mat:Material = null):
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices

	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_POINTS, arrays)
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.mesh = arr_mesh

	mesh_inst.material_override = mat

	%VertexGroup.add_child(mesh_inst)


func draw_prism(points:PackedVector3Array, extrude:Vector3, mat:Material = null, vertex_mat = null):
	var mesh:MeshInstance3D = MeshInstance3D.new()
	%tool_display.add_child(mesh)
	
	var mesh_shape:ImmediateMesh = ImmediateMesh.new()
	mesh.mesh = mesh_shape
	
	for p in points:
		draw_vertex(p, vertex_mat)
		draw_vertex(p + extrude, vertex_mat)
	
	#Bottom loop	
	mesh_shape.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, mat)

	for p in points:
		mesh_shape.surface_add_vertex(p)

	mesh_shape.surface_add_vertex(points[0])
	
	mesh_shape.surface_end()

	#Top loop	
	mesh_shape.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, mat)

	for p in points:
		mesh_shape.surface_add_vertex(p + extrude)

	mesh_shape.surface_add_vertex(points[0] + extrude)
	
	mesh_shape.surface_end()
	
	#Sides
	mesh_shape.surface_begin(Mesh.PRIMITIVE_LINES, mat)

	for p in points:
		mesh_shape.surface_add_vertex(p)
		mesh_shape.surface_add_vertex(p + extrude)
	
	mesh_shape.surface_end()
	

# Draws the bounding box for the points [p0, p1, p2]
func draw_cube(p0:Vector3, p1:Vector3, p2:Vector3, mat:Material = null, vertex_mat:Material = null):	
#	print ("draw_cube %s %s %s" % [p0, p1, p2])
	var mesh:MeshInstance3D = MeshInstance3D.new()
	%tool_display.add_child(mesh)
	
	var mesh_shape:ImmediateMesh = ImmediateMesh.new()
	mesh.mesh = mesh_shape
	
	var bounds:AABB = AABB(p0, Vector3.ZERO)
	bounds = bounds.expand(p1)
	bounds = bounds.expand(p2)
	
	var p000:Vector3 = bounds.position
	var p111:Vector3 = bounds.end
	var p001:Vector3 = Vector3(p000.x, p000.y, p111.z)
	var p010:Vector3 = Vector3(p000.x, p111.y, p000.z)
	var p011:Vector3 = Vector3(p000.x, p111.y, p111.z)
	var p100:Vector3 = Vector3(p111.x, p000.y, p000.z)
	var p101:Vector3 = Vector3(p111.x, p000.y, p111.z)
	var p110:Vector3 = Vector3(p111.x, p111.y, p000.z)
	
	draw_vertex(p000, vertex_mat)
	draw_vertex(p001, vertex_mat)
	draw_vertex(p010, vertex_mat)
	draw_vertex(p011, vertex_mat)
	draw_vertex(p100, vertex_mat)
	draw_vertex(p101, vertex_mat)
	draw_vertex(p110, vertex_mat)
	draw_vertex(p111, vertex_mat)
	
	
	mesh_shape.surface_begin(Mesh.PRIMITIVE_LINES, mat)

	mesh_shape.surface_add_vertex(p000)
	mesh_shape.surface_add_vertex(p001)
	mesh_shape.surface_add_vertex(p000)
	mesh_shape.surface_add_vertex(p100)
	mesh_shape.surface_add_vertex(p101)
	mesh_shape.surface_add_vertex(p001)
	mesh_shape.surface_add_vertex(p101)
	mesh_shape.surface_add_vertex(p100)

	mesh_shape.surface_add_vertex(p010)
	mesh_shape.surface_add_vertex(p011)
	mesh_shape.surface_add_vertex(p010)
	mesh_shape.surface_add_vertex(p110)
	mesh_shape.surface_add_vertex(p111)
	mesh_shape.surface_add_vertex(p011)
	mesh_shape.surface_add_vertex(p111)
	mesh_shape.surface_add_vertex(p110)
	
	mesh_shape.surface_add_vertex(p000)
	mesh_shape.surface_add_vertex(p010)
	mesh_shape.surface_add_vertex(p100)
	mesh_shape.surface_add_vertex(p110)
	mesh_shape.surface_add_vertex(p101)
	mesh_shape.surface_add_vertex(p111)
	mesh_shape.surface_add_vertex(p001)
	mesh_shape.surface_add_vertex(p011)
	
	mesh_shape.surface_end()
	
func draw_triangles(tri_points:PackedVector3Array, mat:Material = null):	
	var mesh:MeshInstance3D = MeshInstance3D.new()
	%tool_display.add_child(mesh)
	
	var mesh_shape:ImmediateMesh = ImmediateMesh.new()
	mesh.mesh = mesh_shape
	
	mesh_shape.surface_begin(Mesh.PRIMITIVE_TRIANGLES, mat)
	
	for p in tri_points:
		mesh_shape.surface_add_vertex(p)
	
	mesh_shape.surface_end()
		

#func draw_sphere(xform:Transform3D = Transform3D.IDENTITY, material:Material = null, segs_lat:int = 6, segs_long:int = 8):
	#unit_sphere.append_to_immediate_mesh(tool_mesh, material, xform)
	

func draw_selection_marquis(viewport_camera:Camera3D):
	#for vr:Viewport3DViewManager in viewport_views:
		#var vm:ViewportMesh3D = vr.draw_selection_marquis()
##		print("got vm " , vm)
		#if vm:
			#%tool_display.add_child(vm)
	#pass
	###########
		
	var mesh:MeshInstance3D = MeshInstance3D.new()
	%tool_display.add_child(mesh)
	
	var mesh_shape:ImmediateMesh = ImmediateMesh.new()
	mesh.mesh = mesh_shape

	var global_scene:CyclopsGlobalScene = get_node("/root/CyclopsAutoload")

	var blocks:Array[CyclopsBlock] = plugin.get_selected_blocks()
	var active_block:CyclopsBlock = plugin.get_active_block()
	for block:CyclopsBlock in blocks:
		var active:bool = block == active_block
		var mat:Material = global_scene.tool_object_active_material if active else global_scene.tool_object_selected_material
		
		#Selection highlight outline
		block.append_mesh_outline(mesh_shape, viewport_camera, block.global_transform, mat)
		
		#block.draw_unit_labels(viewport_camera, block.global_transform)


func draw_screen_rect(viewport_camera:Camera3D, p00:Vector2, p11:Vector2, material:Material):
	var mesh:MeshInstance3D = MeshInstance3D.new()
	%tool_display.add_child(mesh)
	
	var mesh_shape:ImmediateMesh = ImmediateMesh.new()
	mesh.mesh = mesh_shape

	var global_scene:CyclopsGlobalScene = plugin.get_node("/root/CyclopsAutoload")

	var p01:Vector2 = Vector2(p00.x, p11.y)
	var p10:Vector2 = Vector2(p11.x, p00.y)
	var z_pos:float = (viewport_camera.near + viewport_camera.far) / 2
	
	mesh_shape.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, material)
	
	for p in [p00, p01, p11, p10, p00]:
		var p_proj:Vector3 = viewport_camera.project_position(p, z_pos)
#		print("p_proj %s" % p_proj)
		
		mesh_shape.surface_add_vertex(p_proj)
	
	mesh_shape.surface_end()


#Called by CyclopsLevelBuilder to draw 2D components
func draw_over_viewport(overlay:Control):
	#overlay.draw_circle(Vector2(100, 200), 10, Color.AQUAMARINE)
	if true:
		return

	
func clear_tool_display():
	for child:Node in %tool_display.get_children():
		%tool_display.remove_child(child)
		child.queue_free()

	for child:Node in %VertexGroup.get_children():
		%VertexGroup.remove_child(child)
		child.queue_free()

	for vr:Viewport3DViewManager in viewport_views:
		vr.clear_tool_display()

func set_custom_gizmo(gizmo:Node3D):
	for child in %GizmoControl.get_children():
		%GizmoControl.remove_child(child)
	
	if gizmo:
#		print("Setting gizmo")
		%GizmoControl.add_child(gizmo)
	
func _enter_tree():
	for i in 4:
		var vr:Viewport3DViewManager = Viewport3DViewManager.new()
		vr.plugin = plugin
		viewport_views.append(vr)
		add_child(vr)
		
		var viewport:SubViewport = EditorInterface.get_editor_viewport_3d(i)
		vr.viewport = viewport
		vr.viewport_editor_index = i

func _exit_tree():
	for i in 4:
		var vr:Viewport3DViewManager = viewport_views[i]
		#vr.dispose()
		vr.queue_free()
		
	viewport_views.clear()
	
