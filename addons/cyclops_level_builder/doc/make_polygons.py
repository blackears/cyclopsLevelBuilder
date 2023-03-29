import bpy
import bmesh

# Define the list of faces, where each sublist represents a face
#faces = [
#    [(0,0,0), (1,0,0), (1,1,0), (0,1,0)],
#    [(1,0,0), (2,0,0), (2,1,0), (1,1,0)]
#]
faces = [
    [(-2.999999, 6, -0.999997), (-2.999999, 9.999996, -0.999997), (-2.999999, 9.999996, 2.999999), (-2.999999, 6, 2.999999)],
    [(-2.999999, 9.999996, -0.999997), (-2.999999, 6, -0.999997), (0.999997, 6, -0.999997), (0.999997, 9.999996, -0.999997)],
    [(-2.999999, 6, -0.999997), (-2.999999, 6, 2.999999), (-0.999997, 6, 5), (2.999998, 6, 1.000004), (0.999997, 6, -0.999997)],
    [(-2.999999, 9.999996, -0.999997), (0.999997, 9.999996, -0.999997), (1.999999, 9.999996, 0.000005), (-1.999997, 9.999996, 4), (-2.999999, 9.999996, 2.999999)],
    [(-0.999997, 6, 5), (-2.999999, 6, 2.999999), (-2.999999, 9.999996, 2.999999), (-1.999997, 9.999996, 4), (-0.999997, 7.999996, 5)],
    [(0.999997, 9.999996, -0.999997), (0.999997, 6, -0.999997), (2.999999, 6, 1.000004), (2.999999, 7.999996, 1.000004), (1.999998, 9.999996, 0.000004)],
    [(-1.999997, 9.999996, 4), (1.999999, 9.999996, 0.000005), (2.999998, 7.999997, 1.000004), (-0.999997, 7.999997, 5)]
    
]


# Create a new mesh and add a new object to the scene
mesh = bpy.data.meshes.new("Polygon")
obj = bpy.data.objects.new("Polygon", mesh)
bpy.context.collection.objects.link(obj)

# Create a new bmesh and add vertices and faces to it
bm = bmesh.new()
for face_verts in faces:
    # Add vertices for the face
    verts = [bm.verts.new(v) for v in face_verts]
    # Add a new face between the vertices
    bm.faces.new(verts)

# Update the mesh and free the bmesh
bm.to_mesh(mesh)
bm.free()
