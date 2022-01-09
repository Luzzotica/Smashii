extends Node

const UP = "up"
const DOWN = "down"
const LEFT = "left"
const RIGHT = "right"

var swipe_start = null
var minimum_drag = 100

signal swipe

func _input(event):
	if event.is_action_pressed("swipe"):
		swipe_start = event.position
	if event.is_action_released("swipe"):
		_calculate_swipe(event.position)
        
func _calculate_swipe(swipe_end):
	if swipe_start == null: 
		return
	var swipe = swipe_end - swipe_start
	
	if abs(swipe.y) > minimum_drag:
		if swipe.y > 0:
			emit_signal("swipe", DOWN)
		else:
			emit_signal("swipe", UP)
			
	if abs(swipe.x) > minimum_drag:
		if swipe.x > 0:
			emit_signal("swipe", RIGHT)
		else:
			emit_signal("swipe", LEFT)