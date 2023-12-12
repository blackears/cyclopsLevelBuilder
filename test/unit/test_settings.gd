extends GutTest

var export_file_name:String = "settings_test.json"

func test_write_settings():
	var settings:Settings = Settings.new()
	settings.set_property("xform", Transform3D(Basis.from_scale(Vector3(2, 3, 4)), Vector3.ONE))
	
	settings.save_to_file(export_file_name)
	
	settings.load_from_file(export_file_name)
#	var val = settings.get_property_transform3d("xform")
	pass

func after_all():
	#Clean up
	var f:FileAccess = FileAccess.open(export_file_name, FileAccess.READ)
	var abs_path = f.get_path_absolute()
	f.close()
	DirAccess.remove_absolute(abs_path)
	pass
