extends Node

const MAX_SCORES = 10

var GameCenter = null

var highScores = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
var currentScore = 0
var currentScoreIndex = -1

signal scoreChanged(newScore)
signal highScoreChanged(highScore)
signal highScoresChanged(highScores)

func _ready():
	# check if the singleton exists
	if Engine.has_singleton("GameCenter"):
		GameCenter = Engine.get_singleton("GameCenter")
	
	# Load our high scores
	load_high_scores()

func reset():
	currentScore = 0
	currentScoreIndex = -1
	emit_signal("scoreChanged", currentScore)

func add_to_score(amount: int):
	# Add to our current score
	currentScore += amount
	
	# We must ensure that only one score is added per match, this will ensure that
	# If it is a score high enough, make sure it is in our list
	if currentScoreIndex == -1 and currentScore > highScores.front():
		# Append it to the list, sort the list, and pop off the lowest score
		highScores.append(currentScore)
		highScores.sort()
		
		if highScores.size() > MAX_SCORES:
			highScores.pop_front()
		
		# Find the index of our score
		currentScoreIndex = highScores.find(currentScore)
	elif currentScoreIndex != -1:
		# Change the score at the index
		highScores[currentScoreIndex] = currentScore
		# Resort
		highScores.sort()
		# Find the new index for next time
		currentScoreIndex = highScores.find(currentScore)
		# If the current score is our new high score
		if currentScoreIndex == highScores.size() - 1:
			emit_signal("highScoreChanged", get_high_score())
			# If we are on iOS, posst the score to our leaderboard
			if GameCenter != null:
				var result = GameCenter.post_score({"score":get_high_score(), 
													"category":"Smashii_Rocket"})
		
		# Either way, our high scores have changed
		emit_signal("highScoresChanged", get_high_scores())
	
	# Save the score
	save_high_scores()
	
	# Emit the necessary signal
	emit_signal("scoreChanged", currentScore)

func get_high_scores():
	return highScores

func get_high_score():
	# If we have scores, return the first one, which is the highest
	return highScores.back()

func save_high_scores():
	var saveGame = File.new()
	saveGame.open("user://high_scores.save", File.WRITE)
	# Store the high scores as json
	saveGame.store_line(to_json(highScores))
	# Close the file
	saveGame.close()

func load_high_scores():
	var saveGame = File.new()
	if not saveGame.file_exists("user://high_scores.save"):
		return # Error! We don't have a save to load.

    # Load the file, and parse it into our high scores
	saveGame.open("user://high_scores.save", File.READ)
	highScores = parse_json(saveGame.get_line())
	
	# Close the file
	saveGame.close()