# module_3d_materials.gd
extends Node3D
class_name Module3DMaterials

@onready var spheres_container: Node3D = $SpheresContainer
@onready var primitives_container: Node3D = get_node_or_null("PrimitivesContainer")

func _process(delta: float) -> void:
	if spheres_container:
		spheres_container.rotate_y(delta * 0.3)
	if primitives_container:
		primitives_container.rotate_y(delta * -0.2)
