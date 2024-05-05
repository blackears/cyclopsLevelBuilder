@tool
extends Resource
class_name CyclopsRecord

@export var id:int
@export var category:String
@export var name:String

func to_xml()->XMLElement:
	return null
