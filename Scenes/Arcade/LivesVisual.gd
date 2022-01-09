extends Control

func set_lives_visible(lives: int):
	# Show and hide based on lives
	if lives == 0:
		$Panel/LifeOne.visible = false
		$Panel/LifeTwo.visible = false
		$Panel/LifeThree.visible = false
		$Panel/LifeOver.visible = false
	if lives == 1:
		$Panel/LifeOne.visible = true
		$Panel/LifeTwo.visible = false
		$Panel/LifeThree.visible = false
		$Panel/LifeOver.visible = false
	elif lives == 2:
		$Panel/LifeOne.visible = true
		$Panel/LifeTwo.visible = true
		$Panel/LifeThree.visible = false
		$Panel/LifeOver.visible = false
	elif lives == 3:
		$Panel/LifeOne.visible = true
		$Panel/LifeTwo.visible = true
		$Panel/LifeThree.visible = true
		$Panel/LifeOver.visible = false
	elif lives > 3:
		$Panel/LifeOne.visible = false
		$Panel/LifeTwo.visible = false
		$Panel/LifeThree.visible = true
		$Panel/LifeOver.visible = true
		$Panel/LifeOver.text = "X" + str(lives)

func _on_Arcade_playerDeath(livesRemaining):
	set_lives_visible(livesRemaining)

func _on_Player_death(livesRemaining):
	set_lives_visible(livesRemaining)

func _on_reset():
	set_lives_visible(3)

