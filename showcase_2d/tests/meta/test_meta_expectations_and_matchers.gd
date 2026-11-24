# test_meta_expectations_and_matchers.gd
# Meta Test Suite 2: Fluent Expectation and Matcher Engine.
# Validates positive matchers, container/string matchers, numeric ranges, reflection matchers,
# regex pattern matching, negation chaining (.not_()) with automatic state reset,
# custom message annotation via with_message(), and comprehensive negative failure verification
# using IsolatedMockSuite and HarnessObserver sandbox fixtures.
extends "res://addons/gdtest/core/test_suite.gd"

const GDTestExpectation = preload("res://addons/gdtest/core/matchers/expectation.gd")

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
	suite_name = "Meta_Expectations_And_Matchers_Suite"
	test_type = "unit"

# ==============================================================================
# 1. CORE POSITIVE EQUALITY & STRICT EQUALITY MATCHERS
# ==============================================================================

func test_expectation_equality_and_strict_equality() -> void:
	var exp_val = GDTestExpectation.new(100, self)
	exp_val.is_equal_to(100)
	assert_true(exp_val.last_passed, "100 is_equal_to 100 must pass")
	assert_eq(exp_val.last_error, "")

	# BDD alias to_equal
	exp_val.to_equal(100)
	assert_true(exp_val.last_passed)

	# Strict equality
	var exp_strict = GDTestExpectation.new(42, self)
	exp_strict.is_strictly_equal_to(42)
	assert_true(exp_strict.last_passed, "Exact int 42 is strictly equal to int 42")

	# Deep dictionary equality
	var dict_a = {"name": "Warrior", "stats": {"hp": 100, "mp": 50}}
	var dict_b = {"name": "Warrior", "stats": {"hp": 100, "mp": 50}}
	var exp_dict = GDTestExpectation.new(dict_a, self)
	exp_dict.is_equal_to(dict_b)
	assert_true(exp_dict.last_passed, "Deep dictionary equality must pass")

# ==============================================================================
# 2. NULLITY & BOOLEAN MATCHERS
# ==============================================================================

func test_expectation_nullity_and_boolean() -> void:
	var node = autofree(Node.new())
	var exp_node = GDTestExpectation.new(node, self)
	exp_node.is_not_null().to_not_be_null()
	assert_true(exp_node.last_passed, "Valid node must pass is_not_null")

	var exp_null = GDTestExpectation.new(null, self)
	exp_null.is_null().to_be_null()
	assert_true(exp_null.last_passed, "null must pass is_null")

	var exp_true = GDTestExpectation.new(true, self)
	exp_true.is_true().to_be_true()
	assert_true(exp_true.last_passed)

	var exp_false = GDTestExpectation.new(false, self)
	exp_false.is_false().to_be_false()
	assert_true(exp_false.last_passed)

# ==============================================================================
# 3. APPROXIMATE EQUALITY MATCHERS (Float, Vector, Color, Transform)
# ==============================================================================

func test_expectation_approximate_equality() -> void:
	var exp_float = GDTestExpectation.new(3.14159, self)
	exp_float.is_approx(3.14160, 0.001)
	assert_true(exp_float.last_passed, "Float approximate equality")

	var exp_v2 = GDTestExpectation.new(Vector2(10.0, 20.0), self)
	exp_v2.is_approx(Vector2(10.0001, 19.9999), 0.001)
	assert_true(exp_v2.last_passed, "Vector2 approximate equality")

	var exp_v3 = GDTestExpectation.new(Vector3(1.0, 2.0, 3.0), self)
	exp_v3.is_approx(Vector3(1.0, 2.0, 3.0005), 0.001)
	assert_true(exp_v3.last_passed, "Vector3 approximate equality")

	var exp_v4 = GDTestExpectation.new(Vector4(1.0, 2.0, 3.0, 4.0), self)
	exp_v4.is_approx(Vector4(1.0, 2.0, 3.0, 4.0005), 0.001)
	assert_true(exp_v4.last_passed, "Vector4 approximate equality")

	var exp_color = GDTestExpectation.new(Color(1.0, 0.0, 0.0, 1.0), self)
	exp_color.is_approx(Color(0.999, 0.001, 0.0, 1.0), 0.01)
	assert_true(exp_color.last_passed, "Color approximate equality")

	var exp_quat = GDTestExpectation.new(Quaternion(Vector3.UP, 0.5), self)
	exp_quat.is_approx(Quaternion(Vector3.UP, 0.50001), 0.001)
	assert_true(exp_quat.last_passed, "Quaternion approximate equality")

# ==============================================================================
# 4. CONTAINER & STRING MATCHERS
# ==============================================================================

