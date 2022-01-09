extends Node2D

export(PackedScene) var GameplayTutorial

var panels: Array = []
var currentPanelIndex: int
var canSwap = true

var offScreenLeftPos: Vector2
var offScreenRightPos: Vector2
var normalPos: Vector2

var GameCenter = null
var leaderboardPressed = false

signal buttonAdded()

func _ready():
	
	if Constants.isAndroid:
		# For android phones, should quit on back press in main menu
		get_tree().set_quit_on_go_back(true)
	
	# check if the singleton exists
	if Engine.has_singleton("GameCenter"):
		GameCenter = Engine.get_singleton("GameCenter")
	
	# Play the music! If we aren't playing a different one
	if not MusicManager.executingSwap:
		MusicManager.play_main_menu()
	
	# Connect the swipe gesture to us
	SwipeDetection.connect("swipe", self, "_on_SwipeDetection_swipe")
	
	# Setup the panels
	setup_panels()

func start_arcade():
	get_tree().change_scene(Constants.SCENES.ARCADE)
	# Play main menu to gameplay
	MusicManager.play_main_menu_to_gameplay()

func rotate_panels(direction: String, forceRotate: bool = false):
	# If we can't swap, add the direction to our list, unless we want to force rotate
	if not canSwap and not forceRotate:
		return
	canSwap = false
	
	# Assume we are swapping left
	var swapTo = get_panel_left()
	var swapToStartPos = offScreenLeftPos
	var swapFromEndPos = offScreenRightPos
	# If the direction is RIGHT, change our variables
	if direction == "right":
		swapTo = get_panel_right()
		swapToStartPos = offScreenRightPos
		swapFromEndPos = offScreenLeftPos
	
	# Make the thing we are moving to visible
	swapTo.visible = true
	
	# Setup interpolates
	get_panel_swap().interpolate_property(swapTo,
								"modulate",
								Constants.colorInvisible,
								Constants.colorVisible,
								Constants.MAIN_MENU_SWAP_TIME,
								Tween.TRANS_LINEAR,
								Tween.EASE_IN)
	get_panel_swap().interpolate_property(swapTo,
								"rect_position",
								swapToStartPos,
								normalPos,
								Constants.MAIN_MENU_SWAP_TIME,
								Tween.TRANS_LINEAR,
								Tween.EASE_IN)
	# Move the current panel off the screen
	get_panel_swap().interpolate_property(get_panel_current(),
								"modulate",
								Constants.colorVisible,
								Constants.colorInvisible,
								Constants.MAIN_MENU_SWAP_TIME,
								Tween.TRANS_LINEAR,
								Tween.EASE_IN)
	get_panel_swap().interpolate_property(get_panel_current(),
								"rect_position",
								normalPos,
								swapFromEndPos,
								Constants.MAIN_MENU_SWAP_TIME,
								Tween.TRANS_LINEAR,
								Tween.EASE_IN)
	get_panel_swap().start()
	
	# Set the index
	if direction == "left":
		currentPanelIndex -= 1
	elif direction == "right":
		currentPanelIndex += 1
	# Make sure the index wraps
	if currentPanelIndex < 0:
		currentPanelIndex += panels.size()
	currentPanelIndex = currentPanelIndex % panels.size()

func setup_panels():
	panels.append(get_arcade_panel())
	panels.append(get_settings_panel())
	
	# Setup position variables
	offScreenLeftPos = Vector2(Constants.OFF_SCREEN_LEFT, get_panel_current().rect_position.y)
	offScreenRightPos = Vector2(Constants.OFF_SCREEN_RIGHT, get_panel_current().rect_position.y)
	normalPos = get_panel_current().rect_position

##### GETTERS #####

func get_panel_swap():
	return $UILayer/PanelSwap

func get_panel_current():
	return panels[currentPanelIndex]

func get_panel_left():
	# Godot arrays count backwards when negative
	return panels[currentPanelIndex - 1]

func get_panel_right():
	return panels[(currentPanelIndex + 1) % panels.size()]

func get_arcade_panel():
	return get_tree().get_nodes_in_group("ArcadePanel")[0]

func get_settings_panel():
	return get_tree().get_nodes_in_group("SettingsPanel")[0]

func get_main_panel():
	return get_tree().get_nodes_in_group("MainPanel")[0]

func get_high_scores_panel():
	return get_tree().get_nodes_in_group("HighScores")[0]

func get_score_container():
	return get_tree().get_nodes_in_group("ScoreContainer")[0]

func get_main_ui_node():
	return get_tree().get_nodes_in_group("MainUINode")[0]

##### SIGNALS #####

func _on_Start_button_down():
	start_arcade()

func _on_SwipeDetection_swipe(direction: String):
	# If we just pressed the leaderboard, don't swipe
	if leaderboardPressed:
		return
		
	if direction == SwipeDetection.RIGHT:
		rotate_panels("left")
	elif direction == SwipeDetection.LEFT:
		rotate_panels("right")

func _on_Music_button_down():
	pass # Replace with function body.

func _on_SoundFX_button_down():
	pass # Replace with function body.

func _on_Tutorial_button_down():
	# Hide the main panel so we can show the tutorial
	get_main_panel().visible = false
	# Create the tutorial node
	var tut = GameplayTutorial.instance()
	# Connect his signal to ours
	tut.connect("GameplayTutorialDone", self, "_on_GameplayTutorial_done")
	# Add him to the main UI node
	get_main_ui_node().add_child(tut)
	# A button was added, handle its sounds
	emit_signal("buttonAdded", tut.get_buttons()[0])

func _on_Leaderboard_button_down():
	leaderboardPressed = true
	if GameCenter != null:
		var result = GameCenter.show_game_center({"view":"leaderboards", "leaderboard_name":"Smashii_Rocket" }) 
	# Set the pressed variable a little bit later
	$LeaderboardPressedTimer.start()

func _on_HighScore_button_down():
	get_high_scores_panel().visible = true
	get_main_panel().visible = false

func _on_LeftArrow_button_down():
	rotate_panels("left")

func _on_RightArrow_button_down():
	rotate_panels("right")

func _on_PanelSwap_tween_completed(object, key):
	# We can swap again
	canSwap = true
	
	# Make sure all panels other than ours are hidden
	var currentPanel = get_panel_current()
	for panel in panels:
		if panel != currentPanel:
			panel.visible = false

func _on_Done_button_down():
	get_high_scores_panel().visible = false
	get_main_panel().visible = true

func _on_GameplayTutorial_done():
	# Show the main panel
	get_main_panel().visible = true
	# The tutorial will remove itself from the scene

func _on_LeaderboardPressedTiimer_timeout():
	leaderboardPressed = false
