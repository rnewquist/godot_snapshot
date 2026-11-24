# test_integration_physics_2d_shapes.gd
# Tier 1 Integration Suite 1: 2D Collision Shapes, Restitution, Friction, Kinematics, and PhysicsServer2D.
extends "res://addons/gdtest/core/test_suite.gd"

var test_scene_2d: Node2D

func _init() -> void:
	suite_name = "Tier1_Integration_Physics_2D_Shapes"
	test_type = "integration"

func before_each() -> void:
	test_scene_2d = autofree(Node2D.new()) as Node2D
	add_child(test_scene_2d)

# ==============================================================================
# 1. ALL 8 2D COLLISION SHAPES (DISCRETE TESTS)
# ==============================================================================

func test_circle_shape_2d() -> void:
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = 32.0
	assert_approx(circle.radius, 32.0, 0.001, "CircleShape2D radius must be 32.0")
	var r: Rect2 = circle.get_rect()
	assert_approx(r.size.x, 64.0, 0.01, "CircleShape2D bounding rect width must be 64.0")
	assert_approx(r.size.y, 64.0, 0.01, "CircleShape2D bounding rect height must be 64.0")

func test_rectangle_shape_2d() -> void:
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(80.0, 40.0)
	assert_vector2_approx(rect.size, Vector2(80.0, 40.0), 0.001, "RectangleShape2D size must match")
	var r: Rect2 = rect.get_rect()
	assert_approx(r.size.x, 80.0, 0.01, "RectangleShape2D rect width must match")
	assert_approx(r.size.y, 40.0, 0.01, "RectangleShape2D rect height must match")

func test_capsule_shape_2d() -> void:
	var capsule: CapsuleShape2D = CapsuleShape2D.new()
	capsule.radius = 16.0
	capsule.height = 48.0
	assert_approx(capsule.radius, 16.0, 0.001, "CapsuleShape2D radius must match")
	assert_approx(capsule.height, 48.0, 0.001, "CapsuleShape2D height must match")
	var r: Rect2 = capsule.get_rect()
	assert_gte(r.size.y, 48.0, "CapsuleShape2D rect height >= 48.0")

func test_segment_shape_2d() -> void:
	var segment: SegmentShape2D = SegmentShape2D.new()
	segment.a = Vector2(-20.0, 0.0)
	segment.b = Vector2(60.0, 40.0)
	assert_vector2_approx(segment.a, Vector2(-20.0, 0.0), 0.001, "SegmentShape2D point A must match")
	assert_vector2_approx(segment.b, Vector2(60.0, 40.0), 0.001, "SegmentShape2D point B must match")

func test_separation_ray_shape_2d() -> void:
	var sep_ray: SeparationRayShape2D = SeparationRayShape2D.new()
	sep_ray.length = 35.0
	sep_ray.slide_on_slope = true
	assert_approx(sep_ray.length, 35.0, 0.001, "SeparationRayShape2D length must match")
	assert_true(sep_ray.slide_on_slope, "SeparationRayShape2D slide_on_slope must be true")

func test_world_boundary_shape_2d() -> void:
	var world_bound: WorldBoundaryShape2D = WorldBoundaryShape2D.new()
	world_bound.normal = Vector2(0.0, -1.0)
	world_bound.distance = 150.0
	assert_vector2_approx(world_bound.normal, Vector2(0.0, -1.0), 0.001, "WorldBoundaryShape2D normal must match")
	assert_approx(world_bound.distance, 150.0, 0.001, "WorldBoundaryShape2D distance must match")

func test_convex_polygon_shape_2d() -> void:
	var convex: ConvexPolygonShape2D = ConvexPolygonShape2D.new()
	var points: PackedVector2Array = [Vector2(0, 0), Vector2(40, 0), Vector2(40, 40), Vector2(0, 40)]
	convex.points = points
	assert_eq(convex.points.size(), 4, "ConvexPolygonShape2D must contain 4 vertices")
	assert_vector2_approx(convex.points[1], Vector2(40, 0), 0.001, "ConvexPolygonShape2D vertex 1 must match")

func test_concave_polygon_shape_2d() -> void:
	var concave: ConcavePolygonShape2D = ConcavePolygonShape2D.new()
	var segments: PackedVector2Array = [
		Vector2(0, 0), Vector2(30, 0),
		Vector2(30, 0), Vector2(30, 30),
		Vector2(30, 30), Vector2(0, 30)
	]
	concave.segments = segments
	assert_eq(concave.segments.size(), 6, "ConcavePolygonShape2D segments size must equal 6")

# ==============================================================================
# 2. RESTITUTION, FRICTION, AND RIGID BODY KINEMATICS
# ==============================================================================

func test_physics_material_restitution_bounce() -> void:
	var mat: PhysicsMaterial = PhysicsMaterial.new()
	mat.bounce = 0.85
	mat.absorbent = false
	assert_approx(mat.bounce, 0.85, 0.001, "PhysicsMaterial bounce must match")
	assert_false(mat.absorbent, "PhysicsMaterial absorbent should be false")

func test_physics_material_friction_sliding() -> void:
	var mat: PhysicsMaterial = PhysicsMaterial.new()
	mat.friction = 0.4
	mat.rough = true
	assert_approx(mat.friction, 0.4, 0.001, "PhysicsMaterial friction must match")
	assert_true(mat.rough, "PhysicsMaterial rough should be true")

