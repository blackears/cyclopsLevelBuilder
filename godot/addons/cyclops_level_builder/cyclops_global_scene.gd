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
extends Node3D
class_name CyclopsGlobalScene

@export var selection_color:Color = Color(1, .5, .5, 1)
@export var default_material:Material = preload("res://addons/cyclops_level_builder/materials/grid.tres")
@export var selection_rect_material:Material = preload("res://addons/cyclops_level_builder/materials/selection_rect_material.tres")
@export var tool_edit_active_material:Material = preload("res://addons/cyclops_level_builder/materials/tool_edit_active_material.tres")
@export var tool_edit_active_fill_material:Material = preload("res://addons/cyclops_level_builder/materials/tool_edit_active_fill_material.tres")
@export var tool_edit_selected_material:Material = preload("res://addons/cyclops_level_builder/materials/tool_edit_selected_material.tres")
@export var tool_edit_selected_fill_material:Material = preload("res://addons/cyclops_level_builder/materials/tool_edit_selected_fill_material.tres")
@export var tool_edit_unselected_material:Material = preload("res://addons/cyclops_level_builder/materials/tool_edit_unselected_material.tres")
@export var tool_object_active_material:Material = preload("res://addons/cyclops_level_builder/materials/tool_object_active_material.tres")
@export var tool_object_selected_material:Material = preload("res://addons/cyclops_level_builder/materials/tool_object_selected_material.tres")
@export var vertex_unselected_material:Material = preload("res://addons/cyclops_level_builder/materials/vertex_unselected_material.tres")
@export var vertex_selected_material:Material = preload("res://addons/cyclops_level_builder/materials/vertex_selected_material.tres")
@export var vertex_active_material:Material = preload("res://addons/cyclops_level_builder/materials/vertex_active_material.tres")
@export var vertex_tool_material:Material = preload("res://addons/cyclops_level_builder/materials/vertex_tool_material.tres")
@export var vertex_radius:float = 8

@export var tool_material:Material = preload("res://addons/cyclops_level_builder/materials/tool_material.tres")
@export var outline_material:Material = preload("res://addons/cyclops_level_builder/materials/outline_material.tres")
var tool_mesh:ImmediateMesh

@export var units_font:Font
@export var units_font_size:int = 16

#@export var grid_size:int = 0
@export var drag_angle_limit:float = deg_to_rad(5)

const SNAPPING_ENABLED:String = "snapping/enabled"
const SNAPPING_GRID_UNIT_SIZE:String = "snapping/grid/unit_size"
const SNAPPING_GRID_USE_SUBDIVISIONS:String = "snapping/grid/use_subdivisions"
const SNAPPING_GRID_SUBDIVISIONS:String = "snapping/grid/subdivisions"
const SNAPPING_GRID_POWER_OF_TWO_SCALE:String = "snapping/grid/power_of_two_scale"
const SNAPPING_GRID_TRANSFORM:String = "snapping/grid/transform"
const SNAPPING_GRID_ANGLE:String = "snapping/grid/angle"

@export_file("*.config") var settings_file:String = "cyclops_settings.config"
var settings:Settings = Settings.new()

signal xray_mode_changed(value:bool)

@export var xray_mode:bool = false:
	get:
		return xray_mode
	set(value):
		if xray_mode != value:		
			xray_mode = value
			xray_mode_changed.emit(value)

var unit_sphere:GeometryMesh
var builder:CyclopsLevelBuilder


# Called when the node enters the scene tree for the first time.
func _ready():
	init_settings()
	
	unit_sphere = MathGeometry.unit_sphere()
	
	tool_mesh = ImmediateMesh.new()
	$ToolInstance3D.mesh = tool_mesh
	
	if FileAccess.file_exists(settings_file):
		settings.load_from_file(settings_file)

func init_settings():
	settings.add_setting(SNAPPING_ENABLED, true, TYPE_BOOL)
	settings.add_setting(SNAPPING_GRID_UNIT_SIZE, 1, TYPE_FLOAT)
	settings.add_setting(SNAPPING_GRID_POWER_OF_TWO_SCALE, 0, TYPE_INT)
	settings.add_setting(SNAPPING_GRID_USE_SUBDIVISIONS, false, TYPE_BOOL)
	settings.add_setting(SNAPPING_GRID_SUBDIVISIONS, 10, TYPE_INT)
	settings.add_setting(SNAPPING_GRID_TRANSFORM, Transform3D.IDENTITY, TYPE_TRANSFORM3D)
	settings.add_setting(SNAPPING_GRID_ANGLE, 15, TYPE_FLOAT)

