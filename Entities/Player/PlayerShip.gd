extends KinematicBody2D

export(PackedScene) var ForwardBlast
export(PackedScene) var ForwardBlastThird
export(PackedScene) var SideBlast
export(PackedScene) var ForwardDisk
export(PackedScene) var SideDisk
export(PackedScene) var Power
export(PackedScene) var WeaponUp
export(PackedScene) var ShieldUp
export(String) var PowerType = "EMP"
export(float) var moveSpeed = 360.0
export(float) var shootSpeed = 0.2
export(float) var powerSpeed = 8.0
export(float) var health = 1.0
export(float) var lives = 3
export(float) var movementZeroThreshhold = 0.02

var controllable = true

var accelerometerBase = Vector3.ZERO
var canShoot = true
var canUsePower = true

var powerupLevel = Constants.powerupFowardBlast

var flashingHurt = false
var invulnerable = false

var shieldFadeTime = 0.5
var isDead = false

signal shoot(bulletPackages, powerupLevel)
signal usePower(powerObject, _position, _direction, cooldown)
signal death(currentLives)
signal respawn()
signal lost()

# Called when the node enters the scene tree for the first time.
func _ready():
	# Setup our shoot speed and EMP use speed
	$ShootTimer.wait_time = shootSpeed
	$PowerTimer.wait_time = powerSpeed
	
	# Connect the swipe signal to ourselves
	SwipeDetection.connect("swipe", self, "_on_SwipeDetection_swipe")
	
	# Set the shield color
	get_shield_sprite().modulate = Constants.shieldGone
	
	set_process(true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# If we are currently uncontrollable, stop
	if not controllable:
		return
	
	# Handle shooting
	handle_shoot_and_power()
	# Handle player movement
	handle_movement()

func handle_shoot_and_power():
	# If we just pressed our shoot button
	if Input.is_action_just_pressed("shoot"):
		# Shoot!
		shoot()
	if Input.is_action_just_pressed("use_power"):
		use_power()

func shoot():
	# If we can shoot, do stuff
	if canShoot:
		# Set canShoot to false and start our shot timer
		canShoot = false
		$ShootTimer.start()
		
		# Play our fire sound
		if not Settings.soundFXOff:
			$Sounds/PlayerFire.play()
		
		# Get the bullets based on level
		var bulletPackages = get_bullets_by_power_level()
		
		# Emit our shoot signal
		emit_signal("shoot", bulletPackages, powerupLevel)
		
#		powerupLevel += 1
#		powerupLevel %= Constants.powerupSideDisk

func get_bullets_by_power_level():
	
	var packages: Array = []
	if powerupLevel < Constants.powerupTripleForwardBlast:
		packages.append([ForwardBlast, 
						$GunPositions/GunLeft.global_position, 
						$GunPositions/GunLeft.global_rotation])
		packages.append([ForwardBlast, 
						$GunPositions/GunRight.global_position, 
						$GunPositions/GunRight.global_rotation])
						
	elif powerupLevel < Constants.powerupFowardDisk:
		packages.append([ForwardBlast, 
						$GunPositions/GunLeft.global_position, 
						$GunPositions/GunLeft.global_rotation])
		packages.append([ForwardBlast, 
						$GunPositions/GunRight.global_position, 
						$GunPositions/GunRight.global_rotation])
		packages.append([ForwardBlastThird, 
						$GunPositions/GunMain.global_position, 
						$GunPositions/GunMain.global_rotation])
						
	elif powerupLevel >= Constants.powerupFowardDisk:
		packages.append([ForwardDisk, 
						$GunPositions/GunMain.global_position, 
						$GunPositions/GunMain.global_rotation])
	
	if (powerupLevel >= Constants.powerupSideBlast):
#		and powerupLevel < Constants.powerupSideDisk):
			
		packages.append([SideBlast, 
						$GunPositions/GunLowerLeft.global_position, 
						$GunPositions/GunLowerLeft.global_rotation])
		packages.append([SideBlast, 
						$GunPositions/GunLowerRight.global_position, 
						$GunPositions/GunLowerRight.global_rotation])
#	elif powerupLevel >= Constants.powerupSideDisk:
#
#		packages.append([SideDisk, 
#						$GunPositions/GunLowerLeft.global_position, 
#						$GunPositions/GunLowerLeft.global_rotation])
#		packages.append([SideDisk, 
#						$GunPositions/GunLowerRight.global_position, 
#						$GunPositions/GunLowerRight.global_rotation])
	
	return packages

func use_power():
	
	if canUsePower and controllable:
		# Make sure we can't use EMP a ton, start the timer
		canUsePower = false
		$PowerTimer.start()
		
		var launchNode = $GunPositions/EMP
		# Get other launch points if power is different
		# if PowerType == "Saw":  ...
		# Play our fire sound
		if not Settings.soundFXOff:
			$Sounds/EMP.play()
		
		var _position = launchNode.global_position
		var _rotation = launchNode.global_rotation
		
		# Emit our use power signal!
		emit_signal("usePower", Power, _position, _rotation, powerSpeed)

func handle_movement():
	var movement = get_movement()
	move_and_slide(movement * moveSpeed)

func get_movement():
	var movement = Vector2.ZERO
	# If we are on mobile, use the accelerometer
	if Constants.isMobile:
		var accel = get_accelerometer()
		var y = accelerometerBase.y - accel.y
		var x = accel.x - accelerometerBase.x
		var moveY = get_movement_from_value(y, Settings.sensitivityY)
		var moveX = get_movement_from_value(x, Settings.sensitivityX)
		
#		print(moveX, " ", moveY)
		
		movement.y = clamp(moveY, -1.0, 1.0)
		movement.x = clamp(moveX, -1.0, 1.0)
	# Otherwise, use buttons
	else:
		if Input.is_action_pressed("up"):
			movement.y -= 1
		if Input.is_action_pressed("down"):
			movement.y += 1
		if Input.is_action_pressed("left"):
			movement.x -= 1
		if Input.is_action_pressed("right"):
			movement.x += 1
		movement = movement.normalized()
	
	# Return the movement normalized
	return movement

func get_movement_from_value(value: float, sensitivity: int):
	# If the value is 0, return that
	if value == 0.0:
		return 0.0
	
	var absValue = abs(value)
	var signValue = value / absValue
	var powered = pow(1 + absValue, sensitivity)
	
	var movement = powered * value
	if movement < movementZeroThreshhold and movement > -movementZeroThreshhold:
		return 0.0
	# Return the powered value times the value
	return movement

func take_damage(damage: float):
	if not invulnerable:
		var previousHealth = health
		
		health -= 1.0
		
		if health <= 0:
			# We are dead
			isDead = true
			# Remove a life
			lives -= 1
			# Tell everyone we died
			emit_signal("death", lives)
			# Player our death animation
			play_death()
		else:
			invulnerable = true
			$PlayerAnimations.play("Flash")
			
			update_shield(previousHealth)

func respawn(_position: Vector2):
	# Leave cinematic mode
	set_cinematic_mode(false)
	# Move ourselves to the target point
	position = _position
	# Reset our health
	health = 1.0
	# Make ourselves visible
	$Sprite.visible = true
	# We are no longer dead
	isDead = false
	# Invulnerable and flash
	invulnerable = true
	$PlayerAnimations.play("Flash")

###### POWERUPS #####

func weapon_up():
	powerupLevel += 1
	
	# Play our powerup sound
	if not Settings.soundFXOff:
		$Sounds/PowerupGained.play()

func shield_up():
	# Save our previous health
	var previousHealth = health
	
	# Increase health
	health = clamp(health + 1, 1.0, 3.0)
	
	# Update shields
	update_shield(previousHealth)
	
	# Play our powerup sound
	if not Settings.soundFXOff:
		$Sounds/PowerupGained.play()

func update_shield(previousHealth: float):
	# Define a start and end color based on health
	var startColor: Color
	var endColor: Color
	
	# Define the starting color
	if previousHealth == 1:
		startColor = Constants.shieldGone
	elif previousHealth == 2:
		startColor = Constants.shieldWhite
	elif previousHealth == 3:
		startColor = Constants.shieldBlue
	
	# Define the ending color
	if health == 1:
		endColor = Constants.shieldGone
	elif health == 2:
		endColor = Constants.shieldWhite
	elif health == 3:
		endColor = Constants.shieldBlue
	
	# Run the fade tween
	$ShieldFade.interpolate_property(get_shield_sprite(),
									"modulate",
									startColor,
									endColor,
									shieldFadeTime,
									Tween.TRANS_LINEAR,
									Tween.EASE_IN)
	$ShieldFade.start()

##### ANIMATIONS #####

func play_death():
	set_cinematic_mode(true)
	$Sounds/DeathStart.play()
	$PlayerAnimations.play("Death")

func play_enter_scene():
	$PlayerAnimations.play("MoveFromBottom")

##### GETTERS #####

func is_dead():
	return isDead

func get_sprite():
	return $Sprite

func get_shield_sprite():
	return $Sprite/ShipShields

func get_width():
	return get_sprite().texture.get_width() * scale.x

func get_accelerometer():
	if Constants.isAndroid:
		return Input.get_accelerometer() / 10
	else:
		return Input.get_accelerometer()

##### SETTERS #####

func set_accelerometer():
	accelerometerBase = get_accelerometer()

func set_cinematic_mode(cinematic: bool):
	# If we want cinematic mode
	if cinematic:
		# Make him uncontrollable, and disable his physics body
		controllable = false
		$ShipCollider.set_deferred("disabled", true)
	else:
		# Otherwise, do the opposite, it's game time
		controllable = true
		$ShipCollider.set_deferred("disabled", false)

##### Signals #####

func _on_ShootTimer_timeout():
	canShoot = true

func _on_PowerTimer_timeout():
	canUsePower = true

func _on_SwipeDetection_swipe(direction: String):
	if direction == "up":
		use_power()

func _on_PlayerAnimations_animation_finished(anim_name: String):
	# If it was our flashing animation
	if anim_name == "Flash":
		invulnerable = false
	elif anim_name == "Death":
		$DeathNodes/RespawnTimer.start()

func _on_RespawnTimer_timeout():
	# If we still have lives, respawn
	if lives > 0:
		emit_signal("respawn")
	# Otherwise, we lost
	else:
		emit_signal("lost")

func _on_reset():
	# We are not dead
	isDead = false
	# Make sure we are visible
	get_sprite().visible = true
	# Make sure we are scaled correctly
	get_sprite().scale = Vector2(1, 1)
	# Reset lives
	lives = 3
	# Reset health
	health = 1.0
	# Reset weapon level
	powerupLevel = Constants.powerupFowardBlast
