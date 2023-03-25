extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	
	await get_tree().process_frame
	
	var cm: = ControlMesh.new()
	cm.init_block(AABB(Vector3(0, 0, 0), Vector3(1, 1, 1)))
	
	var result:IntersectResults = $CyclopsBlocks.intersect_ray_closest($Marker3D.transform.origin, Vector3.BACK)
	
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
