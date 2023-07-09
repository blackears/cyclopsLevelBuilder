extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_bn_show_pressed():
	var wizard:ExporterGltfWizard = preload("res://addons/cyclops_level_builder/exporter/exporter_gltf_wizard.tscn").instantiate()
	#var wizard:ExporterGltfWizard = ExporterGltfWizard.new()
	
	add_child(wizard)
	wizard.popup_centered()
	
