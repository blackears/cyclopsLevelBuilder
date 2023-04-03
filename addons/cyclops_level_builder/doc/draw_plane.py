import bpy
import mathutils

def draw_plane(hessian):
    # Extract the plane coefficients from the Hessian form
    a, b, c, d = hessian

    # Calculate the normal vector of the plane
    normal = mathutils.Vector((a, b, c)).normalized()

    # Calculate the point at the center of the plane
    point = normal * d

    # Create a new mesh object for the point and line
    mesh = bpy.data.meshes.new(name="Plane Center and Normal")
    obj = bpy.data.objects.new(name="Plane Object", object_data=mesh)

    # Create the vertices for the point and line
    vertices = [
        point,
        point + normal
    ]

    # Create the edges for the line
    edges = [
        (0, 1)
    ]

    # Create the mesh data for the point and line
    mesh.from_pydata(vertices, edges, [])

    # Add the object to the scene
    bpy.context.scene.collection.objects.link(obj)

draw_plane((0, 1, 0, 11))