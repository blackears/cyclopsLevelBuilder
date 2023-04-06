@tool
extends ScrollContainer


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _can_drop_data(at_position:Vector2, data:Variant):
	print("ScrollContainer _can_drop_data %s" % data)
	return typeof(data) == TYPE_DICTIONARY and data.has("type") and data["type"] == "files"

