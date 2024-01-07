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

extends CharacterBody3D
class_name PlayerFirstPerson

var drag:float = 1.0
var friction:float = 4.0
var impulse:float = 5.0
var max_speed:float = 10.0
var jump_impulse:float = 4.5
var rotation_speed:float = 4

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


func _physics_process(delta):

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	#var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var axis_x:float = Input.get_axis("ui_left", "ui_right")
	var axis_y:float = Input.get_axis("ui_up", "ui_down")

	var move_impulse:Vector3 = -global_transform.basis.z * axis_y * impulse
#	velocity -= global_transform.basis.z * axis_y * impulse
	if Input.is_key_pressed(KEY_SHIFT):
#		velocity -= global_transform.basis.x * axis_x * impulse
		move_impulse -= global_transform.basis.x * axis_x * impulse
	else:
		var basis:Basis = global_transform.basis
		basis = basis.rotated(Vector3.UP, -delta * rotation_speed * axis_x)
		global_transform = Transform3D(basis, global_position)
	
	if (velocity + move_impulse).length() < max_speed:
		velocity += move_impulse
	
	velocity -= velocity * drag * delta

	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		var tangent:Vector3 = velocity - velocity.project(Vector3.UP)
		velocity -= tangent * delta * friction

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y += jump_impulse

	move_and_slide()
