# test_meta_structural_differ.gd
# Meta Test Suite 1: Cyclic-Safe Deep Structural Differ Engine.
# Validates cyclic reference handling in dictionaries/arrays, deep path resolution,
# missing/extra keys, array size mismatches, float tolerances, compound math types
# (Transform3D, Quaternion, Vector4), truncation limits, unified diff formatting,
# and sandbox isolation via IsolatedMockSuite / HarnessObserver.
extends "res://addons/gdtest/core/test_suite.gd"

class IsolatedMockSuite extends GDTestSuite:
	func _init() -> void:
		suite_name = "IsolatedMockSuite"
		test_type = "unit"

class HarnessObserver:
	var pass_count: int = 0
	var fail_count: int = 0
	var failures: Array[String] = []

	func _record_pass() -> void:
		pass_count += 1

	func _record_failure(message: String) -> void:
		fail_count += 1
		failures.append(message)

func _init() -> void:
	suite_name = "Meta_Structural_Differ_Suite"
	test_type = "unit"

# ==============================================================================
# 1. PRIMITIVES, NULLS, STRICT TYPES & ARE_EQUAL HELPER
# ==============================================================================

func test_differ_primitives_and_null_handling() -> void:
	# Both null
	var res_null = StructuralDiffer.diff(null, null)
	assert_true(res_null["equal"], "Null == Null must be equal")
	assert_empty(res_null["differences"], "Differences must be empty for null == null")
	assert_eq(res_null["formatted_diff"], "", "Formatted diff must be empty for equal")

	# Actual null, expected value
	var res_null_val = StructuralDiffer.diff(null, 42)
	assert_false(res_null_val["equal"], "null vs 42 must not be equal")
	assert_eq(res_null_val["differences"].size(), 1)
	assert_string_contains(res_null_val["differences"][0]["reason"], "Null mismatch")

	# Actual value, expected null
	var res_val_null = StructuralDiffer.diff("godot", null)
	assert_false(res_val_null["equal"], "'godot' vs null must not be equal")
	assert_string_contains(res_val_null["differences"][0]["reason"], "Null mismatch")

	# Primitives equality & inequality
	assert_true(StructuralDiffer.are_equal(true, true), "Booleans true == true")
	assert_false(StructuralDiffer.are_equal(true, false), "Booleans true != false")
	assert_true(StructuralDiffer.are_equal(100, 100), "Integers 100 == 100")
	assert_false(StructuralDiffer.are_equal(100, 200), "Integers 100 != 200")
	assert_true(StructuralDiffer.are_equal("hello", "hello"), "Strings 'hello' == 'hello'")
	assert_false(StructuralDiffer.are_equal("hello", "world"), "Strings 'hello' != 'world'")
	assert_true(StructuralDiffer.are_equal(&"name", &"name"), "StringNames &name == &name")

func test_differ_strict_types_mode() -> void:
	# Strict types enabled by default: int vs float
	var res_strict = StructuralDiffer.diff(10, 10.0, {"strict_types": true})
	assert_false(res_strict["equal"], "Strict types must treat int 10 != float 10.0")
	assert_string_contains(res_strict["differences"][0]["reason"], "Type mismatch")

	# Strict types disabled: int vs float compared numerically
	var res_loose = StructuralDiffer.diff(10, 10.0, {"strict_types": false})
	assert_true(res_loose["equal"], "Non-strict types should allow 10 == 10.0")

	# Strict types with incompatible types (string vs int)
	var res_str_int = StructuralDiffer.diff("42", 42, {"strict_types": true})
	assert_false(res_str_int["equal"], "String '42' vs int 42 must fail type check")

# ==============================================================================
# 2. FLOAT TOLERANCES & NUMERIC EDGE CASES
# ==============================================================================

func test_differ_float_tolerances() -> void:
	# Default tolerance (0.0001)
	assert_true(StructuralDiffer.are_equal(1.00000, 1.00005), "Within default tolerance 0.0001")
	assert_false(StructuralDiffer.are_equal(1.00000, 1.00020), "Outside default tolerance 0.0001")

	# Custom tolerance option
	var options = {"float_tolerance": 0.05}
	assert_true(StructuralDiffer.are_equal(1.00, 1.04, options), "Within custom tolerance 0.05")
	assert_false(StructuralDiffer.are_equal(1.00, 1.06, options), "Outside custom tolerance 0.05")

	# Negative floats and zero
	assert_true(StructuralDiffer.are_equal(-0.00001, 0.00001), "-0.00001 vs 0.00001 within default tol")
	assert_true(StructuralDiffer.are_equal(-100.5, -100.5), "Negative float equality")
	assert_false(StructuralDiffer.are_equal(-100.5, 100.5), "-100.5 vs 100.5 mismatch")

