# module_2d_materials.gd
extends Node2D
class_name Module2DMaterials

@onready var light: PointLight2D = $LightingRig/PointLight2D
@onready var occluder: LightOccluder2D = $LightingRig/LightOccluder2D

var time_passed: float = 0.0

func _process(delta: float) -> void:
	time_passed += delta
	# Orbit the 2D light source around the occluder to demonstrate dynamic shadow casting
	light.position = Vector2(850, 300) + Vector2(cos(time_passed * 2.0) * 120.0, sin(time_passed * 2.0) * 80.0)
	queue_redraw()

func _draw() -> void:
	# Draw background bounding boxes for blend mode tiles
	draw_rect(Rect2(50, 120, 180, 180), Color(0.15, 0.18, 0.25, 0.8), false, 2.0)
	draw_rect(Rect2(270, 120, 180, 180), Color(0.15, 0.18, 0.25, 0.8), false, 2.0)
	draw_rect(Rect2(490, 120, 180, 180), Color(0.15, 0.18, 0.25, 0.8), false, 2.0)
	draw_rect(Rect2(710, 120, 380, 480), Color(0.15, 0.18, 0.25, 0.8), false, 2.0)
