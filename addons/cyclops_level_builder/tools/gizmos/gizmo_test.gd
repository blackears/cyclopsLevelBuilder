extends Node3D

func _input(event):
	if event is InputEventMouseButton:
		var e:InputEventMouseButton = event
		
		if e.is_pressed():
	
			var cam:Camera3D = %Camera3D
			var ray_norm:Vector3 = cam.project_ray_normal(e.position)
			var ray_orig:Vector3 = cam.project_ray_origin(e.position)
			%gizmo_translate.intersect(ray_orig, ray_norm, cam)
	
	pass

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
