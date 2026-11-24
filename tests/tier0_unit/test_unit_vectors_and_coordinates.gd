# test_unit_vectors_and_coordinates.gd
# Tier 0 Pure Unit Suite: Vector2, Vector2i, Vector3, Vector3i, Vector4, Vector4i arithmetic, products, rotations, projections, and snapping.
extends "res://addons/gdtest/core/test_suite.gd"

func _init() -> void:
	suite_name = "Tier0_Unit_Vectors_And_Coordinates_Suite"
	test_type = "unit"

# 1. Vector2 Arithmetic
func test_vector2_arithmetic() -> void:
	var a: Vector2 = Vector2(10.0, 20.0)
	var b: Vector2 = Vector2(30.0, 40.0)
	assert_vector2_approx(a + b, Vector2(40.0, 60.0), 0.001, "Vector2 addition mismatch")
	assert_vector2_approx(b - a, Vector2(20.0, 20.0), 0.001, "Vector2 subtraction mismatch")
	assert_vector2_approx(a * 2.5, Vector2(25.0, 50.0), 0.001, "Vector2 scalar multiplication mismatch")
	assert_vector2_approx(b / 2.0, Vector2(15.0, 20.0), 0.001, "Vector2 scalar division mismatch")
	assert_vector2_approx(-a, Vector2(-10.0, -20.0), 0.001, "Vector2 negation mismatch")
	assert_approx(Vector2(3.0, 4.0).length(), 5.0, 0.001, "Vector2 length mismatch")
	assert_approx(Vector2(3.0, 4.0).length_squared(), 25.0, 0.001, "Vector2 length_squared mismatch")

# 2. Vector2 Dot Product
func test_vector2_dot_product() -> void:
	var right: Vector2 = Vector2.RIGHT
	var up: Vector2 = Vector2.UP
	var left: Vector2 = Vector2.LEFT
	assert_approx(right.dot(up), 0.0, 0.001, "Orthogonal Vector2 dot product must be 0")
	assert_approx(right.dot(right), 1.0, 0.001, "Parallel Vector2 dot product must be 1")
	assert_approx(right.dot(left), -1.0, 0.001, "Anti-parallel Vector2 dot product must be -1")
	assert_approx(Vector2(2.0, 3.0).dot(Vector2(4.0, 5.0)), 23.0, 0.001, "Arbitrary Vector2 dot product mismatch")

# 3. Vector2 Cross Product
func test_vector2_cross_product() -> void:
	var right: Vector2 = Vector2.RIGHT
	var down: Vector2 = Vector2.DOWN
	# In Godot 2D, cross product returns scalar: x * other.y - y * other.x
	assert_approx(right.cross(down), 1.0, 0.001, "Vector2.RIGHT cross Vector2.DOWN must be 1.0")
	assert_approx(down.cross(right), -1.0, 0.001, "Vector2.DOWN cross Vector2.RIGHT must be -1.0")
	assert_approx(Vector2(2.0, 3.0).cross(Vector2(4.0, 5.0)), -2.0, 0.001, "Vector2 2D cross product mismatch")

# 4. Vector2 Angle & Rotation
func test_vector2_angle_and_rotation() -> void:
	var right: Vector2 = Vector2.RIGHT
	var down: Vector2 = Vector2.DOWN
	var up: Vector2 = Vector2.UP
	assert_approx(right.angle(), 0.0, 0.001, "Vector2.RIGHT angle must be 0")
	assert_approx(down.angle(), PI / 2.0, 0.001, "Vector2.DOWN angle must be PI / 2")
	assert_approx(up.angle(), -PI / 2.0, 0.001, "Vector2.UP angle must be -PI / 2")
	assert_vector2_approx(right.rotated(PI / 2.0), down, 0.001, "Rotating RIGHT by PI/2 must yield DOWN")
	assert_approx(right.angle_to(down), PI / 2.0, 0.001, "angle_to from RIGHT to DOWN must be PI/2")

# 5. Vector2 Slide
func test_vector2_slide() -> void:
	var velocity: Vector2 = Vector2(10.0, 10.0)
	var normal: Vector2 = Vector2.UP # (0, -1)
	var slid: Vector2 = velocity.slide(normal)
	assert_vector2_approx(slid, Vector2(10.0, 0.0), 0.001, "Vector2 slide along horizontal plane must zero vertical component")

# 6. Vector2 Bounce
func test_vector2_bounce() -> void:
	var velocity: Vector2 = Vector2(10.0, 10.0)
	var normal: Vector2 = Vector2.UP # (0, -1)
	var bounced: Vector2 = velocity.bounce(normal)
	assert_vector2_approx(bounced, Vector2(10.0, -10.0), 0.001, "Vector2 bounce off floor normal must invert y velocity")

