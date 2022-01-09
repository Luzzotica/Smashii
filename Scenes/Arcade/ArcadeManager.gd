extends Node2D

export(PackedScene) var CountdownTimer
export(PackedScene) var GameplayTutorial

signal reset()
signal buttonAdded()
signal powerUsed(cooldown)
signal playerDeath(livesRemaining)

# Called when the node enters the scene tree for the first time.
func _ready():
	if Constants.isAndroid:
		# For android phones, shouldn't quit on back press
		get_tree().set_quit_on_go_back(false)
	
	# Connect our reset signal to everything that should recieve it
	connect("reset", get_player(), "_on_reset")
	
	# Connect the player's signals to our functions
	get_player().connect("lost", self, "_on_Player_lost")
	get_player().connect("death", self, "_on_Player_death")
	get_player().connect("usePower", self, "_on_Player_usePower")
	# If this is our first time playing
	if not Settings.hasDoneTutorial:
		# Play the tutorial before starting
		play_tutorial()
	else:
		# Play the beinning cinematic
		play_start_cinematic()

##### GAME STATE #####

func game_paused():
	get_tree().paused = true
	# "Pause" the player
	get_player().set_cinematic_mode(true)

func game_unpause():
	# Run the countdown timer
	get_tree().paused = false
	# "Unpause" the player
	get_player().set_cinematic_mode(false)

func game_restart():
	# Show gameplay, hide pause and death
	get_tree().get_nodes_in_group("GameplayUI")[0].visible = true
	get_tree().get_nodes_in_group("PauseUI")[0].visible = false
	get_tree().get_nodes_in_group("DeathUI")[0].visible = false
	
	# Reset the score manager
	ScoreManager.reset()
	
	# Emit the reset signal
	emit_signal("reset")
	# Play the beginning cinematic
	play_start_cinematic()

func game_quit():
	# Reset the score manager
	ScoreManager.reset()
	# Unpause!
	get_tree().paused = false
	# Swap scenes
	get_tree().change_scene(Constants.SCENES.MAIN_MENU)

##### COUNTDOWN #####

func create_and_start_countdown():
	# Create the timer
	var timer = CountdownTimer.instance()
	# Add it to the scene
	get_ui_layer().add_child(timer)
	# Start the countdown
	timer.start()
	# Return the timer in case we want to do stuff with it
	return timer

func run_countdown_timer_unpause():
	# Create the timer
	var timer = create_and_start_countdown()
	# Connect the finish signal to our unpause function
	timer.connect("finished", self, "game_unpause")

##### GAME START #####

func play_tutorial():
	# Pause the game
	game_paused()
	# Hide the normal gameplay UI
	get_tree().get_nodes_in_group("GameplayUI")[0].visible = false
	
	# Create the tutorial UI
	var tut = GameplayTutorial.instance()
	# Connect its signal to ourselves so we know when the play presses done
	tut.connect("GameplayTutorialDone", self, "_on_GameplayTutorial_done")
	# Add it to the UILayer
	get_ui_layer().add_child(tut)
	# A button was added, handle its sounds
	emit_signal("buttonAdded", tut.get_buttons()[0])

func play_start_cinematic():
	# Pause the game
	game_paused()
	# Animate player moving in
	get_player().play_enter_scene()
	# Start the countdown timers
	var timer = create_and_start_countdown()
	timer.connect("finished", self, "end_start_cinematic")

func end_start_cinematic():
	# Unpause the game
	game_unpause()
	# Start the waves
	$EntityManager.check_spawn_wave()

##### GETTERS #####

func get_player():
	return get_tree().get_nodes_in_group("Player")[0]

func get_ui_layer():
	return $Camera2D/UILayer

##### SIGNALS #####

func _on_Player_usePower(powerObject, _position, _direction, cooldown):
	emit_signal("powerUsed", cooldown)

func _on_Player_death(livesRemaining):
	emit_signal("playerDeath", livesRemaining)

func _on_Player_lost():
	# Pause the game
	game_paused()
	
	# gameplay to lose music
	MusicManager.play_gameplay_to_lost()
	
	# Show gameplay, hide pause
	get_tree().get_nodes_in_group("GameplayUI")[0].visible = false
	get_tree().get_nodes_in_group("DeathUI")[0].visible = true

func _on_PauseButton_button_down():
	# If we are already paused, do nothing
	if get_tree().paused:
		return
	
	# Pause the game
	game_paused()
	
	# Hide gameplay, show pause
	get_tree().get_nodes_in_group("GameplayUI")[0].visible = false
	get_tree().get_nodes_in_group("PauseUI")[0].visible = true

func _on_Resume_button_down():
	# Show gameplay, hide pause
	get_tree().get_nodes_in_group("GameplayUI")[0].visible = true
	get_tree().get_nodes_in_group("PauseUI")[0].visible = false
	
	# Run the countdown
	run_countdown_timer_unpause()

func _on_PauseRestart_button_down():
	# Restart game
	game_restart()

func _on_DeathRestart_button_down():
	# Lost to gameplay sound
	MusicManager.play_lost_to_gameplay()
	# Restart game
	game_restart()

func _on_RecalibrateGyro_button_down():
	get_player().set_accelerometer()

func _on_PauseQuit_button_down():
	# Gameplay to manu menu sound
	MusicManager.play_gameplay_to_main_menu()
	# Quit
	game_quit()

func _on_DeathQuit_button_down():
	# Gameplay to manu menu sound
	MusicManager.play_lost_to_main_menu()
	# Quit
	game_quit()

func _on_GameplayTutorial_done():
	# Show the normal gameplay UI
	get_tree().get_nodes_in_group("GameplayUI")[0].visible = true
	# Play the starting cinematic
	play_start_cinematic()

##### NOTIFCATIONS #####

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_FOCUS_IN:
#		print("NOTIFICATION_WM_FOCUS_IN")
		pass
	elif what == MainLoop.NOTIFICATION_WM_FOCUS_OUT:
		_on_PauseButton_button_down()
	elif what == MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_PauseButton_button_down()
	elif what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		_on_PauseButton_button_down()
	
