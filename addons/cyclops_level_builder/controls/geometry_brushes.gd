@tool
extends Node3D
class_name GeometryBrushes

@export var grid_size:int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	pass

func _input(event):
	if Engine.is_editor_hint():
		pass
		
	#print(event.as_text())
	pass

func intersect_ray(origin:Vector3, dir:Vector3):
	return null
