extends Area2D

##### GENERIC VARS #####
export(float) var health = 80.0
export(int) var scoreOnKill = 40
export(float) var moveSpeed = 80.0
export(float) var moveAccuracy = 5.0
export(float) var wait = 0.3
export(float) var damage = 1.0

var targetPlayer

var targetPoint: Vector2 = Vector2.ZERO
var currentOrder: String = ""

var areaCenter: Vector2
var areaSize: Vector2

var ordersSinceLastShot = 0

var isDead = false

##### KAMIKAZE VARS #####
export(PackedScene) var TipBullet
export(float) var waitAfterFireTip = 1.0
export(float) var waitAfterTarget = 0.1
export(float) var turnSpeed = 1.1
export(float) var lifetime = 30.0
export(float) var fireSelfSpeedMultiplier = 1.4

var hasFiredTip = false

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
	$Timers/Lifetime.wait_time = lifetime
	$Timers/Wait.wait_time = wait
	$Timers/WaitAfterFireTip.wait_time = waitAfterFireTip
	$Timers/WaitAfterTarget.wait_time = waitAfterTarget
	
	set_process(true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	# If we have no orders, do something!
	if currentOrder == "":
		# If we just fired, we want to move
		if ordersSinceLastShot == 0:
			move_to_random_location()
		else:
			# Get a random float between 0 and 1
			var rand = randf()
			# If we have moved twice, 50% change of kamikaze
			if ordersSinceLastShot == 1 and rand > 0.5:
				currentOrder = Constants.humanKamikazeOrders.TARGET_PLAYER
			# If we have moved thrice, we execute kamikaze
			elif ordersSinceLastShot == 3:
				currentOrder = Constants.humanKamikazeOrders.TARGET_PLAYER
			# 50% chance of movement if we have only moved twice
			else:
				move_to_random_location()
	else:
		handle_order(delta)

func move_to_random_location():
	# Increment our orders since last shooting
	ordersSinceLastShot += 1
	
	# Randomize shooting, but after 2 moves, we shoot
	targetPoint = Util.getRandomPointInArea(areaCenter, areaSize)
	currentOrder = Constants.genericOrders.MOVE

func handle_order(delta):
	
	if currentOrder == Constants.genericOrders.WAIT:
		# Do nothing if we are waiting
		return
	
	elif currentOrder == Constants.genericOrders.MOVE:
		
		# Move towards the target point!
		var moveDirection = (targetPoint - global_position).normalized()
#		move_and_slide(moveDirection * moveSpeed)
		position += moveDirection * moveSpeed * delta
		
		# If we are close enough to the point we want to move to, remove our order
		if global_position.distance_to(targetPoint) < moveAccuracy:
			# Wait a little bit before moving again
			currentOrder = Constants.genericOrders.WAIT
			$Timers/Wait.start()
	
	elif currentOrder == Constants.humanKamikazeOrders.TARGET_PLAYER:
		# Set the current order to wait
		currentOrder = Constants.genericOrders.WAIT
		
		# Setup the turn angle
		var facing = Vector2(0, 1).rotated(global_rotation)
		var playerToSelf = targetPlayer.global_position - global_position
		var targetAngle = facing.angle_to(playerToSelf)
		
		# Get how fast this animation should go
		var speed = abs(targetAngle) / turnSpeed
		
		# Define our animation and start it
		get_targeting_tween().interpolate_property(self, 
									"global_rotation",
									global_rotation, 
									global_rotation + targetAngle, 
									speed, 
									Tween.TRANS_LINEAR,
									Tween.EASE_IN) 
		get_targeting_tween().start()
		
	elif currentOrder == Constants.humanKamikazeOrders.FIRE_TIP:
		# Turn the tip red, when the animation is over it will fire
		get_animation_player().play("TipToRed")
		
	elif currentOrder == Constants.humanKamikazeOrders.FIRE_SELF:
		# Make ourselves wait
		currentOrder = Constants.genericOrders.WAIT
		# Start the wait after fire tip timer
		$Timers/WaitAfterTarget.start()
	elif currentOrder == Constants.humanKamikazeOrders.FIRING_SELF:
		# Give ourselves a forward velocity
		var velocity = Vector2(0, moveSpeed * fireSelfSpeedMultiplier).rotated(global_rotation)
#		move_and_slide(velocity)
		position += velocity * delta
		

func take_damage(damage: int):
	health -= damage
	
	# Flash when we get hurt
	emit_signal("hurt")
	
	if health <= 0:
		emit_signal("death", scoreOnKill)
		death()

func stun():
	# Make the kamikaze retarget after being stunned
	currentOrder = Constants.humanKamikazeOrders.TARGET_PLAYER
	
	return true

func death():
	# We are dead
	isDead = true
	
	# Stop his tick
	set_process(false)
	
	# Make him not collide with anything
	$Middle.queue_free()
	$Tip.queue_free()
	
	if not Settings.soundFXOff:
		$Sounds/Death.play()
	
	# Make him invisible
	get_sprite().visible = false
	get_tip_on().visible = false
	get_tip_off().visible = false
	
	# Start explosion, and timer to remove from scene
	$DeathNodes/HumanDeathParticles.emitting = true
	$DeathNodes/WaitAfterDeath.start()

##### GETTERS #####

func is_dead():
	return isDead

func get_stun_time(time: float):
	return time

func get_sprite_container():
	return $Sprites

func get_sprite():
	return $Sprites/Sprite

func get_tip_off():
	return $Sprites/TipOff

func get_tip_on():
	return $Sprites/TipOn

func get_animation_player():
	return $AnimationPlayer

func get_targeting_tween():
	return $Targeting

func get_width():
	return get_sprite().texture.get_width() * get_sprite_container().scale.x

func get_timers():
	return $Timers.get_children()

##### SETTERS #####
func set_target_player(player):
	targetPlayer = player

##### SIGNALS #####

func _on_WaitAfterFireSelf_timeout():
	# Use this to redirect him in midair
	pass

func _on_Wait_timeout():
	currentOrder = ""

func _on_WaitAfterTarget_timeout():
	if isDead:
		return
	# Play our fire self sound
	if not Settings.soundFXOff:
		$Sounds/FireSelf.play()
	# Start our lifetime timer
	$Timers/Lifetime.start()
	# We are now firing ourselves
	currentOrder = Constants.humanKamikazeOrders.FIRING_SELF
	# Remove ourselves from the enemy group
	$Timers/RemoveFromGroup.start()

func _on_WaitAfterFireTip_timeout():
	# Change our current order to target
	currentOrder = Constants.humanKamikazeOrders.TARGET_PLAYER
	# The rest will follow from order handling

func _on_RemoveFromGroup_timeout():
	# Remove ourselves from the group
	remove_from_group("Enemies")
	# Tell everyone who is listening that we were removed
	emit_signal("removed")

func _on_WaitAfterDeath_timeout():
	# Remove ourselves from the tree
	queue_free()

func _on_Lifetime_timeout():
	# Delete ourselves
	queue_free()

func _on_AnimationPlayer_animation_finished(anim_name):
	# If we just finished playing our tip to red, fire our tip
	if anim_name == "TipToRed" and not isDead:
		# We no longer have a tip
		hasFiredTip = true
		# Fire our tip
		emit_signal("shoot", TipBullet, $GunMain.global_position, $GunMain.global_rotation)
		# Hide the tip
		get_tip_off().visible = false
		get_tip_on().visible = false
		# Play the fire tip sound
		if not Settings.soundFXOff:
			$Sounds/FireTip.play()
		# Change our order to target the player, need to fire ourselves now
		currentOrder = Constants.genericOrders.WAIT
		# Wait after firing the tip
		$Timers/WaitAfterFireTip.start()

func _on_Targeting_tween_completed(object, key):
	# If we haven't fired our tip yet, fire it
	if not hasFiredTip:
		currentOrder = Constants.humanKamikazeOrders.FIRE_TIP
	else:
		currentOrder = Constants.humanKamikazeOrders.FIRE_SELF

func _on_HumanKamikaze_body_entered(body):
	if body.has_method("is_dead"):
		if body.is_dead():
			return
	
	# If the body we hit has the method take damage, then call it
	if body.has_method("take_damage"):
		body.take_damage(damage)
