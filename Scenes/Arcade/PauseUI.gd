extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	# If we aren't on mobile
	if not Constants.isMobile:
		# Hide the gyro recalibration
		$Panel/ButtonPanel/RecalibrateGyro.visible = false
