# test_unit_transforms_basis_quaternions.gd
# Tier 0 Pure Unit Suite: Transform2D, Transform3D, Basis, 6 Euler orders, determinants, and Quaternions (slerp/squad).
extends "res://addons/gdtest/core/test_suite.gd"

func _init() -> void:
	suite_name = "Tier0_Unit_Transforms_Basis_Quaternions_Suite"
	test_type = "unit"

# 1. Transform2D Identity & Components
func test_transform2d_identity_and_components() -> void:
	var t: Transform2D = Transform2D.IDENTITY
	assert_vector2_approx(t.x, Vector2(1.0, 0.0), 0.001, "Transform2D X axis must be (1,0)")
	assert_vector2_approx(t.y, Vector2(0.0, 1.0), 0.001, "Transform2D Y axis must be (0,1)")
	assert_vector2_approx(t.origin, Vector2(0.0, 0.0), 0.001, "Transform2D origin must be (0,0)")
	var pt: Vector2 = Vector2(15.0, 25.0)
	assert_vector2_approx(t * pt, pt, 0.001, "Identity Transform2D applied to vector must not change it")

# 2. Transform2D Translation & Rotation
func test_transform2d_translation_and_rotation() -> void:
	var angle: float = PI / 2.0
	var offset: Vector2 = Vector2(50.0, 100.0)
	var t: Transform2D = Transform2D(angle, offset)
	var pt: Vector2 = Vector2(10.0, 0.0)
	var transformed: Vector2 = t * pt
	assert_vector2_approx(transformed, Vector2(50.0, 110.0), 0.01, "Transform2D 90 deg rotation with translation mismatch")

# 3. Transform2D Scaling & Shearing
func test_transform2d_scaling_and_shearing() -> void:
	var t: Transform2D = Transform2D.IDENTITY.scaled(Vector2(2.0, 3.0))
	var pt: Vector2 = Vector2(5.0, 10.0)
	assert_vector2_approx(t * pt, Vector2(10.0, 30.0), 0.001, "Transform2D non-uniform scale mismatch")
	assert_approx(t.get_scale().x, 2.0, 0.001, "Transform2D scale.x mismatch")
	assert_approx(t.get_scale().y, 3.0, 0.001, "Transform2D scale.y mismatch")

# 4. Transform2D Affine Inverse
func test_transform2d_affine_inverse() -> void:
	var t: Transform2D = Transform2D(PI / 3.0, Vector2(120.0, -80.0)).scaled(Vector2(1.5, 2.5))
	var t_inv: Transform2D = t.affine_inverse()
	var product: Transform2D = t * t_inv
	assert_transform2d_approx(product, Transform2D.IDENTITY, 0.001, "Transform2D multiplied by affine inverse must yield IDENTITY")
	var pt: Vector2 = Vector2(42.0, 99.0)
	assert_vector2_approx(t_inv * (t * pt), pt, 0.001, "Point transformed then inverse transformed must roundtrip")

# 5. Transform2D Interpolation
func test_transform2d_interpolation() -> void:
	var t1: Transform2D = Transform2D(0.0, Vector2(0.0, 0.0))
	var t2: Transform2D = Transform2D(PI, Vector2(100.0, 200.0))
	var mid: Transform2D = t1.interpolate_with(t2, 0.5)
	assert_vector2_approx(mid.origin, Vector2(50.0, 100.0), 0.001, "Transform2D interpolated origin must match midpoint")
	assert_approx(abs(mid.get_rotation()), PI / 2.0, 0.01, "Transform2D interpolated rotation magnitude must match PI/2")

# 6. Basis Identity & Orthonormality
func test_basis_identity_and_orthonormality() -> void:
	var b: Basis = Basis.IDENTITY
	assert_true(b.is_conformal(), "Identity Basis must be conformal")
	assert_true(b.is_finite(), "Identity Basis must be finite")
	assert_approx(b.determinant(), 1.0, 0.001, "Identity Basis determinant must be 1.0")

