extends GutTest

var export_file_name:String = "settings_test.json"

func test_write_settings():
	var test_mtx:Transform3D = Transform3D(Basis.from_scale(Vector3(2, 3, 4)), Vector3(5, 6, 7))
	var settings:Settings = Settings.new()
	
	settings.add_setting("xform", Transform3D.IDENTITY, TYPE_TRANSFORM3D)
	settings.set_property("xform", test_mtx)
	
	settings.save_to_file(export_file_name)
	
	settings.load_from_file(export_file_name)
	var val = settings.get_property("xform")
	
	#print(val)
	assert_true(val == test_mtx, "Fetched setting incorrect")
	pass

func after_all():
	#Clean up
	var f:FileAccess = FileAccess.open(export_file_name, FileAccess.READ)
	var abs_path = f.get_path_absolute()
	f.close()
	DirAccess.remove_absolute(abs_path)
	pass
