extends Node
class_name MaterialThumbnailGenerator

@onready var subviewport:SubViewport = %SubViewport

enum Shape { PLANE, SPHERE, CUBE, TORUS }

class Request extends Resource:
	var material:Material
	var mesh_type:MaterialPreviewScene.MeshType
	var size:Vector2i
	var callback:Callable
	

var queue:Array[Request]
var mutex:Mutex = Mutex.new()

var cur_request:Request

func generate_thumbnail(material:Material, mesh_type:MaterialPreviewScene.MeshType, size:Vector2i, callback:Callable):
	var request:Request = Request.new()
	request.material = material
	request.mesh_type = mesh_type
	request.size = size
	request.callback = callback
	
	mutex.lock()
	queue.push_front(request)
	mutex.unlock()
	
func _process(delta: float) -> void:
	if !cur_request:
		if queue.is_empty():
			return
		
		cur_request = queue.pop_back()
		subviewport.size = cur_request.size
		
		
	
	pass