# 7. Vector2 Slerp
func test_vector2_slerp() -> void:
	var from_vec: Vector2 = Vector2.RIGHT
	var to_vec: Vector2 = Vector2.DOWN
	var mid_slerp: Vector2 = from_vec.slerp(to_vec, 0.5)
	var expected: Vector2 = Vector2(cos(PI / 4.0), sin(PI / 4.0))
	assert_vector2_approx(mid_slerp, expected, 0.001, "Vector2 slerp midpoint must equal 45-degree unit vector")
	assert_approx(mid_slerp.length(), 1.0, 0.001, "Vector2 slerp of unit vectors must preserve unit length")

# 8. Vector2 Snapping & Rounding
func test_vector2_snapping() -> void:
	var v: Vector2 = Vector2(1.23, 4.87)
	var snapped_v: Vector2 = v.snapped(Vector2(0.5, 0.5))
	assert_vector2_approx(snapped_v, Vector2(1.0, 5.0), 0.001, "Vector2 snapped mismatch")
	assert_vector2_approx(Vector2(1.7, -2.3).floor(), Vector2(1.0, -3.0), 0.001, "Vector2 floor mismatch")
	assert_vector2_approx(Vector2(1.2, -2.8).ceil(), Vector2(2.0, -2.0), 0.001, "Vector2 ceil mismatch")
	assert_vector2_approx(Vector2(1.4, 1.6).round(), Vector2(1.0, 2.0), 0.001, "Vector2 round mismatch")

# 9. Vector2i Arithmetic & Manhattan
func test_vector2i_arithmetic_and_manhattan() -> void:
	var a: Vector2i = Vector2i(5, 12)
	var b: Vector2i = Vector2i(3, 4)
	assert_eq(a + b, Vector2i(8, 16), "Vector2i addition mismatch")
	assert_eq(a - b, Vector2i(2, 8), "Vector2i subtraction mismatch")
	assert_eq(a * 2, Vector2i(10, 24), "Vector2i scalar multiplication mismatch")
	assert_eq(a / 2, Vector2i(2, 6), "Vector2i integer division mismatch")
	var manhattan_dist: int = abs(a.x - b.x) + abs(a.y - b.y)
	assert_eq(manhattan_dist, 10, "Vector2i Manhattan distance mismatch")
	assert_eq(Vector2i(-5, 8).sign(), Vector2i(-1, 1), "Vector2i sign mismatch")

# 10. Vector2i Aspect Ratio & Snapping
func test_vector2i_aspect_ratio_and_snapping() -> void:
	var res: Vector2i = Vector2i(1920, 1080)
	assert_approx(res.aspect(), 16.0 / 9.0, 0.001, "Vector2i aspect ratio for 1080p must equal 16/9")
	var v: Vector2i = Vector2i(12, 19)
	var snapped_vi: Vector2i = v.snapped(Vector2i(5, 5))
	assert_eq(snapped_vi, Vector2i(10, 20), "Vector2i snapped step (5,5) mismatch")
	var clamped_vi: Vector2i = Vector2i(15, -5).clamp(Vector2i(0, 0), Vector2i(10, 10))
	assert_eq(clamped_vi, Vector2i(10, 0), "Vector2i clamp mismatch")

# 11. Vector3 Arithmetic
func test_vector3_arithmetic() -> void:
	var a: Vector3 = Vector3(1.0, 2.0, 3.0)
	var b: Vector3 = Vector3(4.0, 5.0, 6.0)
	assert_vector3_approx(a + b, Vector3(5.0, 7.0, 9.0), 0.001, "Vector3 addition mismatch")
	assert_vector3_approx(b - a, Vector3(3.0, 3.0, 3.0), 0.001, "Vector3 subtraction mismatch")
	assert_vector3_approx(a * 3.0, Vector3(3.0, 6.0, 9.0), 0.001, "Vector3 scalar multiplication mismatch")
	assert_vector3_approx(b / 2.0, Vector3(2.0, 2.5, 3.0), 0.001, "Vector3 scalar division mismatch")
	assert_approx(Vector3(2.0, 3.0, 6.0).length(), 7.0, 0.001, "Vector3 length (2,3,6) must equal 7")
	assert_approx(Vector3(2.0, 3.0, 6.0).length_squared(), 49.0, 0.001, "Vector3 length_squared (2,3,6) must equal 49")

# 12. Vector3 Dot Product
func test_vector3_dot_product() -> void:
	var right: Vector3 = Vector3.RIGHT
	var up: Vector3 = Vector3.UP
	var forward: Vector3 = Vector3.FORWARD
	assert_approx(right.dot(up), 0.0, 0.001, "Orthogonal Vector3 RIGHT and UP dot product must be 0")
	assert_approx(up.dot(forward), 0.0, 0.001, "Orthogonal Vector3 UP and FORWARD dot product must be 0")
	assert_approx(right.dot(right), 1.0, 0.001, "Parallel Vector3 dot product must be 1")
	assert_approx(Vector3(1.0, 2.0, 3.0).dot(Vector3(4.0, -5.0, 6.0)), 12.0, 0.001, "Vector3 dot product mismatch")

