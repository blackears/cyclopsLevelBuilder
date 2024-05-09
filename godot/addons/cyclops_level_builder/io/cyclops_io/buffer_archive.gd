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
extends ResourceInspector
class_name BufferArchive

class BufferRegion extends Resource:
	var builder:BufferArchive
	#var index:int
	var start_byte:int
	var length:int
	
	func get_buffer()->PackedByteArray:
		return builder.buffer.slice(start_byte, start_byte + length)

var buffer:PackedByteArray
#var region_list:Array[BufferRegion]

func store_buffer(buf:PackedByteArray)->BufferRegion:
	var region:BufferRegion = BufferRegion.new()

	region.builder = self
	#region.index = region_list.size()	
	region.start_byte = buffer.size()
	region.length = buf.size()
	
	buffer.append_array(buf)
#	buffer.resize(buffer.size() + byte_len)
	
	#region_list.append(region)
	
	return region
	

#func allocate_buffer(byte_len:int)->BufferRegion:
	#var region:BufferRegion = BufferRegion.new()
#
	#region.builder = self
	#region.index = region_list.size()	
	#region.start_byte = buffer.size()
	#region.length = byte_len
	#buffer.resize(buffer.size() + byte_len)
	#
	#region_list.append(region)
	#
	#return region

func to_dictionary()->Dictionary:
	var result:Dictionary
	
	#result["regions"] = []
	#for region in region_list:
		#result.region.append({
			##"index": region.index,
			#"start": region.start_byte,
			#"length": region.length
		#})
	
	result["buffer"] = Marshalls.raw_to_base64(buffer.compress())
	
	return result
