@tool
extends PanelContainer
class_name CyclopsTree

@export var node_display_component:PackedScene

var model:AbstractCyclopsTreeModel:
	get:
		return model
	set(value):
		if model == value:
			return
		
		if model:
			model.tree_nodes_inserted.disconnect(on_tree_nodes_inserted)
			model.tree_nodes_removed.disconnect(on_tree_nodes_removed)
			model.refresh_node.disconnect(on_refresh_node)
			model.tree_node_changed.disconnect(on_tree_node_changed)
			model.tree_structure_changed.disconnect(on_tree_structure_changed)
		
		model = value
		
		if model:
			model.tree_nodes_inserted.connect(on_tree_nodes_inserted)
			model.tree_nodes_removed.connect(on_tree_nodes_removed)
			model.refresh_node.connect(on_refresh_node)
			model.tree_node_changed.connect(on_tree_node_changed)
			model.tree_structure_changed.connect(on_tree_structure_changed)
		
		rebuild_tree()

func on_tree_nodes_inserted(parent_node:Object, child_nodes:Array[Object], child_node_indices:PackedInt32Array):
	pass

func on_tree_nodes_removed(parent_node:Object, child_nodes:Array[Object], child_node_indices:PackedInt32Array):
	pass

func on_refresh_node(old_node:Object, new_node:Object):
	pass

func on_tree_node_changed(node:Object):
	pass

func on_tree_structure_changed():
	rebuild_tree()

func rebuild_tree():
	for child in get_children():
		remove_child(child)
		child.queue_free()
	
	if !model:
		return
		
	model.get_root()
	pass

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
