extends Area2D

export (float) var speed = 300
export (float) var damage = 1.0
export (float) var lifetime = 5.0

var velocity = Vector2()

func _ready():
	# Change color based on power level
	$Sprites/BulletOuter.modulate = Constants.humanSniperBlastColor
	$ParticleTrail.modulate = Constants.humanSniperBlastColor
	$DeathNodes/BlastDeathParticles.modulate = Constants.humanSniperBlastColor

func start(_position, _rotation):
	# Setup bullet position and angle
	position = _position
	rotation = _rotation
	
	# Setup out velocity
	var dir = Vector2(0, 1).rotated(_rotation)
	velocity = dir * speed
	
	# Define a lifetime, very valuable
	$Lifetime.start(lifetime)

func _process(delta):
	# Move ourselves
	position += velocity * delta

func explode():
	# Don't tick
	set_process(false)
	
	# Don't hit anything
	$BulletColliderShape.queue_free()
	
	# Hide ourselves
	$Sprites/BulletInner.visible = false
	$Sprites/BulletOuter.visible = false
	
	# Stop trail from emitting
	$ParticleTrail.emitting = false
	
	# Start explosion, and timer to remove from scene
	$DeathNodes/BlastDeathParticles.emitting = true
	$DeathNodes/WaitAfterDeath.start()

##### SIGNALS #####

func _on_Lifetime_timeout():
	queue_free()

func _on_Bullet_body_entered(body):
	# If the body is dead, don't do anything
	if body.has_method("is_dead"):
		if body.is_dead():
			return
	
	# Explode
	explode()
	
	# If the body we hit has the method take damage, then call it
	if body.has_method("take_damage"):
		body.take_damage(damage)

func _on_WaitAfterDeath_timeout():
	# Remove ourselves from the scene
	queue_free()
