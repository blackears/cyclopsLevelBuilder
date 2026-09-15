@tool
extends Node
class_name MaterialThumbnailGenerator

@onready var subviewport:SubViewport = %SubViewport
@onready var material_preview_scene:MaterialPreviewScene = %material_preview_scene

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
		
		mutex.lock()

		cur_request = queue.pop_back()
		subviewport.size = cur_request.size
		subviewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		
		material_preview_scene.mesh_type = cur_request.mesh_type
		material_preview_scene.display_material = cur_request.material
		
		mutex.unlock()
		
		#Wait for image to be ready
		#await ???
		#await RenderingServer.frame_post_draw
		await get_tree().process_frame
		
		mutex.lock()
		var img:Image = subviewport.get_texture().get_image()
		var result:ImageTexture = ImageTexture.create_from_image(img)
		cur_request.callback.call(result)
		cur_request = null
		mutex.unlock()
	
