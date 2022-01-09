extends VBoxContainer

var scoreLabels: Array = []

# Called when the node enters the scene tree for the first time.
func _ready():
	ScoreManager.connect("highScoresChanged", self, "_on_ScoreManager_high_scores_changed")
	
	for node in get_children():
		if node is Label:
			scoreLabels.append(node)
	
	setup_scores(ScoreManager.get_high_scores())

func setup_scores(highScores):
	for i in range(scoreLabels.size()):
		scoreLabels[i].text = str(highScores[highScores.size() - i - 1])

func _on_ScoreManager_high_scores_changed(highScores):
	setup_scores(highScores)