func save_settings():
	#print("saving ", settings_file)
	settings.save_to_file(settings_file)

func calc_snap_to_grid_util():
	var snap_to_grid_util:SnapToGridUtil = SnapToGridUtil.new()
	#print("calc_snap_to_grid_util")
	snap_to_grid_util.unit_size = settings.get_property(SNAPPING_GRID_UNIT_SIZE)
	#print("unit_size ", snap_to_grid_util.unit_size)
	snap_to_grid_util.power_of_two_scale = settings.get_property(SNAPPING_GRID_POWER_OF_TWO_SCALE)
	#print("power_of_two_scale ", snap_to_grid_util.power_of_two_scale)
	snap_to_grid_util.use_subdivisions = settings.get_property(SNAPPING_GRID_USE_SUBDIVISIONS)
	snap_to_grid_util.grid_subdivisions = settings.get_property(SNAPPING_GRID_SUBDIVISIONS)
	snap_to_grid_util.grid_transform = settings.get_property(SNAPPING_GRID_TRANSFORM)
	return snap_to_grid_util
	
#Called by CyclopsLevelBuilder to draw 2D components
func draw_over_viewport(overlay:Control):
	pass

func draw_line(p0:Vector3, p1:Vector3, mat:Material):
	
	tool_mesh.surface_begin(Mesh.PRIMITIVE_LINES, mat)

	tool_mesh.surface_add_vertex(p0)
	tool_mesh.surface_add_vertex(p1)
	
	tool_mesh.surface_end()

func draw_loop(points:PackedVector3Array, closed:bool = true, mat:Material = null):
	if points.is_empty():
		return
	
	tool_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, mat)

	for p in points:
		tool_mesh.surface_add_vertex(p)

	if closed:		
		tool_mesh.surface_add_vertex(points[0])
	
	tool_mesh.surface_end()
	

func draw_prism(points:PackedVector3Array, extrude:Vector3, mat:Material = null, vertex_mat = null):
	for p in points:
		draw_vertex(p, vertex_mat)
		draw_vertex(p + extrude, vertex_mat)
	
	#Bottom loop	
	tool_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, mat)

	for p in points:
		tool_mesh.surface_add_vertex(p)

	tool_mesh.surface_add_vertex(points[0])
	
	tool_mesh.surface_end()

	#Top loop	
	tool_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, mat)

	for p in points:
		tool_mesh.surface_add_vertex(p + extrude)

	tool_mesh.surface_add_vertex(points[0] + extrude)
	
	tool_mesh.surface_end()
	
	#Sides
	tool_mesh.surface_begin(Mesh.PRIMITIVE_LINES, mat)

	for p in points:
		tool_mesh.surface_add_vertex(p)
		tool_mesh.surface_add_vertex(p + extrude)
	
	tool_mesh.surface_end()
	

func draw_triangles(tri_points:PackedVector3Array, mat:Material = null):	
	tool_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, mat)
	
	for p in tri_points:
		tool_mesh.surface_add_vertex(p)
	
	tool_mesh.surface_end()
	
func draw_rect(start:Vector3, end:Vector3, mat:Material = null, vertex_mat:Material = null):	
	
	var p0:Vector3 = start
	var p2:Vector3 = end
	var p1:Vector3 = Vector3(p0.x, p0.y, p2.z)
	var p3:Vector3 = Vector3(p2.x, p0.y, p0.z)
	
	draw_vertex(p0, vertex_mat)
	draw_vertex(p1, vertex_mat)
	draw_vertex(p2, vertex_mat)
	draw_vertex(p3, vertex_mat)
	
	tool_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, mat)

	tool_mesh.surface_add_vertex(p0)
	tool_mesh.surface_add_vertex(p1)
	tool_mesh.surface_add_vertex(p2)
	tool_mesh.surface_add_vertex(p3)
	tool_mesh.surface_add_vertex(p0)
	
	tool_mesh.surface_end()
	
