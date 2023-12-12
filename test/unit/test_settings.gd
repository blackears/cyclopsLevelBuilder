extends GutTest

var export_file_name:String = "settings_test.json"

func test_write_settings():
	var settings:Settings = Settings.new()
	settings.set_property("xform", Transform3D.IDENTITY)
	
	settings.save_to_file(export_file_name)
	pass

func after_all():
	#Clean up
	var f:FileAccess = FileAccess.open(export_file_name, FileAccess.READ)
	var abs_path = f.get_path_absolute()
	f.close()
	DirAccess.remove_absolute(abs_path)
	pass