# 7. Basis Determinant & Scaling
func test_basis_determinant_and_scale() -> void:
	var scale_basis: Basis = Basis.from_scale(Vector3(2.0, 3.0, 4.0))
	assert_approx(scale_basis.determinant(), 24.0, 0.001, "Scaled Basis determinant must equal product of scale components (24.0)")
	var reflection: Basis = Basis.from_scale(Vector3(-1.0, 1.0, 1.0))
	assert_approx(reflection.determinant(), -1.0, 0.001, "Reflected Basis determinant must equal -1.0")

# 8. Basis Inverse & Transposition
func test_basis_inverse_and_transposition() -> void:
	var rot: Basis = Basis(Vector3.UP, PI / 4.0)
	assert_true(rot.is_conformal(), "Pure rotation Basis must be conformal")
	var inv: Basis = rot.inverse()
	var transp: Basis = rot.transposed()
	# For orthonormal basis, inverse equals transposed
	assert_vector3_approx(inv.x, transp.x, 0.001, "Orthonormal basis inverse.x must match transpose.x")
	assert_vector3_approx(inv.y, transp.y, 0.001, "Orthonormal basis inverse.y must match transpose.y")
	assert_vector3_approx(inv.z, transp.z, 0.001, "Orthonormal basis inverse.z must match transpose.z")
	var identity_test: Basis = rot * inv
	assert_vector3_approx(identity_test.x, Vector3.RIGHT, 0.001, "Basis * inverse must yield identity X")
	assert_vector3_approx(identity_test.y, Vector3.UP, 0.001, "Basis * inverse must yield identity Y")
	assert_vector3_approx(identity_test.z, Vector3.BACK, 0.001, "Basis * inverse must yield identity Z")

# 9. Basis Euler Order XYZ
func test_basis_euler_order_xyz() -> void:
	var angles: Vector3 = Vector3(0.2, 0.4, 0.6)
	var b: Basis = Basis.from_euler(angles, EULER_ORDER_XYZ)
	var recovered: Vector3 = b.get_euler(EULER_ORDER_XYZ)
	assert_vector3_approx(recovered, angles, 0.001, "Euler order XYZ roundtrip mismatch")

# 10. Basis Euler Order XZY
func test_basis_euler_order_xzy() -> void:
	var angles: Vector3 = Vector3(0.3, -0.5, 0.2)
	var b: Basis = Basis.from_euler(angles, EULER_ORDER_XZY)
	var recovered: Vector3 = b.get_euler(EULER_ORDER_XZY)
	assert_vector3_approx(recovered, angles, 0.001, "Euler order XZY roundtrip mismatch")

# 11. Basis Euler Order YXZ
func test_basis_euler_order_yxz() -> void:
	var angles: Vector3 = Vector3(-0.4, 0.3, 0.5)
	var b: Basis = Basis.from_euler(angles, EULER_ORDER_YXZ)
	var recovered: Vector3 = b.get_euler(EULER_ORDER_YXZ)
	assert_vector3_approx(recovered, angles, 0.001, "Euler order YXZ roundtrip mismatch")

# 12. Basis Euler Order YZX
func test_basis_euler_order_yzx() -> void:
	var angles: Vector3 = Vector3(0.1, 0.6, -0.4)
	var b: Basis = Basis.from_euler(angles, EULER_ORDER_YZX)
	var recovered: Vector3 = b.get_euler(EULER_ORDER_YZX)
	assert_vector3_approx(recovered, angles, 0.001, "Euler order YZX roundtrip mismatch")

# 13. Basis Euler Order ZXY
func test_basis_euler_order_zxy() -> void:
	var angles: Vector3 = Vector3(0.5, -0.2, 0.4)
	var b: Basis = Basis.from_euler(angles, EULER_ORDER_ZXY)
	var recovered: Vector3 = b.get_euler(EULER_ORDER_ZXY)
	assert_vector3_approx(recovered, angles, 0.001, "Euler order ZXY roundtrip mismatch")

