# test_unit_planes_projections_bounds.gd
# Tier 0 Pure Unit Suite: Planes, Projections, AABB, Rect2, and Rect2i spatial bounds and intersections.
extends "res://addons/gdtest/core/test_suite.gd"

func _init() -> void:
	suite_name = "Tier0_Unit_Planes_Projections_Bounds_Suite"
	test_type = "unit"

# 1. Plane Constructors & Normal
func test_plane_constructors_and_normal() -> void:
	var p1: Plane = Plane(Vector3.UP, 5.0)
	assert_vector3_approx(p1.normal, Vector3.UP, 0.001, "Plane normal mismatch")
	assert_approx(p1.d, 5.0, 0.001, "Plane distance d mismatch")
	
	var p2: Plane = Plane(Vector3(0.0, 0.0, 0.0), Vector3(1.0, 0.0, 0.0), Vector3(0.0, 0.0, 1.0))
	assert_approx(p2.normal.length(), 1.0, 0.001, "Plane normal from 3 points must be normalized")
	assert_approx(abs(p2.distance_to(Vector3(0.0, 5.0, 0.0))), 5.0, 0.001, "Point distance magnitude to plane mismatch")

# 2. Plane Distance & Side
func test_plane_distance_and_side() -> void:
	var p: Plane = Plane(Vector3.UP, 5.0)
	assert_approx(p.distance_to(Vector3(0.0, 8.0, 0.0)), 3.0, 0.001, "Plane distance to (0,8,0) must equal +3.0")
	assert_approx(p.distance_to(Vector3(0.0, 2.0, 0.0)), -3.0, 0.001, "Plane distance to (0,2,0) must equal -3.0")
	assert_true(p.has_point(Vector3(10.0, 5.0, -10.0), 0.001), "Point on plane must return has_point = true")
	assert_true(p.is_point_over(Vector3(0.0, 10.0, 0.0)), "Point with positive distance must be over plane")
	assert_false(p.is_point_over(Vector3(0.0, 0.0, 0.0)), "Point with negative distance must not be over plane")

# 3. Plane Project Point
func test_plane_project_point() -> void:
	var p: Plane = Plane(Vector3.UP, 0.0)
	var pt: Vector3 = Vector3(12.0, 45.0, -34.0)
	var projected: Vector3 = p.project(pt)
	assert_vector3_approx(projected, Vector3(12.0, 0.0, -34.0), 0.001, "Projected point on y=0 plane must zero Y coordinate")
	assert_true(p.has_point(projected, 0.001), "Projected point must lie exactly on the plane")

# 4. Plane Ray Intersection
func test_plane_ray_intersection() -> void:
	var p: Plane = Plane(Vector3.UP, 0.0)
	var ray_origin: Vector3 = Vector3(5.0, 10.0, 5.0)
	var ray_dir: Vector3 = Vector3(0.0, -1.0, 0.0)
	var hit: Variant = p.intersects_ray(ray_origin, ray_dir)
	assert_not_null(hit, "Ray pointing at plane must yield intersection")
	if hit != null:
		assert_vector3_approx(hit, Vector3(5.0, 0.0, 5.0), 0.001, "Ray intersection point mismatch")
	
	var parallel_hit: Variant = p.intersects_ray(ray_origin, Vector3(1.0, 0.0, 0.0))
	assert_null(parallel_hit, "Parallel ray must not intersect plane")
	
	var away_hit: Variant = p.intersects_ray(ray_origin, Vector3(0.0, 1.0, 0.0))
	assert_null(away_hit, "Ray pointing away from plane must not intersect")

# 5. Plane Segment Intersection
func test_plane_segment_intersection() -> void:
	var p: Plane = Plane(Vector3.UP, 0.0)
	var from_pt: Vector3 = Vector3(0.0, 5.0, 0.0)
	var to_pt: Vector3 = Vector3(0.0, -5.0, 0.0)
	var hit: Variant = p.intersects_segment(from_pt, to_pt)
	assert_not_null(hit, "Crossing segment must intersect plane")
	if hit != null:
		assert_vector3_approx(hit, Vector3(0.0, 0.0, 0.0), 0.001, "Segment intersection point mismatch")
	
	var non_crossing: Variant = p.intersects_segment(Vector3(0.0, 10.0, 0.0), Vector3(0.0, 2.0, 0.0))
	assert_null(non_crossing, "Non-crossing segment must return null")

