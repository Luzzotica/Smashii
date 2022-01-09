extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func play_cooldown_animation(time: float):
	# Setup the playback speed
	$Darkening/AnimationPlayer.playback_speed = 1 / time
	
	# Run the animation
	$Darkening/AnimationPlayer.play("Cooldown")

func _on_Player_usePower(powerObject, _position, _direction, cooldown):
	play_cooldown_animation(cooldown)

func _on_Arcade_powerUsed(cooldown):
	play_cooldown_animation(cooldown)
