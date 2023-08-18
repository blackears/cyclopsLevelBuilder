@tool
extends Node3D
class_name GizmoTranslate

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func proj_mul_point(m:Projection, p:Vector3)->Vector3:
	var p4:Vector4 = Vector4(p.x, p.y, p.z, 1)
	var p4_t = m * p4
	p4_t /= p4_t.w
	return Vector3(p4_t.x, p4_t.y, p4_t.z)

func proj_mul_vec(m:Projection, p:Vector3)->Vector3:
	var p4:Vector4 = Vector4(p.x, p.y, p.z, 0)
	var p4_t = m * p4
	p4_t /= p4_t.w
	return Vector3(p4_t.x, p4_t.y, p4_t.z)

func intersect(ray_origin:Vector3, ray_dir:Vector3, viewport_camera:Camera3D):
#	if intersect_part(ray_origin, ray_dir, viewport_camera, $gizmo_translate/axis_y):
	for child in $gizmo_translate.get_children():
		if intersect_part(ray_origin, ray_dir, viewport_camera, child):
			print("hit " + child.name)
			return
		
	print("miss")

#	if intersect_part(ray_origin, ray_dir, viewport_camera, $gizmo_translate/plane_xz):
#		print("hit")
#	else:
#		print("miss")
	
func intersect_part(ray_origin:Vector3, ray_dir:Vector3, viewport_camera:Camera3D, mesh_inst:MeshInstance3D)->bool:
	var proj:Projection = viewport_camera.get_camera_projection()
	
	#Calc modelview matrix
	var view_inv_matrix:Transform3D = viewport_camera.global_transform.affine_inverse()
	var mv:Projection = Projection(view_inv_matrix * mesh_inst.global_transform)
	#Static size adjustment
	if proj[3][3] != 0:
		var h:float = abs(1 / (2 * proj[1][1]))
		var sc = h * 2
		mv[0] *= sc
		mv[1] *= sc
		mv[2] *= sc
	else:
		var sc:float = -mv[3].z
		mv[0] *= sc
		mv[1] *= sc
		mv[2] *= sc
	
	var model_mtx:Projection = Projection(viewport_camera.global_transform) * mv

	var mesh:Mesh = mesh_inst.mesh
	var tris:PackedVector3Array = mesh.get_faces()
	for i in range(0, tris.size(), 3):
		var p0:Vector3 = tris[i]
		var p1:Vector3 = tris[i + 1]
		var p2:Vector3 = tris[i + 2]
		
		var p0_t:Vector3 = proj_mul_point(model_mtx, p0)
		var p1_t:Vector3 = proj_mul_point(model_mtx, p1)
		var p2_t:Vector3 = proj_mul_point(model_mtx, p2)
		
		#print("tri world %s %s %s" % [p0_t, p1_t, p2_t])
		if MathUtil.intersects_triangle(ray_origin, ray_dir, p0_t, p1_t, p2_t):
			return true
		
	return false
	
	var mvp:Projection = proj * mv
		
	##############
		
		
#
#	var mv_inv:Projection = mv.inverse()
#	var ray_origin_4:Vector4 = Vector4(ray_origin.x, ray_origin.y, ray_origin.z, 1)
#	var ray_dir_4:Vector4 = Vector4(ray_dir.x, ray_dir.y, ray_dir.z, 0)
#
#	var ray_origin_local:Vector4 = mv_inv * ray_origin_4
#	ray_origin_local /= ray_origin_local.w
#	var ray_dir_local:Vector4 = mv_inv * ray_dir_4
#
#	var mesh:Mesh = mesh_inst.mesh
#	var tris:PackedVector3Array = mesh.get_faces()
#	for i in range(0, tris.size(), 3):
#		var p0:Vector3 = tris[i]
#		var p1:Vector3 = tris[i + 1]
#		var p2:Vector3 = tris[i + 2]
#
#		if MathUtil.intersects_triangle(ray_origin, ray_dir, p0, p1, p2):
#			return true
#
#	return false
