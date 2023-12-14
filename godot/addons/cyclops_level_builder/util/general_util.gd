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
class_name GeneralUtil

static func find_unique_name(parent:Node, base_name:String)->String:
	#Check if numeric suffix already exists
	var regex = RegEx.new()
	regex.compile("(\\d+)")
	var match_res:RegExMatch = regex.search(base_name)
	
	var name_idx:int = 0
	
	if match_res:
		var suffix:String = match_res.get_string(1)
		name_idx = int(suffix) + 1
		base_name = base_name.substr(0, base_name.length() - suffix.length())

	#Search for free index	
	while true:
		var name = base_name + str(name_idx)
		if !parent.find_child(name, false):
			return name
			
		name_idx += 1
		
	return ""

static func format_planes_string(planes:Array[Plane])->String:
	var result:String = ""
	for p in planes:
		result = result + "(%s, %s, %s, %s)," % [p.x, p.y, p.z, p.d]
	return result
	

static func dump_properties(obj):
	for prop in obj.get_property_list():
		var name:String =  prop["name"]
		print ("%s:   %s" % [name, str(obj.get(name))])
