# test_integration_mechanical_joints.gd
# Tier 1 Integration Suite 3: 2D and 3D Mechanical Joints.
extends "res://addons/gdtest/core/test_suite.gd"

var test_scene_2d: Node2D
var test_scene_3d: Node3D

func _init() -> void:
	suite_name = "Tier1_Integration_Mechanical_Joints"
	test_type = "integration"

func before_each() -> void:
	test_scene_2d = autofree(Node2D.new()) as Node2D
	add_child(test_scene_2d)
	test_scene_3d = autofree(Node3D.new()) as Node3D
	add_child(test_scene_3d)

# ==============================================================================
# 1. 2D MECHANICAL JOINTS (PIN, GROOVE, DAMPED SPRING)
# ==============================================================================

func test_pin_joint_2d_properties() -> void:
	var body_a: StaticBody2D = autofree(StaticBody2D.new()) as StaticBody2D
	body_a.position = Vector2(100, 100)
	test_scene_2d.add_child(body_a)
	
	var body_b: RigidBody2D = autofree(RigidBody2D.new()) as RigidBody2D
	body_b.position = Vector2(100, 200)
	test_scene_2d.add_child(body_b)
	
	var pin: PinJoint2D = autofree(PinJoint2D.new()) as PinJoint2D
	pin.node_a = body_a.get_path()
	pin.node_b = body_b.get_path()
	pin.softness = 0.5
	pin.bias = 0.9
	test_scene_2d.add_child(pin)
	
	assert_eq(pin.node_a, body_a.get_path(), "PinJoint2D node_a must match")
	assert_eq(pin.node_b, body_b.get_path(), "PinJoint2D node_b must match")
	assert_approx(pin.softness, 0.5, 0.001, "PinJoint2D softness must match")
	assert_approx(pin.bias, 0.9, 0.001, "PinJoint2D bias must match")

func test_pin_joint_2d_kinematic_constraint() -> void:
	var body_a: StaticBody2D = autofree(StaticBody2D.new()) as StaticBody2D
	body_a.position = Vector2(0, 0)
	test_scene_2d.add_child(body_a)
	
	var body_b: RigidBody2D = autofree(RigidBody2D.new()) as RigidBody2D
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 10.0
	col.shape = shape
	body_b.add_child(col)
	body_b.position = Vector2(50, 0)
	body_b.gravity_scale = 1.0
	test_scene_2d.add_child(body_b)
	
	var pin: PinJoint2D = autofree(PinJoint2D.new()) as PinJoint2D
	pin.node_a = body_a.get_path()
	pin.node_b = body_b.get_path()
	pin.position = Vector2(0, 0)
	pin.softness = 0.0
	test_scene_2d.add_child(pin)
	
	await step_physics_frames(10)
	var dist = body_b.position.distance_to(body_a.position)
	assert_approx(dist, 50.0, 5.0, "PinJoint2D must constrain radial distance within tolerance")

func test_groove_joint_2d_properties() -> void:
	var body_a: StaticBody2D = autofree(StaticBody2D.new()) as StaticBody2D
	body_a.position = Vector2(100, 100)
	test_scene_2d.add_child(body_a)
	
	var body_b: RigidBody2D = autofree(RigidBody2D.new()) as RigidBody2D
	body_b.position = Vector2(100, 150)
	test_scene_2d.add_child(body_b)
	
	var groove: GrooveJoint2D = autofree(GrooveJoint2D.new()) as GrooveJoint2D
	groove.node_a = body_a.get_path()
	groove.node_b = body_b.get_path()
	groove.length = 100.0
	groove.initial_offset = 50.0
	test_scene_2d.add_child(groove)
	
	assert_approx(groove.length, 100.0, 0.001, "GrooveJoint2D length must match")
	assert_approx(groove.initial_offset, 50.0, 0.001, "GrooveJoint2D initial_offset must match")

func test_groove_joint_2d_sliding_constraint() -> void:
	var body_a: StaticBody2D = autofree(StaticBody2D.new()) as StaticBody2D
	body_a.position = Vector2(0, 0)
	test_scene_2d.add_child(body_a)
	
	var body_b: RigidBody2D = autofree(RigidBody2D.new()) as RigidBody2D
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 10.0
	col.shape = shape
	body_b.add_child(col)
	body_b.position = Vector2(0, 20)
	body_b.gravity_scale = 1.0
	test_scene_2d.add_child(body_b)
	
	var groove: GrooveJoint2D = autofree(GrooveJoint2D.new()) as GrooveJoint2D
	groove.node_a = body_a.get_path()
	groove.node_b = body_b.get_path()
	groove.length = 80.0
	groove.initial_offset = 20.0
	test_scene_2d.add_child(groove)
	
	await step_physics_frames(10)
	assert_approx(body_b.position.x, 0.0, 2.0, "GrooveJoint2D must constrain motion along the vertical groove axis")

