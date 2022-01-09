extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	setup_buttons()

func setup_buttons():
	# Loop through all the buttons and connect them to our button sound
	for button in get_tree().get_nodes_in_group("Buttons"):
		button.connect("button_down", self, "_on_button_down")

func _on_button_added(button):
	button.connect("button_down", self, "_on_button_down")

func _on_button_down():
	# If we don't want to play fx sounds, stop
	if Settings.soundFXOff:
		return
	
	$ButtonDown.play()
