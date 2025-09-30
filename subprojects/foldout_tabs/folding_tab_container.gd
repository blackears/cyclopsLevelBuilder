@tool
extends Container
class_name FoldingTabContainer

@export var vertical:bool = true:
	set(v):
		vertical = v
		
		if is_node_ready():
			build_layout()

var label_area:VBoxContainer

func build_layout():
	if label_area:
		label_area.queue_free()
	
	label_area = VBoxContainer.new()
	
	for child in get_children():
		var label:Label = Label.new()
		label.text = child.name
		label_area.add_child(label)
	
	add_child(label_area)


func _ready() -> void:
	#label_area = VBoxContainer.new()
	pass
	
func _notification(what):
	if what == NOTIFICATION_SORT_CHILDREN:
		# Must re-sort the children
		for c in get_children():
			if c == label_area:
				label_area.get
			# Fit to own size
			#fit_child_in_rect(c, Rect2(Vector2(), rect_size))
			pass


func _on_child_entered_tree(node: Node) -> void:
	pass # Replace with function body.


func _on_child_exiting_tree(node: Node) -> void:
	pass # Replace with function body.


func _on_child_order_changed() -> void:
	pass # Replace with function body.
