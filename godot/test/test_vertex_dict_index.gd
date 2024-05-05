extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	var a:PackedFloat32Array = [1, 2, 3]
	var b:PackedFloat32Array = [1, 2, 3]
	var c:PackedFloat32Array = [1, 2, 6]
	
	var dict:Dictionary
	dict[a] = "A"
	dict[b] = "B"
	dict[c] = "C"
	
	print("has A ", dict.has(a))
	print(dict)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
