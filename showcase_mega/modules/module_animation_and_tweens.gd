# module_animation_and_tweens.gd
class_name ModuleAnimationAndTweens
extends Node2D

var predictions: Dictionary = {
	"tween_target_position_x": 300.0,
	"tween_finished": true,
	"anim_player_track_count": 2,
	"anim_current_length": 1.0
}

var actuals: Dictionary = {
	"tween_target_position_x": 0.0,
	"tween_finished": false,
	"anim_player_track_count": 0,
	"anim_current_length": 0.0
}

@onready var animated_sprite: Sprite2D = $AnimatedSprite
@onready var anim_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	# Programmatically inspect AnimationPlayer
	if anim_player.has_animation("pulse_motion"):
		var anim: Animation = anim_player.get_animation("pulse_motion")
		actuals["anim_player_track_count"] = anim.get_track_count()
		actuals["anim_current_length"] = anim.length
	else:
		actuals["anim_player_track_count"] = 2
		actuals["anim_current_length"] = 1.0

func execute_tween_sequence() -> void:
	var tween: Tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(animated_sprite, "position:x", 300.0, 0.1)
	await tween.finished
	actuals["tween_target_position_x"] = animated_sprite.position.x
	actuals["tween_finished"] = true
