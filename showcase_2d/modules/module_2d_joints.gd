# module_2d_joints.gd
extends Node2D
class_name Module2DJoints

@onready var pin_bob: RigidBody2D = $PinSection/PinBob
@onready var spring_weight: RigidBody2D = $SpringSection/SpringWeight
@onready var groove_piston: RigidBody2D = $GrooveSection/GroovePiston
@onready var raycast: RayCast2D = $RaySection/RayCast2D
@onready var laser_line: Line2D = $RaySection/LaserLine
@onready var shape_cast: ShapeCast2D = get_node_or_null("RaySection/ShapeCast2D")
@onready var shape_line: Line2D = get_node_or_null("RaySection/ShapeLine")

var has_detected_obstacle: bool = false
var has_shape_detected: bool = false
var ray_angle: float = 0.0

func _ready() -> void:
	if pin_bob:
		pin_bob.apply_impulse(Vector2(200, 0))
	if spring_weight:
		spring_weight.apply_impulse(Vector2(0, 300))
	if groove_piston:
		groove_piston.apply_impulse(Vector2(0, 100))

func _physics_process(delta: float) -> void:
	ray_angle += delta * 1.0
	# Sweep +- 30 degrees across obstacle at (100, 0)
	var sweep = sin(ray_angle) * 0.5
	var dir = Vector2(cos(sweep), sin(sweep))
	
	if raycast:
		raycast.target_position = dir * 200.0
		raycast.force_raycast_update()
		if raycast.is_colliding():
			has_detected_obstacle = true
		
		if laser_line:
			laser_line.clear_points()
			laser_line.add_point(Vector2.ZERO)
			if raycast.is_colliding():
				var hit_local = raycast.to_local(raycast.get_collision_point())
				laser_line.add_point(hit_local)
			else:
				laser_line.add_point(raycast.target_position)

	if shape_cast:
		shape_cast.target_position = dir * 180.0
		shape_cast.force_shapecast_update()
		if shape_cast.is_colliding():
			has_shape_detected = true
		if shape_line:
			shape_line.clear_points()
			shape_line.add_point(Vector2.ZERO)
			if shape_cast.is_colliding():
				var hit_local = shape_cast.to_local(shape_cast.get_collision_point(0))
				shape_line.add_point(hit_local)
			else:
				shape_line.add_point(shape_cast.target_position)

	queue_redraw()

func _draw() -> void:
	if has_node("PinSection/PinAnchor") and pin_bob:
		draw_line($PinSection/PinAnchor.position, pin_bob.position, Color(0.6, 0.6, 0.7), 3.0)
	if has_node("SpringSection/SpringAnchor") and spring_weight:
		draw_line($SpringSection/SpringAnchor.position, spring_weight.position, Color(0.9, 0.4, 0.4), 2.0)
