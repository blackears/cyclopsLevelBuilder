import bpy
import bmesh

# Define the list of points for the polygon
points = [(0,0,0), (1,0,0), (1,1,0), (0,1,0)]

# Create a new mesh and add a new object to the scene
mesh = bpy.data.meshes.new("Polygon")
obj = bpy.data.objects.new("Polygon", mesh)
bpy.context.collection.objects.link(obj)

# Create a new bmesh and add vertices to it
bm = bmesh.new()
for point in points:
    bm.verts.new(point)

# Add the vertices to the mesh
bm.to_mesh(mesh)
bm.free()