# ==============================================================================
# 3. COMPOUND MATH TYPES (Vectors, Rects, Colors)
# ==============================================================================

func test_differ_compound_vectors() -> void:
	# Vector2 and Vector2i
	assert_true(StructuralDiffer.are_equal(Vector2(1.0, 2.0), Vector2(1.00002, 2.00001)))
	assert_false(StructuralDiffer.are_equal(Vector2(1.0, 2.0), Vector2(1.5, 2.0)))
	assert_true(StructuralDiffer.are_equal(Vector2i(10, 20), Vector2i(10, 20)))
	assert_false(StructuralDiffer.are_equal(Vector2i(10, 20), Vector2i(10, 21)))

	# Vector3 and Vector3i
	assert_true(StructuralDiffer.are_equal(Vector3(1.0, 2.0, 3.0), Vector3(1.0, 2.0, 3.00004)))
	assert_false(StructuralDiffer.are_equal(Vector3(1.0, 2.0, 3.0), Vector3(1.0, 2.0, 4.0)))
	assert_true(StructuralDiffer.are_equal(Vector3i(1, 2, 3), Vector3i(1, 2, 3)))
	assert_false(StructuralDiffer.are_equal(Vector3i(1, 2, 3), Vector3i(1, 2, 9)))

	# Vector4 and Vector4i
	assert_true(StructuralDiffer.are_equal(Vector4(1.0, 2.0, 3.0, 4.0), Vector4(1.0, 2.0, 3.0, 4.00003)))
	assert_false(StructuralDiffer.are_equal(Vector4(1.0, 2.0, 3.0, 4.0), Vector4(1.0, 2.0, 3.0, 4.5)))
	assert_true(StructuralDiffer.are_equal(Vector4i(1, 2, 3, 4), Vector4i(1, 2, 3, 4)))
	assert_false(StructuralDiffer.are_equal(Vector4i(1, 2, 3, 4), Vector4i(1, 2, 3, 5)))

	# Rect2 and Rect2i
	assert_true(StructuralDiffer.are_equal(Rect2(0, 0, 100, 200), Rect2(0.00001, 0, 100, 200)))
	assert_false(StructuralDiffer.are_equal(Rect2(0, 0, 100, 200), Rect2(0, 0, 100, 250)))
	assert_true(StructuralDiffer.are_equal(Rect2i(5, 5, 50, 50), Rect2i(5, 5, 50, 50)))
	assert_false(StructuralDiffer.are_equal(Rect2i(5, 5, 50, 50), Rect2i(5, 5, 50, 51)))

	# Color
	assert_true(StructuralDiffer.are_equal(Color(1.0, 0.5, 0.2, 1.0), Color(1.00001, 0.50001, 0.2, 1.0)))
	assert_false(StructuralDiffer.are_equal(Color.RED, Color.BLUE))

func test_differ_compound_transforms_and_quaternions() -> void:
	# Transform2D
	var t2d_a = Transform2D(0.5, Vector2(100, 200))
	var t2d_b = Transform2D(0.5, Vector2(100.00002, 200.00001))
	var t2d_c = Transform2D(0.8, Vector2(100, 200))
	assert_true(StructuralDiffer.are_equal(t2d_a, t2d_b), "Transform2D within tolerance")
	assert_false(StructuralDiffer.are_equal(t2d_a, t2d_c), "Transform2D with different rotation")

	# Transform3D
	var t3d_a = Transform3D(Basis.from_euler(Vector3(0.1, 0.2, 0.3)), Vector3(10, 20, 30))
	var t3d_b = Transform3D(Basis.from_euler(Vector3(0.1, 0.2, 0.3)), Vector3(10.00002, 20.0, 30.00001))
	var t3d_c = Transform3D(Basis.from_euler(Vector3(0.5, 0.2, 0.3)), Vector3(10, 20, 30))
	assert_true(StructuralDiffer.are_equal(t3d_a, t3d_b), "Transform3D within tolerance")
	assert_false(StructuralDiffer.are_equal(t3d_a, t3d_c), "Transform3D different basis")

	# Quaternion
	var q_a = Quaternion(Vector3.UP, 0.785)
	var q_b = Quaternion(q_a.x + 0.00001, q_a.y, q_a.z, q_a.w)
	var q_c = Quaternion(Vector3.RIGHT, 1.57)
	assert_true(StructuralDiffer.are_equal(q_a, q_b), "Quaternion within tolerance")
	assert_false(StructuralDiffer.are_equal(q_a, q_c), "Quaternion different axis/angle")

	# Plane, AABB, Basis, Projection
	assert_true(StructuralDiffer.are_equal(Plane(Vector3.UP, 5.0), Plane(Vector3.UP, 5.0)))
	assert_false(StructuralDiffer.are_equal(Plane(Vector3.UP, 5.0), Plane(Vector3.RIGHT, 5.0)))
	assert_true(StructuralDiffer.are_equal(AABB(Vector3.ZERO, Vector3.ONE), AABB(Vector3.ZERO, Vector3.ONE)))
	assert_false(StructuralDiffer.are_equal(AABB(Vector3.ZERO, Vector3.ONE), AABB(Vector3.ZERO, Vector3(2, 2, 2))))

