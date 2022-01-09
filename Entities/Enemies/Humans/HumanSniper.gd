extends KinematicBody2D

##### GENERIC VARS #####
export(float) var health = 90.0
export(int) var scoreOnKill = 50
export(float) var moveSpeed = 80.0
export(float) var moveAccuracy = 5.0
export(float) var wait = 0.3

var targetPlayer

var targetPoint: Vector2 = Vector2.ZERO
var currentOrder: String = ""

var areaCenter: Vector2
var areaSize: Vector2

var ordersSinceLastAction = 0

var isDead = false

##### SNIPER VARS #####
export(PackedScene) var FastBlast
export(float) var turnSpeed = 1.1 # Radians per second
export(float) var turnAmount = PI / 30
export(int) var shotCount = 3
export(float) var waitAfterShoot = 0.2

var normalFacing = Vector2(0, 1)
var currentShotCount = shotCount

signal shoot(Bullet, _position,  _direction)
signal death(scoreOnKill)
signal removed()
signal hurt()

# Called when the node enters the scene tree for the first time.
func _ready():
	var centerX = get_viewport().size.x / 2
	var centerY = get_viewport().size.y / 8
	var sizeX = (get_viewport().size.x - get_width())
	var sizeY = (get_viewport().size.y / 4 - get_width())
	
	areaCenter = Vector2(centerX, centerY)
	areaSize = Vector2(sizeX, sizeY)
	
	# Setup the wait for each of our timers
	$Timers/Wait.wait_time = wait
	$Timers/WaitAfterShoot.wait_time = waitAfterShoot
	
	set_process(true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	# If we have no orders, do something!
	if currentOrder == "":
		# If we just fired, we want to move
		if ordersSinceLastAction <= 0:
			move_to_random_location()
		else:
			# Get a random float between 0 and 1
			var rand = randf()
			# If we have moved twice, 50% change of firing
			if ordersSinceLastAction == 1 and rand > 0.5:
				currentOrder = Constants.humanKamikazeOrders.TARGET_PLAYER
			# If we have moved thrice, we execute kamikaze
			elif ordersSinceLastAction == 2:
				currentOrder = Constants.humanKamikazeOrders.TARGET_PLAYER
			# 50% chance of movement if we have only moved twice
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
		move_and_slide(moveDirection * moveSpeed)
		
		# If we are close enough to the point we want to move to, remove our order
		if global_position.distance_to(targetPoint) < moveAccuracy:
			# Wait a little bit before moving again
			currentOrder = Constants.genericOrders.WAIT
			$Timers/Wait.start()
	
	elif currentOrder == Constants.humanKamikazeOrders.TARGET_PLAYER:
		# Set the current order to wait
		currentOrder = Constants.genericOrders.WAIT
		
		# Setup the turn angle
		var facing = normalFacing.rotated(global_rotation)
		var playerToSelf = targetPlayer.global_position - global_position
		var targetAngle = facing.angle_to(playerToSelf)
		
		# Turn to the target angle
		turn_by_angle(get_targeting_tween(), targetAngle)
		
		# Change our line color
		get_animation_player().play("LineWhiteToRed")
		
	elif currentOrder == Constants.humanSniperOrders.SHOOT:
		# Change our order
		currentOrder = Constants.genericOrders.WAIT
		
		# Play the fire sound
		if not Settings.soundFXOff:
			$Sounds/Shoot.play()
		
		# Shoot!
		emit_signal("shoot", FastBlast, $GunMain.global_position, $GunMain.global_rotation)
		currentShotCount -= 1
		
		# Shoot a little to the left, then a little to the right
		if currentShotCount == 2:
			turn_by_angle(get_targeting_tween(), turnAmount)
		elif currentShotCount == 1:
			turn_by_angle(get_targeting_tween(), turnAmount * -2)
		# If we have shot 3 bullets, face forward
		elif currentShotCount == 0:
			currentOrder = Constants.humanSniperOrders.FACE_FORWARD

	elif currentOrder == Constants.humanSniperOrders.FACE_FORWARD:
		# Set the current order to wait
		currentOrder = Constants.genericOrders.WAIT
		
		# Get our current turn angle, we want the opposite of it to return to normal
		var currentFacing = normalFacing.rotated(global_rotation)
		var toTurn = currentFacing.angle_to(normalFacing)
		
		# Face forward
		turn_by_angle(get_face_forward_tween(), toTurn) 
		
		# Change our line color
		get_animation_player().play("LineRedToWhite")


func take_damage(damage: int):
	health -= damage
	
	# Tell people that are listening that we are hurt
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
	$Boosters.queue_free()
	$Wings.queue_free()
	$Middle.queue_free()
	$Tip.queue_free()
	
	if not Settings.soundFXOff:
		$Sounds/Death.play()
	
	# Make him invisible
	get_sprite().visible = false
	get_color_line().visible = false
	
	# Start explosion, and timer to remove from scene
	$DeathNodes/HumanDeathParticles.emitting = true
	$DeathNodes/WaitAfterDeath.start()

##### SNIPER FUNCTIONS #####

func turn_by_angle(tween: Tween, targetAngle: float):
	# Get how fast this animation should go
	var animSpeed = abs(targetAngle) / turnSpeed
	
	# Define our animation and start it
	tween.interpolate_property(self, 
								"global_rotation",
								global_rotation, 
								global_rotation + targetAngle, 
								animSpeed, 
								Tween.TRANS_LINEAR,
								Tween.EASE_IN) 
	tween.start()

##### GETTERS #####

func is_dead():
	return isDead

func get_stun_time(time: float):
	return time

func get_sprite_container():
	return $Sprites

func get_sprite():
	return $Sprites/Sprite

func get_color_line():
	return $Sprites/ColorLine

func get_animation_player():
	return $AnimationPlayer

func get_targeting_tween():
	return $Targeting

func get_face_forward_tween():
	return $FaceForward

func get_width():
	return get_sprite().texture.get_width() * get_sprite_container().scale.x

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

func _on_Wait_timeout():
	currentOrder = ""

func _on_WaitAfterDeath_timeout():
	# Remove ourselves from the tree
	queue_free()

func _on_AnimationPlayer_animation_finished(anim_name):
	# Do nothing, we don't care when this animation finishes
	pass

func _on_Targeting_tween_completed(object, key):
	# We want to fire
	currentOrder = Constants.humanSniperOrders.SHOOT

func _on_FaceForward_tween_completed(object, key):
	# We want to move after we have finished firing
	$Timers/WaitAfterShoot.start()
