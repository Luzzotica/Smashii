extends KinematicBody2D

##### GENERIC VARS #####
export(float) var health = 65.0
export(int) var scoreOnKill = 0
export(float) var movespeed = 70.0
export(float) var moveAccuracy = 5.0
export(float) var wait = 0.2

var targetPlayer

var targetPoint: Vector2 = Vector2.ZERO
var currentOrder: String = ""

var areaCenter: Vector2
var areaSize: Vector2

var ordersSinceLastAction = 0

var isDead = false

##### PRODUCER DEFENDER VARS #####
export(float) var destroyAfterParentDeath = 4.0

var active
var parentProducer

signal shoot(Bullet, _position,  _direction)
signal death(scoreOnKill)
signal removed()
signal hurt()

# Called when the node enters the scene tree for the first time.
func _ready():
	var centerX = get_viewport().size.x / 2
	var centerY = get_viewport().size.y / 3.5
	
	areaCenter = Vector2(centerX, centerY)
	
	# Setup the wait for each of our timers
	$Timers/Wait.wait_time = wait
	$Timers/DestroyAfterParentDeath.wait_time = destroyAfterParentDeath
	
	set_process(true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	# If we have no orders, do something!
	if currentOrder == "" and active:
		# Defender only moves
		move_to_random_location()
	else:
		handle_order()

func move_to_random_location():
	# Increment our orders since last shooting
	ordersSinceLastAction += 1
	
	# Adjust our area based on our parent position
	var weakRef = weakref(parentProducer)
	# If the parent has not been freed, then change the center
	if weakRef.get_ref():
		if parentProducer.get("global_position"):
			var parentPosition = parentProducer.global_position
			areaCenter = Vector2(parentPosition.x, 
								parentPosition.y + areaSize.y)
	
	# Get a random point in our area and start to move there
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


func take_damage(damage: int):
	health -= damage
	
	# Flash when we get hurt
	emit_signal("hurt")
	
	if health <= 0:
		emit_signal("death", scoreOnKill)
		death()

func death():
	# If we are already dead, stop
	if isDead:
		return
	isDead = true
	
	# Stop his tick
	set_process(false)
	
	# Make him not collide with anything
	if has_node("Collider"):
		$Collider.queue_free()
	
	if not Settings.soundFXOff:
		$Sounds/Death.play()
	
	# Make him invisible
	get_sprite().visible = false
	
	# Start explosion, and timer to remove from scene
	$DeathNodes/HumanDeathParticles.emitting = true
	$DeathNodes/WaitAfterDeath.start()

##### PRODUCER BOT #####

func start(_position, _rotation, movePoint):
	position = _position
	rotation = _rotation
	# Set our move point
	targetPoint = movePoint
	# Set our current order to move
	currentOrder = Constants.genericOrders.MOVE
	# Increase our speed for start
	movespeed += Constants.botMovespeedStartIncrease

##### GETTERS #####

func is_dead():
	return isDead

func get_stun_time(time: float):
	return time

func get_sprite_container():
	return $Sprites

func get_sprite():
	return $Sprites/Sprite

func get_width():
	return get_sprite().texture.get_width() * get_sprite_container().scale.x

func get_timers():
	return $Timers.get_children()

##### SETTERS #####

func set_target_player(player):
	targetPlayer = player

func set_parent_producer(producer):
	parentProducer = producer
	
	# Setup the area of his movement to be in front of the producer
	var sizeX = producer.get_width() * 0.6
	var sizeY = producer.get_width() * 0.8
	areaSize =  Vector2(sizeX, sizeY)
	areaCenter = Vector2(producer.global_position.x, 
						producer.global_position.x + sizeY)

##### SIGNALS #####

func _on_Wait_timeout():
	if not active:
		active = true
		# Decrease speed
		movespeed -= Constants.botMovespeedStartIncrease
	currentOrder = ""

func _on_WaitAfterDeath_timeout():
	# Remove ourselves from the tree
	queue_free()

func _on_DestroyAfterParentDeath_timeout():
	# Kill ourselves
	death()

func _on_parent_death(scoreOnKill):
	$Timers/DestroyAfterParentDeath.start()

func _on_DestoryAfterParentDeath_timeout():
	# Kill ourselves
	death()
