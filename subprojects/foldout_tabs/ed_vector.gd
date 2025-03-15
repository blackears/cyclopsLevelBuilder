extends Control


func _ready() -> void:
	var ss = EditorSpinSlider.new()
	$VBoxContainer.add_child(ss)
	
	$VBoxContainer.add_child(CheckButton.new())
