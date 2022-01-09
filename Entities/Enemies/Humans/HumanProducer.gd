extends KinematicBody2D

##### GENERIC VARS #####
export(float) var health = 110.0
export(int) var scoreOnKill = 100
export(float) var moveSpeed = 50.0
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
export(PackedScene) var AttackBot
export(PackedScene) var DefenseBot
export(float) var waitAfterProduce = 1.0
export(int) var attackBotProduceCount = 3
export(int) var defenseBotProduceCount = 4
export(int) var attackBotMax = 4
export(int) var defenseBotMax = 5
export(float) var stutterProduction = 0.9

var productionBotMade = 0
var attackBotCount = 0
var defenseBotCount = 0

signal produce(Bot, botType, Producer, _position,  _direction, movePoint)
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
	$Timers/StutterProduction.wait_time = stutterProduction
	$Timers/WaitAfterProduce.wait_time = waitAfterProduce
	
	set_process(true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	# If we have no orders, do something!
	if currentOrder == "":
		# If we can still make bots, see if we want to make them
		if not is_maxed_attackers() or not is_maxed_defenders():
			# Get a random float between 0 and 1
			var rand = randf()
			# If we we have moved at least once, 90% change to produce
			if ordersSinceLastAction == 1 and rand > 0.1:
				handle_production()
			elif ordersSinceLastAction >= 2:
				handle_production()
			else:
				move_to_random_location()
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
	
	if (currentOrder == Constants.genericOrders.WAIT or
		currentOrder == Constants.humanProducerOrders.CREATE_ATTACKERS or
		currentOrder == Constants.humanProducerOrders.CREATE_DEFENDERS):
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
	
	# Otherwise, we are producing

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
	$Rear.queue_free()
	$Wings.queue_free()
	$Base.queue_free()
	$Front.queue_free()
	
	if not Settings.soundFXOff:
		$Sounds/Death.play()
	
	# Make him invisible
	get_sprite().visible = false
	
	# Start explosion, and timer to remove from scene
	$DeathNodes/HumanDeathParticles.emitting = true
	$DeathNodes/WaitAfterDeath.start()

##### PRODUCER FUNCTIONS #####

func handle_production():
	# ASSUMPTION: If we got here, something needs to be made
	# Reset the amount made to 0
	productionBotMade = 0
	
	# 50% chance to make either bot
	var randType = randf()
	currentOrder = Constants.humanProducerOrders.CREATE_ATTACKERS
	# If attackers are maxed out, make defenders
	if is_maxed_attackers() or (randType > 0.5 and not is_maxed_defenders()):
		currentOrder = Constants.humanProducerOrders.CREATE_DEFENDERS
	
	# Create a bot
	create_bot()
	# Start the timer to make more
	$Timers/StutterProduction.start()

func create_bot():
	# If we are dead, we can't make bots
	if isDead:
		return
	# Made another bot
	productionBotMade += 1
	# Get the bot to make
	var productionBot
	var botType
	if currentOrder == Constants.humanProducerOrders.CREATE_ATTACKERS:
		productionBot = AttackBot
		botType = Constants.humanProducerBotTypes.ATTACKER
		# Increment our bot count
		attackBotCount += 1
	elif currentOrder == Constants.humanProducerOrders.CREATE_DEFENDERS:
		productionBot = DefenseBot
		botType = Constants.humanProducerBotTypes.DEFENDER
		# Increment our bot count
		defenseBotCount += 1
	
	# Create the bot
	emit_signal("produce", productionBot, botType, self, 
				$SpawnMain.global_position, 
				$SpawnMain.global_rotation,
				$SpawnMove.global_position)
	# Play the creation sound
	$Sounds/ProduceOne.play()

func is_maxed_attackers():
	return attackBotCount >= attackBotMax

func is_maxed_defenders():
	return defenseBotCount >= defenseBotMax

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

func _on_WaitAfterProduce_timeout():
	# Reset all the things
	ordersSinceLastAction = 0
	
	# Remove the current order
	currentOrder = ""

func _on_Wait_timeout():
	currentOrder = ""

func _on_WaitAfterDeath_timeout():
	# Remove ourselves from the tree
	queue_free()

func _on_StutterProduction_timeout():
	# If we can still make more
	if currentOrder == Constants.humanProducerOrders.CREATE_ATTACKERS and not is_maxed_attackers():
		if productionBotMade < attackBotProduceCount:
			# Create the bot
			create_bot()
			# Restart the timer
			$Timers/StutterProduction.start()
			# Stop here
			return
	if currentOrder == Constants.humanProducerOrders.CREATE_DEFENDERS and not is_maxed_defenders():
		if productionBotMade < defenseBotProduceCount:
			# Create the bot
			create_bot()
			# Restart the timer
			$Timers/StutterProduction.start()
			# Stop here
			return
	
	# If we got here, we can't make anymore bots, so we stop
	productionBotMade = 0
	# Start the wait after production timer
	$Timers/WaitAfterProduce.start()
	
func _on_AttackBot_death(scoreOnKill):
	attackBotCount -= 1

func _on_DefenseBot_death(scoreOnKill):
	defenseBotCount -= 1