# ==============================================================================
# 4. PACKED ARRAYS
# ==============================================================================

func test_differ_packed_arrays() -> void:
	# PackedByteArray
	var pba_1 = PackedByteArray([1, 2, 3, 4])
	var pba_2 = PackedByteArray([1, 2, 3, 4])
	var pba_3 = PackedByteArray([1, 2, 3, 9])
	assert_true(StructuralDiffer.are_equal(pba_1, pba_2), "PackedByteArray identical")
	assert_false(StructuralDiffer.are_equal(pba_1, pba_3), "PackedByteArray mismatch")

	# PackedStringArray
	var psa_1 = PackedStringArray(["alpha", "beta", "gamma"])
	var psa_2 = PackedStringArray(["alpha", "beta", "gamma"])
	var psa_3 = PackedStringArray(["alpha", "beta"])
	assert_true(StructuralDiffer.are_equal(psa_1, psa_2), "PackedStringArray identical")
	var diff_psa = StructuralDiffer.diff(psa_3, psa_1)
	assert_false(diff_psa["equal"], "PackedStringArray size mismatch")
	assert_string_contains(diff_psa["differences"][0]["reason"], "size mismatch")

	# PackedVector2Array & PackedColorArray
	var pva_1 = PackedVector2Array([Vector2(0, 0), Vector2(10, 20)])
	var pva_2 = PackedVector2Array([Vector2(0, 0), Vector2(10, 20)])
	assert_true(StructuralDiffer.are_equal(pva_1, pva_2))

	var pca_1 = PackedColorArray([Color.RED, Color.GREEN])
	var pca_2 = PackedColorArray([Color.RED, Color.GREEN])
	var pca_3 = PackedColorArray([Color.RED, Color.BLUE])
	assert_true(StructuralDiffer.are_equal(pca_1, pca_2))
	assert_false(StructuralDiffer.are_equal(pca_1, pca_3))

# ==============================================================================
# 5. DICTIONARIES: MISSING/EXTRA KEYS, IGNORE KEYS & PATH TRACKING
# ==============================================================================

func test_differ_dictionaries_missing_and_extra_keys() -> void:
	var actual = {"name": "Warrior", "level": 10, "extra_field": "bonus"}
	var expected = {"name": "Warrior", "level": 10, "gold": 500}

	var diff_res = StructuralDiffer.diff(actual, expected)
	assert_false(diff_res["equal"], "Dict with missing and extra keys must fail")
	assert_eq(diff_res["differences"].size(), 2, "Must contain exactly 2 differences (1 missing, 1 extra)")

	var found_missing = false
	var found_extra = false
	for d in diff_res["differences"]:
		if d["reason"].begins_with("Key missing"):
			found_missing = true
			assert_eq(d["path"], 'root["gold"]')
			assert_eq(d["actual"], "<missing key>")
			assert_eq(d["expected"], "500")
		elif d["reason"].begins_with("Unexpected extra key"):
			found_extra = true
			assert_eq(d["path"], 'root["extra_field"]')
			assert_eq(d["actual"], '"bonus"')
			assert_eq(d["expected"], "<unexpected key>")

	assert_true(found_missing, "Missing key 'gold' must be detected")
	assert_true(found_extra, "Extra key 'extra_field' must be detected")

