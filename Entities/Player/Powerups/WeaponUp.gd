extends Area2D

export(float) var lifetime = 60.0
export(float) var speed = 40.0

var velocity: Vector2
var expended = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func start(_position, _rotation):
	# Setup position
	position = _position
	
	# Setup out velocity
	var dir = Vector2(0, 1).rotated(_rotation)
	velocity = dir * speed
	
	# Define a lifetime, very valuable
	$Lifetime.start(lifetime)
	
	# Make him tick
	set_process(true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Move ourselves
	position += velocity * delta

func _on_WeaponUp_body_entered(body):
	if not expended:
		expended = true
		body.weapon_up()
		
		ScoreManager.add_to_score(Constants.powerupScore)
	
	# Remove ourselves from the scene
	queue_free()
