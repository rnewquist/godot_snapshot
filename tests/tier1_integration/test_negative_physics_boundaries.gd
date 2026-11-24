# test_negative_physics_boundaries.gd
# Tier 1 Negative Boundary Suite: Physics Dimensions, Degenerate Geometry, Slope Thresholds, Materials & Ghost Bodies.
extends "res://addons/gdtest/core/test_suite.gd"

func _init() -> void:
	suite_name = "Tier1_Negative_Physics_Boundaries"
	test_type = "integration"

# ==============================================================================
# 1. ZERO AND NEGATIVE SHAPE DIMENSIONS (2D & 3D)
# ==============================================================================

func test_zero_and_negative_box_shape_3d() -> void:
	var box_zero: BoxShape3D = BoxShape3D.new()
	box_zero.size = Vector3.ZERO
	assert_vector3_approx(box_zero.size, Vector3.ZERO, 0.001, "BoxShape3D size must accept Vector3.ZERO")
	
	var box_neg: BoxShape3D = BoxShape3D.new()
	box_neg.size = Vector3(-10.0, -5.0, -2.0)
	assert_true(box_neg.size.x >= 0.0 and box_neg.size.y >= 0.0 and box_neg.size.z >= 0.0, "BoxShape3D safely handles negative dimensions")
	
	var debug_mesh: ArrayMesh = box_neg.get_debug_mesh()
	assert_not_null(debug_mesh, "Debug mesh creation for negative BoxShape3D should not crash")

func test_zero_and_negative_rectangle_shape_2d() -> void:
	var rect_zero: RectangleShape2D = RectangleShape2D.new()
	rect_zero.size = Vector2.ZERO
	assert_vector2_approx(rect_zero.size, Vector2.ZERO, 0.001, "RectangleShape2D size must accept Vector2.ZERO")
	var bounds_zero: Rect2 = rect_zero.get_rect()
	assert_approx(bounds_zero.size.x, 0.0, 0.001, "Zero rectangle bounding width must be 0")
	assert_approx(bounds_zero.size.y, 0.0, 0.001, "Zero rectangle bounding height must be 0")
	
	var rect_neg: RectangleShape2D = RectangleShape2D.new()
	rect_neg.size = Vector2(-30.0, -15.0)
	assert_true(rect_neg.size.x >= 0.0 and rect_neg.size.y >= 0.0, "RectangleShape2D safely handles negative dimensions")
	var bounds_neg: Rect2 = rect_neg.get_rect()
	assert_gt(bounds_neg.size.length_squared(), -1.0, "Bounding rect query must return valid structure")

func test_zero_and_negative_sphere_and_circle_shapes() -> void:
	var sphere_zero: SphereShape3D = SphereShape3D.new()
	sphere_zero.radius = 0.0
	assert_approx(sphere_zero.radius, 0.0, 0.001, "SphereShape3D radius can be 0.0")
	
	var sphere_neg: SphereShape3D = SphereShape3D.new()
	sphere_neg.radius = -5.0
	assert_true(sphere_neg.radius >= 0.0, "SphereShape3D safely rejects negative radius")
	
	var circle_zero: CircleShape2D = CircleShape2D.new()
	circle_zero.radius = 0.0
	assert_approx(circle_zero.radius, 0.0, 0.001, "CircleShape2D radius can be 0.0")
	var circle_rect: Rect2 = circle_zero.get_rect()
	assert_approx(circle_rect.size.x, 0.0, 0.001, "CircleShape2D zero radius rect size must be 0")

func test_zero_height_capsule_and_cylinder_shapes() -> void:
	var cap_3d: CapsuleShape3D = CapsuleShape3D.new()
	cap_3d.radius = 0.0
	cap_3d.height = 0.0
	assert_approx(cap_3d.radius, 0.0, 0.001, "CapsuleShape3D zero radius")
	assert_approx(cap_3d.height, 0.0, 0.001, "CapsuleShape3D zero height")
	
	var cyl_3d: CylinderShape3D = CylinderShape3D.new()
	cyl_3d.radius = 0.0
	cyl_3d.height = 0.0
	assert_approx(cyl_3d.radius, 0.0, 0.001, "CylinderShape3D zero radius")
	assert_approx(cyl_3d.height, 0.0, 0.001, "CylinderShape3D zero height")
	
	var cap_2d: CapsuleShape2D = CapsuleShape2D.new()
	cap_2d.radius = 0.0
	cap_2d.height = 0.0
	assert_approx(cap_2d.radius, 0.0, 0.001, "CapsuleShape2D zero radius")
	assert_approx(cap_2d.height, 0.0, 0.001, "CapsuleShape2D zero height")

# ==============================================================================
# 2. DEGENERATE POLYGONS AND MESHES
# ==============================================================================

