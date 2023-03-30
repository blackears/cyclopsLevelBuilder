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

@tool
#extends RefCounted
class_name  MathGeometry
	

static func unit_sphere(segs_lat:int = 6, segs_long:int = 8)->GeometryMesh:
	var mesh:GeometryMesh = GeometryMesh.new()

	for la in range(segs_lat):
		
		var z0:float = cos(deg_to_rad(180 * la / segs_lat))
		var z1:float = cos(deg_to_rad(180 * (la + 1) / segs_lat))
		var r0:float = sin(deg_to_rad(180 * la / segs_lat))
		var r1:float = sin(deg_to_rad(180 * (la + 1) / segs_lat))
		
		for lo in range(segs_long):
			var cx0:float = sin(deg_to_rad(360 * lo / segs_long))
			var cx1:float = sin(deg_to_rad(360 * (lo + 1) / segs_long))
			var cy0:float = cos(deg_to_rad(360 * lo / segs_long))
			var cy1:float = cos(deg_to_rad(360 * (lo + 1) / segs_long))
			
			var v00:Vector3 = Vector3(cx0 * r0, cy0 * r0, z0)
			var v10:Vector3 = Vector3(cx1 * r0, cy1 * r0, z0)
			var v01:Vector3 = Vector3(cx0 * r1, cy0 * r1, z1)
			var v11:Vector3 = Vector3(cx1 * r1, cy1 * r1, z1)
			
			if la != 0:
				mesh.coords.append(v00)
				mesh.coords.append(v11)
				mesh.coords.append(v10)
			
				mesh.normals.append(v00)
				mesh.normals.append(v10)
				mesh.normals.append(v11)
			
				mesh.uvs.append(Vector2(lo / segs_long, la / segs_lat))
				mesh.uvs.append(Vector2((lo + 1) / segs_long, la / segs_lat))
				mesh.uvs.append(Vector2((lo + 1) / segs_long, (la + 1) / segs_lat))
			
			if la != segs_lat - 1:
				mesh.coords.append(v00)
				mesh.coords.append(v01)
				mesh.coords.append(v11)
			
				mesh.normals.append(v00)
				mesh.normals.append(v11)
				mesh.normals.append(v01)
				
				mesh.uvs.append(Vector2(lo / segs_long, la / segs_lat))
				mesh.uvs.append(Vector2((lo + 1) / segs_long, (la + 1) / segs_lat))
				mesh.uvs.append(Vector2(lo / segs_long, (la + 1) / segs_lat))

	return mesh

