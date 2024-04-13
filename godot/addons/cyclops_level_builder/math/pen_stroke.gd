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
class_name PenStroke
extends Resource

class StrokePoint extends Resource:
	@export var position:Vector3
	@export var pressure:float

	#func _init(position:Vector3 = Vector3.ZERO, pressure:float = 1):
		#print("ppp ", position)
		#self.position = position
		#self.pressure = pressure
		
	func _to_string()->String:
		return "%s %f" % [str(position), pressure]

	func lerp(p:StrokePoint, weight:float):
		var r:StrokePoint = StrokePoint.new()
		r.position = lerp(position, p.position, weight)
		r.pressure = lerp(pressure, p.pressure, weight)
		return r

var stroke_points:Array[StrokePoint]

func clear():
	stroke_points.clear()

func is_empty()->bool:
	return stroke_points.is_empty()

func append_stroke_point(position:Vector3, pressure:float = 1):
	var p:StrokePoint = StrokePoint.new()
	p.position = position
	p.pressure = pressure
	stroke_points.append(p)

func resample_points(resample_dist:float)->PenStroke:
	if stroke_points.is_empty():
		return null
	
	var result:PenStroke = PenStroke.new()
	
	#var p_start:StrokePoint = stroke_points[0]
	#var p_start1:StrokePoint = p_start.duplicate(true)
	#print("p_start ", p_start)
	#print("p_start1 ", p_start1)
	#print("stroke_points[0] ", stroke_points[0].position)
	result.stroke_points.append(stroke_points[0].duplicate())
	#print("--stroke_points[0] ", stroke_points[0].position)
	
	var seg_dist_covered:float = 0
	var last_pos_plotted:float = 0
	
	for src_p_idx in stroke_points.size() - 1:
		var p0:StrokePoint = stroke_points[src_p_idx]
		var p1:StrokePoint = stroke_points[src_p_idx + 1]
		var seg_len:float = p0.position.distance_to(p1.position)
		
		while last_pos_plotted + resample_dist <= seg_dist_covered + seg_len:
			var pn:StrokePoint = p0.lerp(p1, \
				(last_pos_plotted + resample_dist - seg_dist_covered) / seg_len)
			result.stroke_points.append(pn)
			last_pos_plotted += resample_dist
			
		seg_dist_covered += seg_len
	
	#print("stroke points res ", str(result.stroke_points))
	
	return result


