@tool
extends PanelContainer
class_name TreeTextComponent

@export var text:String
@export var edit_mode:bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	%Label.text = text
	%Label.visible = !edit_mode
	%LineEdit.visible = edit_mode
	pass