# 13. Vector3 Cross Product
func test_vector3_cross_product() -> void:
	var right: Vector3 = Vector3.RIGHT
	var up: Vector3 = Vector3.UP
	var back: Vector3 = Vector3.BACK # (0, 0, 1)
	var forward: Vector3 = Vector3.FORWARD # (0, 0, -1)
	assert_vector3_approx(right.cross(up), back, 0.001, "Vector3 RIGHT cross UP must equal BACK")
	assert_vector3_approx(up.cross(right), forward, 0.001, "Vector3 UP cross RIGHT must equal FORWARD")
	assert_vector3_approx(up.cross(back), right, 0.001, "Vector3 UP cross BACK must equal RIGHT")

# 14. Vector3 Angle To & Signed Angle To
func test_vector3_angle_to_and_signed_angle_to() -> void:
	var right: Vector3 = Vector3.RIGHT
	var up: Vector3 = Vector3.UP
	var back: Vector3 = Vector3.BACK
	assert_approx(right.angle_to(up), PI / 2.0, 0.001, "Vector3 angle_to between RIGHT and UP must be PI/2")
	assert_approx(right.signed_angle_to(up, back), PI / 2.0, 0.001, "Vector3 signed_angle_to around BACK must be +PI/2")
	assert_approx(up.signed_angle_to(right, back), -PI / 2.0, 0.001, "Vector3 signed_angle_to around BACK must be -PI/2")

# 15. Vector3 Slide
func test_vector3_slide() -> void:
	var velocity: Vector3 = Vector3(10.0, -5.0, 20.0)
	var normal: Vector3 = Vector3.UP
	var slid: Vector3 = velocity.slide(normal)
	assert_vector3_approx(slid, Vector3(10.0, 0.0, 20.0), 0.001, "Vector3 slide on floor normal must zero Y component")

# 16. Vector3 Bounce
func test_vector3_bounce() -> void:
	var velocity: Vector3 = Vector3(5.0, -10.0, 5.0)
	var normal: Vector3 = Vector3.UP
	var bounced: Vector3 = velocity.bounce(normal)
	assert_vector3_approx(bounced, Vector3(5.0, 10.0, 5.0), 0.001, "Vector3 bounce on floor normal must reflect Y component")

# 17. Vector3 Slerp & Bezier Interpolate
func test_vector3_slerp_and_bezier_interpolate() -> void:
	var from_vec: Vector3 = Vector3.RIGHT
	var to_vec: Vector3 = Vector3.UP
	var mid_slerp: Vector3 = from_vec.slerp(to_vec, 0.5)
	assert_vector3_approx(mid_slerp, Vector3(0.707107, 0.707107, 0.0), 0.001, "Vector3 slerp midpoint mismatch")
	
	var p0: Vector3 = Vector3.ZERO
	var p1: Vector3 = Vector3(0.0, 10.0, 0.0)
	var p2: Vector3 = Vector3(10.0, 10.0, 0.0)
	var p3: Vector3 = Vector3(10.0, 0.0, 0.0)
	var b_mid: Vector3 = p0.bezier_interpolate(p1, p2, p3, 0.5)
	assert_vector3_approx(b_mid, Vector3(5.0, 7.5, 0.0), 0.001, "Vector3 cubic bezier midpoint mismatch")

# 18. Vector3 Snapping & Clamping
func test_vector3_snapping_and_clamping() -> void:
	var v: Vector3 = Vector3(1.23, 4.56, 7.89)
	var snapped_v: Vector3 = v.snapped(Vector3(0.5, 0.5, 0.5))
	assert_vector3_approx(snapped_v, Vector3(1.0, 4.5, 8.0), 0.001, "Vector3 snapped mismatch")
	var limited: Vector3 = Vector3(10.0, 0.0, 0.0).limit_length(5.0)
	assert_vector3_approx(limited, Vector3(5.0, 0.0, 0.0), 0.001, "Vector3 limit_length mismatch")
	var clamped_v: Vector3 = Vector3(-5.0, 15.0, 3.0).clamp(Vector3.ZERO, Vector3(10.0, 10.0, 10.0))
	assert_vector3_approx(clamped_v, Vector3(0.0, 10.0, 3.0), 0.001, "Vector3 clamp mismatch")

