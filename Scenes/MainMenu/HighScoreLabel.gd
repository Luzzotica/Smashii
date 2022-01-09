extends Label


# Called when the node enters the scene tree for the first time.
func _ready():
#	ScoreManager.connect("highScoreReady", self, "_on_HighScore_ready")
	text = "High Score: " + str(ScoreManager.get_high_score())

func _on_HighScore_ready(highScore: int):
	print("Got here")
	
