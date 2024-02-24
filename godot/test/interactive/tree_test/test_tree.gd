extends Control

func _input(event):
	if event is InputEventMouseButton:
		var e:InputEventMouseButton = event
		
		if e.button_index == MOUSE_BUTTON_RIGHT:
			if !e.is_pressed():
				
				%PopupMenu.popup(Rect2i(e.position.x, e.position.y, 0, 0))

			get_viewport().set_input_as_handled()
		

# Called when the node enters the scene tree for the first time.
func _ready():
	var root:TreeItem = %Tree.create_item()
	var child1:TreeItem = %Tree.create_item(root)
	var child2:TreeItem = %Tree.create_item(root)
	var subchild1:TreeItem = %Tree.create_item(child1)
	subchild1.set_text(0, "Subchild1")
	
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_tree_custom_item_clicked(mouse_button_index:int):
	print("bn ", mouse_button_index)
	pass # Replace with function body.


func _on_tree_item_selected():
	print("_on_tree_item_selected")
