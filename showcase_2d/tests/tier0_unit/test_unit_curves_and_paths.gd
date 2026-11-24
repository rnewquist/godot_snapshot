# test_unit_curves_and_paths.gd
# Tier 0 Pure Unit Suite: Curve, Curve2D, and Curve3D baking, interpolation, tangents, and sampled lengths.
extends "res://addons/gdtest/core/test_suite.gd"

func _init() -> void:
	suite_name = "Tier0_Unit_Curves_And_Paths_Suite"
	test_type = "unit"

# 1. Curve 1D Point Management
func test_curve1d_point_management() -> void:
	var curve: Curve = Curve.new()
	assert_eq(curve.point_count, 0, "Initial curve point count must be 0")
	curve.add_point(Vector2(0.0, 0.0))
	curve.add_point(Vector2(1.0, 1.0))
	assert_eq(curve.point_count, 2, "Curve point count must equal 2")
	assert_vector2_approx(curve.get_point_position(0), Vector2(0.0, 0.0), 0.001, "Curve point 0 position mismatch")
	assert_vector2_approx(curve.get_point_position(1), Vector2(1.0, 1.0), 0.001, "Curve point 1 position mismatch")
	curve.remove_point(0)
	assert_eq(curve.point_count, 1, "Curve point count after removal must be 1")
	curve.clear_points()
	assert_eq(curve.point_count, 0, "Curve point count after clear must be 0")

# 2. Curve 1D Linear Sampling
func test_curve1d_linear_sampling() -> void:
	var curve: Curve = Curve.new()
	curve.max_value = 10.0
	curve.add_point(Vector2(0.0, 0.0))
	curve.add_point(Vector2(1.0, 10.0))
	assert_approx(curve.sample(0.0), 0.0, 0.001, "Curve sample at 0.0 must be 0.0")
	assert_approx(curve.sample(0.5), 5.0, 0.01, "Curve sample at 0.5 must be 5.0")
	assert_approx(curve.sample(1.0), 10.0, 0.001, "Curve sample at 1.0 must be 10.0")
	assert_approx(curve.sample(0.25), 1.5625, 0.01, "Curve sample at 0.25 must match cubic easing value (1.5625)")

# 3. Curve 1D Tangents & Easing
func test_curve1d_tangents_and_easing() -> void:
	var curve: Curve = Curve.new()
	curve.add_point(Vector2(0.0, 0.0), 0.0, 0.0) # Start flat
	curve.add_point(Vector2(1.0, 1.0), 2.0, 0.0) # Fast rise
	curve.bake()
	var mid_val: float = curve.sample_baked(0.5)
	assert_in_range(mid_val, 0.0, 1.0, "Eased curve midpoint must be in range [0, 1]")
	assert_lt(mid_val, 0.5, "Ease-in curve midpoint must be lower than linear midpoint (0.5)")

# 4. Curve 1D Bake & Sample Baked
func test_curve1d_bake_and_sample_baked() -> void:
	var curve: Curve = Curve.new()
	curve.max_value = 100.0
	curve.bake_resolution = 100
	curve.add_point(Vector2(0.0, 0.0))
	curve.add_point(Vector2(1.0, 100.0))
	curve.bake()
	assert_approx(curve.sample_baked(0.5), 50.0, 0.1, "Sample baked at 0.5 must approximate 50.0")
	assert_approx(curve.sample_baked(0.0), 0.0, 0.01, "Sample baked at 0.0 must approximate 0.0")
	assert_approx(curve.sample_baked(1.0), 100.0, 0.01, "Sample baked at 1.0 must approximate 100.0")

# 5. Curve2D Point Management
func test_curve2d_point_management() -> void:
	var c2: Curve2D = Curve2D.new()
	assert_eq(c2.point_count, 0, "Initial Curve2D point count must be 0")
	c2.add_point(Vector2(0.0, 0.0), Vector2(-10.0, 0.0), Vector2(10.0, 0.0))
	c2.add_point(Vector2(100.0, 0.0), Vector2(-10.0, 0.0), Vector2(10.0, 0.0))
	assert_eq(c2.point_count, 2, "Curve2D point count must be 2")
	assert_vector2_approx(c2.get_point_position(0), Vector2(0.0, 0.0), 0.001, "Curve2D point 0 position mismatch")
	assert_vector2_approx(c2.get_point_out(0), Vector2(10.0, 0.0), 0.001, "Curve2D point 0 out tangent mismatch")
	c2.set_point_in(1, Vector2(-20.0, 0.0))
	assert_vector2_approx(c2.get_point_in(1), Vector2(-20.0, 0.0), 0.001, "Curve2D point 1 in tangent mismatch")

