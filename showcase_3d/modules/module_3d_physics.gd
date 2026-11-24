# module_3d_physics.gd
extends Node3D
class_name Module3DPhysics

@onready var bouncy_sphere: RigidBody3D = $BouncySphere
@onready var heavy_block: RigidBody3D = $HeavyBlock
@onready var elevator: AnimatableBody3D = $Elevator
@onready var capsule_body: RigidBody3D = get_node_or_null("CapsuleBody")
@onready var cylinder_body: RigidBody3D = get_node_or_null("CylinderBody")
@onready var convex_pyramid: RigidBody3D = get_node_or_null("ConvexPyramid")
@onready var hover_probe: CharacterBody3D = get_node_or_null("HoverProbe3D")
@onready var concave_ramp: StaticBody3D = get_node_or_null("ConcaveRamp")
@onready var terrain_heightmap: StaticBody3D = get_node_or_null("TerrainHeightMap")
@onready var world_boundary: StaticBody3D = get_node_or_null("WorldBoundaryFloor")

var time_passed: float = 0.0

func _physics_process(delta: float) -> void:
	time_passed += delta
	# Move AnimatableBody3D elevator smoothly up and down
	if elevator:
		var target_y = 1.0 + sin(time_passed * 2.0) * 0.8
		elevator.position.y = target_y

func reset_physics() -> void:
	if bouncy_sphere:
		PhysicsServer3D.body_set_state(bouncy_sphere.get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, Transform3D(Basis(), Vector3(-1.5, 3.0, 0)))
		PhysicsServer3D.body_set_state(bouncy_sphere.get_rid(), PhysicsServer3D.BODY_STATE_LINEAR_VELOCITY, Vector3.ZERO)
	
	if heavy_block:
		PhysicsServer3D.body_set_state(heavy_block.get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, Transform3D(Basis(), Vector3(1.5, 3.0, 0)))
		PhysicsServer3D.body_set_state(heavy_block.get_rid(), PhysicsServer3D.BODY_STATE_LINEAR_VELOCITY, Vector3.ZERO)

	if capsule_body:
		PhysicsServer3D.body_set_state(capsule_body.get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, Transform3D(Basis(), Vector3(-2.8, 3.0, -1.0)))
		PhysicsServer3D.body_set_state(capsule_body.get_rid(), PhysicsServer3D.BODY_STATE_LINEAR_VELOCITY, Vector3.ZERO)

	if cylinder_body:
		PhysicsServer3D.body_set_state(cylinder_body.get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, Transform3D(Basis(), Vector3(2.8, 3.0, -1.0)))
		PhysicsServer3D.body_set_state(cylinder_body.get_rid(), PhysicsServer3D.BODY_STATE_LINEAR_VELOCITY, Vector3.ZERO)

	if convex_pyramid:
		PhysicsServer3D.body_set_state(convex_pyramid.get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, Transform3D(Basis(), Vector3(0.0, 3.5, 1.0)))
		PhysicsServer3D.body_set_state(convex_pyramid.get_rid(), PhysicsServer3D.BODY_STATE_LINEAR_VELOCITY, Vector3.ZERO)
