extends Node

# Volume values
# HomeScreen volume = -35
# Gameplay = -25
# Lost = -20

var executingSwap = false

##### PLAY #####

func play_main_menu():
	if not Settings.musicOff:
		get_track_fader().play("HomeScreen")
		executingSwap = true

func play_main_menu_to_gameplay():
	if not Settings.musicOff:
		get_track_fader().play("HomeScreenToGameplay")
		executingSwap = true

func play_gameplay_to_main_menu():
	if not Settings.musicOff:
		get_track_fader().play("GameplayToHomeScreen")
		executingSwap = true

func play_gameplay_to_lost():
	if not Settings.musicOff:
		get_track_fader().play("GameplayToLost")
		executingSwap = true

func play_lost_to_gameplay():
	if not Settings.musicOff:
		get_track_fader().play("LostToGameplay")
		executingSwap = true

func play_lost_to_main_menu():
	if not Settings.musicOff:
		get_track_fader().play("LostToHomeScreen")
		executingSwap = true

func get_track_fader():
	return $AnimationPlayer

##### TURNING ON/OFF #####

func turn_on_music():
	# If they turned if on then they are in the main menu
	play_main_menu()

func turn_off_music():
	# Stop all music
	$HomeScreen.stop()
	$Gameplay.stop()
	$Lost.stop()
	executingSwap = false

##### SIGNALS #####

func _on_AnimationPlayer_animation_finished(anim_name):
	executingSwap = false
	# Stop other tracks depending on what we just swapped to
	if "ToHomeScreen" in anim_name or "HomeScreen" == anim_name:
		$Gameplay.stop()
		$Lost.stop()
	elif "ToGameplay" in anim_name:
		$HomeScreen.stop()
		$Lost.stop()
	elif "ToLost" in anim_name:
		$HomeScreen.stop()
		$Gameplay.stop()