# 6. Curve2D Sample Baked
func test_curve2d_sample_baked() -> void:
	var c2: Curve2D = Curve2D.new()
	c2.add_point(Vector2(0.0, 0.0))
	c2.add_point(Vector2(200.0, 0.0))
	var sample_mid: Vector2 = c2.sample_baked(100.0)
	assert_vector2_approx(sample_mid, Vector2(100.0, 0.0), 0.1, "Straight Curve2D midpoint sample mismatch")
	var sample_end: Vector2 = c2.sample_baked(200.0)
	assert_vector2_approx(sample_end, Vector2(200.0, 0.0), 0.1, "Straight Curve2D end sample mismatch")

# 7. Curve2D Baked Length
func test_curve2d_baked_length() -> void:
	var c2_straight: Curve2D = Curve2D.new()
	c2_straight.add_point(Vector2(0.0, 0.0))
	c2_straight.add_point(Vector2(100.0, 0.0))
	assert_approx(c2_straight.get_baked_length(), 100.0, 0.1, "Straight line length must be 100.0")
	
	var c2_curved: Curve2D = Curve2D.new()
	c2_curved.add_point(Vector2(0.0, 0.0), Vector2.ZERO, Vector2(0.0, -50.0))
	c2_curved.add_point(Vector2(100.0, 0.0), Vector2(0.0, -50.0), Vector2.ZERO)
	assert_gt(c2_curved.get_baked_length(), 100.0, "Curved arc length must exceed chord distance 100.0")

# 8. Curve2D Sample Baked With Rotation
func test_curve2d_sample_baked_with_rotation() -> void:
	var c2: Curve2D = Curve2D.new()
	c2.add_point(Vector2(0.0, 0.0))
	c2.add_point(Vector2(100.0, 0.0))
	var t: Transform2D = c2.sample_baked_with_rotation(50.0)
	assert_vector2_approx(t.origin, Vector2(50.0, 0.0), 0.1, "Sampled transform origin mismatch")
	assert_approx(t.get_rotation(), 0.0, 0.01, "Horizontal line rotation must be 0")

# 9. Curve3D Point Management
func test_curve3d_point_management() -> void:
	var c3: Curve3D = Curve3D.new()
	assert_eq(c3.point_count, 0, "Initial Curve3D point count must be 0")
	c3.add_point(Vector3(0.0, 0.0, 0.0), Vector3.ZERO, Vector3.ZERO)
	c3.add_point(Vector3(0.0, 50.0, 0.0), Vector3.ZERO, Vector3.ZERO)
	assert_eq(c3.point_count, 2, "Curve3D point count must be 2")
	c3.set_point_tilt(0, 0.5)
	assert_approx(c3.get_point_tilt(0), 0.5, 0.001, "Curve3D point tilt mismatch")

# 10. Curve3D Sample Baked & Length
func test_curve3d_sample_baked_and_length() -> void:
	var c3: Curve3D = Curve3D.new()
	c3.add_point(Vector3(0.0, 0.0, 0.0))
	c3.add_point(Vector3(0.0, 100.0, 0.0))
	assert_approx(c3.get_baked_length(), 100.0, 0.1, "Curve3D baked length must equal 100.0")
	var sampled: Vector3 = c3.sample_baked(50.0)
	assert_vector3_approx(sampled, Vector3(0.0, 50.0, 0.0), 0.1, "Curve3D sample_baked at 50 must equal (0,50,0)")

# 11. Curve3D Sample Baked Up Vector
func test_curve3d_sample_baked_up_vector() -> void:
	var c3: Curve3D = Curve3D.new()
	c3.up_vector_enabled = true
	c3.add_point(Vector3(0.0, 0.0, 0.0))
	c3.add_point(Vector3(100.0, 0.0, 0.0))
	var up_vec: Vector3 = c3.sample_baked_up_vector(50.0)
	assert_approx(up_vec.length(), 1.0, 0.01, "Up vector must be unit length")
	assert_vector3_approx(up_vec, Vector3.UP, 0.05, "Default curve up vector must align with Vector3.UP")

# 12. Curve3D Closest Point & Offset
func test_curve3d_closest_point_and_offset() -> void:
	var c3: Curve3D = Curve3D.new()
	c3.add_point(Vector3(0.0, 0.0, 0.0))
	c3.add_point(Vector3(0.0, 100.0, 0.0))
	var query: Vector3 = Vector3(10.0, 40.0, 0.0)
	var closest_pt: Vector3 = c3.get_closest_point(query)
	assert_vector3_approx(closest_pt, Vector3(0.0, 40.0, 0.0), 0.1, "Curve3D closest point mismatch")
	var closest_off: float = c3.get_closest_offset(query)
	assert_approx(closest_off, 40.0, 0.1, "Curve3D closest offset mismatch")