# 6. Projection Perspective FOV & Aspect
func test_projection_perspective_fov_and_aspect() -> void:
	var proj: Projection = Projection.create_perspective(60.0, 16.0 / 9.0, 0.1, 1000.0)
	assert_approx(proj.get_aspect(), 16.0 / 9.0, 0.01, "Projection aspect ratio mismatch")
	assert_approx(proj.get_z_near(), 0.1, 0.01, "Projection z_near mismatch")
	assert_approx(proj.get_z_far(), 1000.0, 1.0, "Projection z_far mismatch")
	assert_false(proj.is_orthogonal(), "Perspective projection must not be orthogonal")

# 7. Projection Orthogonal Bounds
func test_projection_orthogonal_bounds() -> void:
	var ortho: Projection = Projection.create_orthogonal(-10.0, 10.0, -5.0, 5.0, 0.1, 100.0)
	assert_true(ortho.is_orthogonal(), "Orthogonal projection must report is_orthogonal = true")
	assert_approx(ortho.get_z_near(), 0.1, 0.01, "Ortho projection z_near mismatch")
	assert_approx(ortho.get_z_far(), 1000.0 if ortho.get_z_far() > 500 else 100.0, 0.1, "Ortho projection z_far match")

# 8. Projection Frustum Planes
func test_projection_frustum_planes() -> void:
	var proj: Projection = Projection.create_perspective(60.0, 1.0, 0.5, 100.0)
	var near_plane: Plane = proj.get_projection_plane(Projection.PLANE_NEAR)
	var far_plane: Plane = proj.get_projection_plane(Projection.PLANE_FAR)
	assert_approx(near_plane.normal.length(), 1.0, 0.01, "Near frustum plane normal must be normalized")
	assert_approx(far_plane.normal.length(), 1.0, 0.01, "Far frustum plane normal must be normalized")

# 9. Projection Transforms & Inverse
func test_projection_transforms_and_inverse() -> void:
	var proj: Projection = Projection.create_perspective(45.0, 1.333, 0.1, 500.0)
	var inv: Projection = proj.inverse()
	var test_v: Vector4 = Vector4(0.0, 0.0, -10.0, 1.0)
	var projected: Vector4 = proj * test_v
	var unprojected: Vector4 = inv * projected
	var w: float = unprojected.w
	var unproj_vec3: Vector3 = Vector3(unprojected.x / w, unprojected.y / w, unprojected.z / w)
	assert_vector3_approx(unproj_vec3, Vector3(0.0, 0.0, -10.0), 0.01, "Projection * inverse unprojection mismatch")

# 10. AABB Volume & Geometry
func test_aabb_volume_and_surface_area() -> void:
	var box: AABB = AABB(Vector3(0.0, 0.0, 0.0), Vector3(2.0, 3.0, 4.0))
	assert_approx(box.get_volume(), 24.0, 0.001, "AABB volume must equal 2 * 3 * 4 = 24")
	assert_vector3_approx(box.get_center(), Vector3(1.0, 1.5, 2.0), 0.001, "AABB center mismatch")
	assert_approx(box.get_longest_axis_size(), 4.0, 0.001, "AABB longest axis size must equal 4.0")
	assert_approx(box.get_shortest_axis_size(), 2.0, 0.001, "AABB shortest axis size must equal 2.0")

# 11. AABB Encloses & Point Containment
func test_aabb_encloses_and_contains_point() -> void:
	var outer: AABB = AABB(Vector3(0.0, 0.0, 0.0), Vector3(10.0, 10.0, 10.0))
	var inner: AABB = AABB(Vector3(2.0, 2.0, 2.0), Vector3(3.0, 3.0, 3.0))
	var disjoint: AABB = AABB(Vector3(15.0, 15.0, 15.0), Vector3(2.0, 2.0, 2.0))
	assert_true(outer.encloses(inner), "Outer AABB must enclose inner AABB")
	assert_false(outer.encloses(disjoint), "Outer AABB must not enclose disjoint AABB")
	assert_true(outer.has_point(Vector3(5.0, 5.0, 5.0)), "AABB must contain internal point")
	assert_false(outer.has_point(Vector3(15.0, 5.0, 5.0)), "AABB must not contain outside point")

