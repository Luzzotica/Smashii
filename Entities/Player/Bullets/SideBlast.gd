extends Area2D

export (float) var speed = 5.0
export (int) var damage = 6
export (float) var lifetime = 5.0

var velocity = Vector2()

func start(_position, _rotation, powerupLevel):
	var realPowerupLevel = powerupLevel - Constants.powerupSideBlast
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
	$ParticleTrail.modulate = Constants.powerupColors[clamp(powerupLevel, 0, 2)]
	$DeathNodes/BlastDeathParticles.modulate = Constants.powerupColors[clamp(powerupLevel, 0, 2)]

func _process(delta):
	# Move ourselves
	position += velocity * delta

func explode():
	# Don't tick
	set_process(false)
	
	# Don't hit anything
	$BulletColliderShape.queue_free()
	
	# Hide ourselves
	$BulletInner.visible = false
	$BulletOuter.visible = false
	
	# Stop trail from emitting
	$ParticleTrail.emitting = false
	
	# Start explosion, and timer to remove from scene
	$DeathNodes/BlastDeathParticles.emitting = true
	$DeathNodes/WaitAfterDeath.start()

func hit_body(body):
	# Explode
	explode()
	
	# If the body we hit has the method take damage, then call it
	if body.has_method("take_damage"):
		body.take_damage(damage)

##### SIGNALS #####

func _on_Lifetime_timeout():
	# Explode
	queue_free()

func _on_Bullet_body_entered(body):
	hit_body(body)

func _on_WaitAfterDeath_timeout():
	queue_free()

func _on_Bullet_area_entered(area):
	hit_body(area)