func test_expectation_containers_and_strings() -> void:
	# String contains
	var exp_str = GDTestExpectation.new("Godot Engine 4.x", self)
	exp_str.contains("Engine").to_contain("Godot").does_not_contain("Unity")
	assert_true(exp_str.last_passed)

	# Array contains and size
	var exp_arr = GDTestExpectation.new(["apple", "banana", "cherry"], self)
	exp_arr.contains("banana").to_contain("cherry").has_size(3).is_not_empty().to_not_be_empty()
	assert_true(exp_arr.last_passed)

	# Dictionary contains key/value and emptiness
	var exp_dict = GDTestExpectation.new({"key_a": "val_a", "key_b": "val_b"}, self)
	exp_dict.contains("key_a").contains("val_b").has_size(2).is_not_empty()
	assert_true(exp_dict.last_passed)

	var exp_empty = GDTestExpectation.new([], self)
	exp_empty.is_empty().to_be_empty().has_size(0)
	assert_true(exp_empty.last_passed)

	# PackedByteArray contains & size
	var pba = PackedByteArray([10, 20, 30])
	var exp_pba = GDTestExpectation.new(pba, self)
	exp_pba.contains(20).has_size(3)
	assert_true(exp_pba.last_passed)

# ==============================================================================
# 5. NUMERIC COMPARISONS & RANGE MATCHERS
# ==============================================================================

func test_expectation_numeric_comparisons_and_ranges() -> void:
	var exp_num = GDTestExpectation.new(75, self)
	exp_num.is_greater_than(50).is_gt(70).to_be_greater_than(0)
	assert_true(exp_num.last_passed)

	exp_num.is_greater_than_or_equal_to(75).is_gte(75).to_be_greater_than_or_equal(74)
	assert_true(exp_num.last_passed)

	exp_num.is_less_than(100).is_lt(80).to_be_less_than(999)
	assert_true(exp_num.last_passed)

	exp_num.is_less_than_or_equal_to(75).is_lte(75).to_be_less_than_or_equal(100)
	assert_true(exp_num.last_passed)

	# In range (inclusive and exclusive)
	exp_num.is_between(50, 100, true).to_be_in_range(70, 80)
	assert_true(exp_num.last_passed)

	exp_num.is_between(74, 76, false) # exclusive
	assert_true(exp_num.last_passed)

# ==============================================================================
# 6. REFLECTION, GROUPS, SIGNALS & CUSTOM PREDICATES
# ==============================================================================

func test_expectation_reflection_groups_and_predicates() -> void:
	var btn = autofree(Button.new())
	btn.add_to_group(&"ui_buttons")

	var exp_btn = GDTestExpectation.new(btn, self)
	exp_btn.to_be_instance_of(Button).to_be_instance_of(Control).to_be_instance_of(Node)
	assert_true(exp_btn.last_passed, "Instance of check")

	exp_btn.is_type(TYPE_OBJECT)
	assert_true(exp_btn.last_passed, "Type check")

	exp_btn.to_have_method(&"get_text").to_have_method(&"set_text").to_have_method(&"is_pressed")
	assert_true(exp_btn.last_passed, "Method existence check")

	exp_btn.to_have_signal(&"pressed").to_have_signal(&"toggled").to_have_signal(&"button_down")
	assert_true(exp_btn.last_passed, "Signal existence check")

	exp_btn.is_in_group(&"ui_buttons").to_be_in_group(&"ui_buttons")
	assert_true(exp_btn.last_passed, "Group membership check")

	# Custom predicate
	var exp_custom = GDTestExpectation.new(24, self)
	exp_custom.satisfies(func(v): return v % 2 == 0 and v > 20)
	assert_true(exp_custom.last_passed, "Custom predicate must pass")

# ==============================================================================
# 7. REGEX PATTERN MATCHERS
# ==============================================================================

func test_expectation_regex_matching() -> void:
	var email = "user.name123@domain.org"
	var exp_str = GDTestExpectation.new(email, self)
	exp_str.matches_regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$")
	assert_true(exp_str.last_passed, "Valid email pattern regex")

	# Compiled RegEx object
	var reg = RegEx.new()
	reg.compile("^user\\.[a-z]+[0-9]+")
	exp_str.matches_regex(reg).to_match_regex(reg)
	assert_true(exp_str.last_passed, "Compiled RegEx matcher")

# ==============================================================================
# 8. NEGATION CHAINING (.not_() / not_to) & AUTOMATIC STATE RESET
# ==============================================================================

func test_expectation_negation_and_state_reset() -> void:
	# Single negation
	var exp_neg = GDTestExpectation.new(50, self)
	exp_neg.not_().is_equal_to(100)
	assert_true(exp_neg.last_passed, "not_().is_equal_to(100) must pass for 50")

	# CRITICAL STATE RESET VERIFICATION:
	# After evaluating not_().is_equal_to(100), the internal _is_negated flag must be reset to false!
	# Thus, the subsequent chained matcher .is_greater_than(20) must evaluate positively.
	exp_neg.not_().is_equal_to(999).is_greater_than(20)
	assert_true(exp_neg.last_passed, "Chained call after not_() must reset negation state to positive")

	# not_to property alias
	var exp_not_to = GDTestExpectation.new("hello", self)
	exp_not_to.not_to.contains("goodbye")
	assert_true(exp_not_to.last_passed, "not_to alias must invert matcher")

	# Double negation cancelation
	var exp_double = GDTestExpectation.new(42, self)
	exp_double.not_().not_().is_equal_to(42)
	assert_true(exp_double.last_passed, "Double not_() must revert to positive")

