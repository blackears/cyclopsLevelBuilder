extends GutTest

func test_gram_schmidt_decomposition():
#	var basis:Basis = Basis(Vector3(1, 2, 3), Vector3(1, 3, 4), Vector3(-1, 2, 5))
	var basis:Basis = Basis(Vector3(1, 0, 0), Vector3(0, 0, 5), Vector3(0, 2, 0))
	var result:Array[Basis] = MathUtil.gram_schmidt_decomposition(basis)
	
	var dot_xy = result[0].x.dot(result[0].y)
	var dot_xz = result[0].x.dot(result[0].z)
	var dot_yz = result[0].y.dot(result[0].z)

	assert_true(is_zero_approx(dot_xy), "Dot product should be 0: %f" % dot_xy)
	assert_true(is_zero_approx(dot_xz), "Dot product should be 0: %f" % dot_xz)
	assert_true(is_zero_approx(dot_yz), "Dot product should be 0: %f" % dot_yz)
	
	#Should be identity
	var prod = result[0] * result[2]
	
	#Should be equal to basis
	var mult = result[0] * result[1]
	
	print(result[0])
	print(result[1])
	print(result[2])
	#print(prod)
	#print(mult)
	
	assert_true(true, "Success")

func test_matrix_decompose_3d():
	var basis:Basis = Basis(Vector3(1, 2, 3), Vector3(1, 3, 4), Vector3(-1, 2, 5))
	var xform:Transform3D = Transform3D(basis, Vector3(4, 5, 6))
	
	var decom:Dictionary = MathUtil.decompose_matrix_3d(xform)
	#print(decom.translate)
	#print(decom.rotate)
	#print(decom.shear)
	#print(decom.scale)
	
	var m:Transform3D = MathUtil.compose_matrix_3d(decom.translate, decom.rotate, EULER_ORDER_YXZ, decom.shear, decom.scale)

	for j in 3:
		assert_true(is_equal_approx(basis[j].x, m.basis[j].x), "Basis entry mismatch [%d x]" % j)
		assert_true(is_equal_approx(basis[j].y, m.basis[j].y), "Basis entry mismatch [%d y]" % j)
		assert_true(is_equal_approx(basis[j].z, m.basis[j].z), "Basis entry mismatch [%d z]" % j)
#	print(m)
	pass
