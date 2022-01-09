extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	get_node("BackgroundGas").material.set_shader_param("speed_scale", -0.002)
	get_node("BackgroundStar1").material.set_shader_param("speed_scale", -0.015)
	get_node("BackgroundStar2").material.set_shader_param("speed_scale", -0.025)