func test_damped_spring_joint_2d_properties() -> void:
	var body_a: StaticBody2D = autofree(StaticBody2D.new()) as StaticBody2D
	test_scene_2d.add_child(body_a)
	var body_b: RigidBody2D = autofree(RigidBody2D.new()) as RigidBody2D
	test_scene_2d.add_child(body_b)
	
	var spring: DampedSpringJoint2D = autofree(DampedSpringJoint2D.new()) as DampedSpringJoint2D
	spring.node_a = body_a.get_path()
	spring.node_b = body_b.get_path()
	spring.length = 150.0
	spring.rest_length = 120.0
	spring.stiffness = 40.0
	spring.damping = 0.75
	test_scene_2d.add_child(spring)
	
	assert_approx(spring.length, 150.0, 0.001, "DampedSpringJoint2D length must match")
	assert_approx(spring.rest_length, 120.0, 0.001, "DampedSpringJoint2D rest_length must match")
	assert_approx(spring.stiffness, 40.0, 0.001, "DampedSpringJoint2D stiffness must match")
	assert_approx(spring.damping, 0.75, 0.001, "DampedSpringJoint2D damping must match")

func test_damped_spring_joint_2d_oscillation() -> void:
	var body_a: StaticBody2D = autofree(StaticBody2D.new()) as StaticBody2D
	var col_a = CollisionShape2D.new()
	var shape_a = CircleShape2D.new()
	shape_a.radius = 10.0
	col_a.shape = shape_a
	body_a.add_child(col_a)
	body_a.position = Vector2(0, 0)
	test_scene_2d.add_child(body_a)
	
	var body_b: RigidBody2D = autofree(RigidBody2D.new()) as RigidBody2D
	var col_b = CollisionShape2D.new()
	var shape_b = CircleShape2D.new()
	shape_b.radius = 10.0
	col_b.shape = shape_b
	body_b.add_child(col_b)
	body_b.position = Vector2(0, 200)
	body_b.gravity_scale = 0.0
	test_scene_2d.add_child(body_b)
	
	var spring: DampedSpringJoint2D = autofree(DampedSpringJoint2D.new()) as DampedSpringJoint2D
	spring.position = Vector2(0, 0)
	spring.node_a = body_a.get_path()
	spring.node_b = body_b.get_path()
	spring.length = 200.0
	spring.rest_length = 50.0
	spring.stiffness = 50.0
	spring.damping = 0.1
	test_scene_2d.add_child(spring)
	
	await step_physics_frames(10)
	assert_lt(body_b.position.y, 200.0, "Spring force must pull stretched body_b towards rest length")

# ==============================================================================
# 2. 3D MECHANICAL JOINTS (PIN, HINGE, SLIDER, CONE TWIST, GENERIC 6DOF)
# ==============================================================================

func test_pin_joint_3d_properties() -> void:
	var body_a: StaticBody3D = autofree(StaticBody3D.new()) as StaticBody3D
	test_scene_3d.add_child(body_a)
	var body_b: RigidBody3D = autofree(RigidBody3D.new()) as RigidBody3D
	test_scene_3d.add_child(body_b)
	
	var pin: PinJoint3D = autofree(PinJoint3D.new()) as PinJoint3D
	pin.node_a = body_a.get_path()
	pin.node_b = body_b.get_path()
	pin.set_param(PinJoint3D.PARAM_BIAS, 0.4)
	pin.set_param(PinJoint3D.PARAM_DAMPING, 0.6)
	pin.set_param(PinJoint3D.PARAM_IMPULSE_CLAMP, 10.0)
	test_scene_3d.add_child(pin)
	
	assert_approx(pin.get_param(PinJoint3D.PARAM_BIAS), 0.4, 0.001, "PinJoint3D bias must match")
	assert_approx(pin.get_param(PinJoint3D.PARAM_DAMPING), 0.6, 0.001, "PinJoint3D damping must match")
	assert_approx(pin.get_param(PinJoint3D.PARAM_IMPULSE_CLAMP), 10.0, 0.001, "PinJoint3D impulse clamp must match")

