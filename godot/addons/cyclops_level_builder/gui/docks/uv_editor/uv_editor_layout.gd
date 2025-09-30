@tool
extends PanelContainer

@export var uv_editor:UvEditor:
	set(v):
		if uv_editor == v:
			return
		uv_editor = v

		if is_node_ready():
			update_editor_link()

@onready var vec_ed_subdiv = %vectorEdit_subdiv
@onready var vec_ed_subdiv_offset = %vectorEdit_offset

func update_editor_link():
	if !is_node_ready() || !uv_editor:
		return
		
	vec_ed_subdiv.set_value_no_signal(uv_editor.subdivisions)
	uv_editor.subdivisions_changed.connect(on_subdivisions_changed)
		
	vec_ed_subdiv_offset.set_value_no_signal(uv_editor.subdivisions_offset)
	uv_editor.subdivisions_offset_changed.connect(on_subdivisions_offset_changed)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_editor_link()
#	update_editor_link()
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func on_subdivisions_changed(v:Vector2):
	print("on_subdivisions_changed ", v)
	vec_ed_subdiv.set_value_no_signal(v)

func on_subdivisions_offset_changed(v:Vector2):
	print("on_subdivisions_offset_changed ", v)
	vec_ed_subdiv_offset.set_value_no_signal(v)

func _on_vector_edit_subdiv_value_changed(value: Vector2) -> void:
	print("_on_vector_edit_subdiv_value_changed ", value)
	uv_editor.subdivisions = value
	pass # Replace with function body.


func _on_vector_edit_offset_value_changed(value: Vector2) -> void:
	print("_on_vector_edit_offset_value_changed ", value)
	uv_editor.subdivisions_offset = value
	pass # Replace with function body.
