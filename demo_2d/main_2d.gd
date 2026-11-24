# main_2d.gd
extends Node2D
class_name Main2D

const GSS = preload("res://addons/gdtest/core/gss.gd")

@export var score: int = 0

@onready var ball: Ball2D = $Ball2D
@onready var target_zone: TargetZone2D = $TargetZone2D
@onready var score_label: Label = $CanvasLayer/HUD/Header/ScoreLabel
@onready var status_label: Label = $CanvasLayer/HUD/StatusLabel
@onready var pos_label: Label = $CanvasLayer/HUD/PositionLabel
@onready var reset_button: Button = $CanvasLayer/HUD/ResetButton

func _ready() -> void:
	GSS.install_hotkey_listener(self)
	target_zone.target_reached.connect(_on_target_reached)
	ball.dragged.connect(_on_ball_dragged)
	ball.dropped.connect(_on_ball_dropped)
	reset_button.pressed.connect(_on_reset_pressed)
	update_ui()

func _on_target_reached(points: int) -> void:
	score += points
	status_label.text = "🎯 GOAL REACHED! +%d Points" % points
	status_label.modulate = Color(0.2, 1.0, 0.4)
	update_ui()

func _on_ball_dragged(pos: Vector2) -> void:
	status_label.text = "Dragging Ball..."
	status_label.modulate = Color(1.0, 0.8, 0.2)
	pos_label.text = "Ball Pos: (%.1f, %.1f)" % [pos.x, pos.y]

func _on_ball_dropped(pos: Vector2) -> void:
	pos_label.text = "Ball Pos: (%.1f, %.1f)" % [pos.x, pos.y]
	if not target_zone.is_active:
		status_label.text = "Ball Dropped Outside Target"
		status_label.modulate = Color(0.8, 0.8, 0.8)

func _on_reset_pressed() -> void:
	score = 0
	ball.reset_position()
	target_zone.reset_zone()
	status_label.text = "Game Reset. Click & Drag Ball to Target!"
	status_label.modulate = Color(1.0, 1.0, 1.0)
	pos_label.text = "Ball Pos: (%.1f, %.1f)" % [ball.position.x, ball.position.y]
	update_ui()

func update_ui() -> void:
	score_label.text = "SCORE: %04d" % score
