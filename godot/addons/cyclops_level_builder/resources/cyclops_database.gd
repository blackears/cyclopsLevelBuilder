@tool
extends Resource
class_name CyclopsDatabase

@export var record_list:Array[CyclopsRecord]

var available_ids:Array[int]
var next_available_id:int = 0

func get_record_index(id:int)->int:
	for r_idx in record_list.size():
		if record_list[r_idx].id == id:
			return r_idx
	return -1

func allocate_id()->int:
	if available_ids.is_empty():
		var id:int = available_ids.pop_back()
		return id
	else:	
		var id:int = next_available_id
		next_available_id += 1
		return id

func create_record(category:String)->CyclopsRecord:
	match category:
		"mesh":
			var rec:CyclopsMeshRecord = CyclopsMeshRecord.new()
			rec.id = allocate_id()
			record_list.append(rec.id)
			return rec
		_:	
			return null

func free_record(id:int):
	var idx:int = get_record_index(id)
	if idx != -1:
		record_list.remove_at(idx)
		available_ids.append(id)

#Contains tree of objects in scene
func get_scene_list():
	pass
	
func get_node_list():
	pass

func get_mesh_list():
	pass
	

