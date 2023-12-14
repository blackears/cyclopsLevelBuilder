import bpy

# Define the coordinates of the line segments
line_segments = [
    [(0, 0, 0), (1, 1, 1)],
    [(1, 1, 1), (2, -1, 0)],
    [(2, -1, 0), (0, 0, 0)]
]

# Clear existing objects
bpy.ops.object.select_all(action='DESELECT')
bpy.ops.object.select_by_type(type='MESH')
bpy.ops.object.delete()

# Create a new mesh object
mesh = bpy.data.meshes.new(name='LineSegments')
obj = bpy.data.objects.new('LineSegments', mesh)

# Link the object to the scene
scene = bpy.context.scene
scene.collection.objects.link(obj)

# Create the vertices and edges for the line segments
vertices = []
edges = []

for segment in line_segments:
    v1, v2 = segment
    idx1 = len(vertices)
    idx2 = idx1 + 1
    vertices.extend([v1, v2])
    edges.append((idx1, idx2))

# Create the mesh data
mesh.from_pydata(vertices, edges, [])

# Update the mesh
mesh.update()

# Set the object mode to 'EDIT' to see the lines
bpy.context.view_layer.objects.active = obj
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.mesh.mark_sharp(clear=True)
bpy.ops.object.mode_set(mode='OBJECT')

# Set the object mode to 'EDIT' again to apply smooth shading
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.mesh.normals_make_consistent(inside=False)

# Set the object mode to 'OBJECT'
bpy.ops.object.mode_set(mode='OBJECT')
