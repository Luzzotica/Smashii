extends Node2D

export(PackedScene) var Asteroid
export(PackedScene) var HumanShooter
export(PackedScene) var HumanKamikaze
export(PackedScene) var HumanSniper
export(PackedScene) var HumanProducer
export(float) var enemyHealthScale = 1.0
export(float) var enemyHealthScalePerWaveDuring = 0.06
export(float) var enemyHealthScalePerWaveEnd = 0.1
export(int) var difficulty = 1
export(String) var waveMode = Constants.WAVE_MODE.REPEAT
export(String) var scaleModeDuring = Constants.SCALE_MODE.LINEAR
export(String) var scaleModeEnd = Constants.SCALE_MODE.EXP

var waveData: Array = Constants.ENEMY_WAVE_DATA_GENERIC
var enemyHealthScaleBase = enemyHealthScale
export(int) var currentWave = 0
export(int) var totalWaves = 0


func _ready():
	# Setup all signals
	setup_signals()
	
	# Attempt to spawn a wave
	check_spawn_wave()

##### WAVE HANDLING #####

func set_wave_data(data: Array):
	waveData = data

func check_spawn_wave():
	# If the tree is null, stop, sometimes this happens...?
	if get_tree() == null:
		return
	# Track all of the enemies, if there are none left, spawn a new wave
	if (len(get_tree().get_nodes_in_group("Enemies")) == 0):
		spawn_wave()

func spawn_wave():
	var wave = get_wave_info()
	
	# Asteroids
	if Constants.ASTEROID in wave.keys():
		spawn_asteroid(wave[Constants.ASTEROID], enemyHealthScale)
	# Human Shooter
	if Constants.HUMAN_SHOOTER in wave.keys():
		var groups = [Constants.SIGNAL_GROUPS.HAS_SHOOT]
		spawn_enemy(HumanShooter, groups, wave[Constants.HUMAN_SHOOTER], enemyHealthScale)
	# Human Kamikaze
	if Constants.HUMAN_KAMIKAZE in wave.keys():
		var groups = [Constants.SIGNAL_GROUPS.HAS_SHOOT]
		spawn_enemy(HumanKamikaze, groups, wave[Constants.HUMAN_KAMIKAZE], enemyHealthScale)
	# Human Sniper
	if Constants.HUMAN_SNIPER in wave.keys():
		var groups = [Constants.SIGNAL_GROUPS.HAS_SHOOT]
		spawn_enemy(HumanSniper, groups, wave[Constants.HUMAN_SNIPER], enemyHealthScale)
	# Human Producer
	if Constants.HUMAN_PRODUCER in wave.keys():
		var groups = [Constants.SIGNAL_GROUPS.HAS_PRODUCE]
		spawn_enemy(HumanProducer, groups, wave[Constants.HUMAN_PRODUCER], enemyHealthScale)
	
	# Increment the wave
	currentWave += 1
	totalWaves += 1

func spawn_asteroid(count, healthScale):
	for i in range(count):
		var e = Asteroid.instance()
		e.position = get_point_in_spawn()
		e.add_to_group("Asteroids")
		setup_asteroid(e, healthScale)
		call_deferred("add_child", e)

func spawn_enemy(EnemyScene, groups, count, healthScale):
	for i in range(count):
		var e = EnemyScene.instance()
		e.position = get_point_in_spawn()
		e.add_to_group("Enemies")
		# Add the enemy to all identifying groups
		for group in groups:
			e.add_to_group(group)
		setup_enemy(e, healthScale)
		call_deferred("add_child", e)
		
		# If the enemy has a place for the player, give it to them
		if e.has_method("set_target_player"):
			e.set_target_player(get_player())

func get_wave_info():
	var waveSpawn = get_wave_spawn()
	# Set wave health
	set_wave_health()
	
	return waveSpawn

func get_wave_spawn():
	if currentWave >= waveData.size():
		# Repeat the last wave
		if waveMode == Constants.WAVE_MODE.REPEAT:
			return waveData[waveData.size() - 1]
		# Or restart the ways if that's what we want
		elif waveMode == Constants.WAVE_MODE.LOOP:
			currentWave = 0
			return waveData[currentWave]
	else:
		return waveData[currentWave]

