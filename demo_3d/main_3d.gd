# main_3d.gd
extends Node3D
class_name Main3D

const GSS = preload("res://addons/gdtest/core/gss.gd")

@export var score: int = 0

@onready var camera: Camera3D = $Camera3D
@onready var target_sphere: TargetSphere3D = $TargetSphere3D
@onready var goal_pedestal: GoalPedestal3D = $GoalPedestal3D
@onready var status_label: Label = $CanvasLayer/HUD/StatusLabel
@onready var coords_label: Label = $CanvasLayer/HUD/CoordsLabel
@onready var score_label: Label = $CanvasLayer/HUD/Header/ScoreLabel
@onready var reset_button: Button = $CanvasLayer/HUD/ResetButton

func _ready() -> void:
	GSS.install_hotkey_listener(self)
	target_sphere.dragged.connect(_on_sphere_dragged)
	target_sphere.dropped.connect(_on_sphere_dropped)
	goal_pedestal.goal_reached.connect(_on_goal_reached)
	goal_pedestal.goal_exited.connect(_on_goal_exited)
	reset_button.pressed.connect(_on_reset_pressed)
	update_ui()

func _process(_delta: float) -> void:
	var screen_pos = camera.unproject_position(target_sphere.global_position)
	coords_label.text = "3D Sphere: (%.2f, %.2f, %.2f) | Screen: (%.1f, %.1f)" % [
		target_sphere.global_position.x,
		target_sphere.global_position.y,
		target_sphere.global_position.z,
		screen_pos.x,
		screen_pos.y
	]

func _on_goal_reached() -> void:
	score += 100
	status_label.text = "🎯 3D GOAL REACHED! +100 Points"
	status_label.modulate = Color(0.2, 1.0, 0.4)
	update_ui()

func _on_goal_exited() -> void:
	status_label.text = "Sphere moved away from Goal Pedestal"
	status_label.modulate = Color(0.8, 0.8, 0.8)

func _on_sphere_dragged(_pos: Vector3) -> void:
	status_label.text = "Dragging 3D Sphere..."
	status_label.modulate = Color(1.0, 0.8, 0.2)

func _on_sphere_dropped(_pos: Vector3) -> void:
	if not goal_pedestal.is_active:
		status_label.text = "Sphere Dropped Outside Goal"
		status_label.modulate = Color(0.8, 0.8, 0.8)

func _on_reset_pressed() -> void:
	score = 0
	target_sphere.reset_position()
	goal_pedestal.reset_pedestal()
	status_label.text = "Game Reset. Click & Drag 3D Sphere onto the Pedestal!"
	status_label.modulate = Color(1.0, 1.0, 1.0)
	update_ui()

func update_ui() -> void:
	score_label.text = "SCORE: %04d" % score
