# goal_pedestal_3d.gd
extends Area3D
class_name GoalPedestal3D

signal goal_reached()
signal goal_exited()

@export var pedestal_position: Vector3 = Vector3(2.5, 0.25, 0.0)

var is_active: bool = false
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
var inactive_mat: StandardMaterial3D
var active_mat: StandardMaterial3D

func _ready() -> void:
	position = pedestal_position
	
	inactive_mat = StandardMaterial3D.new()
	inactive_mat.albedo_color = Color(0.2, 0.5, 0.9, 1.0)
	inactive_mat.metallic = 0.6
	inactive_mat.roughness = 0.3
	
	active_mat = StandardMaterial3D.new()
	active_mat.albedo_color = Color(0.2, 0.95, 0.4, 1.0)
	active_mat.emission_enabled = true
	active_mat.emission = Color(0.2, 1.0, 0.4, 1.0)
	active_mat.emission_energy_multiplier = 2.0
	
	if mesh_instance:
		mesh_instance.material_override = inactive_mat
		
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _on_area_entered(area: Area3D) -> void:
	if area is TargetSphere3D:
		is_active = true
		if mesh_instance:
			mesh_instance.material_override = active_mat
		goal_reached.emit()

func _on_area_exited(area: Area3D) -> void:
	if area is TargetSphere3D:
		is_active = false
		if mesh_instance:
			mesh_instance.material_override = inactive_mat
		goal_exited.emit()

func reset_pedestal() -> void:
	is_active = false
	if mesh_instance:
		mesh_instance.material_override = inactive_mat
