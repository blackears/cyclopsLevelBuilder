@tool
extends Node3D
class_name MaterialPreviewScene

@onready var mesh_sphere:MeshInstance3D = %mesh_sphere
@onready var mesh_rectangle:MeshInstance3D = %mesh_rectangle
@onready var mesh_cube:MeshInstance3D = %mesh_cube
@onready var mesh_torus:MeshInstance3D = %mesh_torus

enum MeshType { RECTANGLE, SPHERE, CUBE, TORUS }

@export var mesh_type:MeshType = MeshType.RECTANGLE:
	set(v):
		if v == mesh_type:
			return
		mesh_type = v
		
		update_mesh()

@export var display_material:Material:
	set(v):
		if v == display_material:
			return
		display_material = v
		
		if is_node_ready():
			update_material()

func update_mesh():
	if is_node_ready():
		#mesh_instance.set_surface_override_material(0, display_material)
		mesh_sphere.visible = mesh_type == MeshType.SPHERE
		mesh_rectangle.visible = mesh_type == MeshType.RECTANGLE
		mesh_cube.visible = mesh_type == MeshType.CUBE
		mesh_torus.visible = mesh_type == MeshType.TORUS

func update_material():
	if is_node_ready():
		mesh_sphere.set_surface_override_material(0, display_material)
		mesh_rectangle.set_surface_override_material(0, display_material)
		mesh_cube.set_surface_override_material(0, display_material)
		mesh_torus.set_surface_override_material(0, display_material)

func _ready() -> void:
	update_mesh()
	update_material()
