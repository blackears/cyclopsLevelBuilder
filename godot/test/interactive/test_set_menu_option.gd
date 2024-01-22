extends Control

enum Bar { ALPHA, BETA, GAMMA, DELTA }
# Called when the node enters the scene tree for the first time.
func _ready():
	for t in Bar.keys():
		%option_bn.add_item(t)
		
	%option_bn.select(2)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
