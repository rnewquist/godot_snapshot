# module_3d_lighting.gd
extends Node3D
class_name Module3DLighting

@onready var omni_light: OmniLight3D = $OmniLight3D
@onready var spot_light: SpotLight3D = $SpotLight3D

var time_passed: float = 0.0

func _process(delta: float) -> void:
	time_passed += delta
	# Orbit the colored omni light
	if omni_light:
		omni_light.position = Vector3(cos(time_passed * 1.5) * 2.5, 1.8, sin(time_passed * 1.5) * 2.5)
	# Swing spotlight cone
	if spot_light:
		spot_light.rotation.y = sin(time_passed * 0.8) * 0.4
