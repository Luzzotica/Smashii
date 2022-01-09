extends Area2D

export (float) var speed = 5.0
export (int) var damage = 8.0
export (float) var lifetime = 5.0
export (int) var hitCount = 5
export (float) var searchTime = 0.1

var velocity = Vector2()
var collidingBodies = []
var timeSinceSearch = 0.0

func start(_position, _rotation, powerupLevel):
	var realPowerupLevel = powerupLevel - Constants.powerupFowardDisk
	# Setup damange based on powerupLevel
	damage += realPowerupLevel * 2
	
	# Setup bullet position and angle
	position = _position
	rotation = _rotation
	
	# Setup out velocity
	var dir = Vector2(0, -1).rotated(_rotation)
	velocity = dir * speed
	
	# Define a lifetime, very valuable
	$Lifetime.wait_time = lifetime
	
	# Change color based on power level
	$BulletOuter.modulate = Constants.powerupColors[clamp(realPowerupLevel, 0, 2)]

func _process(delta):
	timeSinceSearch += delta
	if timeSinceSearch > searchTime:
		# Reset time since search
		timeSinceSearch = 0.0
		
		# Deal damage to all bodies we are in contact with
		for body in collidingBodies:
			if not body.isDead:
				# Decrement hit count for each body we hit
				hitCount -= 1
				# Deal damage
				body.take_damage(damage)
				# See if the bullet should disappear
				check_death()
		
	# Move ourselves
	position += velocity * delta

func hit_body(body):
	# If the body we hit has the method take damage, then call it
	if body.has_method("take_damage"):
		# If we hit something that can take damage, decrement hit count
		hitCount -= 1
		# Append the body to our bodies we are attached to
		collidingBodies.append(body)
		# Make them take damage
		body.take_damage(damage)
	
	# See if we have reached our max hit count
	check_death()

func check_death():
	# If we can't hit anymore people
	if hitCount == 0:
		# Play death animation
		$DiskBirthDeath.play("Death")
		# Remove colliders
		$DiskColliderShape.queue_free()

func exited_body(body):
	# Loop through our bodies
	for i in range(collidingBodies.size()):
		# If the body is equal to any, remove that one
		if body == collidingBodies[i]:
			collidingBodies.remove(i)
			break

##### SIGNALS #####

func _on_Lifetime_timeout():
	# Explode
	queue_free()

func _on_Disk_body_entered(body):
	hit_body(body)

func _on_Disk_body_exited(body):
	exited_body(body)

func _on_DiskBirthDeath_animation_finished(anim_name):
	# If we just finished our death animation, remove ourselves from the scene
	if anim_name == "Death":
		queue_free()

func _on_Disk_area_entered(area):
	hit_body(area)

func _on_Disk_area_exited(area):
	exited_body(area)
