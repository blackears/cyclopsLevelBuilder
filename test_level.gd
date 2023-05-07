# MIT License
#
# Copyright (c) 2023 Mark McKay
# https://github.com/blackears/cyclopsLevelBuilder
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

extends Node3D

func add_point(arr:PackedVector3Array):
	arr.append(Vector3(4, 5, 6))
	
func test_planes():
	var p0:Plane = Plane(1, 0, 0, 6)
	var p1:Plane = Plane(1, 0, 0, 6)

	var planes:Array[Plane] = []
	planes.append(p0)
	
	print("has %s" % [planes.has(p1)])
	
	print("has2 %s" % planes.any(func(p): return p.is_equal_approx(p1)))

func test_volume():
	
	#var face_planes:Array[Plane] = Array([Plane(0, 1, 0, 11), Plane(0, 0, -1, -16), Plane(-0.957704, 0.239425, 0.159618, -2.47408), Plane(0.948683, 0, -0.316228, -1.26491), Plane(-0.948683, -4.52367e-07, -0.316228, -12.6491), Plane(1.18011e-06, -0.707107, -0.707107, -21.2132), Plane(0.588349, -0.196116, 0.784464, 9.80581), Plane(0.303045, -0.505077, 0.808122, 4.64669), Plane(0.948683, -0.316228, 0, -0.632454), Plane(0.514496, -0.857493, 0, -9.94692)])
#	var face_uv_transform:Array[Transform2D] = Array([Transform2D(1, 0, 0, 1, 0, 0), Transform2D(1, 0, 0, 1, 0, 0), Transform2D(1, 0, 0, 1, 0, 0), Transform2D(1, 0, 0, 1, 0, 0), Transform2D(1, 0, 0, 1, 0, 0), Transform2D(1, 0, 0, 1, 0, 0), Transform2D(1, 0, 0, 1, 0, 0), Transform2D(1, 0, 0, 1, 0, 0), Transform2D(1, 0, 0, 1, 0, 0), Transform2D(1, 0, 0, 1, 0, 0)])
	#var face_material_indices = PackedInt32Array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
	#var face_ids = PackedInt32Array([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])

	var points:PackedVector3Array = [Vector3(3, -1.999998, -4), Vector3(4.000005, -3.000003, 1.999994), Vector3(-1.999997, -5.000001, -1), Vector3(-0.999991, 0.999997, -5.999997), Vector3(-5, 4, -2), Vector3(-2.999999, -2, 1), Vector3(5, 1, -3)]
	var vol = ConvexVolume.new()
	vol.init_from_points(points)
	
	for f in vol.faces:
		print("vol plane %s" % f.plane)

	pass

func test_volume2():
	var points:PackedVector3Array = [Vector3(1.999997, 3, 8.999995), Vector3(1.999995, 7.000015, 8.999995), Vector3(-5, 3, 6.999998), Vector3(1.999998, 3, 2.999989), Vector3(-2.999995, 3, 0.999999), Vector3(-5.000003, 6.999996, 3.000013), Vector3(-2.999998, 6.999998, 6.000011), Vector3(0.999997, 7.000027, 3.000014)]

	var vol = ConvexVolume.new()
	vol.init_block(AABB(Vector3(0, 0, 0), Vector3(1, 1, 1)))

	vol.init_from_points(points)
	
	for f in vol.faces:
		print("vol plane %s" % f.plane)
	pass

func isect_test():
	var result:IntersectResults = $CyclopsBlocks.intersect_ray_closest($Marker3D.transform.origin, $Marker3D.transform.basis.z)
	#var result:IntersectResults = $CyclopsBlocks.intersect_ray_closest(Vector3(-2.827666, 11.78138, -14.39898), Vector3(0.703937, -0.382888, 0.598221))
	pass

func test_move_face():
	var vol:ConvexVolume = ConvexVolume.new()
	vol.init_block(AABB(Vector3(0, 0, 0), Vector3(5, 5, 5)))
	
	var new_vol:ConvexVolume = vol.translate_face_plane(0, Vector3(5, 0, 0))
	pass

func test_cut_plane():
	var vol:ConvexVolume = ConvexVolume.new()
	vol.init_block(AABB(Vector3(0, 0, 0), Vector3(5, 5, 5)))

	var plane = Plane(Vector3(-1, 0, 0), Vector3(3, 3, 3))
	var new_vol:ConvexVolume = vol.cut_with_plane(plane)
	pass

# Called when the node enters the scene tree for the first time.
func _ready():
	
	await get_tree().process_frame

	#test_planes()
	#test_volume2()
	isect_test()
	#test_cut_plane()


#	var points:PackedVector3Array
#	points.append(Vector3(0, 0, 0))	
#	points.append(Vector3(0, 0, 1))	
#	points.append(Vector3(0, 1, 0))	
#	points.append(Vector3(0, 1, 1))	
#	points.append(Vector3(1, 0, 0))	
#	points.append(Vector3(1, 0, 1))	
#	points.append(Vector3(1, 1, 0))	
#	points.append(Vector3(1, 1, 1))	
#	points.append(Vector3(2, 1, 1))	
#	points.append(Vector3(2, 2, 3))	
#
#	var qh:QuickHull = QuickHull.new()
#	var hull:QuickHull.Hull = qh.quickhull(points)
##	print(hull)
#	print(hull.format_points())
	
	pass

	
	#var result:IntersectResults = $CyclopsBlocks.intersect_ray_closest($Marker3D.transform.origin, $Marker3D.transform.basis.z)
	#var result:IntersectResults = $CyclopsBlocks.intersect_ray_closest(Vector3(-2.827666, 11.78138, -14.39898), Vector3(0.703937, -0.382888, 0.598221))
	
	#print(result)
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
