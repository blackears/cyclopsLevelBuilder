@tool
class_name AbstractCyclopsTreeModel

signal tree_nodes_inserted(parent_node:Object, child_nodes:Array[Object], child_node_indices:PackedInt32Array)
signal tree_nodes_removed(parent_node:Object, child_nodes:Array[Object], child_node_indices:PackedInt32Array)

#Display data of  node has changed, but no the child structore
signal value_for_node_changed(old_node:Object, new_node:Object)

#Rebuild this ode and all children
signal tree_node_changed(node:Object)

#Entire tree needs to be rebuilt
signal tree_structure_changed()

class CyclopsTreePath:
	var path:Array[Object]

func get_child(parent:Object, index:int)->Object:
	return null

func get_child_count(parent:Object)->int:
	return 0

func get_index_of_child(parent:Object, child:Object)->int:
	return -1
	
func get_root()->Object:
	return null
	
func is_leaf(node:Object)->bool:
	return true
