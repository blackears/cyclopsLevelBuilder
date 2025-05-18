@tool
extends Node
class_name UvEditorSnapping

signal use_snap_changed(use_snap:bool)
signal snap_tool_changed(path:NodePath)

@export var use_snap:bool = false:
	set(v):
		if v == use_snap:
			return
		use_snap = v
		use_snap_changed.emit(use_snap)

@export var cur_snap_tool_path:NodePath:
	set(v):
		if v == cur_snap_tool_path:
			return
		cur_snap_tool_path = v
		snap_tool_changed.emit(cur_snap_tool_path)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
