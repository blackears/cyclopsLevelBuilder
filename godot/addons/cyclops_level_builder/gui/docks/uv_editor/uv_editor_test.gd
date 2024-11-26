extends Node2D

@export var blocks:Array[CyclopsBlock]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%UvEditor.block_nodes = blocks
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