func set_wave_health():
	if currentWave >= waveData.size():
		set_health_with_scale(Constants.PERIOD.END, scaleModeEnd)
	else:
		set_health_with_scale(Constants.PERIOD.DURING, scaleModeDuring)

func set_health_with_scale(period, scaleMode):
	# No scaling
	if scaleMode == Constants.SCALE_MODE.NONE:
		enemyHealthScale = 1.0
	# Linear
	if scaleMode == Constants.SCALE_MODE.LINEAR:
		var wavesOffset = 0
		var perWaveScale = enemyHealthScalePerWaveDuring
		# If scaling in the end, and we weren't scaling health before, start from last level
		if (period == Constants.PERIOD.END and 
			scaleModeDuring == Constants.SCALE_MODE.NONE):
				wavesOffset = waveData.size()
				perWaveScale = enemyHealthScalePerWaveEnd
		# Set the health scale to the base + scale per wave * wavesOffset
		enemyHealthScale = (enemyHealthScaleBase + 
							(perWaveScale * 
							(totalWaves - wavesOffset)))
	
	# Exponential
	elif scaleMode == Constants.SCALE_MODE.EXP:
		# Reset to base each time we scale
		enemyHealthScale = enemyHealthScaleBase
		var wavesOffset = 0
		var perWaveScale = enemyHealthScalePerWaveDuring
		# If scaling in the end, and we weren't scaling health before, start from last level
		if (period == Constants.PERIOD.END and 
			scaleModeDuring == Constants.SCALE_MODE.NONE):
				wavesOffset = waveData.size()
				perWaveScale = enemyHealthScalePerWaveEnd
		# Scale the health exponentially
		for i in range(totalWaves - wavesOffset):
			enemyHealthScale *= (1.0 + perWaveScale)
	
	else:
		enemyHealthScale = 1.0

##### SIGNAL SETUP #####

func setup_signals():
	# Loop through all the players and connect them up
	for player in get_tree().get_nodes_in_group("Player"):
		player.connect("shoot", self, "_on_Player_shoot")
		player.connect("usePower", self, "_on_Player_usePower")
#		player.connect("usePower", get_powerup_ui(), "_on_Player_usePower")
		player.connect("respawn", self, "_on_Player_respawn")
#		player.connect("death", get_lives_ui(), "_on_Player_death")
#		player.connect("death", self, "_on_Player_death")
	
	# Loop through each enemy and connect them up
	for enemy in get_tree().get_nodes_in_group("Enemies"):
		setup_enemy(enemy, enemyHealthScale)
	
	# Loop through each asteroid and connect them up
	for asteroid in get_tree().get_nodes_in_group("Asteroids"):
		setup_asteroid(asteroid, enemyHealthScale)

func setup_enemy(enemy, healthScale):
	
	enemy.connect("death", self, "_on_Enemy_death")
	enemy.connect("removed", self, "_on_Enemy_removed")
	enemy.connect("tree_exited", self, "_on_Enemy_removed")
	# If the enemy can shoot, wire it up
	if enemy.is_in_group(Constants.SIGNAL_GROUPS.HAS_SHOOT):
		enemy.connect("shoot", self, "_on_Enemy_shoot")
	# If the enemy can produce, wire it up
	if enemy.is_in_group(Constants.SIGNAL_GROUPS.HAS_PRODUCE):
		enemy.connect("produce", self, "_on_Producer_produce")
	# Scale health
	enemy.health *= healthScale

func setup_asteroid(asteroid, healthScale):
	asteroid.connect("death", self, "_on_Asteroid_death")
	# Scale health
#	asteroid.health *= healthScale

##### GETTERS #####

func get_player():
	return get_tree().get_nodes_in_group("Player")[0]

func get_point_in_spawn():
	return Util.getRandomPointInArea(Constants.spawnAreaCenter, 
									Constants.spawnAreaSize)

##### PLAYER SIGNALS #####