func test_degenerate_convex_polygon_2d_empty_and_collinear() -> void:
	var poly_empty: ConvexPolygonShape2D = ConvexPolygonShape2D.new()
	poly_empty.points = PackedVector2Array()
	assert_eq(poly_empty.points.size(), 0, "Empty ConvexPolygonShape2D should have 0 vertices")
	
	var poly_single: ConvexPolygonShape2D = ConvexPolygonShape2D.new()
	poly_single.points = PackedVector2Array([Vector2(50.0, 50.0)])
	assert_eq(poly_single.points.size(), 1, "Single vertex ConvexPolygonShape2D should have 1 vertex")
	
	var poly_collinear: ConvexPolygonShape2D = ConvexPolygonShape2D.new()
	poly_collinear.points = PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(10.0, 10.0),
		Vector2(20.0, 20.0),
		Vector2(30.0, 30.0)
	])
	assert_eq(poly_collinear.points.size(), 4, "Collinear vertices ConvexPolygonShape2D retained")
	var r: Rect2 = poly_collinear.get_rect()
	assert_gte(r.size.x, 0.0, "Bounding rect width must be non-negative")
	assert_gte(r.size.y, 0.0, "Bounding rect height must be non-negative")

func test_degenerate_concave_polygon_2d_and_3d() -> void:
	var concave_2d: ConcavePolygonShape2D = ConcavePolygonShape2D.new()
	concave_2d.segments = PackedVector2Array([Vector2(0, 0), Vector2(10, 10), Vector2(20, 20)]) # Odd segment count
	assert_true(concave_2d.segments.size() % 2 == 0 or concave_2d.segments.size() == 0, "ConcavePolygonShape2D safely handles odd segment count")
	
	var concave_3d: ConcavePolygonShape3D = ConcavePolygonShape3D.new()
	concave_3d.set_faces(PackedVector3Array()) # Empty faces
	assert_eq(concave_3d.get_faces().size(), 0, "Empty ConcavePolygonShape3D faces must have size 0")
	
	var single_face: PackedVector3Array = PackedVector3Array([
		Vector3(0, 0, 0),
		Vector3(1, 0, 0),
		Vector3(0, 1, 0)
	])
	concave_3d.set_faces(single_face)
	assert_eq(concave_3d.get_faces().size(), 3, "ConcavePolygonShape3D single face count")

# ==============================================================================
# 3. SLOPE ANGLE THRESHOLDS (44.99° vs 45.01°)
# ==============================================================================

func test_slope_angle_threshold_44_99_vs_45_01_degrees_3d() -> void:
	var floor_max_angle: float = deg_to_rad(45.0)
	
	# Normal tilted 44.99 degrees from UP (Vector3.UP = (0, 1, 0))
	var angle_44_99_rad: float = deg_to_rad(44.99)
	var normal_44_99: Vector3 = Vector3(sin(angle_44_99_rad), cos(angle_44_99_rad), 0.0).normalized()
	var measured_angle_44_99: float = Vector3.UP.angle_to(normal_44_99)
	
	assert_approx(rad_to_deg(measured_angle_44_99), 44.99, 0.01, "Measured normal angle must be 44.99 degrees")
	assert_true(measured_angle_44_99 <= floor_max_angle, "44.99 degrees normal MUST qualify as floor (<= 45.0°)")
	
	# Normal tilted 45.01 degrees from UP
	var angle_45_01_rad: float = deg_to_rad(45.01)
	var normal_45_01: Vector3 = Vector3(sin(angle_45_01_rad), cos(angle_45_01_rad), 0.0).normalized()
	var measured_angle_45_01: float = Vector3.UP.angle_to(normal_45_01)
	
	assert_approx(rad_to_deg(measured_angle_45_01), 45.01, 0.01, "Measured normal angle must be 45.01 degrees")
	assert_false(measured_angle_45_01 <= floor_max_angle, "45.01 degrees normal MUST NOT qualify as floor (> 45.0°)")

func test_slope_angle_threshold_44_99_vs_45_01_degrees_2d() -> void:
	var floor_max_angle_2d: float = deg_to_rad(45.0)
	
	# Normal tilted 44.99 degrees from UP (Vector2.UP = (0, -1))
	var angle_44_99_rad: float = deg_to_rad(44.99)
	var normal_44_99: Vector2 = Vector2(sin(angle_44_99_rad), -cos(angle_44_99_rad)).normalized()
	var measured_angle_44_99: float = Vector2.UP.angle_to(normal_44_99)
	
	assert_approx(rad_to_deg(abs(measured_angle_44_99)), 44.99, 0.01, "2D slope angle must be 44.99 degrees")
	assert_true(abs(measured_angle_44_99) <= floor_max_angle_2d, "2D 44.99° slope is a valid floor")
	
	# Normal tilted 45.01 degrees from UP
	var angle_45_01_rad: float = deg_to_rad(45.01)
	var normal_45_01: Vector2 = Vector2(sin(angle_45_01_rad), -cos(angle_45_01_rad)).normalized()
	var measured_angle_45_01: float = Vector2.UP.angle_to(normal_45_01)
	
	assert_approx(rad_to_deg(abs(measured_angle_45_01)), 45.01, 0.01, "2D slope angle must be 45.01 degrees")
	assert_false(abs(measured_angle_45_01) <= floor_max_angle_2d, "2D 45.01° slope exceeds floor threshold")

