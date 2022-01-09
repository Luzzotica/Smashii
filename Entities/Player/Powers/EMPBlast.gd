extends Area2D

export (float) var speed = 450.0
export (float) var lifetime = 5.0
export (float) var stunTime = 4.0
export (PackedScene) var stunBehavior

var velocity = Vector2()

func start(_position, _rotation):
	# Setup bullet position and angle
	position = _position
	rotation = _rotation
	
	# Setup out velocity
	var dir = Vector2(0, -1).rotated(_rotation)
	velocity = dir * speed
	
	# Define a lifetime, very valuable
	$Lifetime.wait_time = lifetime

func _process(delta):
	# Move ourselves
	position += velocity * delta

##### SIGNALS #####

func _on_Lifetime_timeout():
	queue_free()

func _on_EMP_body_entered(body):
	# Attach the stun behavior to everyone we hit
	var stunB = stunBehavior.instance()
	body.add_child(stunB)
	# Start the stun
	stunB.start(stunTime)

func _on_EMP_area_entered(area):
	# Destroy bullets
	if area.has_method("explode"):
		area.explode()
	else:
		# Attach the stun behavior to everyone we hit
		var stunB = stunBehavior.instance()
		area.add_child(stunB)
		# Start the stun
		stunB.start(stunTime)