func _on_Player_shoot(bulletPackages, powerupLevel):
	# Look through each bullet we want to shoot
	for bulletPackage in bulletPackages:
		
		# Create an instance of that bullet
		var b = bulletPackage[0].instance()
		
		# Add the bullet to the player bullet group
		b.add_to_group("PlayerBullets")
		
		# Start the bullet with the position and rotation and powerup level
		b.start(bulletPackage[1], bulletPackage[2], powerupLevel)
		call_deferred("add_child", b)

func _on_Player_usePower(powerObject, _position, _direction, cooldown):
	var p = powerObject.instance()
	p.add_to_group("PlayerBullets")
	p.start(_position, _direction)
	call_deferred("add_child", p)

func _on_Player_death(lives):
	pass

func _on_Player_respawn():
	var _position = $RespawnPoint.global_position
	get_player().respawn(_position)

##### ENEMY SIGNALS #####

func _on_Enemy_shoot(Bullet, _position, _direction):
	var p = Bullet.instance()
	p.add_to_group("Bullets")
	p.start(_position, _direction)
	call_deferred("add_child", p)

func _on_Enemy_death(scoreOnKill):
	# Add to our score if it is greater than 0
	if scoreOnKill > 0:
		ScoreManager.add_to_score(scoreOnKill)

func _on_Enemy_removed():
	check_spawn_wave()

func _on_Producer_produce(Bot, botType, Producer, _position, _direction, movePoint):
	var p = Bot.instance()
	# Make sure the producer knows when the bot dies
	if botType == Constants.humanProducerBotTypes.ATTACKER:
		p.connect("death", Producer, "_on_AttackBot_death")
		# Attacker can shoot
		p.add_to_group(Constants.SIGNAL_GROUPS.HAS_SHOOT)
	elif botType == Constants.humanProducerBotTypes.DEFENDER:
		p.connect("death", Producer, "_on_DefenseBot_death")
	# Make sure the children know when the parent dies
	Producer.connect("death", p, "_on_parent_death")
	# Make sure the bot knows who its parent is
	p.set_parent_producer(Producer)
	# Setup the bot
	setup_enemy(p, enemyHealthScale)
	
	# Start the bot
	p.start(_position, _direction, movePoint)
	# Add it to the scene
	call_deferred("add_child", p)

##### ASTEROID SIGNALS #####

func _on_Asteroid_death(spawnPowerup, _position, scoreOnKill):
	# Add to our score
	ScoreManager.add_to_score(scoreOnKill)
	
	# If we don't want to spawn a powerup, stop
	if not spawnPowerup:
		return
	
	# Get the player health
	var playerHealth = get_player().health
	
	# Get probability of spawning different powerups based on health
	var shieldProbability = 0.4
	if playerHealth == 2:
		shieldProbability = 0.15
	elif playerHealth == 3:
		shieldProbability = -1.0
	
	# Randomize powerup and create it
	var rand = randf()
	var powerup
	if rand > shieldProbability:
		powerup = get_player().WeaponUp.instance()
	else:
		powerup = get_player().ShieldUp.instance()
	
	# Add powerup to our group
	powerup.add_to_group("Powerups")
	# Add it to the scene
	call_deferred("add_child", powerup) #add_child(powerup)
	# put it where the asteroid died
	powerup.start(_position, 0.0)

##### GENERIC SIGNALS #####

func _on_Arcade_reset():
	# Kill everything!
	for bullet in get_tree().get_nodes_in_group("PlayerBullets"):
		bullet.queue_free()
	
	for enemy in get_tree().get_nodes_in_group("Enemies"):
		enemy.queue_free()
	
	for asteroid in get_tree().get_nodes_in_group("Asteroids"):
		asteroid.queue_free()
	
	for bullet in get_tree().get_nodes_in_group("Bullets"):
		bullet.queue_free()
	
	for powerup in get_tree().get_nodes_in_group("Powerups"):
		powerup.queue_free()
	
	# Reset waves
	currentWave = 0
	totalWaves = 0
	enemyHealthScale = 1.0
	difficulty = 1
