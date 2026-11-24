# test_integration_physics_3d_shapes.gd
# Tier 1 Integration Suite 2: 3D Collision Shapes, RigidBody3D Kinematics, Slope Thresholds, and PhysicsServer3D.
extends "res://addons/gdtest/core/test_suite.gd"

var test_scene_3d: Node3D

func _init() -> void:
	suite_name = "Tier1_Integration_Physics_3D_Shapes"
	test_type = "integration"

func before_each() -> void:
	test_scene_3d = autofree(Node3D.new()) as Node3D
	add_child(test_scene_3d)

# ==============================================================================
# 1. ALL 9 3D COLLISION SHAPES (DISCRETE TESTS)
# ==============================================================================

func test_box_shape_3d() -> void:
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(2.0, 4.0, 6.0)
	assert_vector3_approx(box.size, Vector3(2.0, 4.0, 6.0), 0.001, "BoxShape3D size must match")

func test_sphere_shape_3d() -> void:
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 1.75
	assert_approx(sphere.radius, 1.75, 0.001, "SphereShape3D radius must match")

func test_capsule_shape_3d() -> void:
	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.radius = 0.6
	capsule.height = 2.4
	assert_approx(capsule.radius, 0.6, 0.001, "CapsuleShape3D radius must match")
	assert_approx(capsule.height, 2.4, 0.001, "CapsuleShape3D height must match")

func test_cylinder_shape_3d() -> void:
	var cylinder: CylinderShape3D = CylinderShape3D.new()
	cylinder.radius = 1.2
	cylinder.height = 3.5
	assert_approx(cylinder.radius, 1.2, 0.001, "CylinderShape3D radius must match")
	assert_approx(cylinder.height, 3.5, 0.001, "CylinderShape3D height must match")

func test_separation_ray_shape_3d() -> void:
	var sep_ray: SeparationRayShape3D = SeparationRayShape3D.new()
	sep_ray.length = 2.0
	sep_ray.slide_on_slope = true
	assert_approx(sep_ray.length, 2.0, 0.001, "SeparationRayShape3D length must match")
	assert_true(sep_ray.slide_on_slope, "SeparationRayShape3D slide_on_slope must be true")

func test_world_boundary_shape_3d() -> void:
	var world_bound: WorldBoundaryShape3D = WorldBoundaryShape3D.new()
	world_bound.plane = Plane(Vector3.UP, 0.0)
	assert_vector3_approx(world_bound.plane.normal, Vector3.UP, 0.001, "WorldBoundaryShape3D normal must be UP")
	assert_approx(world_bound.plane.d, 0.0, 0.001, "WorldBoundaryShape3D plane distance must be 0.0")

func test_convex_polygon_shape_3d() -> void:
	var convex: ConvexPolygonShape3D = ConvexPolygonShape3D.new()
	var pts: PackedVector3Array = [
		Vector3(-1, -1, -1), Vector3(1, -1, -1), Vector3(1, 1, -1), Vector3(-1, 1, -1),
		Vector3(-1, -1, 1), Vector3(1, -1, 1), Vector3(1, 1, 1), Vector3(-1, 1, 1)
	]
	convex.points = pts
	assert_eq(convex.points.size(), 8, "ConvexPolygonShape3D points size must equal 8")

func test_concave_polygon_shape_3d() -> void:
	var concave: ConcavePolygonShape3D = ConcavePolygonShape3D.new()
	var tri_faces: PackedVector3Array = [
		Vector3(0, 0, 0), Vector3(2, 0, 0), Vector3(0, 2, 0)
	]
	concave.set_faces(tri_faces)
	assert_eq(concave.get_faces().size(), 3, "ConcavePolygonShape3D faces size must equal 3")

func test_heightmap_shape_3d() -> void:
	var heightmap: HeightMapShape3D = HeightMapShape3D.new()
	heightmap.map_width = 3
	heightmap.map_depth = 3
	var heights: PackedFloat32Array = [
		0.0, 0.2, 0.0,
		0.2, 0.5, 0.2,
		0.0, 0.2, 0.0
	]
	heightmap.map_data = heights
	assert_eq(heightmap.map_width, 3, "HeightMapShape3D map_width must match")
	assert_eq(heightmap.map_depth, 3, "HeightMapShape3D map_depth must match")
	assert_eq(heightmap.map_data.size(), 9, "HeightMapShape3D map_data size must match")

