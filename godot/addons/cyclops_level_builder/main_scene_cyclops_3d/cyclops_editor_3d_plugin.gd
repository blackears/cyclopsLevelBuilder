@tool
extends EditorPlugin

var main_window_cyclops_3d:MainWindowCyclops3D


func _enable_plugin() -> void:
	pass


func _disable_plugin() -> void:
	pass


func _enter_tree() -> void:
	main_window_cyclops_3d = preload("res://addons/cyclops_level_builder/main_scene_cyclops_3d/main_window_cyclops_3d.tscn").instantiate()
	EditorInterface.get_editor_main_screen().add_child(main_window_cyclops_3d)
	_make_visible(false)


func _exit_tree() -> void:
	if main_window_cyclops_3d:
		main_window_cyclops_3d.queue_free()


func _has_main_screen() -> bool:
	return true

func _make_visible(visible: bool) -> void:
	if main_window_cyclops_3d:
		main_window_cyclops_3d.visible = true

func _get_plugin_name() -> String:
	return "Cyclops 3D"

func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon("Node", "EditorIcons")
