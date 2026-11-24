# ball_2d.gd
extends Area2D
class_name Ball2D

signal dragged(new_position: Vector2)
signal dropped(final_position: Vector2)

@export var radius: float = 35.0
@export var ball_color: Color = Color(0.95, 0.25, 0.35, 1.0)
@export var drag_color: Color = Color(1.0, 0.55, 0.2, 1.0)

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var initial_position: Vector2 = Vector2(250, 324)

func _ready() -> void:
	position = initial_position
	input_pickable = true
	
	if not has_node("CollisionShape2D"):
		var col = CollisionShape2D.new()
		var circle = CircleShape2D.new()
		circle.radius = radius
		col.shape = circle
		add_child(col)
		
	input_event.connect(_on_input_event)

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius + 4.0, Color(0, 0, 0, 0.4))
	var current_color = drag_color if is_dragging else ball_color
	draw_circle(Vector2.ZERO, radius, current_color)
	draw_circle(Vector2(-radius * 0.3, -radius * 0.3), radius * 0.35, Color(1, 1, 1, 0.6))

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not is_dragging:
			start_drag(event.position)

func _unhandled_input(event: InputEvent) -> void:
	if is_dragging:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			stop_drag(event.position)
		elif event is InputEventMouseMotion:
			position = event.position + drag_offset
			queue_redraw()
			dragged.emit(position)

func start_drag(mouse_pos: Vector2) -> void:
	is_dragging = true
	drag_offset = position - mouse_pos
	queue_redraw()

func stop_drag(mouse_pos: Vector2) -> void:
	is_dragging = false
	position = mouse_pos + drag_offset
	queue_redraw()
	dropped.emit(position)

func reset_position() -> void:
	is_dragging = false
	position = initial_position
	queue_redraw()