# 14. Basis Euler Order ZYX
func test_basis_euler_order_zyx() -> void:
	var angles: Vector3 = Vector3(-0.3, 0.4, -0.2)
	var b: Basis = Basis.from_euler(angles, EULER_ORDER_ZYX)
	var recovered: Vector3 = b.get_euler(EULER_ORDER_ZYX)
	assert_vector3_approx(recovered, angles, 0.001, "Euler order ZYX roundtrip mismatch")

# 15. Transform3D Affine Inverse
func test_transform3d_affine_inverse() -> void:
	var basis: Basis = Basis(Quaternion(Vector3.UP, PI / 3.0)).scaled(Vector3(2.0, 3.0, 4.0))
	var origin: Vector3 = Vector3(10.0, 20.0, 30.0)
	var t: Transform3D = Transform3D(basis, origin)
	var t_inv: Transform3D = t.affine_inverse()
	var product: Transform3D = t * t_inv
	assert_transform3d_approx(product, Transform3D.IDENTITY, 0.001, "Transform3D * affine_inverse must yield IDENTITY")
	var pt: Vector3 = Vector3(7.0, -11.0, 13.0)
	assert_vector3_approx(t_inv * (t * pt), pt, 0.001, "Transform3D 3D point roundtrip mismatch")

# 16. Transform3D Composition & Look At
func test_transform3d_composition_and_look_at() -> void:
	var t: Transform3D = Transform3D.IDENTITY.looking_at(Vector3(0.0, 0.0, -10.0), Vector3.UP)
	var forward: Vector3 = t.basis * Vector3.FORWARD
	assert_vector3_approx(forward, Vector3.FORWARD, 0.001, "Looking at -Z must preserve forward orientation")
	var t_right: Transform3D = Transform3D.IDENTITY.looking_at(Vector3(10.0, 0.0, 0.0), Vector3.UP)
	var transformed_forward: Vector3 = t_right.basis * Vector3.FORWARD
	assert_vector3_approx(transformed_forward, Vector3.RIGHT, 0.001, "Looking at +X must align forward axis with RIGHT")

# 17. Quaternion Slerp & Angles
func test_quaternion_slerp_and_angles() -> void:
	var q1: Quaternion = Quaternion(Vector3.UP, 0.0)
	var q2: Quaternion = Quaternion(Vector3.UP, PI / 2.0)
	assert_approx(q1.angle_to(q2), PI / 2.0, 0.001, "Angle between 0 and 90 deg yaw quaternions must equal PI/2")
	var mid: Quaternion = q1.slerp(q2, 0.5)
	assert_approx(q1.angle_to(mid), PI / 4.0, 0.001, "Halfway slerp angle must equal PI/4")
	assert_approx(mid.length(), 1.0, 0.001, "Slerp result quaternion must remain normalized")

# 18. Quaternion Spherical Cubic Interpolation & Algebra
func test_quaternion_squad_and_algebra() -> void:
	var q0: Quaternion = Quaternion(Vector3.UP, 0.0)
	var q1: Quaternion = Quaternion(Vector3.UP, PI / 3.0)
	var q2: Quaternion = Quaternion(Vector3.UP, 2.0 * PI / 3.0)
	var q3: Quaternion = Quaternion(Vector3.UP, PI)
	
	var squad_start: Quaternion = q0.spherical_cubic_interpolate(q3, q1, q2, 0.0)
	assert_approx(abs(squad_start.dot(q0)), 1.0, 0.01, "Quaternion spherical cubic interpolation at t=0 must match q0")
	var squad_end: Quaternion = q0.spherical_cubic_interpolate(q3, q1, q2, 1.0)
	assert_approx(abs(squad_end.dot(q3)), 1.0, 0.01, "Quaternion spherical cubic interpolation at t=1 must match q3")
	
	var q_rot: Quaternion = Quaternion(Vector3(0.0, 1.0, 0.0), PI / 4.0)
	var q_inv: Quaternion = q_rot.inverse()
	assert_quaternion_approx(q_rot * q_inv, Quaternion.IDENTITY, 0.001, "Quaternion * inverse must equal IDENTITY")
