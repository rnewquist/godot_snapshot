# test_unit_fluent_expectations_matrix.gd
# Tier 0 Unit Suite: GDTest 3.0 Fluent Expectations, Dual Contract Requirements, Matrix & Parameterized Tests, and Benchmarking.
extends "res://addons/gdtest/core/test_suite.gd"

func _init() -> void:
	suite_name = "Tier0_Unit_Fluent_Expectations_Matrix_Suite"
	test_type = "unit"

# 1. Fluent Expectations: Equality, Booleans, Nulls, Ranges
func test_fluent_expectations_basic() -> void:
	expect(42).to_equal(42)
	expect("godot").to_equal("godot")
	expect(true).to_be_true()
	expect(false).to_be_false()
	expect(null).to_be_null()
	expect("valid").to_not_be_null()
	expect(3.14159).to_be_approx(3.14, 0.01)
	expect(25.0).to_be_in_range(20.0, 30.0)
	expect(100.0).to_be_greater_than(50.0)
	expect(10.0).to_be_less_than(20.0)

# 2. Fluent Expectations: Containers, Strings, Types & Regex
func test_fluent_expectations_containers_and_types() -> void:
	expect([1, 2, 3]).to_contain(2)
	expect([1, 2, 3]).to_not_contain(99)
	expect([]).to_be_empty()
	expect(["a", "b"]).to_not_be_empty()
	expect(["x", "y", "z"]).to_have_size(3)
	expect("HelloWorld").to_begin_with("Hello")
	expect("HelloWorld").to_end_with("World")
	expect("user_id_1234").to_match_regex("^user_id_\\d+$")
	expect(100).to_be_of_type(TYPE_INT)
	expect(RefCounted.new()).to_be_instance_of(RefCounted)

# 3. Inverted Expectations (not_to)
func test_fluent_expectations_inverted() -> void:
	expect(10).not_to.to_equal(20)
	expect(true).not_to.to_be_false()
	expect("hello").not_to.to_be_empty()
	expect([10, 20]).not_to.to_contain(30)

# 4. Dual-Contract Requirements (require_* returns bool & validates)
func test_dual_contract_requirements_success() -> void:
	var req1 = require_true(10 > 5, "10 must be greater than 5")
	assert_true(req1, "require_true must return true on success")
	
	var req2 = require_not_null(RefCounted.new())
	assert_true(req2, "require_not_null must return true on success")
	
	var req3 = require_eq("alpha", "alpha")
	assert_true(req3, "require_eq must return true on success")
	
	var req4 = require_size([1, 2, 3, 4], 4)
	assert_true(req4, "require_size must return true on success")
	
	assert_false(is_test_aborted(), "Suite must not be marked aborted when requirements pass")

# 5. Parameterized testing with run_parameterized
func test_parameterized_dataset_execution() -> void:
	var dataset = [
		[2, 3, 5],
		[10, 20, 30],
		[-5, 5, 0],
		[100, -50, 50]
	]
	
	var execution_count: Array[int] = [0]
	
	await run_parameterized(dataset, func(a: int, b: int, expected_sum: int):
		execution_count[0] += 1
		expect(a + b).to_equal(expected_sum)
	)
	
	assert_eq(execution_count[0], 4, "Parameterized runner must iterate through all 4 test cases")

# 6. Cartesian Matrix testing with run_matrix
func test_matrix_cartesian_product() -> void:
	var matrix_axes = {
		"difficulty": ["easy", "normal", "hard"],
		"multiplier": [1.0, 2.0]
	}
	
	var combos_tested: Array[Dictionary] = []
	
	await run_matrix(matrix_axes, func(combo: Dictionary):
		combos_tested.append(combo)
		expect(combo).to_contain("difficulty")
		expect(combo).to_contain("multiplier")
	)
	
	assert_eq(combos_tested.size(), 6, "3x2 matrix must produce exactly 6 combinations")

# 7. Benchmarking and assert_benchmark_under
func test_benchmarking_execution() -> void:
	var work_callable = func():
		var arr: Array[int] = []
		for i in range(100):
			arr.append(i * 2)
			
	var stats = benchmark(work_callable, 50, 5)
	assert_eq(stats["iterations"], 50, "Benchmark must record 50 iterations")
	assert_gt(stats["ops_per_sec"], 0.0, "Ops per second must be positive")
	
	# Microsecond threshold for 100 array appends (generous 5000 µs = 5 ms)
	assert_benchmark_under(work_callable, 5000.0, 50, "Micro-loop should run under 5ms")

# 8. Snapshot assertions & Telemetry attachments
func test_snapshots_and_telemetry_attachments() -> void:
	var sample_state = {
		"version": "3.0.0",
		"player": {
			"health": 100,
			"score": 5000,
			"tags": ["hero", "warrior"]
		}
	}
	
	# Assert JSON snapshot
	var snap_ok = assert_json_snapshot(sample_state, "sample_game_state", true)
	assert_true(snap_ok, "JSON snapshot assertion should record and validate state")
	
	# Attach telemetry JSON
	attach_json("diagnostics", {"cpu_load": 0.15, "fps": 60})
	var attachments = get_attachments(current_test_name)
	assert_eq(attachments.size(), 1, "Attached diagnostic telemetry must be recorded")
	assert_eq(attachments[0]["label"], "diagnostics", "Attachment label must match")
