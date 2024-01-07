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
class_name CyclopsBlock

signal mesh_changed

@export var collision_type:Collision.Type = Collision.Type.STATIC:
	get:
		return collision_type
	set(value):
		collision_type = value
		update_physics_body()

var mesh_instance:MeshInstance3D
var mesh_wire:MeshInstance3D
var collision_body:PhysicsBody3D
var collision_shape:CollisionShape3D
#var occluder:OccluderInstance3D
#var selected:bool
var active:bool

var dirty:bool = true

var control_mesh:ConvexVolume

@export var block_data:ConvexBlockData:
	get:
		return block_data
	set(value):
		if block_data != value:
			block_data = value
			control_mesh = ConvexVolume.new()
			control_mesh.init_from_convex_block_data(block_data)
			
			dirty = true
			mesh_changed.emit()
	
@export var materials:Array[Material]

var default_material:Material = preload("res://addons/cyclops_level_builder/materials/grid.tres")
var display_mode:DisplayMode.Type = DisplayMode.Type.MATERIAL

@export_flags_3d_physics var collision_layer:int = 1:
	get:
		return collision_layer
	set(value):
		collision_layer = value
		if collision_body:
			collision_body.collision_layer = collision_layer
		
@export_flags_3d_physics var collision_mask:int = 1:
	get:
		return collision_mask
	set(value):
		collision_mask = value
		if collision_body:
			collision_body.collision_mask = collision_mask

# Called when the node enters the scene tree for the first time.
func _ready():
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	mesh_instance.gi_mode = GeometryInstance3D.GI_MODE_STATIC

	#print("block owner path %s" % owner.get_path())

	if Engine.is_editor_hint():
		mesh_wire = MeshInstance3D.new()
		add_child(mesh_wire)
	
	collision_shape = CollisionShape3D.new()

	#occluder = OccluderInstance3D.new()
	#add_child(occluder)
	
	build_from_block()
	update_physics_body()

func update_physics_body():
	
	if collision_body:
		collision_body.remove_child(collision_shape)
		collision_body.queue_free()
		collision_body = null
	
	match collision_type:
		Collision.Type.STATIC:
			collision_body = StaticBody3D.new()
		Collision.Type.KINEMATIC:
			collision_body = CharacterBody3D.new()
		Collision.Type.RIGID:
			collision_body = RigidBody3D.new()
			
	if collision_body:
		collision_body.collision_layer = collision_layer
		collision_body.collision_mask = collision_mask
		add_child(collision_body)
		
		collision_body.add_child(collision_shape)
	

func build_from_block():
		
	dirty = false
	
	mesh_instance.mesh = null
	collision_shape.shape = null

	if Engine.is_editor_hint():
#		var global_scene:CyclopsGlobalScene = get_node("/root/CyclopsAutoload")
		var global_scene = get_node("/root/CyclopsAutoload")
		display_mode = global_scene.builder.display_mode
	
#	print("block_data %s" % block_data)
#	print("vert points %s" % block_data.vertex_points)
	if !block_data:
		return
	
#	print("got block data")		
	
	var vol:ConvexVolume = ConvexVolume.new()
	vol.init_from_convex_block_data(block_data)
	
	#print("volume %s" % vol)
	
	var mesh:ArrayMesh

	if Engine.is_editor_hint():
		var global_scene = get_node("/root/CyclopsAutoload")
		mesh_wire.mesh = vol.create_mesh_wire(global_scene.outline_material)
		#print ("added wireframe")

		if display_mode == DisplayMode.Type.MATERIAL:
			mesh = vol.create_mesh(materials, default_material)
		if display_mode == DisplayMode.Type.MESH:
			mesh = vol.create_mesh(materials, default_material, true)
			#print ("added faces")
	else:
		mesh = vol.create_mesh(materials, default_material)
	
	mesh_instance.mesh = mesh
	
	var shape:ConvexPolygonShape3D = ConvexPolygonShape3D.new()
	shape.points = vol.get_points()
	collision_shape.shape = shape
	
	#if !Engine.is_editor_hint():
		##Disabling this in the editor for now since this is causing slowdown
		#var occluder_object:ArrayOccluder3D = ArrayOccluder3D.new()
		#occluder_object.vertices = vol.get_points()
		#occluder_object.indices = vol.get_trimesh_indices()
		#occluder.occluder = occluder_object
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if dirty:
			
		build_from_block()

	if Engine.is_editor_hint():
#		var global_scene:CyclopsGlobalScene = get_node("/root/CyclopsAutoload")
		var global_scene = get_node("/root/CyclopsAutoload")

		if display_mode != global_scene.builder.display_mode:
			dirty = true
			return

func draw_unit_labels(viewport_camera:Camera3D, local_to_world:Transform3D):
	var global_scene:CyclopsGlobalScene = get_node("/root/CyclopsAutoload")

	var font:Font = global_scene.units_font
	var font_size:float = global_scene.units_font_size	
	var descent:float = font.get_descent(font_size)
	var text_offset:Vector2 = Vector2(0, -global_scene.vertex_radius - descent)
	
	if control_mesh:
		for e_idx in control_mesh.edges.size():
			var e:ConvexVolume.EdgeInfo = control_mesh.edges[e_idx]
			var focus:Vector3 = local_to_world * e.get_midpoint()
			if !viewport_camera.is_position_behind(focus):
				var focus_2d:Vector2 = viewport_camera.unproject_position(focus)
				
				var v0:ConvexVolume.VertexInfo = control_mesh.vertices[e.start_index]
				var v1:ConvexVolume.VertexInfo = control_mesh.vertices[e.end_index]
				var distance:Vector3 = v1.point - v0.point
				global_scene.draw_text("%.3f" % distance.length(), focus_2d, font, font_size)
		
		

func append_mesh_outline(mesh:ImmediateMesh, viewport_camera:Camera3D, local_to_world:Transform3D, mat:Material):
	#var global_scene:CyclopsGlobalScene = get_node("/root/CyclopsAutoload")
	
	if control_mesh:
		control_mesh.append_mesh_outline(mesh, viewport_camera, local_to_world, mat)

func append_mesh_wire(mesh:ImmediateMesh):
	var global_scene:CyclopsGlobalScene = get_node("/root/CyclopsAutoload")
	
	var mat:Material = global_scene.outline_material
	control_mesh.append_mesh_wire(mesh, mat)


func intersect_ray_closest(origin:Vector3, dir:Vector3)->IntersectResults:
	if !block_data:
		return null
	
	var xform:Transform3D = global_transform.affine_inverse()
	var origin_local:Vector3 = xform * origin
	var dir_local:Vector3 = xform.basis * dir
	
	var result:IntersectResults = control_mesh.intersect_ray_closest(origin_local, dir_local)
	if result:
		result.object = self
		
	return result


func select_face(face_idx:int, select_type:Selection.Type = Selection.Type.REPLACE):
	if select_type == Selection.Type.REPLACE:
		for f in control_mesh.faces:
			f.selected = f.index == face_idx
	elif select_type == Selection.Type.ADD:
		control_mesh.faces[face_idx].selected = true
	elif select_type == Selection.Type.SUBTRACT:
		control_mesh.faces[face_idx].selected = true
	elif select_type == Selection.Type.TOGGLE:
		control_mesh.faces[face_idx].selected = !control_mesh.faces[face_idx].selected

	mesh_changed.emit()
