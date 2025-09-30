@tool
extends Node
class_name ToolUvBoxHandle

enum Style { SQUARE, AREA }

@export var uv_position:Vector2
@export var style:Style
@export var viewport_handle:Node2D
