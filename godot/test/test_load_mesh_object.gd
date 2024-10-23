extends Node3D

@export var mesh_vector_data:MeshVectorData

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var cv:ConvexVolume = ConvexVolume.new()
	cv.init_from_mesh_vector_data(mesh_vector_data)
	
	cv.generate_uv_triplanar()
	
	var new_mvd:MeshVectorData = cv.to_mesh_vector_data()
	
	var cv2:ConvexVolume = ConvexVolume.new()
	cv2.init_from_mesh_vector_data(new_mvd)
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
