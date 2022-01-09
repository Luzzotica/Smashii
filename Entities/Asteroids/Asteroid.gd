extends Area2D

export(float) var health = 10.0
export(float) var speed = 200
export(float) var spread = 90
export(float) var damage = 10.0
export(int) var scoreOnKill = 25
export(PackedScene) var WeaponUp
export(PackedScene) var ShieldUp

var velocity: Vector2
var isDead = false

signal death(spawnPowerup, _position, scoreOnKill)

# Called when the node enters the scene tree for the first time.
func _ready():
	# Get random angle and shoot us in that direction
	var angle = spread * randf() - spread / 2.0
	
	# Setup out velocity
	var dir = Vector2(0, 1).rotated(deg2rad(angle))
	velocity = dir * speed
	
	set_process(true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position += velocity * delta

func death(createPowerup = true):
	# We are dying
	isDead = true
	
	# TODO: Randomize the powerup drop based on player's shield status
	# Tell the scene that an asteroid died
	emit_signal("death", createPowerup, global_position, scoreOnKill)
	
	# Stop his tick
	set_process(false)
	
	if not Settings.soundFXOff:
		$AsteroidDeath.play()
	
	# Make him not collide with anything
	$CollisionShape2D.queue_free()
	
	# Make him invisible
	get_sprite().visible = false
	
	# Start explosion, and timer to remove from scene
	$DeathNodes/DeathParticles.emitting = true
	$DeathNodes/WaitAfterDeath.start()

func take_damage(damage: float):
	health -= damage
	
	if health <= 0.0:
		death()

##### GETTERS #####

func is_dead():
	return isDead

func get_sprite_container():
	return $Sprites

func get_sprite():
	return $Sprites/Sprite

func get_width():
	return get_sprite().texture.get_width() * get_sprite_container().scale.x

##### SINGALS #####

func _on_WaitAfterDeath_timeout():
	# Remove ourselves from the scene
	queue_free()

func _on_Asteroid_body_entered(body):
	if body.has_method("is_dead"):
		if body.is_dead():
			return
	
	# If the body we hit has the method take damage, then call it
	if body.has_method("take_damage"):
		body.take_damage(damage)
