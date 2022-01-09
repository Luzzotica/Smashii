extends Label

# Called when the node enters the scene tree for the first time.
func _ready():
	# Connect the newHighScore signal to our listener
	ScoreManager.connect("highScoreChanged", self, "_on_ScoreManager_high_score_changed")
	# Set the text to the current high score
	text = "High Score: " + str(ScoreManager.get_high_score())

func _on_ScoreManager_high_score_changed(highScore):
	# Set the text to the new high score
	text = "High Score: " + str(highScore)