# 19. Vector3i Arithmetic & Coordinates
func test_vector3i_arithmetic_and_coordinates() -> void:
	var a: Vector3i = Vector3i(1, 2, 3)
	var b: Vector3i = Vector3i(4, 5, 6)
	assert_eq(a + b, Vector3i(5, 7, 9), "Vector3i addition mismatch")
	assert_eq(b - a, Vector3i(3, 3, 3), "Vector3i subtraction mismatch")
	assert_eq(a * 3, Vector3i(3, 6, 9), "Vector3i scalar multiplication mismatch")
	assert_eq(Vector3i(-5, 10, -15).abs(), Vector3i(5, 10, 15), "Vector3i abs mismatch")
	assert_eq(Vector3i(-5, 0, 8).sign(), Vector3i(-1, 0, 1), "Vector3i sign mismatch")
	assert_eq(Vector3i(2, 8, 4).min(Vector3i(5, 3, 6)), Vector3i(2, 3, 4), "Vector3i component min mismatch")
	assert_eq(Vector3i(2, 8, 4).max(Vector3i(5, 3, 6)), Vector3i(5, 8, 6), "Vector3i component max mismatch")

# 20. Vector3i Distance & Grid Clamping
func test_vector3i_distance_and_grid() -> void:
	var origin: Vector3i = Vector3i.ZERO
	var target: Vector3i = Vector3i(2, 3, 6)
	assert_approx(origin.distance_to(target), 7.0, 0.001, "Vector3i distance_to (2,3,6) must equal 7.0")
	assert_approx(origin.distance_squared_to(target), 49.0, 0.001, "Vector3i distance_squared_to (2,3,6) must equal 49")
	var clamped_vi: Vector3i = Vector3i(1, -2, 5).clamp(Vector3i(0, 0, 0), Vector3i(2, 2, 2))
	assert_eq(clamped_vi, Vector3i(1, 0, 2), "Vector3i grid clamp mismatch")

# 21. Vector4 Arithmetic & Lengths
func test_vector4_arithmetic_and_lengths() -> void:
	var a: Vector4 = Vector4(1.0, 2.0, 3.0, 4.0)
	var b: Vector4 = Vector4(5.0, 6.0, 7.0, 8.0)
	assert_vector4_approx(a + b, Vector4(6.0, 8.0, 10.0, 12.0), 0.001, "Vector4 addition mismatch")
	assert_vector4_approx(b - a, Vector4(4.0, 4.0, 4.0, 4.0), 0.001, "Vector4 subtraction mismatch")
	assert_approx(a.length_squared(), 30.0, 0.001, "Vector4 (1,2,3,4) length_squared must equal 30")
	assert_approx(Vector4(0.0, 0.0, 3.0, 4.0).length(), 5.0, 0.001, "Vector4 (0,0,3,4) length must equal 5")
	assert_approx(a.normalized().length(), 1.0, 0.001, "Vector4 normalized length must equal 1")

# 22. Vector4 Dot & Lerp
func test_vector4_dot_and_lerp() -> void:
	var a: Vector4 = Vector4(1.0, 2.0, 3.0, 4.0)
	var b: Vector4 = Vector4(2.0, 0.0, -1.0, 1.0)
	assert_approx(a.dot(b), 3.0, 0.001, "Vector4 dot product (1*2 + 2*0 + 3*-1 + 4*1 = 3) mismatch")
	var mid: Vector4 = Vector4.ZERO.lerp(Vector4(2.0, 4.0, 6.0, 8.0), 0.5)
	assert_vector4_approx(mid, Vector4(1.0, 2.0, 3.0, 4.0), 0.001, "Vector4 lerp midpoint mismatch")

# 23. Vector4i Arithmetic
func test_vector4i_arithmetic() -> void:
	var a: Vector4i = Vector4i(10, 20, 30, 40)
	var b: Vector4i = Vector4i(1, 2, 3, 4)
	assert_eq(a - b, Vector4i(9, 18, 27, 36), "Vector4i subtraction mismatch")
	assert_eq(b * 2, Vector4i(2, 4, 6, 8), "Vector4i scalar multiplication mismatch")
	assert_eq(Vector4i(-10, 20, -30, 40).abs(), Vector4i(10, 20, 30, 40), "Vector4i abs mismatch")
	assert_eq(a.min(b), b, "Vector4i min mismatch")
	assert_eq(a.max(b), a, "Vector4i max mismatch")

# 24. Vector4i Equality & Constants
func test_vector4i_equality_and_hashing() -> void:
	var v_zero: Vector4i = Vector4i.ZERO
	var v_one: Vector4i = Vector4i.ONE
	assert_eq(v_zero, Vector4i(0, 0, 0, 0), "Vector4i.ZERO mismatch")
	assert_eq(v_one, Vector4i(1, 1, 1, 1), "Vector4i.ONE mismatch")
	assert_ne(Vector4i(1, 2, 3, 4), Vector4i(1, 2, 3, 5), "Vector4i inequality mismatch")
	assert_eq(hash(Vector4i(1, 2, 3, 4)), hash(Vector4i(1, 2, 3, 4)), "Vector4i hash determinism mismatch")
