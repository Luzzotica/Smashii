extends Panel

signal GameplayTutorialDone()

func get_buttons():
	return [$Background/Done]

func _on_Done_button_down():
	# Save that we have seen the tutorial
	Settings.set_has_done_tutorial(true)
	# Remove ourselves from the tree
	queue_free()
	# Pass the signal along
	emit_signal("GameplayTutorialDone")