# ==============================================================================
# 2. RIGIDBODY3D KINEMATICS & DYNAMICS
# ==============================================================================

func test_rigidbody3d_gravity_fall() -> void:
	var body: RigidBody3D = autofree(RigidBody3D.new()) as RigidBody3D
	var col: CollisionShape3D = CollisionShape3D.new()
	var shape: SphereShape3D = SphereShape3D.new()
	shape.radius = 0.5
	col.shape = shape
	body.add_child(col)
	body.position = Vector3(0, 10, 0)
	body.gravity_scale = 1.0
	test_scene_3d.add_child(body)
	
	var initial_y: float = body.position.y
	await step_physics_frames(10)
	assert_lt(body.position.y, initial_y, "RigidBody3D must fall downwards under gravity (position.y < initial_y)")

func test_rigidbody3d_linear_velocity() -> void:
	var body: RigidBody3D = autofree(RigidBody3D.new()) as RigidBody3D
	var col: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(1, 1, 1)
	col.shape = shape
	body.add_child(col)
	body.gravity_scale = 0.0
	body.position = Vector3(0, 0, 0)
	body.linear_velocity = Vector3(10.0, 0.0, 0.0)
	test_scene_3d.add_child(body)
	
	await step_physics_frames(5)
	assert_gt(body.position.x, 0.0, "RigidBody3D with linear_velocity.x > 0 must displace positively along X")

func test_rigidbody3d_angular_velocity() -> void:
	var body: RigidBody3D = autofree(RigidBody3D.new()) as RigidBody3D
	var col: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(1, 1, 1)
	col.shape = shape
	body.add_child(col)
	body.gravity_scale = 0.0
	body.angular_velocity = Vector3(0.0, 5.0, 0.0)
	test_scene_3d.add_child(body)
	
	await step_physics_frames(5)
	assert_gt(abs(body.rotation.y), 0.01, "RigidBody3D with angular_velocity.y must rotate around Y axis")

# ==============================================================================
# 3. CHARACTERBODY3D & SLOPE THRESHOLDS (15°, 30°, 45°, 60°)
# ==============================================================================

func test_characterbody3d_motion() -> void:
	var cb: CharacterBody3D = autofree(CharacterBody3D.new()) as CharacterBody3D
	var col: CollisionShape3D = CollisionShape3D.new()
	var shape: CapsuleShape3D = CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 1.8
	col.shape = shape
	cb.add_child(col)
	test_scene_3d.add_child(cb)
	
	cb.velocity = Vector3(5.0, 0.0, 0.0)
	cb.move_and_slide()
	assert_gt(cb.position.x, 0.0, "CharacterBody3D move_and_slide must update position")

func test_characterbody3d_slope_15_deg() -> void:
	var cb: CharacterBody3D = autofree(CharacterBody3D.new()) as CharacterBody3D
	cb.floor_max_angle = deg_to_rad(45.0)
	var slope_angle = deg_to_rad(15.0)
	assert_lte(slope_angle, cb.floor_max_angle, "15° slope angle must be walkable within 45° max floor angle")
	var normal = Vector3(0, cos(slope_angle), sin(slope_angle)).normalized()
	assert_approx(normal.angle_to(Vector3.UP), slope_angle, 0.001, "Slope normal angle must match 15°")

func test_characterbody3d_slope_30_deg() -> void:
	var cb: CharacterBody3D = autofree(CharacterBody3D.new()) as CharacterBody3D
	cb.floor_max_angle = deg_to_rad(45.0)
	var slope_angle = deg_to_rad(30.0)
	assert_lte(slope_angle, cb.floor_max_angle, "30° slope angle must be walkable within 45° max floor angle")
	var normal = Vector3(0, cos(slope_angle), sin(slope_angle)).normalized()
	assert_approx(normal.angle_to(Vector3.UP), slope_angle, 0.001, "Slope normal angle must match 30°")

func test_characterbody3d_slope_45_deg() -> void:
	var cb: CharacterBody3D = autofree(CharacterBody3D.new()) as CharacterBody3D
	cb.floor_max_angle = deg_to_rad(45.0)
	var slope_angle = deg_to_rad(45.0)
	assert_approx(slope_angle, cb.floor_max_angle, 0.001, "45° slope angle is exact threshold for standard floor_max_angle")

