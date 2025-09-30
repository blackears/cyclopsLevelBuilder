extends Control

func _ready() -> void:
	%PopupPanel.show()
	
	%Popup.show()


func _on_gui_input(event: InputEvent) -> void:
	print(event)
	
#	if event.is_action_pressed("ui_accept"):
	if event is InputEventMouseButton:
		%PopupPanel.show()
		
		%Popup.show()
		
	pass # Replace with function body.
