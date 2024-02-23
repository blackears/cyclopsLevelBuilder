@tool
extends RefCounted
class_name MaterialGroup
	
var name:String
var children:Array[MaterialGroup]

func _init(name:String = ""):
	self.name = name
	