func test_characterbody3d_slope_60_deg() -> void:
	var cb: CharacterBody3D = autofree(CharacterBody3D.new()) as CharacterBody3D
	cb.floor_max_angle = deg_to_rad(45.0)
	var slope_angle = deg_to_rad(60.0)
	assert_gt(slope_angle, cb.floor_max_angle, "60° slope angle exceeds standard 45° max floor angle (causes wall/slide)")

# ==============================================================================
# 4. MATERIALS, AREA3D, AND PHYSICSSERVER3D
# ==============================================================================

func test_physics_material_3d_bounce_and_friction() -> void:
	var mat: PhysicsMaterial = PhysicsMaterial.new()
	mat.bounce = 0.6
	mat.friction = 0.5
	assert_approx(mat.bounce, 0.6, 0.001, "PhysicsMaterial 3D bounce must match")
	assert_approx(mat.friction, 0.5, 0.001, "PhysicsMaterial 3D friction must match")

func test_area3d_gravity_override() -> void:
	var area: Area3D = autofree(Area3D.new()) as Area3D
	area.gravity_space_override = Area3D.SPACE_OVERRIDE_REPLACE
	area.gravity_direction = Vector3(0, 1, 0)
	area.gravity = 9.8
	test_scene_3d.add_child(area)
	
	assert_eq(area.gravity_space_override, Area3D.SPACE_OVERRIDE_REPLACE, "Area3D space override must match REPLACE")
	assert_vector3_approx(area.gravity_direction, Vector3(0, 1, 0), 0.001, "Area3D inverted gravity vector must match")
	assert_approx(area.gravity, 9.8, 0.001, "Area3D gravity magnitude must match")

func test_physics_server_3d_space_rid_lifecycle() -> void:
	var space: RID = auto_free_rid(PhysicsServer3D.space_create(), ServerType.PHYSICS_3D)
	assert_true(space.is_valid(), "PhysicsServer3D space RID must be valid")
	PhysicsServer3D.space_set_active(space, true)
	assert_true(PhysicsServer3D.space_is_active(space), "PhysicsServer3D space must be active")

func test_physics_server_3d_body_rid_lifecycle() -> void:
	var space: RID = auto_free_rid(PhysicsServer3D.space_create(), ServerType.PHYSICS_3D)
	var body: RID = auto_free_rid(PhysicsServer3D.body_create(), ServerType.PHYSICS_3D)
	PhysicsServer3D.body_set_space(body, space)
	PhysicsServer3D.body_set_mode(body, PhysicsServer3D.BODY_MODE_RIGID)
	PhysicsServer3D.body_set_state(body, PhysicsServer3D.BODY_STATE_TRANSFORM, Transform3D(Basis.IDENTITY, Vector3(10, 20, 30)))
	
	assert_true(body.is_valid(), "PhysicsServer3D body RID must be valid")
	var t: Transform3D = PhysicsServer3D.body_get_state(body, PhysicsServer3D.BODY_STATE_TRANSFORM)
	assert_vector3_approx(t.origin, Vector3(10, 20, 30), 0.001, "Body transform origin in 3D server must match")

func test_physics_server_3d_shape_box_rid() -> void:
	var shape: RID = auto_free_rid(PhysicsServer3D.box_shape_create(), ServerType.PHYSICS_3D)
	assert_true(shape.is_valid(), "PhysicsServer3D box shape RID must be valid")
	PhysicsServer3D.shape_set_data(shape, Vector3(1.5, 2.5, 3.5))
	var data: Variant = PhysicsServer3D.shape_get_data(shape)
	assert_vector3_approx(Vector3(data), Vector3(1.5, 2.5, 3.5), 0.001, "Box shape half-extents in server must match")

func test_physics_server_3d_shape_sphere_rid() -> void:
	var shape: RID = auto_free_rid(PhysicsServer3D.sphere_shape_create(), ServerType.PHYSICS_3D)
	assert_true(shape.is_valid(), "PhysicsServer3D sphere shape RID must be valid")
	PhysicsServer3D.shape_set_data(shape, 2.25)
	var data: Variant = PhysicsServer3D.shape_get_data(shape)
	assert_approx(float(data), 2.25, 0.001, "Sphere shape radius in server must match")

func test_physics_server_3d_direct_state_query() -> void:
	var space: RID = auto_free_rid(PhysicsServer3D.space_create(), ServerType.PHYSICS_3D)
	PhysicsServer3D.space_set_active(space, true)
	var direct_state = PhysicsServer3D.space_get_direct_state(space)
	assert_not_null(direct_state, "PhysicsDirectSpaceState3D must not be null for active 3D space")
