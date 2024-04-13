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
class_name ToolVertexColorBrushSettings


@export var component_type:GeometryComponentType.Type = GeometryComponentType.Type.OBJECT

@export var mask_type:CommandVertexPaintStroke.MaskType = CommandVertexPaintStroke.MaskType.NONE:
	set(value):
		if value != mask_type:
			mask_type = value
			emit_changed()

@export var color:Color = Color.WHITE:
	set(value):
		if value != color:
			color = value
			emit_changed()

@export var radius:float:
	set(value):
		if value != radius:
			radius = value
			emit_changed()

@export var strength:float:
	set(value):
		if value != strength:
			strength = value
			emit_changed()

@export var pen_pressure_strength:bool:
	set(value):
		if value != pen_pressure_strength:
			pen_pressure_strength = value
			emit_changed()

@export var falloff_curve:Curve:
	set(value):
		if value != falloff_curve:
			falloff_curve = value
			emit_changed()

func load_from_cache(cache:Dictionary):
	component_type = cache.get("component_type", GeometryComponentType.Type.OBJECT)
	color = str_to_var(cache.get("color", var_to_str(Color.WHITE)))
	radius = cache.get("radius", 1)
	strength = cache.get("strength", 1)
	pen_pressure_strength = cache.get("pen_pressure_strength", false)
	
	if cache.has("falloff_curve"):
		falloff_curve = str_to_var(cache.get("falloff_curve"))
	else:
		falloff_curve = Curve.new()
		falloff_curve.add_point(Vector2(0, 0))
		falloff_curve.add_point(Vector2(1, 1))

func save_to_cache():
	return {
		"component_type": component_type,
		"color": var_to_str(color),
		"radius": radius,
		"strength": strength,
		"pen_pressure_strength": pen_pressure_strength,
		"falloff_curve": var_to_str(falloff_curve)
	}





