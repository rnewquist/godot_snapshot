# target_sphere_3d.gd
extends Area3D
class_name TargetSphere3D

signal dragged(world_position: Vector3)
signal dropped(final_world_position: Vector3)

@export var sphere_radius: float = 0.5
@export var initial_position: Vector3 = Vector3(-2.5, 0.5, 0.0)

var is_dragging: bool = false
var drag_plane: Plane

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
var default_mat: StandardMaterial3D
var drag_mat: StandardMaterial3D

func _ready() -> void:
	position = initial_position
	input_ray_pickable = true
	drag_plane = Plane(Vector3.UP, initial_position.y)
	
	default_mat = StandardMaterial3D.new()
	default_mat.albedo_color = Color(0.95, 0.25, 0.35, 1.0)
	default_mat.roughness = 0.2
	default_mat.metallic = 0.4
	
	drag_mat = StandardMaterial3D.new()
	drag_mat.albedo_color = Color(1.0, 0.6, 0.1, 1.0)
	drag_mat.emission_enabled = true
	drag_mat.emission = Color(1.0, 0.5, 0.1, 1.0)
	drag_mat.emission_energy_multiplier = 1.5
	
	if mesh_instance:
		mesh_instance.material_override = default_mat
		
	input_event.connect(_on_input_event)

func _on_input_event(_camera: Camera3D, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not is_dragging:
			start_drag()

func _unhandled_input(event: InputEvent) -> void:
	if not is_dragging:
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		stop_drag()
	elif event is InputEventMouseMotion:
		var cam = get_viewport().get_camera_3d()
		if cam:
			var ray_origin = cam.project_ray_origin(event.position)
			var ray_dir = cam.project_ray_normal(event.position)
			var hit_pos = drag_plane.intersects_ray(ray_origin, ray_dir)
			if hit_pos:
				global_position = hit_pos
				dragged.emit(global_position)

func start_drag() -> void:
	is_dragging = true
	if mesh_instance:
		mesh_instance.material_override = drag_mat

func stop_drag() -> void:
	is_dragging = false
	if mesh_instance:
		mesh_instance.material_override = default_mat
	dropped.emit(global_position)

func reset_position() -> void:
	is_dragging = false
	global_position = initial_position
	if mesh_instance:
		mesh_instance.material_override = default_mat
