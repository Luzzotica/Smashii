extends KinematicBody2D

##### GENERIC VARS #####
export(float) var health = 110.0
export(int) var scoreOnKill = 35
export(float) var movespeed = 65.0
export(float) var moveAccuracy = 5.0
export(float) var wait = 0.8

var targetPlayer

var targetPoint: Vector2 = Vector2.ZERO
var currentOrder: String = ""

var areaCenter: Vector2
var areaSize: Vector2

var ordersSinceLastAction = 0

var isDead = false

##### SHOOTER VARS #####
export(PackedScene) var MainBlast
export(int) var shotCount = 2
export(float) var waitAfterShoot = 1.5
export(float) var fireStutter = 0.2

var currentShotCount = shotCount

signal shoot(Bullet, _position,  _direction)
signal death(scoreOnKill)
signal removed()
signal hurt()

# Called when the node enters the scene tree for the first time.
func _ready():
	var centerX = get_viewport().size.x / 2
	var centerY = get_viewport().size.y / 5
	var sizeX = (get_viewport().size.x - get_width())
	var sizeY = (get_viewport().size.y / 2.5 - get_width())
	
	areaCenter = Vector2(centerX, centerY)
	areaSize = Vector2(sizeX, sizeY)
	
	# Setup the wait for each of our timers
	$Timers/Wait.wait_time = wait
	$Timers/WaitAfterShoot.wait_time = waitAfterShoot
	$Timers/FireStutter.wait_time = fireStutter
	
	set_process(true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	# If we have no orders, do something!
	if currentOrder == "":
		# If we just fired, we want to move
		if ordersSinceLastAction == 0:
			move_to_random_location()
		else:
			# Get a random float between 0 and 1
			var rand = randf()
			# If we have moved once, 50% change of shooting
			if ordersSinceLastAction == 1 and rand > 0.5:
				currentOrder = Constants.humanShooterOrders.SHOOT
			# If we have moved twice, we shoot
			elif ordersSinceLastAction == 2:
				currentOrder = Constants.humanShooterOrders.SHOOT
			# 50% chance of movement if we have only moved once
			else:
				move_to_random_location()
	else:
		handle_order()

func move_to_random_location():
	# Increment our orders since last shooting
	ordersSinceLastAction += 1
	
	# Randomize shooting, but after 2 moves, we shoot
	targetPoint = Util.getRandomPointInArea(areaCenter, areaSize)
	currentOrder = Constants.genericOrders.MOVE

func handle_order():
	if currentOrder == Constants.genericOrders.WAIT:
		# Do nothing if we are waiting
		return
	
	elif currentOrder == Constants.genericOrders.MOVE:
		
		# Move towards the target point!
		var moveDirection = (targetPoint - global_position).normalized()
		move_and_slide(moveDirection * movespeed)
		
		# If we are close enough to the point we want to move to, remove our order
		if global_position.distance_to(targetPoint) < moveAccuracy:
			# Wait a little bit before moving again
			currentOrder = Constants.genericOrders.WAIT
			$Timers/Wait.start()
	
	elif currentOrder == Constants.humanShooterOrders.SHOOT:
		# Change our order
		currentOrder = Constants.humanShooterOrders.SHOOTING
		
		# Play the fire sound
		if not Settings.soundFXOff:
			$Sounds/ShootOne.play()
		
		# Shoot!
		emit_signal("shoot", MainBlast, $GunMain.global_position, $GunMain.global_rotation)
		currentShotCount -= 1
		
		# Start our fire stutter timer
		$Timers/FireStutter.start()


func take_damage(damage: int):
	health -= damage
	
	# Flash when we get hurt
	emit_signal("hurt")
	
	if health <= 0:
		emit_signal("death", scoreOnKill)
		death()

func death():
	# We are dead
	isDead = true
	
	# Stop his tick
	set_process(false)
	
	# Make him not collide with anything
	$Base.queue_free()
	$Tip.queue_free()
	
	if not Settings.soundFXOff:
		$Sounds/Death.play()
	
	# Make him invisible
	get_sprite().visible = false
	
	# Start explosion, and timer to remove from scene
	$DeathNodes/HumanDeathParticles.emitting = true
	$DeathNodes/WaitAfterDeath.start()

##### GETTERS #####

func is_dead():
	return isDead

func get_stun_time(time: float):
	return time

func get_sprite():
	return $Sprite

func get_width():
	return get_sprite().texture.get_width() * scale.x

func get_timers():
	return $Timers.get_children()

##### SETTERS #####

func set_target_player(player):
	targetPlayer = player

##### SIGNALS #####

func _on_WaitAfterShoot_timeout():
	# Reset all the shooting things
	currentShotCount = shotCount
	ordersSinceLastAction = 0
	
	# Remove the current order
	currentOrder = ""

func _on_FireStutter_timeout():
	# Shoot until the shotCount is 0
	if currentShotCount > 0:
		currentOrder = Constants.humanShooterOrders.SHOOT
	else:
		# Run the wait after shoot timer
		currentOrder = Constants.genericOrders.WAIT
		$Timers/WaitAfterShoot.start()

func _on_Wait_timeout():
	currentOrder = ""

func _on_WaitAfterDeath_timeout():
	# Remove ourselves from the tree
	queue_free()
