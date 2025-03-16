@tool
extends ScrollContainer
class_name VerticalTabBar

class ItemInfo extends Resource:
	var label:String
	var id:int

@export var items:Array[ItemInfo]:
	set(v):
		items = v
		
		if is_node_ready():
			update_layout()
	

var bn_group:ButtonGroup

func get_button_width()->float:
	return %VBoxContainer.get_minimum_size().x

func clear():
	items.clear()
	update_layout()

func add_item(label:String, id:int = -1):
	var info:ItemInfo = ItemInfo.new()
	info.label = label
	
	if id == -1:
		id = items.size()
	
	info.id = id
	
	items.append(info)
	
	update_layout()
	pass

func update_layout():
	for child in %VBoxContainer.get_children():
		child.queue_free()
	
	for item in items:
		var bn:Button = Button.new()
		bn.button_group = bn_group
		bn.text = item.label
		bn.pressed.connect(func():_on_button_pressed(item.id))
		
		var cont:RotationContainer = preload("res://new folder/rotate_container.tscn").instantiate()
		cont.add_child(bn)
		
		%VBoxContainer.add_child(cont)
	pass

func _on_button_pressed(id:int):
	print("button pressed ", id)
	

func _ready() -> void:
	bn_group = ButtonGroup.new()
