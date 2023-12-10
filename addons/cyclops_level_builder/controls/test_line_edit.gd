@tool
extends Control
class_name TestLineEdit


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#$Label.text = "Bar"
	var lab:Label = get_node("Label")
	print(lab.text)
	pass
