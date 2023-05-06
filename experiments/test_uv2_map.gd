extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	var vol:ConvexVolume = ConvexVolume.new()
#	vol.init_block(AABB(Vector3(0, 0, 0), Vector3(1, 1, 1)))
	vol.init_prism([\
		Vector3(1, 0, 3),
		Vector3(1, 0, 4),
		Vector3(0, 0, 3),
		Vector3(-1, 0, 2),
		Vector3(5, 0, 0),
		Vector3(3, 0, -2),
		], Vector3(0, 1, 0))
	
	var packer:FacePacker = FacePacker.new()
	var tree:FacePacker.FaceTree =  packer.build_faces(vol, .1)
	
	for f in tree.face_list:
		var line:Line2D = Line2D.new()
		add_child(line)
		line.width = 1
		
		var points:PackedVector2Array = f.points
		for i in points.size():
			points[i] *= 50
		line.points = points
	
	pass # Replace with function body.
 

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
