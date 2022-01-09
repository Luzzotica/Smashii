extends Panel

# Called when the node enters the scene tree for the first time.
func _ready():
	get_music_button().toggle(!Settings.musicOff)
	get_sound_fx_button().toggle(!Settings.soundFXOff)
	pass # Replace with function body.

func _on_Music_button_down():
	# Change the settings
	Settings.set_music(!Settings.musicOff)
	# Toggle the music button
	get_music_button().toggle(!Settings.musicOff)
	
	# Tell the music manager if we turned on or off
	if Settings.musicOff:
		MusicManager.turn_off_music()
	else:
		MusicManager.turn_on_music()


func _on_SoundFX_button_down():
	# Change the settings
	Settings.set_soundFX(!Settings.soundFXOff)
	# Toggle the music button
	get_sound_fx_button().toggle(!Settings.soundFXOff)


func _on_Tutorial_button_down():
	pass # Replace with function body.


func get_music_button():
	return $Music

func get_sound_fx_button():
	return $SoundFX