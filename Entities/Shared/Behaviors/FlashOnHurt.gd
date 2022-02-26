extends Node

var flashingHurt = false
var sprite

# Called when the node enters the scene tree for the first time.
func _ready():
	# Connect the parent hurt signal to our flash
	get_parent().connect("hurt", self, "_on_hurt_flash")
	# Make sure our parent has a get_sprite function
	if get_parent().has_method("get_sprite"):
		sprite = get_parent().get_sprite()


func _on_hurt_flash():
	if not flashingHurt:
		flashingHurt = true
		
		$ColorGray.interpolate_property(sprite, 
										"modulate",
										sprite.modulate,
										Constants.enemyHitColor,
										Constants.flashHurtTime,
										Tween.TRANS_LINEAR,
										Tween.EASE_IN)
		$ColorGray.start()

func _on_ColorGray_tween_completed(object, key):
	$ColorNormal.interpolate_property(sprite, 
										"modulate",
										sprite.modulate,
										Constants.enemyNormalColor,
										Constants.flashHurtTime,
										Tween.TRANS_LINEAR,
										Tween.EASE_IN)
	# Color ourselves normally
	$ColorNormal.start()

func _on_ColorNormal_tween_completed(object, key):
	flashingHurt = false