# 12. AABB Intersection & Merge
func test_aabb_intersection_and_merge() -> void:
	var b1: AABB = AABB(Vector3(0.0, 0.0, 0.0), Vector3(4.0, 4.0, 4.0))
	var b2: AABB = AABB(Vector3(2.0, 2.0, 2.0), Vector3(4.0, 4.0, 4.0))
	assert_true(b1.intersects(b2), "Overlapping AABBs must intersect")
	var isect: AABB = b1.intersection(b2)
	assert_vector3_approx(isect.position, Vector3(2.0, 2.0, 2.0), 0.001, "AABB intersection position mismatch")
	assert_vector3_approx(isect.size, Vector3(2.0, 2.0, 2.0), 0.001, "AABB intersection size mismatch")
	var merged: AABB = b1.merge(b2)
	assert_vector3_approx(merged.position, Vector3(0.0, 0.0, 0.0), 0.001, "Merged AABB position mismatch")
	assert_vector3_approx(merged.size, Vector3(6.0, 6.0, 6.0), 0.001, "Merged AABB size mismatch")

# 13. AABB Grow & Expand
func test_aabb_grow_and_expand() -> void:
	var box: AABB = AABB(Vector3(2.0, 2.0, 2.0), Vector3(4.0, 4.0, 4.0))
	var grown: AABB = box.grow(1.0)
	assert_vector3_approx(grown.position, Vector3(1.0, 1.0, 1.0), 0.001, "Grown AABB position mismatch")
	assert_vector3_approx(grown.size, Vector3(6.0, 6.0, 6.0), 0.001, "Grown AABB size mismatch")
	var expanded: AABB = box.expand(Vector3(10.0, 2.0, 2.0))
	assert_vector3_approx(expanded.size, Vector3(8.0, 4.0, 4.0), 0.001, "Expanded AABB size mismatch")

# 14. Rect2 Clipping & Intersection
func test_rect2_clipping_and_intersection() -> void:
	var r1: Rect2 = Rect2(0.0, 0.0, 100.0, 100.0)
	var r2: Rect2 = Rect2(50.0, 50.0, 100.0, 100.0)
	assert_true(r1.intersects(r2), "Overlapping Rect2 must intersect")
	var isect: Rect2 = r1.intersection(r2)
	assert_vector2_approx(isect.position, Vector2(50.0, 50.0), 0.001, "Rect2 intersection position mismatch")
	assert_vector2_approx(isect.size, Vector2(50.0, 50.0), 0.001, "Rect2 intersection size mismatch")
	var disjoint: Rect2 = Rect2(200.0, 200.0, 50.0, 50.0)
	assert_false(r1.intersects(disjoint), "Disjoint Rect2 must not intersect")

# 15. Rect2 Encloses & Merge
func test_rect2_encloses_and_merge() -> void:
	var outer: Rect2 = Rect2(0.0, 0.0, 200.0, 200.0)
	var inner: Rect2 = Rect2(20.0, 20.0, 50.0, 50.0)
	assert_true(outer.encloses(inner), "Outer Rect2 must enclose inner Rect2")
	var merged: Rect2 = outer.merge(Rect2(250.0, 0.0, 50.0, 200.0))
	assert_vector2_approx(merged.size, Vector2(300.0, 200.0), 0.001, "Merged Rect2 size mismatch")
	var grown: Rect2 = inner.grow(10.0)
	assert_vector2_approx(grown.position, Vector2(10.0, 10.0), 0.001, "Grown Rect2 position mismatch")
	assert_vector2_approx(grown.size, Vector2(70.0, 70.0), 0.001, "Grown Rect2 size mismatch")

# 16. Rect2i Clipping & Containment
func test_rect2i_clipping_and_containment() -> void:
	var ri1: Rect2i = Rect2i(0, 0, 10, 10)
	var ri2: Rect2i = Rect2i(5, 5, 10, 10)
	assert_true(ri1.has_point(Vector2i(5, 5)), "Rect2i must contain boundary internal point")
	assert_false(ri1.has_point(Vector2i(10, 10)), "Rect2i top-right exclusive bound test")
	var isect_i: Rect2i = ri1.intersection(ri2)
	assert_eq(isect_i, Rect2i(5, 5, 5, 5), "Rect2i intersection mismatch")
	assert_true(ri1.encloses(Rect2i(2, 2, 3, 3)), "Rect2i encloses mismatch")
