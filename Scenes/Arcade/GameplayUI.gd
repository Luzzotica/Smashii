extends Control

func _ready():
	# If we are on a device with a safe area, move our UI into the light
	var safeArea = OS.get_window_safe_area()
	
	self.rect_position.y += safeArea.position.y / 3
	
	
