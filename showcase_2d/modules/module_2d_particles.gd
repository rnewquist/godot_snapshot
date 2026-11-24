# module_2d_particles.gd
extends Node2D
class_name Module2DParticles

@onready var path_follow: PathFollow2D = $PathSection/Path2D/PathFollow2D
@onready var poly: Polygon2D = $PolygonSection/Polygon2D

var time_passed: float = 0.0

func _process(delta: float) -> void:
	time_passed += delta
	# Advance PathFollow2D along the bezier spline
	if path_follow:
		path_follow.progress += delta * 180.0
		
	# Animate polygon vertices for organic deformation
	if poly:
		var base_poly = PackedVector2Array([
			Vector2(-50, -50) + Vector2(sin(time_passed * 3.0) * 10, 0),
			Vector2(50, -40) + Vector2(0, cos(time_passed * 3.0) * 10),
			Vector2(60, 50) + Vector2(-sin(time_passed * 2.5) * 10, 0),
			Vector2(-40, 60) + Vector2(0, -cos(time_passed * 2.5) * 10)
		])
		poly.polygon = base_poly