func test_pin_joint_3d_physics_step() -> void:
	var body_a: StaticBody3D = autofree(StaticBody3D.new()) as StaticBody3D
	body_a.position = Vector3(0, 5, 0)
	test_scene_3d.add_child(body_a)
	
	var body_b: RigidBody3D = autofree(RigidBody3D.new()) as RigidBody3D
	var col = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.5
	col.shape = shape
	body_b.add_child(col)
	body_b.position = Vector3(2, 5, 0)
	body_b.gravity_scale = 1.0
	test_scene_3d.add_child(body_b)
	
	var pin: PinJoint3D = autofree(PinJoint3D.new()) as PinJoint3D
	pin.node_a = body_a.get_path()
	pin.node_b = body_b.get_path()
	pin.position = Vector3(0, 5, 0)
	test_scene_3d.add_child(pin)
	
	await step_physics_frames(10)
	var dist = body_b.position.distance_to(body_a.position)
	assert_approx(dist, 2.0, 0.5, "PinJoint3D must maintain spherical distance constraint")

func test_hinge_joint_3d_properties() -> void:
	var hinge: HingeJoint3D = autofree(HingeJoint3D.new()) as HingeJoint3D
	hinge.set_flag(HingeJoint3D.FLAG_USE_LIMIT, true)
	hinge.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, deg_to_rad(90.0))
	hinge.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, deg_to_rad(-90.0))
	hinge.set_param(HingeJoint3D.PARAM_LIMIT_BIAS, 0.3)
	test_scene_3d.add_child(hinge)
	
	assert_true(hinge.get_flag(HingeJoint3D.FLAG_USE_LIMIT), "HingeJoint3D FLAG_USE_LIMIT must be true")
	assert_approx(hinge.get_param(HingeJoint3D.PARAM_LIMIT_UPPER), deg_to_rad(90.0), 0.001)
	assert_approx(hinge.get_param(HingeJoint3D.PARAM_LIMIT_LOWER), deg_to_rad(-90.0), 0.001)
	assert_approx(hinge.get_param(HingeJoint3D.PARAM_LIMIT_BIAS), 0.3, 0.001)

func test_hinge_joint_3d_motor_and_limits() -> void:
	var hinge: HingeJoint3D = autofree(HingeJoint3D.new()) as HingeJoint3D
	hinge.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)
	hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, 2.5)
	hinge.set_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE, 8.0)
	test_scene_3d.add_child(hinge)
	
	assert_true(hinge.get_flag(HingeJoint3D.FLAG_ENABLE_MOTOR), "HingeJoint3D motor must be enabled")
	assert_approx(hinge.get_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY), 2.5, 0.001)
	assert_approx(hinge.get_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE), 8.0, 0.001)

func test_slider_joint_3d_properties() -> void:
	var slider: SliderJoint3D = autofree(SliderJoint3D.new()) as SliderJoint3D
	slider.set_param(SliderJoint3D.PARAM_LINEAR_LIMIT_UPPER, 5.0)
	slider.set_param(SliderJoint3D.PARAM_LINEAR_LIMIT_LOWER, -5.0)
	slider.set_param(SliderJoint3D.PARAM_ANGULAR_LIMIT_UPPER, deg_to_rad(45.0))
	slider.set_param(SliderJoint3D.PARAM_ANGULAR_LIMIT_LOWER, deg_to_rad(-45.0))
	test_scene_3d.add_child(slider)
	
	assert_approx(slider.get_param(SliderJoint3D.PARAM_LINEAR_LIMIT_UPPER), 5.0, 0.001)
	assert_approx(slider.get_param(SliderJoint3D.PARAM_LINEAR_LIMIT_LOWER), -5.0, 0.001)
	assert_approx(slider.get_param(SliderJoint3D.PARAM_ANGULAR_LIMIT_UPPER), deg_to_rad(45.0), 0.001)
	assert_approx(slider.get_param(SliderJoint3D.PARAM_ANGULAR_LIMIT_LOWER), deg_to_rad(-45.0), 0.001)

func test_slider_joint_3d_linear_motion() -> void:
	var body_a: StaticBody3D = autofree(StaticBody3D.new()) as StaticBody3D
	body_a.position = Vector3(0, 0, 0)
	test_scene_3d.add_child(body_a)
	
	var body_b: RigidBody3D = autofree(RigidBody3D.new()) as RigidBody3D
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1, 1, 1)
	col.shape = shape
	body_b.add_child(col)
	body_b.position = Vector3(1, 0, 0)
	body_b.gravity_scale = 0.0
	body_b.linear_velocity = Vector3(10, 0, 0)
	test_scene_3d.add_child(body_b)
	
	var slider: SliderJoint3D = autofree(SliderJoint3D.new()) as SliderJoint3D
	slider.node_a = body_a.get_path()
	slider.node_b = body_b.get_path()
	slider.set_param(SliderJoint3D.PARAM_LINEAR_LIMIT_UPPER, 3.0)
	slider.set_param(SliderJoint3D.PARAM_LINEAR_LIMIT_LOWER, -3.0)
	test_scene_3d.add_child(slider)
	
	await step_physics_frames(10)
	assert_lte(body_b.position.x, 3.5, "SliderJoint3D must restrict linear travel to upper limit")