# ==============================================================================
# 9. CUSTOM MESSAGE ANNOTATION VIA with_message()
# ==============================================================================

func test_expectation_with_message_prefix() -> void:
	var mock_suite = IsolatedMockSuite.new()
	autofree(mock_suite)

	# Deliberate failure with custom message inside isolated sandbox
	var exp_fail = GDTestExpectation.new(10, mock_suite)
	exp_fail.with_message("Player Level Validation").is_equal_to(20)

	assert_false(exp_fail.last_passed, "Mismatch must fail")
	assert_eq(mock_suite.fail_count, 1, "Mock suite must record 1 failure")
	assert_eq(mock_suite.failures.size(), 1)
	assert_string_contains(mock_suite.failures[0]["message"], "[Player Level Validation]", "Custom message must prefix failure")

# ==============================================================================
# 10. COMPREHENSIVE NEGATIVE FAILURE VERIFICATION IN ISOLATED SANDBOX
# ==============================================================================

func test_expectation_negative_failures_in_isolated_mock_suite() -> void:
	var mock_suite = IsolatedMockSuite.new()
	autofree(mock_suite)

	var obs = HarnessObserver.new()

	# 1. Equality mismatch
	var e1 = GDTestExpectation.new("apple", mock_suite)
	e1.is_equal_to("orange")
	assert_false(e1.last_passed)
	obs._record_failure(e1.last_error)

	# 2. Strict equality type mismatch
	var e2 = GDTestExpectation.new(10, mock_suite)
	e2.is_strictly_equal_to(10.0)
	assert_false(e2.last_passed)
	obs._record_failure(e2.last_error)

	# 3. is_not_null on null
	var e3 = GDTestExpectation.new(null, mock_suite)
	e3.is_not_null()
	assert_false(e3.last_passed)
	obs._record_failure(e3.last_error)

	# 4. is_null on valid object
	var node = autofree(Node.new())
	var e4 = GDTestExpectation.new(node, mock_suite)
	e4.is_null()
	assert_false(e4.last_passed)
	obs._record_failure(e4.last_error)

	# 5. is_true on false
	var e5 = GDTestExpectation.new(false, mock_suite)
	e5.is_true()
	assert_false(e5.last_passed)
	obs._record_failure(e5.last_error)

	# 6. is_approx exceeding tolerance
	var e6 = GDTestExpectation.new(1.0, mock_suite)
	e6.is_approx(2.0, 0.01)
	assert_false(e6.last_passed)
	obs._record_failure(e6.last_error)

	# 7. contains on missing item
	var e7 = GDTestExpectation.new([1, 2, 3], mock_suite)
	e7.contains(99)
	assert_false(e7.last_passed)
	obs._record_failure(e7.last_error)

	# 8. has_size mismatch
	var e8 = GDTestExpectation.new([1, 2, 3], mock_suite)
	e8.has_size(10)
	assert_false(e8.last_passed)
	obs._record_failure(e8.last_error)

	# 9. is_greater_than on smaller number
	var e9 = GDTestExpectation.new(5, mock_suite)
	e9.is_greater_than(10)
	assert_false(e9.last_passed)
	obs._record_failure(e9.last_error)

	# 10. is_between out of range
	var e10 = GDTestExpectation.new(150, mock_suite)
	e10.is_between(10, 100)
	assert_false(e10.last_passed)
	obs._record_failure(e10.last_error)

	# 11. has_method missing
	var e11 = GDTestExpectation.new(node, mock_suite)
	e11.to_have_method(&"non_existent_method_xyz")
	assert_false(e11.last_passed)
	obs._record_failure(e11.last_error)

	# 12. has_signal missing
	var e12 = GDTestExpectation.new(node, mock_suite)
	e12.to_have_signal(&"non_existent_signal_xyz")
	assert_false(e12.last_passed)
	obs._record_failure(e12.last_error)

	# 13. matches_regex failure
	var e13 = GDTestExpectation.new("abc123", mock_suite)
	e13.matches_regex("^[0-9]+$")
	assert_false(e13.last_passed)
	obs._record_failure(e13.last_error)

	# 14. Negation failure (not_().is_equal_to on matching value)
	var e14 = GDTestExpectation.new(42, mock_suite)
	e14.not_().is_equal_to(42)
	assert_false(e14.last_passed)
	obs._record_failure(e14.last_error)

	# Assert sandbox recorded all 14 failures accurately
	assert_eq(mock_suite.fail_count, 14, "Mock suite must capture all 14 negative failure assertions")
	assert_eq(mock_suite.failures.size(), 14)
	assert_eq(obs.fail_count, 14, "HarnessObserver must record 14 failures")
