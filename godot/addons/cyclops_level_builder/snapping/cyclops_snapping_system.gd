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

extends Resource
class_name CyclopsSnappingSystem

var move_constraint:MoveConstraint.Type = MoveConstraint.Type.NONE

var plugin:CyclopsLevelBuilder

func _activate(plugin:CyclopsLevelBuilder):
	self.plugin = plugin
	
func _deactivate():
	pass

func _snap_point(point:Vector3, query:SnappingQuery)->Vector3:
	return point

func _snap_angle(angle:float, query:SnappingQuery)->float:
	return angle

func _get_properties_editor()->Control:
	return null
	
func constrain_point(point:Vector3, target_point:Vector3, move_constraint:MoveConstraint.Type = MoveConstraint.Type.NONE)->Vector3:
	match move_constraint:
		MoveConstraint.Type.NONE:
			return target_point
		MoveConstraint.Type.AXIS_X:
			return Vector3(target_point.x, point.y, point.z)
		MoveConstraint.Type.AXIS_Y:
			return Vector3(point.x, target_point.y, point.z)
		MoveConstraint.Type.AXIS_Z:
			return Vector3(point.x, point.y, target_point.z)
		MoveConstraint.Type.PLANE_XY:
			return Vector3(target_point.x, target_point.y, point.z)
		MoveConstraint.Type.PLANE_XZ:
			return Vector3(target_point.x, point.y, target_point.z)
		MoveConstraint.Type.PLANE_YZ:
			return Vector3(point.x, target_point.y, target_point.z)
		_:
			return point


