extends Node2D

var flashTime = 1.0
var sprite = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func start(time: float):
	
	var realTime = time
	# If they have a method to determine stun time, get the real stun time from it
	if get_parent().has_method("get_stun_time"):
		realTime = get_parent().get_stun_time(time)
	
	# Get the parent and stun them if they have the stun method
	if get_parent().has_method("stun"):
		var genericStun = get_parent().stun()
		# Start the stun timer
		$StunTimer.start(realTime)
		# If we want a generic stun
		if genericStun:
			stun_start()
			# Start generic animation if we have the info we need
			start_generic_animation()
	# Otherwise, just stop their process, run the generic animation
	else:
		stun_start()
		
		# Start the stun timer
		$StunTimer.start(realTime)
		# Start generic animation if we have the info we need
		start_generic_animation()

func stun_start():
	get_parent().set_process(false)
	
	# If the target has timers
	if get_parent().has_method("get_timers"):
		# We want to pause each of them
		var timers = get_parent().get_timers()
		for timer in timers:
			timer.paused = true

func stun_end():
	get_parent().set_process(true)
	
	# If the target has timers
	if get_parent().has_method("get_timers"):
		# We want to unpause each of them
		var timers = get_parent().get_timers()
		for timer in timers:
			timer.paused = false

func start_generic_animation():
	# If we can get the parent's sprite, we animate
	if not get_parent().has_method("get_sprite"):
		return
	sprite = get_parent().get_sprite()
	# Start up our stun animation
	$ColorStun.interpolate_property(sprite,
									"modulate",
									sprite.modulate,
									Constants.enemyStunColor,
									flashTime / 2.0,
									Tween.TRANS_LINEAR,
									Tween.EASE_IN)
	$ColorStun.start()

func _on_StunTimer_timeout():
	# Get the parent and unstun them if they have that method
	if get_parent().has_method("end_stun"):
		get_parent().end_stun()
	# Otherwise, start processing again
	else:
		stun_end()
	
	# Color them normally
	if sprite != null:
		$ColorFinish.interpolate_property(sprite,
										"modulate",
										sprite.modulate,
										Constants.enemyNormalColor,
										flashTime / 5.0,
										Tween.TRANS_LINEAR,
										Tween.EASE_IN)
		$ColorFinish.start()

func _on_ColorStun_tween_completed(object, key):
	# Color them stunned
	$ColorUnstun.interpolate_property(sprite,
									"modulate",
									sprite.modulate,
									Constants.enemyStunColor,
									flashTime / 2.0,
									Tween.TRANS_LINEAR,
									Tween.EASE_IN)
	$ColorUnstun.start()

func _on_ColorUnstun_tween_completed(object, key):
	# Color them stunned
	$ColorStun.interpolate_property(sprite,
									"modulate",
									sprite.modulate,
									Constants.enemyNormalColor,
									flashTime / 2.0,
									Tween.TRANS_LINEAR,
									Tween.EASE_IN)
	$ColorStun.start()

func _on_ColorFinish_tween_completed(object, key):
	# Remove ourselves from the parent, they are not longer stunned
	queue_free()
