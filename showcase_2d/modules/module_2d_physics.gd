# module_2d_physics.gd
extends Node2D
class_name Module2DPhysics

@onready var bouncy_ball: RigidBody2D = $BouncyBall
@onready var dead_ball: RigidBody2D = $DeadBall
@onready var ice_box: RigidBody2D = $FrictionRamp/IceBox
@onready var rubber_box: RigidBody2D = $FrictionRamp/RubberBox
@onready var char_body: CharacterBody2D = $KinematicSection/CharacterBody2D
@onready var convex_wedge: RigidBody2D = get_node_or_null("ConvexWedge")
@onready var concave_cradle: StaticBody2D = get_node_or_null("ConcaveCradle")
@onready var segment_barrier: StaticBody2D = get_node_or_null("SegmentBarrier")
@onready var hover_probe: CharacterBody2D = get_node_or_null("HoverProbe")
@onready var world_floor: StaticBody2D = get_node_or_null("WorldFloorBoundary")

var char_dir: float = 1.0

func _physics_process(_delta: float) -> void:
	if char_body:
		char_body.velocity.x = char_dir * 120.0
		char_body.move_and_slide()
		if char_body.position.x > 1050:
			char_dir = -1.0
		elif char_body.position.x < 750:
			char_dir = 1.0

func reset_physics() -> void:
	if bouncy_ball:
		PhysicsServer2D.body_set_state(bouncy_ball.get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, Transform2D(0, Vector2(150, 160)))
		PhysicsServer2D.body_set_state(bouncy_ball.get_rid(), PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, Vector2.ZERO)
	
	if dead_ball:
		PhysicsServer2D.body_set_state(dead_ball.get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, Transform2D(0, Vector2(250, 160)))
		PhysicsServer2D.body_set_state(dead_ball.get_rid(), PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, Vector2.ZERO)

	if convex_wedge:
		PhysicsServer2D.body_set_state(convex_wedge.get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, Transform2D(0, Vector2(340, 180)))
		PhysicsServer2D.body_set_state(convex_wedge.get_rid(), PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, Vector2.ZERO)
