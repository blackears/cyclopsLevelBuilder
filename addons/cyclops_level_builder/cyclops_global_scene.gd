@tool
extends Node3D
class_name CyclopsGlobalScene

@export var vertex_material:StandardMaterial3D

#var mesh:ImmediateMesh
var dirty:bool = true

# Called when the node enters the scene tree for the first time.
func _ready():
	#mesh = ImmediateMesh.new()
	pass # Replace with function body.
	
func rebuild_mesh():
	var mat:StandardMaterial3D = StandardMaterial3D.new()
	mat.emission = Color(1, 0, 1)
	mat.emission_enabled = true
	mat.albedo_color = Color(0, 0, 0)
	
	
	if dirty:
		var mesh:ImmediateMesh = ImmediateMesh.new()

#		mesh.clear_surfaces()
		
		mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, vertex_material)
#		mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, mat)

		mesh.surface_add_vertex(Vector3(0, 0, 0))
		mesh.surface_add_vertex(Vector3(0, 1, 0))
		mesh.surface_add_vertex(Vector3(0, 1, 1))
		
		mesh.surface_end()
		
		$ControlMesh.mesh = mesh
		
		dirty = false
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Engine.is_editor_hint():
		rebuild_mesh()
	pass