func test_differ_dictionaries_ignore_keys_option() -> void:
	var actual = {"id": "123", "name": "Sword", "timestamp": 999999, "transient_id": "temp_1"}
	var expected = {"id": "123", "name": "Sword", "timestamp": 111111, "transient_id": "temp_2"}

	var diff_ignored = StructuralDiffer.diff(actual, expected, {
		"ignore_keys": ["timestamp", "transient_id"]
	})
	assert_true(diff_ignored["equal"], "Differences in ignored keys must be bypassed")
	assert_empty(diff_ignored["differences"])

# ==============================================================================
# 6. ARRAYS: SIZE MISMATCHES & DEEP INDEX PATHS
# ==============================================================================

func test_differ_arrays_size_mismatches_and_elements() -> void:
	var actual_arr = [10, 20, 30]
	var expected_arr = [10, 20, 30, 40, 50]

	var diff_res = StructuralDiffer.diff(actual_arr, expected_arr)
	assert_false(diff_res["equal"])
	assert_eq(diff_res["differences"][0]["path"], "root.size()")
	assert_eq(diff_res["differences"][0]["actual"], 3)
	assert_eq(diff_res["differences"][0]["expected"], 5)

	# Missing elements at indices 3 and 4
	var has_idx_3_missing = false
	var has_idx_4_missing = false
	for d in diff_res["differences"]:
		if d["path"] == "root[3]" and d["actual"] == "<missing>":
			has_idx_3_missing = true
		if d["path"] == "root[4]" and d["actual"] == "<missing>":
			has_idx_4_missing = true

	assert_true(has_idx_3_missing, "Missing element at root[3]")
	assert_true(has_idx_4_missing, "Missing element at root[4]")

func test_differ_deep_nested_paths() -> void:
	var actual = {
		"player": {
			"inventory": [
				{"id": "sword_01", "damage": 25.0},
				{"id": "shield_01", "defense": 10.0}
			],
			"position": Vector3(10, 0, 5)
		}
	}
	var expected = {
		"player": {
			"inventory": [
				{"id": "sword_01", "damage": 30.0}, # Mismatch here
				{"id": "shield_01", "defense": 10.0}
			],
			"position": Vector3(10, 0, 5)
		}
	}

	var diff_res = StructuralDiffer.diff(actual, expected)
	assert_false(diff_res["equal"])
	assert_eq(diff_res["differences"].size(), 1)
	var expected_path = 'root["player"]["inventory"][0]["damage"]'
	assert_eq(diff_res["differences"][0]["path"], expected_path, "Deep path must resolve precisely")

# ==============================================================================
# 7. CYCLIC REFERENCES IN DICTIONARIES AND ARRAYS
# ==============================================================================

func test_differ_cyclic_references_self_referencing_dictionaries() -> void:
	var dict_a = {"name": "NodeA", "value": 42}
	dict_a["self"] = dict_a

	var dict_b = {"name": "NodeA", "value": 42}
	dict_b["self"] = dict_b

	# Comparing two identical cyclic structures must succeed without stack overflow
	var res = StructuralDiffer.diff(dict_a, dict_b)
	assert_true(res["equal"], "Identical self-referencing dicts must evaluate to equal")
	assert_empty(res["differences"])

func test_differ_cyclic_references_mutual_dictionaries() -> void:
	var d1 = {"id": 1}
	var d2 = {"id": 2}
	d1["partner"] = d2
	d2["partner"] = d1

	var e1 = {"id": 1}
	var e2 = {"id": 2}
	e1["partner"] = e2
	e2["partner"] = e1

	var res_equal = StructuralDiffer.diff(d1, e1)
	assert_true(res_equal["equal"], "Mutual cyclic dictionaries must evaluate to equal")

	# Mutual cyclic dictionaries with mismatched leaf value
	var bad_e2 = {"id": 999}
	var bad_e1 = {"id": 1}
	bad_e1["partner"] = bad_e2
	bad_e2["partner"] = bad_e1

	var res_mismatch = StructuralDiffer.diff(d1, bad_e1)
	assert_false(res_mismatch["equal"], "Mutual cyclic dicts with leaf mismatch must fail")
	assert_eq(res_mismatch["differences"].size(), 1)
	assert_eq(res_mismatch["differences"][0]["path"], 'root["partner"]["id"]')

