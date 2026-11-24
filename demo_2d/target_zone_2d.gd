# target_zone_2d.gd
extends Area2D
class_name TargetZone2D

signal target_reached(score_points: int)

@export var zone_radius: float = 65.0
@export var default_color: Color = Color(0.2, 0.6, 0.9, 0.4)
@export var active_color: Color = Color(0.2, 0.9, 0.4, 0.8)
@export var points_awarded: int = 100

var is_active: bool = false

func _ready() -> void:
	# Ensure collision shape
	if not has_node("CollisionShape2D"):
		var col = CollisionShape2D.new()
		var circle = CircleShape2D.new()
		circle.radius = zone_radius
		col.shape = circle
		add_child(col)
	
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _draw() -> void:
	var color = active_color if is_active else default_color
	# Ring outline
	draw_arc(Vector2.ZERO, zone_radius, 0, TAU, 64, color, 4.0, true)
	# Center fill
	draw_circle(Vector2.ZERO, zone_radius - 4.0, Color(color.r, color.g, color.b, 0.25 if not is_active else 0.5))
	# Crosshairs
	draw_line(Vector2(-15, 0), Vector2(15, 0), color, 2.0)
	draw_line(Vector2(0, -15), Vector2(0, 15), color, 2.0)

func _on_area_entered(area: Area2D) -> void:
	if area is Ball2D:
		is_active = true
		queue_redraw()
		target_reached.emit(points_awarded)

func _on_area_exited(area: Area2D) -> void:
	if area is Ball2D:
		is_active = false
		queue_redraw()

func reset_zone() -> void:
	is_active = false
	queue_redraw()
