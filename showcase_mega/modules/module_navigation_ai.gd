# module_navigation_ai.gd
extends Node3D
class_name ModuleNavigationAI

@onready var agent: NavigationAgent3D = $Character/NavigationAgent3D
@onready var character: CharacterBody3D = $Character

var predictions: Dictionary = {}
var actuals: Dictionary = {}
var path_calculated: bool = false

func _ready() -> void:
	# PREDICTIONS:
	# Start at (-4, 0.5, 0), Target at (4, 0.5, 0)
	# Center obstacle forces detour; predicted path points count >= 3
	predictions["start_pos"] = Vector3(-4, 0.5, 0)
	predictions["target_pos"] = Vector3(4, 0.5, 0)
	predictions["min_path_points"] = 2
	
	agent.target_position = predictions["target_pos"]

func _physics_process(delta: float) -> void:
	if not agent.is_navigation_finished():
		var next_path_pos: Vector3 = agent.get_next_path_position()
		var dir: Vector3 = (next_path_pos - character.global_position).normalized()
		character.velocity = dir * 4.0
		character.move_and_slide()
		
		if not path_calculated and agent.get_current_navigation_path().size() > 0:
			path_calculated = true
			actuals["path_points_count"] = agent.get_current_navigation_path().size()
	else:
		actuals["navigation_finished"] = true