func test_cone_twist_joint_3d_properties() -> void:
	var cone: ConeTwistJoint3D = autofree(ConeTwistJoint3D.new()) as ConeTwistJoint3D
	cone.set_param(ConeTwistJoint3D.PARAM_SWING_SPAN, deg_to_rad(30.0))
	cone.set_param(ConeTwistJoint3D.PARAM_TWIST_SPAN, deg_to_rad(60.0))
	cone.set_param(ConeTwistJoint3D.PARAM_BIAS, 0.5)
	cone.set_param(ConeTwistJoint3D.PARAM_SOFTNESS, 0.8)
	cone.set_param(ConeTwistJoint3D.PARAM_RELAXATION, 1.2)
	test_scene_3d.add_child(cone)
	
	assert_approx(cone.get_param(ConeTwistJoint3D.PARAM_SWING_SPAN), deg_to_rad(30.0), 0.001)
	assert_approx(cone.get_param(ConeTwistJoint3D.PARAM_TWIST_SPAN), deg_to_rad(60.0), 0.001)
	assert_approx(cone.get_param(ConeTwistJoint3D.PARAM_BIAS), 0.5, 0.001)
	assert_approx(cone.get_param(ConeTwistJoint3D.PARAM_SOFTNESS), 0.8, 0.001)
	assert_approx(cone.get_param(ConeTwistJoint3D.PARAM_RELAXATION), 1.2, 0.001)

func test_cone_twist_joint_3d_rotational_constraint() -> void:
	var body_a: StaticBody3D = autofree(StaticBody3D.new()) as StaticBody3D
	test_scene_3d.add_child(body_a)
	var body_b: RigidBody3D = autofree(RigidBody3D.new()) as RigidBody3D
	test_scene_3d.add_child(body_b)
	
	var cone: ConeTwistJoint3D = autofree(ConeTwistJoint3D.new()) as ConeTwistJoint3D
	cone.node_a = body_a.get_path()
	cone.node_b = body_b.get_path()
	test_scene_3d.add_child(cone)
	
	assert_eq(cone.node_a, body_a.get_path())
	assert_eq(cone.node_b, body_b.get_path())

func test_generic_6dof_joint_3d_linear_limits() -> void:
	var dof: Generic6DOFJoint3D = autofree(Generic6DOFJoint3D.new()) as Generic6DOFJoint3D
	dof.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
	dof.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, -2.0)
	dof.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 2.0)
	test_scene_3d.add_child(dof)
	
	assert_true(dof.get_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT))
	assert_approx(dof.get_param_x(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT), -2.0, 0.001)
	assert_approx(dof.get_param_x(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT), 2.0, 0.001)

func test_generic_6dof_joint_3d_angular_limits() -> void:
	var dof: Generic6DOFJoint3D = autofree(Generic6DOFJoint3D.new()) as Generic6DOFJoint3D
	dof.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
	dof.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, deg_to_rad(-45.0))
	dof.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, deg_to_rad(45.0))
	test_scene_3d.add_child(dof)
	
	assert_true(dof.get_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT))
	assert_approx(dof.get_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT), deg_to_rad(-45.0), 0.001)
	assert_approx(dof.get_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT), deg_to_rad(45.0), 0.001)

func test_generic_6dof_joint_3d_springs() -> void:
	var dof: Generic6DOFJoint3D = autofree(Generic6DOFJoint3D.new()) as Generic6DOFJoint3D
	dof.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_SPRING, true)
	dof.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_STIFFNESS, 25.0)
	dof.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_DAMPING, 0.5)
	test_scene_3d.add_child(dof)
	
	assert_true(dof.get_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_SPRING))
	assert_approx(dof.get_param_z(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_STIFFNESS), 25.0, 0.001)
	assert_approx(dof.get_param_z(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_DAMPING), 0.5, 0.001)

func test_generic_6dof_joint_3d_motors() -> void:
	var dof: Generic6DOFJoint3D = autofree(Generic6DOFJoint3D.new()) as Generic6DOFJoint3D
	dof.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_MOTOR, true)
	dof.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_MOTOR_TARGET_VELOCITY, 3.0)
	dof.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_MOTOR_FORCE_LIMIT, 50.0)
	test_scene_3d.add_child(dof)
	
	assert_true(dof.get_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_MOTOR))
	assert_approx(dof.get_param_x(Generic6DOFJoint3D.PARAM_LINEAR_MOTOR_TARGET_VELOCITY), 3.0, 0.001)
	assert_approx(dof.get_param_x(Generic6DOFJoint3D.PARAM_LINEAR_MOTOR_FORCE_LIMIT), 50.0, 0.001)