func clear_tool_mesh():
	#tool_mesh = ImmediateMesh.new()
	#$ToolInstance3D.mesh = tool_mesh
	tool_mesh.clear_surfaces()
	
	for child in %VertexGroup.get_children():
		%VertexGroup.remove_child(child)
		child.queue_free()
	#print("clear")
	%cyclops_overlay.clear()

func draw_text(text:String, pos:Vector2, font:Font, font_size:float):
	%cyclops_overlay.draw_text(text, pos, font, font_size)

# Draws the bounding box for the points [p0, p1, p2]
func draw_cube(p0:Vector3, p1:Vector3, p2:Vector3, mat:Material = null, vertex_mat:Material = null):	
#	print ("draw_cube %s %s %s" % [p0, p1, p2])
	
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
	
	
	tool_mesh.surface_begin(Mesh.PRIMITIVE_LINES, mat)

	tool_mesh.surface_add_vertex(p000)
	tool_mesh.surface_add_vertex(p001)
	tool_mesh.surface_add_vertex(p000)
	tool_mesh.surface_add_vertex(p100)
	tool_mesh.surface_add_vertex(p101)
	tool_mesh.surface_add_vertex(p001)
	tool_mesh.surface_add_vertex(p101)
	tool_mesh.surface_add_vertex(p100)

	tool_mesh.surface_add_vertex(p010)
	tool_mesh.surface_add_vertex(p011)
	tool_mesh.surface_add_vertex(p010)
	tool_mesh.surface_add_vertex(p110)
	tool_mesh.surface_add_vertex(p111)
	tool_mesh.surface_add_vertex(p011)
	tool_mesh.surface_add_vertex(p111)
	tool_mesh.surface_add_vertex(p110)
	
	tool_mesh.surface_add_vertex(p000)
	tool_mesh.surface_add_vertex(p010)
	tool_mesh.surface_add_vertex(p100)
	tool_mesh.surface_add_vertex(p110)
	tool_mesh.surface_add_vertex(p101)
	tool_mesh.surface_add_vertex(p111)
	tool_mesh.surface_add_vertex(p001)
	tool_mesh.surface_add_vertex(p011)
	
	tool_mesh.surface_end()
	
	#$ToolInstance3D.mesh = mesh

func draw_points(points:PackedVector3Array, vertex_mat:Material = null):
	draw_vertices(points, vertex_mat)

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

	

func draw_sphere(xform:Transform3D = Transform3D.IDENTITY, material:Material = null, segs_lat:int = 6, segs_long:int = 8):
	unit_sphere.append_to_immediate_mesh(tool_mesh, material, xform)
	

func draw_selected_blocks(viewport_camera:Camera3D):
	var global_scene:CyclopsGlobalScene = builder.get_node("/root/CyclopsAutoload")

	var blocks:Array[CyclopsBlock] = builder.get_selected_blocks()
	var active_block:CyclopsBlock = builder.get_active_block()
	for block in blocks:
		var active:bool = block == active_block
		var mat:Material = global_scene.tool_object_active_material if active else global_scene.tool_object_selected_material
		
		#Selection highlight outline
		block.append_mesh_outline(tool_mesh, viewport_camera, block.global_transform, mat)
		
		#block.draw_unit_labels(viewport_camera, block.global_transform)


func draw_screen_rect(viewport_camera:Camera3D, p00:Vector2, p11:Vector2, material:Material):
	var global_scene:CyclopsGlobalScene = builder.get_node("/root/CyclopsAutoload")

	var p01:Vector2 = Vector2(p00.x, p11.y)
	var p10:Vector2 = Vector2(p11.x, p00.y)
	var z_pos:float = (viewport_camera.near + viewport_camera.far) / 2
	
	tool_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, material)
	
	for p in [p00, p01, p11, p10, p00]:
		var p_proj:Vector3 = viewport_camera.project_position(p, z_pos)
#		print("p_proj %s" % p_proj)
		
		tool_mesh.surface_add_vertex(p_proj)
	
	tool_mesh.surface_end()
	
func set_custom_gizmo(gizmo:Node3D):
	for child in %GizmoControl.get_children():
		%GizmoControl.remove_child(child)
	
	if gizmo:
#		print("Setting gizmo")
		%GizmoControl.add_child(gizmo)
	
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
