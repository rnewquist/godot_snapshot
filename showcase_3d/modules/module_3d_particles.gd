# module_3d_particles.gd
extends Node3D
class_name Module3DParticles

@onready var path_follow: PathFollow3D = $Path3D/PathFollow3D

func _process(delta: float) -> void:
	if path_follow:
		path_follow.progress += delta * 4.0
