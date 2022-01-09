extends Node2D

var width = 0.0
var screenWidth = 0.0

export(float) var buffer = 3.0


# Called when the node enters the scene tree for the first time.
func _ready():
	if get_parent().has_method("get_width"):
		width = get_parent().get_width()
		screenWidth = get_viewport().size.x
		set_process(true)
	else:
		print("FATAL ERROR: Parent of wrap node must have method 'get_width'")
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	if global_position.x - width / 2 + buffer > screenWidth:
		get_parent().position.x = -width / 2
	elif global_position.x + width / 2 - buffer < 0:
		get_parent().position.x = screenWidth + width / 2
