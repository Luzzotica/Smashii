extends TextureButton

export(Texture) var onTexture
export(Texture) var offTexture

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func toggle(on: bool):
	if on:
		texture_normal = onTexture
	else:
		texture_normal = offTexture
