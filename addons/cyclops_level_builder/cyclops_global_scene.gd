@tool
extends Node3D
class_name CyclopsGlobalScene

@export var vertex_material:BaseMaterial3D
@export var selected_material:Material

#var mesh:ImmediateMesh
var dirty:bool = true

# Called when the node enters the scene tree for the first time.
func _ready():
	#mesh = ImmediateMesh.new()
	pass # Replace with function body.
	
func rebuild_mesh():
#	var mat:StandardMaterial3D = StandardMaterial3D.new()
#	mat.emission = Color(1, 0, 1)
#	mat.emission_enabled = true
#	mat.albedo_color = Color(0, 0, 0)
	
	
	if dirty:
		var mesh:ImmediateMesh = ImmediateMesh.new()

#		mesh.clear_surfaces()
		
#		mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, vertex_material)
		mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, selected_material)
#		mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, mat)

		mesh.surface_add_vertex(Vector3(0, 0, 0))
		mesh.surface_add_vertex(Vector3(0, 1, 0))
		mesh.surface_add_vertex(Vector3(0, 1, 1))
		
		mesh.surface_end()
		
		$ControlMesh.mesh = mesh
		
		dirty = false

func draw_rect(start:Vector3, end:Vector3):	
	print ("draw_rect %s %s" % [start, end])
	
	var p0:Vector3 = start
	var p2:Vector3 = end
	var p1:Vector3 = Vector3(p0.x, p0.y, p2.z)
	var p3:Vector3 = Vector3(p2.x, p0.y, p0.z)
	
	
	var mesh:ImmediateMesh = ImmediateMesh.new()
	
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, selected_material)

	mesh.surface_add_vertex(p0)
	mesh.surface_add_vertex(p1)
	mesh.surface_add_vertex(p2)
	mesh.surface_add_vertex(p3)
	mesh.surface_add_vertex(p0)
	
	mesh.surface_end()
	
	$ControlMesh.mesh = mesh
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
#	if Engine.is_editor_hint():
#		rebuild_mesh()
	pass