func test_differ_cyclic_references_arrays() -> void:
	var arr_a: Array = [1, 2]
	arr_a.append(arr_a)

	var arr_b: Array = [1, 2]
	arr_b.append(arr_b)

	var res = StructuralDiffer.diff(arr_a, arr_b)
	assert_true(res["equal"], "Identical self-referencing arrays must evaluate to equal")

	# Self-referencing array compared against differing leaf
	var arr_c: Array = [1, 999]
	arr_c.append(arr_c)
	var res_diff = StructuralDiffer.diff(arr_a, arr_c)
	assert_false(res_diff["equal"], "Self-referencing array with leaf mismatch must fail")
	assert_eq(res_diff["differences"][0]["path"], "root[1]")

# ==============================================================================
# 8. TRUNCATION LIMITS (Depth, Items, Strings)
# ==============================================================================

func test_differ_truncation_max_depth() -> void:
	# Build deeply nested dictionary beyond depth 5
	var deep_a = {"level": 0}
	var curr_a = deep_a
	var deep_b = {"level": 0}
	var curr_b = deep_b

	for i in range(1, 10):
		var next_a = {"level": i}
		curr_a["child"] = next_a
		curr_a = next_a
		var next_b = {"level": i}
		curr_b["child"] = next_b
		curr_b = next_b

	# Diff with max_depth: 4
	var diff_res = StructuralDiffer.diff(deep_a, deep_b, {"max_depth": 4})
	assert_false(diff_res["equal"], "Exceeding max_depth must trigger depth difference")
	assert_string_contains(diff_res["differences"][0]["reason"], "Max comparison depth (4) exceeded")

func test_differ_truncation_max_items_arrays_and_dicts() -> void:
	var large_arr_a = []
	var large_arr_b = []
	for i in range(60):
		large_arr_a.append(i)
		large_arr_b.append(i)
	large_arr_b[0] = 999 # mismatch in first element

	var diff_arr = StructuralDiffer.diff(large_arr_a, large_arr_b, {"max_items": 10})
	assert_false(diff_arr["equal"])
	var has_truncation_notice = false
	for d in diff_arr["differences"]:
		if d["path"] == "root[...]" and "Array truncated" in d["reason"]:
			has_truncation_notice = true
	assert_true(has_truncation_notice, "Array exceeding max_items must append truncation entry")

func test_differ_format_value_string_truncation() -> void:
	var long_str = "A".repeat(200)
	var formatted = StructuralDiffer.format_value(long_str, 50)
	assert_true(formatted.length() <= 60, "Formatted string must be truncated near max_length")
	assert_string_contains(formatted, "...", "Truncated string must end with ellipsis")

# ==============================================================================
# 9. UNIFIED DIFF FORMATTING & VISUAL MARKERS
# ==============================================================================

func test_differ_unified_diff_formatting() -> void:
	var actual = {"health": 80, "name": "Hero"}
	var expected = {"health": 100, "name": "Hero"}

	var diff_res = StructuralDiffer.diff(actual, expected)
	assert_false(diff_res["equal"])
	var formatted = diff_res["formatted_diff"]
	assert_not_empty(formatted)
	assert_string_contains(formatted, "--- Expected")
	assert_string_contains(formatted, "+++ Actual")
	assert_string_contains(formatted, "@@ Structural Differences")
	assert_string_contains(formatted, "root[\"health\"]")
	assert_string_contains(formatted, "Expected: 100")
	assert_string_contains(formatted, "Actual:   80")

# ==============================================================================
# 10. ISOLATED MOCK SUITE & HARNESS OBSERVER NEGATIVE ISOLATION
# ==============================================================================

func test_differ_isolated_mock_suite_negative_assertion() -> void:
	var mock_suite = IsolatedMockSuite.new()
	autofree(mock_suite)

	var obs = HarnessObserver.new()

	# Run a structural mismatch inside the sandbox
	var val_a = {"x": 10}
	var val_b = {"x": 20}
	var diff_res = StructuralDiffer.diff(val_a, val_b)
	
	if not diff_res["equal"]:
		obs._record_failure("Deliberate isolated structural difference")
		mock_suite._record_failure("Mock suite isolated failure: %s" % diff_res["formatted_diff"])
	else:
		obs._record_pass()

	assert_eq(obs.fail_count, 1, "HarnessObserver must capture isolated failure")
	assert_eq(obs.pass_count, 0)
	assert_eq(mock_suite.fail_count, 1, "Mock suite must record isolated failure without failing outer suite")
	assert_eq(mock_suite.failures.size(), 1)
	assert_string_contains(mock_suite.failures[0]["message"], "Mock suite isolated failure")
