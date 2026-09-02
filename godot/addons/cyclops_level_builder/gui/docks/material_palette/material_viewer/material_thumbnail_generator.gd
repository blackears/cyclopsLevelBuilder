extends Node
class_name MaterialThumbnailGenerator

enum Shape { PLANE, SPHERE, CUBE, TORUS }

class Request extends Resource:
	var material:Material
	var mesh_type:MaterialPreviewScene.MeshType
	var size:Vector2i
	var callback:Callable
	

var queue:Array[Request]
var mutex:Mutex = Mutex.new()

func generate_thumbnail(material:Material, mesh_type:MaterialPreviewScene.MeshType, size:Vector2i, callback:Callable):
	var request:Request = Request.new()
	request.material = material
	request.mesh_type = mesh_type
	request.size = size
	request.callback = callback
	
	queue.append(request)
	pass
