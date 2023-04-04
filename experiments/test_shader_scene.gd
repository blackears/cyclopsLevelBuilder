@tool
extends Node3D

@export var face_material:Material
@export var wire_material:Material

var mesh:ImmediateMesh

# Called when the node enters the scene tree for the first time.
func _ready():
	mesh = ImmediateMesh.new()
	$MeshInstance3D.mesh = mesh
	
	var vol:ConvexVolume = ConvexVolume.new()
	vol.init_block(AABB(Vector3(0, 0, 0), Vector3(1, 1, 1)))
	vol.append_mesh(mesh, face_material)
	vol.append_mesh_wire(mesh, wire_material)
	
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
