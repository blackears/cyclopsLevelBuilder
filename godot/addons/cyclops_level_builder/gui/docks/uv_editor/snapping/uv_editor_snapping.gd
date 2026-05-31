@tool
extends Node
class_name UvEditorSnapping

signal use_snap_changed(use_snap:bool)
signal snap_tool_changed(snap_tool:Node)

@export var use_snap:bool = false:
	set(v):
		if v == use_snap:
			return
		use_snap = v
		use_snap_changed.emit(use_snap)

@export var cur_snap_tool:Node:
	set(v):
		if v == cur_snap_tool:
			return
		cur_snap_tool = v
		snap_tool_changed.emit(cur_snap_tool)

@export var rotation_increment:float = 15

@export var affects_flags:int = AFFECTS_MOVE | AFFECTS_ROTATE

const AFFECTS_MOVE:int = 1
const AFFECTS_ROTATE:int = 0b10
const AFFECTS_SCALE:int = 0b100

func snap_point(point:Vector2, exclude_uvs:Dictionary)->Vector2:
	if use_snap && cur_snap_tool:
		return cur_snap_tool.snap_point(point, exclude_uvs)
	return point

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
