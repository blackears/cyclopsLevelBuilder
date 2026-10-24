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

signal mesh_changed(node:CyclopsBlock)

var mesh_instance:MeshInstance3D
var mesh_wire:MeshInstance3D
var collision_body:PhysicsBody3D
var collision_shape:CollisionShape3D
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
			
			#Convert to mesh vector data
			var mvd:MeshVectorData = MeshVectorData.new()
			mvd.create_from_convex_block(block_data)
			mesh_vector_data = mvd
			
			#dirty = true
			#mesh_changed.emit()

@export var mesh_vector_data:MeshVectorData:
	set(value):
		if mesh_vector_data != value:
			mesh_vector_data = value

			control_mesh = ConvexVolume.new()
			control_mesh.init_from_mesh_vector_data(mesh_vector_data)

			dirty = true
			mesh_changed.emit(self)

## Size of one lightmap texel in local units. Smaller values give sharper baked lighting
## at the cost of larger lightmaps. Set to 0 to skip lightmap UV (UV2) generation.
@export_range(0.0, 2.0, 0.01, "or_greater") var lightmap_texel_size:float = 0.1:
	set(value):
		if lightmap_texel_size != value:
			lightmap_texel_size = value
			dirty = true

@export var materials:Array[Material]

var default_material:Material = preload("res://addons/cyclops_level_builder/materials/grid.tres")
var display_mode:DisplayMode.Type = DisplayMode.Type.MATERIAL

@export var collision_type:Collision.Type = Collision.Type.STATIC:
	get:
		return collision_type
	set(value):
		collision_type = value
		update_physics_body()

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

func _init():
	##The render mesh is created here rather than in _ready() so that it already exists
	##when a LightmapGI node resolves its stored node paths on entering the tree.
	##LightmapGI ignores nodes that have no owner, so the mesh is owned by this block.
	##Nodes whose owner is not the scene root are not saved with the scene.
	#mesh_instance = MeshInstance3D.new()
	#mesh_instance.name = &"BlockMesh"
	#add_child(mesh_instance)
	#mesh_instance.owner = self
	#
	#mesh_instance.gi_mode = GeometryInstance3D.GI_MODE_STATIC
	pass
	

# Called when the node enters the scene tree for the first time.
func _ready():
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = &"BlockMesh"
	add_child(mesh_instance)
	mesh_instance.owner = self
	
	mesh_instance.gi_mode = GeometryInstance3D.GI_MODE_STATIC

	#print("block owner path %s" % owner.get_path())

	if Engine.is_editor_hint():
		mesh_wire = MeshInstance3D.new()
		add_child(mesh_wire)
		mesh_wire.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	
	collision_shape = CollisionShape3D.new()
	
	build_from_block()
	update_physics_body()
	
	#This is a work around to reattach lightmaps when the scene loads.  Needed until 
	# way to load individual node refreshes are possible.
	# https://github.com/godotengine/godot-proposals/discussions/15696
	_queue_lightmap_refresh()


#Baked lightmaps are assigned by LightmapGI as the scene enters the tree, which is before the
#blocks have built their meshes (in _ready). Once every block has built, ask any LightmapGI
#in the scene to assign its lightmaps again. Only one refresh is queued per scene load.

static var _lightmap_refresh_queued:bool = false

func _queue_lightmap_refresh():
	if _lightmap_refresh_queued || !is_inside_tree():
		return
	_lightmap_refresh_queued = true
	_refresh_lightmaps.call_deferred(owner if owner else get_tree().root)

static func _refresh_lightmaps(scene_root:Node):
	_lightmap_refresh_queued = false
	if !is_instance_valid(scene_root) || !scene_root.is_inside_tree():
		return
	for n in scene_root.find_children("*", "LightmapGI", true, false):
		var gi:LightmapGI = n
		var data:LightmapGIData = gi.light_data
		if data:
			gi.light_data = null
			gi.light_data = data

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
	#print("build_from_block")
		
	dirty = false
	
	mesh_instance.mesh = null
	collision_shape.shape = null

	if Engine.is_editor_hint():
		if has_node("/root/CyclopsAutoload"):
			var global_scene = get_node("/root/CyclopsAutoload")
			if global_scene && global_scene.builder:
				display_mode = global_scene.builder.display_mode
	
#	print("block_data %s" % block_data)
#	print("vert points %s" % block_data.vertex_points)
	#if !block_data:
		#return
	if !mesh_vector_data:
		return
	
#	print("got block data")
	
	var vol:ConvexVolume = ConvexVolume.new()
	vol.init_from_mesh_vector_data(mesh_vector_data)
	#vol.init_from_convex_block_data(block_data)
	
	#print("volume %s" % vol)
	
	var mesh:ArrayMesh

	if Engine.is_editor_hint():
		if has_node("/root/CyclopsAutoload"):
			var global_scene = get_node("/root/CyclopsAutoload")
			mesh_wire.mesh = vol.create_mesh_wire(global_scene.outline_material)
			#print ("added wireframe")

			#print("rebuilding mesh")
			if display_mode == DisplayMode.Type.MATERIAL:
				mesh = vol.create_mesh(materials, default_material, false, lightmap_texel_size)
			if display_mode == DisplayMode.Type.MESH:
				mesh = vol.create_mesh(materials, default_material, true, lightmap_texel_size)
				#print ("added faces")
	else:
		mesh = vol.create_mesh(materials, default_material, false, lightmap_texel_size)
	
	mesh_instance.mesh = mesh
	
	var shape:ConvexPolygonShape3D = ConvexPolygonShape3D.new()
	shape.points = vol.get_points()
	collision_shape.shape = shape
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if dirty:
		build_from_block()

	if Engine.is_editor_hint():
		if has_node("/root/CyclopsAutoload"):
			var global_scene = get_node("/root/CyclopsAutoload")

			if global_scene && global_scene.builder:
				if display_mode != global_scene.builder.display_mode:
					dirty = true
					return

func draw_unit_labels(viewport_camera:Camera3D, local_to_world:Transform3D):
	if !has_node("/root/CyclopsAutoload"):
		return
	
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
	
	if control_mesh:
		control_mesh.append_mesh_outline(mesh, viewport_camera, local_to_world, mat)


func intersect_ray_closest(origin:Vector3, dir:Vector3)->IntersectResults:
	if !mesh_vector_data:
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

	mesh_changed.emit(self)

func export_to_cyclops_file(file_builder:CyclopsFileBuilder)->Dictionary:
	var result:Dictionary
	
	result["collision_type"] = Collision.Type.keys()[collision_type]
	result["collision_layer"] = collision_layer
	result["collision_mask"] = collision_mask
	
	var mat_res_paths:PackedStringArray
	for mat in materials:
		if mat:
			mat_res_paths.append(mat.resource_path)
		else:
			mat_res_paths.append("")
	result["materials"] = mat_res_paths
	
	if mesh_vector_data:
		result["mesh"] = mesh_vector_data.to_dictionary(file_builder)
		
	return result
