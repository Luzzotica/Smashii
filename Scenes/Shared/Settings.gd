extends Node

const MUSIC_OFF = "music_off"
const SOUND_FX_OFF = "soundFX_off"
const HAS_DONE_TUTORIAL = "has_done_tutorial"

var musicOff = false
var soundFXOff = false
var hasDoneTutorial = false

var sensitivityX = 5.0
var sensitivityY = 9.0

func _ready():
	load_settings()

##### GETTERS #####

func get_settings():
	
	var data = {
		MUSIC_OFF: musicOff,
		SOUND_FX_OFF: soundFXOff,
		HAS_DONE_TUTORIAL: hasDoneTutorial
	}
	
	return data

##### SETTERS #####

func set_music(off: bool):
	musicOff = off
	# Save settings
	save_settings()

func set_soundFX(off: bool):
	soundFXOff = off
	# Save settings
	save_settings()

func set_has_done_tutorial(done: bool):
	hasDoneTutorial = done
	# Save settings
	save_settings()

##### SAVING/LOADING #####

func load_settings():
	var settings = File.new()
	# If the file doesn't exist create a new one
	if not settings.file_exists("user://settings.save"):
		save_settings()
		return
	# Get the file
	settings.open("user://settings.save", File.READ)
	# Read the line of our settings
	var data = parse_json(settings.get_line())
	# Fill in our settings from the data
	musicOff = data[MUSIC_OFF]
	soundFXOff = data[SOUND_FX_OFF]
	hasDoneTutorial = data[HAS_DONE_TUTORIAL]

func save_settings():
	var settings = File.new()
	# Open up the settings file
	settings.open("user://settings.save", File.WRITE)
	# Write our current settings
	settings.store_line(to_json(get_settings()))
	# Close the file
	settings.close()
