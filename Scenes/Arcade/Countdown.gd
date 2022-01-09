extends Control

var currentNumber = 1

signal finished()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func start():
	$Three.visible = true
	$Timer.start()

func _on_Timer_timeout():
	if currentNumber == 1:
		$Three.visible = false
		$Two.visible = true
	elif currentNumber == 2:
		$Two.visible = false
		$One.visible = true
	elif currentNumber == 3:
		$One.visible = false
		$Start.visible = true
		
		# Emit the done signal here
		# We will show start for a second before removing it
		emit_signal("finished")
	elif currentNumber == 4:
		# Stop the timer
		$Timer.stop()
		# Remove ourselves from the scene
		queue_free()
	
	# Increment the number
	currentNumber += 1
