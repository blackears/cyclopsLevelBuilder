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
class_name SerialUtil

static func save_cache_vector3(value:Vector3)->Dictionary:
	return {
		"value": [value.x, value.y, value.z]
	}
	
static func load_cache_vector3(cache:Dictionary, default_value:Vector3 = Vector3.ZERO)->Vector3:
	if !cache:
		return default_value
	
	return Vector3(cache.value[0], cache.value[1], cache.value[2])

static func save_cache_color(value:Color)->Dictionary:
	return {
		"color": [value.r, value.g, value.b, value.a]
	}
	
static func load_cache_color(cache:Dictionary, default_value:Color = Color.BLACK)->Color:
	if !cache:
		return default_value
	
	return Color(cache.color[0], cache.color[1], cache.color[2], cache.color[3])

static func save_cache_transform_3d(t:Transform3D)->String:
	var dict:Dictionary = {
		"x": [t.basis.x.x, t.basis.x.y, t.basis.x.z],
		"y": [t.basis.y.x, t.basis.y.y, t.basis.y.z],
		"z": [t.basis.z.x, t.basis.z.y, t.basis.z.z],
		"o": [t.origin.x, t.origin.y, t.origin.z],
	}
	return JSON.stringify(dict)
	
static func load_cache_transform_3d(text:String, default_value:Transform3D = Transform3D.IDENTITY)->Transform3D:
	if text.is_empty():
		return default_value
	
	var cache:Dictionary = JSON.parse_string(text)
	var x:Vector3 = Vector3(cache.x[0], cache.x[1], cache.x[2])
	var y:Vector3 = Vector3(cache.y[0], cache.y[1], cache.y[2])
	var z:Vector3 = Vector3(cache.z[0], cache.z[1], cache.z[2])
	var o:Vector3 = Vector3(cache.o[0], cache.o[1], cache.o[2])
	
	return Transform3D(x, y, z, o)

