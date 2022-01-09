extends TextureButton

# Called when the node enters the scene tree for the first time.
func _ready():
	# If we are android, we hide this button, no leaderboards
	if Constants.isAndroid:
		visible = false
