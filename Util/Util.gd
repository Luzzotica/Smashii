extends Node

func getRandomPointInArea(center: Vector2, size: Vector2):
	# Get the random x
	var x = center.x + randf() * size.x - size.x / 2
	# Get the random y
	var y = center.y + randf() * size.y - size.y / 2
	
	# Return is as a vector
	return Vector2(x, y)

func invertAccelerometer(accelerometer: Vector3):
	var inverted = accelerometer
	if inverted.x > 0:
		inverted.x -= 1
	if inverted.x < 0:
		inverted.x += 1
	if inverted.y > 0:
		inverted.y -= 1
	if inverted.y < 0:
		inverted.y += 1
	if inverted.z > 0:
		inverted.z -= 1
	if inverted.z < 0:
		inverted.z += 1
	
	return inverted