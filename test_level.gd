extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	
	await get_tree().process_frame

	var points:PackedVector3Array = [Vector3(4, 6, 1), Vector3(6, 6, 0), Vector3(5, 6, -2), Vector3(3, 6, -1)]
	
	print("points %s" % points)
	var bounds:PackedVector3Array = MathUtil.bounding_polygon_3d(points, Vector3(0, 1, 0))
	print("bounds %s" % bounds)
	#var cm: = ControlMesh.new()
	#cm.init_block(AABB(Vector3(0, 0, 0), Vector3(1, 1, 1)))
	
#	var result:IntersectResults = $CyclopsBlocks.intersect_ray_closest($Marker3D.transform.origin, $Marker3D.transform.basis.z)
	#var result:IntersectResults = $CyclopsBlocks.intersect_ray_closest(Vector3(-2.827666, 11.78138, -14.39898), Vector3(0.703937, -0.382888, 0.598221))
	
	#print(result)
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
