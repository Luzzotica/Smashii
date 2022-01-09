extends Label

# Called when the node enters the scene tree for the first time.
func _ready():
	# Connect the scoreChanged signal to our listener
	ScoreManager.connect("scoreChanged", self, "_on_ScoreManager_score_changed")

func _on_ScoreManager_score_changed(newScore):
	# Set the text to the new score
	text = "Current Score: " + str(newScore)
