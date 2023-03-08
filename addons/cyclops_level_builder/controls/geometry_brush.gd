extends Node

class VertexInfo:
	var point:Vector3

class EdgeInfo:
	var start_index:int
	var end_index:int

class FaceInfo:
	var vertex_indices:Array[int]
	var edge_indices:Array[int]
	var material_index:int

class FaceCornerInfo:
	var uv:Vector2
	var vertex_index:int
	var face_index:int
	

var vertices:Array[VertexInfo]
var edges:Array[EdgeInfo]
var faces:Array[FaceInfo]
var faceCorners:Array[FaceCornerInfo]

var points:PackedVector3Array


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