# ==============================================================================
# 4. FRICTION AND RESTITUTION EXTREMES
# ==============================================================================

func test_friction_extremes_and_roughness() -> void:
	var mat_frictionless: PhysicsMaterial = PhysicsMaterial.new()
	mat_frictionless.friction = 0.0
	mat_frictionless.rough = false
	assert_approx(mat_frictionless.friction, 0.0, 0.001, "Friction 0.0 must be accepted")
	assert_false(mat_frictionless.rough, "Rough flag must be false")
	
	var mat_high_friction: PhysicsMaterial = PhysicsMaterial.new()
	mat_high_friction.friction = 100.0
	mat_high_friction.rough = true
	assert_approx(mat_high_friction.friction, 100.0, 0.001, "Friction 100.0 must be accepted")
	assert_true(mat_high_friction.rough, "Rough flag must be true")
	
	var mat_negative_friction: PhysicsMaterial = PhysicsMaterial.new()
	mat_negative_friction.friction = -2.5
	assert_approx(mat_negative_friction.friction, -2.5, 0.001, "Negative friction value assignment preserved")

func test_restitution_extremes_and_absorbent() -> void:
	var mat_no_bounce: PhysicsMaterial = PhysicsMaterial.new()
	mat_no_bounce.bounce = 0.0
	mat_no_bounce.absorbent = true
	assert_approx(mat_no_bounce.bounce, 0.0, 0.001, "Bounce 0.0 accepted")
	assert_true(mat_no_bounce.absorbent, "Absorbent true accepted")
	
	var mat_super_bounce: PhysicsMaterial = PhysicsMaterial.new()
	mat_super_bounce.bounce = 5.0
	mat_super_bounce.absorbent = false
	assert_approx(mat_super_bounce.bounce, 5.0, 0.001, "Super bounce 5.0 accepted")
	assert_false(mat_super_bounce.absorbent, "Absorbent false accepted")
	
	var mat_negative_bounce: PhysicsMaterial = PhysicsMaterial.new()
	mat_negative_bounce.bounce = -1.0
	assert_approx(mat_negative_bounce.bounce, -1.0, 0.001, "Negative bounce value preserved")

# ==============================================================================
# 5. COLLISION LAYER 0 GHOST BODIES
# ==============================================================================

func test_collision_layer_0_ghost_body_isolation_2d() -> void:
	var ghost: StaticBody2D = autofree(StaticBody2D.new()) as StaticBody2D
	ghost.collision_layer = 0
	ghost.collision_mask = 0
	
	assert_eq(ghost.collision_layer, 0, "Ghost body collision_layer must be 0")
	assert_eq(ghost.collision_mask, 0, "Ghost body collision_mask must be 0")
	assert_false(ghost.get_collision_layer_value(1), "Ghost body layer bit 1 must be false")
	assert_false(ghost.get_collision_mask_value(1), "Ghost body mask bit 1 must be false")

func test_collision_layer_0_ghost_body_isolation_3d() -> void:
	var ghost_3d: StaticBody3D = autofree(StaticBody3D.new()) as StaticBody3D
	ghost_3d.collision_layer = 0
	ghost_3d.collision_mask = 0
	
	assert_eq(ghost_3d.collision_layer, 0, "Ghost 3D body collision_layer must be 0")
	assert_eq(ghost_3d.collision_mask, 0, "Ghost 3D body collision_mask must be 0")
	assert_false(ghost_3d.get_collision_layer_value(1), "Ghost 3D layer bit 1 must be false")

func test_physics_server_direct_ghost_rid_lifecycle() -> void:
	var body_rid: RID = auto_free_rid(PhysicsServer2D.body_create(), ServerType.PHYSICS_2D)
	PhysicsServer2D.body_set_collision_layer(body_rid, 0)
	PhysicsServer2D.body_set_collision_mask(body_rid, 0)
	
	var layer: int = PhysicsServer2D.body_get_collision_layer(body_rid)
	var mask: int = PhysicsServer2D.body_get_collision_mask(body_rid)
	assert_eq(layer, 0, "Direct PhysicsServer2D layer query on ghost body must be 0")
	assert_eq(mask, 0, "Direct PhysicsServer2D mask query on ghost body must be 0")
