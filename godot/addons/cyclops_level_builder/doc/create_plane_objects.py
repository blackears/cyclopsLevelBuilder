import bpy
import mathutils

def create_plane_on_plane(p0):
    # Extract the normal and distance from the Hessian form of the plane
    normal = mathutils.Vector(p0[:3])
    distance = p0[3]

    # Calculate the center of the plane
    center = normal * distance

    # Create a new plane object
    bpy.ops.mesh.primitive_plane_add()
    obj0 = bpy.context.active_object

    # Set the plane's origin to the center of the plane
    obj0.location = center

    # Calculate the rotation needed to align the z-axis with the plane normal
    z_axis = mathutils.Vector((0, 0, 1))
    angle = normal.angle(z_axis, 0)
    axis = z_axis.cross(normal)
    euler = mathutils.Matrix.Rotation(angle, 4, axis).to_euler()
    obj0.rotation_euler = euler


    return obj0


planes = [(0.274721, 9.82474e-08, -0.961524, -8.10427), (-1, -3.57626e-07, -2.38418e-07, -2), (0.904534, 0.301512, 0.301512, -1.50755), (0, 1, 0, 3), (5.08628e-06, -1, -2.75509e-06, -7.00003), (0.727606, -0.485071, -0.485072, -8.48875), (0.465341, -0.426562, -0.775566, -9.03536), (-0.369799, -0.0924517, 0.924501, 1.75654), (3.19872e-07, -0.447214, 0.894427, -0.447216), (-0.957704, -0.239427, 0.159618, -2.15484)]
for p in planes:
    create_plane_on_plane(p)

#create_plane_on_plane((0.274721, 9.82474e-08, -0.961524, -8.10427))