func test_rigidbody2d_gravity_fall() -> void:
	var body: RigidBody2D = autofree(RigidBody2D.new()) as RigidBody2D
	var col: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 10.0
	col.shape = shape
	body.add_child(col)
	body.position = Vector2(100.0, 100.0)
	body.gravity_scale = 1.0
	test_scene_2d.add_child(body)
	
	var initial_y: float = body.position.y
	await step_physics_frames(10)
	assert_gt(body.position.y, initial_y, "RigidBody2D must fall under gravity (position.y > initial_y)")

func test_rigidbody2d_linear_velocity() -> void:
	var body: RigidBody2D = autofree(RigidBody2D.new()) as RigidBody2D
	var col: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(20, 20)
	col.shape = shape
	body.add_child(col)
	body.gravity_scale = 0.0
	body.position = Vector2(50, 50)
	body.linear_velocity = Vector2(200.0, 0.0)
	test_scene_2d.add_child(body)
	
	await step_physics_frames(5)
	assert_gt(body.position.x, 50.0, "RigidBody2D with linear_velocity.x > 0 must displace positively on X")

func test_rigidbody2d_angular_velocity() -> void:
	var body: RigidBody2D = autofree(RigidBody2D.new()) as RigidBody2D
	var col: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(20, 20)
	col.shape = shape
	body.add_child(col)
	body.gravity_scale = 0.0
	body.angular_velocity = 5.0
	test_scene_2d.add_child(body)
	
	await step_physics_frames(5)
	assert_gt(abs(body.rotation), 0.01, "RigidBody2D with angular_velocity must rotate")

func test_area2d_gravity_override() -> void:
	var area: Area2D = autofree(Area2D.new()) as Area2D
	area.gravity_space_override = Area2D.SPACE_OVERRIDE_REPLACE
	area.gravity_direction = Vector2(0, -1)
	area.gravity = 980.0
	test_scene_2d.add_child(area)
	
	assert_eq(area.gravity_space_override, Area2D.SPACE_OVERRIDE_REPLACE, "Area2D space override must be REPLACE")
	assert_vector2_approx(area.gravity_direction, Vector2(0, -1), 0.001, "Area2D gravity vector must match")
	assert_approx(area.gravity, 980.0, 0.001, "Area2D gravity magnitude must match")

func test_area2d_point_gravity() -> void:
	var area: Area2D = autofree(Area2D.new()) as Area2D
	area.gravity_point = true
	area.gravity_point_unit_distance = 100.0
	area.gravity_point_center = Vector2(200, 200)
	test_scene_2d.add_child(area)
	
	assert_true(area.gravity_point, "Area2D gravity_point must be true")
	assert_approx(area.gravity_point_unit_distance, 100.0, 0.001, "Point unit distance must match")
	assert_vector2_approx(area.gravity_point_center, Vector2(200, 200), 0.001, "Point center must match")

# ==============================================================================
# 3. LOW-LEVEL PHYSICSSERVER2D RIDS
# ==============================================================================

func test_physics_server_2d_space_rid_lifecycle() -> void:
	var space: RID = auto_free_rid(PhysicsServer2D.space_create(), ServerType.PHYSICS_2D)
	assert_true(space.is_valid(), "PhysicsServer2D space RID must be valid")
	PhysicsServer2D.space_set_active(space, true)
	assert_true(PhysicsServer2D.space_is_active(space), "PhysicsServer2D space must be active")

func test_physics_server_2d_body_rid_lifecycle() -> void:
	var space: RID = auto_free_rid(PhysicsServer2D.space_create(), ServerType.PHYSICS_2D)
	var body: RID = auto_free_rid(PhysicsServer2D.body_create(), ServerType.PHYSICS_2D)
	PhysicsServer2D.body_set_space(body, space)
	PhysicsServer2D.body_set_mode(body, PhysicsServer2D.BODY_MODE_RIGID)
	PhysicsServer2D.body_set_state(body, PhysicsServer2D.BODY_STATE_TRANSFORM, Transform2D(0.0, Vector2(75, 125)))
	
	assert_true(body.is_valid(), "PhysicsServer2D body RID must be valid")
	var t: Transform2D = PhysicsServer2D.body_get_state(body, PhysicsServer2D.BODY_STATE_TRANSFORM)
	assert_vector2_approx(t.origin, Vector2(75, 125), 0.001, "Body transform origin must match")

func test_physics_server_2d_shape_circle_rid() -> void:
	var shape: RID = auto_free_rid(PhysicsServer2D.circle_shape_create(), ServerType.PHYSICS_2D)
	assert_true(shape.is_valid(), "PhysicsServer2D circle shape RID must be valid")
	PhysicsServer2D.shape_set_data(shape, 25.0)
	var data: Variant = PhysicsServer2D.shape_get_data(shape)
	assert_approx(float(data), 25.0, 0.001, "Circle shape radius in server must match 25.0")

func test_physics_server_2d_shape_rect_rid() -> void:
	var shape: RID = auto_free_rid(PhysicsServer2D.rectangle_shape_create(), ServerType.PHYSICS_2D)
	assert_true(shape.is_valid(), "PhysicsServer2D rectangle shape RID must be valid")
	PhysicsServer2D.shape_set_data(shape, Vector2(50, 30))
	var data: Variant = PhysicsServer2D.shape_get_data(shape)
	assert_vector2_approx(Vector2(data), Vector2(50, 30), 0.001, "Rectangle shape half-extents in server must match")

func test_physics_server_2d_direct_state_query() -> void:
	var space: RID = auto_free_rid(PhysicsServer2D.space_create(), ServerType.PHYSICS_2D)
	PhysicsServer2D.space_set_active(space, true)
	var direct_state = PhysicsServer2D.space_get_direct_state(space)
	assert_not_null(direct_state, "PhysicsDirectSpaceState2D must not be null for active space")
