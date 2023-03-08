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
	#print ("draw_rect %s %s" % [start, end])
	
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
	

func draw_cube(p0:Vector3, p1:Vector3, p2:Vector3):	
	#print ("draw_rect %s %s" % [start, end])
	
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
	
	
	var mesh:ImmediateMesh = ImmediateMesh.new()
	
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, selected_material)

	mesh.surface_add_vertex(p000)
	mesh.surface_add_vertex(p001)
	mesh.surface_add_vertex(p000)
	mesh.surface_add_vertex(p100)
	mesh.surface_add_vertex(p101)
	mesh.surface_add_vertex(p001)
	mesh.surface_add_vertex(p101)
	mesh.surface_add_vertex(p100)

	mesh.surface_add_vertex(p010)
	mesh.surface_add_vertex(p011)
	mesh.surface_add_vertex(p010)
	mesh.surface_add_vertex(p110)
	mesh.surface_add_vertex(p111)
	mesh.surface_add_vertex(p011)
	mesh.surface_add_vertex(p111)
	mesh.surface_add_vertex(p110)
	
	mesh.surface_add_vertex(p000)
	mesh.surface_add_vertex(p010)
	mesh.surface_add_vertex(p100)
	mesh.surface_add_vertex(p110)
	mesh.surface_add_vertex(p101)
	mesh.surface_add_vertex(p111)
	mesh.surface_add_vertex(p001)
	mesh.surface_add_vertex(p011)
	
	mesh.surface_end()
	
	$ControlMesh.mesh = mesh

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
#	if Engine.is_editor_hint():
#		rebuild_mesh()
	pass
