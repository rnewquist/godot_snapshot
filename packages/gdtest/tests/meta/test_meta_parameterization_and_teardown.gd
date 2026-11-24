# test_meta_parameterization_and_teardown.gd
# Meta Test Suite: Parameterization engine and LIFO scoped teardown stack.
# Validates table-driven execution, Cartesian product generation, subcase isolation,
# stop_on_failure early abort, LIFO callback execution order (3 -> 2 -> 1), multi-server RID teardown,
# and error-isolated teardown resilience using IsolatedMockSuite fixtures.
extends "res://addons/gdtest/core/test_suite.gd"

const GDTestParameterizedRunner = preload("res://addons/gdtest/core/parameterization/parameterized_runner.gd")
const GDTestTeardownStack = preload("res://addons/gdtest/core/teardown/teardown_stack.gd")

class IsolatedMockSuite extends GDTestSuite:
	func _init() -> void:
		suite_name = "IsolatedMockSuite"
		test_type = "unit"

func _init() -> void:
	suite_name = "Meta_Parameterization_And_Teardown_Suite"
	test_type = "unit"

# ==============================================================================
# 1. PARAMETERIZED TABLE TESTING (run_table, Normalization, Subcase Isolation)
# ==============================================================================

func test_parameterized_run_table_with_dict_rows() -> void:
	var table = [
		{"a": 2, "b": 3, "expected": 5, "name": "2+3"},
		{"a": 10, "b": 20, "expected": 30, "name": "10+20"},
		{"a": -5, "b": 5, "expected": 0, "name": "-5+5"}
	]
	
	var executed_cases: Array[String] = []
	var summary = await GDTestParameterizedRunner.run_table(table, func(row: Dictionary):
		executed_cases.append(row["name"])
		assert_eq(row["a"] + row["b"], row["expected"], "Sum must match expected")
	, {"suite": self})
	
	assert_eq(summary["total_cases"], 3, "Total cases should be 3")
	assert_eq(summary["passed_cases"], 3, "Passed cases should be 3")
	assert_eq(summary["failed_cases"], 0, "Failed cases should be 0")
	assert_true(summary["all_passed"], "All cases must pass")
	assert_eq(executed_cases.size(), 3, "All 3 rows must be executed")
	assert_eq(executed_cases[0], "2+3")
	assert_eq(executed_cases[1], "10+20")
	assert_eq(executed_cases[2], "-5+5")

func test_parameterized_run_table_with_header_array_format() -> void:
	var raw_table = [
		["x", "y", "product"],
		[2, 3, 6],
		[4, 5, 20],
		[7, 8, 56]
	]
	
	var executed_products: Array[int] = []
	var summary = await GDTestParameterizedRunner.run_table(raw_table, func(row: Dictionary):
		var p = row["x"] * row["y"]
		executed_products.append(p)
		assert_eq(p, row["product"], "Multiplication must match")
	, {"suite": self})
	
	assert_eq(summary["total_cases"], 3, "Normalized table should have 3 data rows")
	assert_eq(summary["passed_cases"], 3, "All rows should pass")
	assert_true(summary["all_passed"], "Summary all_passed must be true")
	assert_eq(executed_products, [6, 20, 56], "Executed products must match headers mapping")

func test_parameterized_hooks_and_subcase_isolation() -> void:
	var table = [{"id": 1}, {"id": 2}, {"id": 3}]
	var trace: Array[String] = []
	
	var before_fn = func(params: Dictionary):
		trace.append("before_%d" % params["id"])
		
	var after_fn = func(params: Dictionary):
		trace.append("after_%d" % params["id"])
		
	var test_fn = func(params: Dictionary):
		trace.append("test_%d" % params["id"])
		
	var summary = await GDTestParameterizedRunner.run_table(table, test_fn, {
		"suite": self,
		"before_case": before_fn,
		"after_case": after_fn,
		"name_prefix": "HookTest"
	})
	
	assert_eq(summary["total_cases"], 3)
	assert_true(summary["all_passed"])
	var expected_trace = [
		"before_1", "test_1", "after_1",
		"before_2", "test_2", "after_2",
		"before_3", "test_3", "after_3"
	]
	assert_eq(trace, expected_trace, "before_case -> test -> after_case order must be strictly preserved")

# ==============================================================================
# 2. CARTESIAN PRODUCT MATRIX GENERATION & EXECUTION (run_matrix)
# ==============================================================================

func test_cartesian_product_generation() -> void:
	var axes = {
		"weapon": ["sword", "bow"],
		"tier": [1, 2],
		"enchanted": [true, false]
	}
	
	var combos = GDTestParameterizedRunner.cartesian_product(axes)
	assert_eq(combos.size(), 8, "2 * 2 * 2 dimensions must produce exactly 8 combinations")
	
	# Verify distinct combination elements
	var seen: Dictionary = {}
	for c in combos:
		assert_true(c.has("weapon") and c.has("tier") and c.has("enchanted"), "Each combo must contain all keys")
		var key = "%s_%d_%s" % [c["weapon"], c["tier"], str(c["enchanted"])]
		assert_false(seen.has(key), "Combination '%s' must be unique" % key)
		seen[key] = true
	assert_eq(seen.size(), 8, "Must generate 8 unique tuples")

func test_parameterized_run_matrix_execution() -> void:
	var axes = {
		"mode": ["fast", "slow"],
		"count": [10, 20]
	}
	
	var executed_combos: Array[Dictionary] = []
	var summary = await GDTestParameterizedRunner.run_matrix(axes, func(combo: Dictionary):
		executed_combos.append(combo)
		assert_true(combo["count"] >= 10, "Count must be at least 10")
	, {"suite": self})
	
	assert_eq(summary["total_cases"], 4, "2 * 2 dimensions should execute 4 subcases")
	assert_eq(summary["passed_cases"], 4)
	assert_true(summary["all_passed"])
	assert_eq(executed_combos.size(), 4)

# ==============================================================================
# 3. STOP ON FAILURE & EARLY ABORT (IsolatedMockSuite Sandbox)
# ==============================================================================

func test_parameterized_stop_on_failure_early_abort() -> void:
	var mock_suite = IsolatedMockSuite.new()
	autofree(mock_suite)
	
	var table = [
		{"val": 1, "should_fail": false},
		{"val": 2, "should_fail": true}, # Fails here
		{"val": 3, "should_fail": false},
		{"val": 4, "should_fail": false}
	]
	
	var evaluated_vals: Array[int] = []
	var summary = await GDTestParameterizedRunner.run_table(table, func(row: Dictionary):
		evaluated_vals.append(row["val"])
		if row["should_fail"]:
			mock_suite.assert_true(false, "Deliberate mock subcase failure")
		else:
			mock_suite.assert_true(true)
	, {
		"suite": mock_suite,
		"stop_on_failure": true
	})
	
	# Validate mock suite recorded the failure without failing this outer suite
	assert_eq(summary["total_cases"], 4, "Total dataset size is 4")
	assert_eq(summary["passed_cases"], 1, "Only case 1 passed")
	assert_eq(summary["failed_cases"], 1, "Case 2 failed")
	assert_false(summary["all_passed"], "Summary must indicate failure")
	assert_eq(evaluated_vals, [1, 2], "Execution must halt immediately after case 2 failure (cases 3 and 4 aborted)")
	assert_eq(mock_suite.fail_count, 1, "Mock suite must record exactly 1 failure")

# ==============================================================================
# 4. LIFO TEARDOWN EXECUTION ORDER (GDTestTeardownStack & Suite Integration)
# ==============================================================================

func test_teardown_stack_lifo_order() -> void:
	var stack = GDTestTeardownStack.new()
	var execution_trace: Array[int] = []
	
	stack.push(func(): execution_trace.append(1), "first_pushed")
	stack.push(func(): execution_trace.append(2), "second_pushed")
	stack.push(func(): execution_trace.append(3), "third_pushed")
	
	assert_eq(stack.size(), 3, "Stack should contain 3 entries")
	assert_false(stack.is_empty(), "Stack should not be empty")
	
	await stack.execute_all()
	
	assert_eq(execution_trace, [3, 2, 1], "Teardowns must execute strictly in LIFO order (3 -> 2 -> 1)")
	assert_eq(stack.size(), 0, "Stack must be empty after execute_all()")
	assert_true(stack.is_empty(), "Stack is_empty() must return true")

func test_teardown_scoped_execution() -> void:
	var stack = GDTestTeardownStack.new()
	var trace: Array[String] = []
	
	# Root scope (0)
	stack.push(func(): trace.append("root_1"), "root_teardown")
	
	# Nested scope 1
	var scope1 = stack.enter_scope("subcase_1")
	assert_eq(scope1, 1, "Scope counter should increment to 1")
	stack.push(func(): trace.append("scope1_a"), "scope1_a")
	stack.push(func(): trace.append("scope1_b"), "scope1_b")
	
	# Exit scope 1 -> executes scope1 teardowns in LIFO order (b then a), keeps root_1 pending
	await stack.exit_scope()
	assert_eq(trace, ["scope1_b", "scope1_a"], "Exiting scope 1 must execute only scope 1 items in LIFO order")
	assert_eq(stack.size(), 1, "Root scope teardown must remain pending")
	
	# Execute remaining root scope
	await stack.execute_all()
	assert_eq(trace, ["scope1_b", "scope1_a", "root_1"], "Root teardown executed on execute_all()")

func test_suite_add_teardown_lifo_integration() -> void:
	var mock_suite = IsolatedMockSuite.new()
	autofree(mock_suite)
	
	var order: Array[String] = []
	mock_suite.add_teardown(func(): order.append("T1"))
	mock_suite.add_teardown(func(): order.append("T2"))
	mock_suite.add_teardown(func(): order.append("T3"))
	
	mock_suite._execute_teardown_callbacks()
	
	assert_eq(order, ["T3", "T2", "T1"], "Suite _execute_teardown_callbacks() must run in LIFO order (T3 -> T2 -> T1)")

# ==============================================================================
# 5. MULTI-SERVER RID TEARDOWN (Physics2D, Physics3D, Rendering, Navigation)
# ==============================================================================

func test_teardown_multi_server_rid_destruction() -> void:
	var stack = GDTestTeardownStack.new()
	
	# 1. PhysicsServer2D RID
	var shape_2d: RID = PhysicsServer2D.circle_shape_create()
	assert_true(shape_2d.is_valid(), "PhysicsServer2D shape RID must be valid initially")
	stack.push_rid_free(shape_2d, GDTestTeardownStack.ServerType.PHYSICS_2D, "free_shape_2d")
	
	# 2. PhysicsServer3D RID
	var shape_3d: RID = PhysicsServer3D.sphere_shape_create()
	assert_true(shape_3d.is_valid(), "PhysicsServer3D shape RID must be valid initially")
	stack.push_rid_free(shape_3d, GDTestTeardownStack.ServerType.PHYSICS_3D, "free_shape_3d")
	
	# 3. RenderingServer RID
	var canvas_item: RID = RenderingServer.canvas_item_create()
	assert_true(canvas_item.is_valid(), "RenderingServer canvas item RID must be valid initially")
	stack.push_rid_free(canvas_item, GDTestTeardownStack.ServerType.RENDERING, "free_canvas_item")
	
	# 4. NavigationServer2D RID
	var nav_map_2d: RID = NavigationServer2D.map_create()
	assert_true(nav_map_2d.is_valid(), "NavigationServer2D map RID must be valid initially")
	stack.push_rid_free(nav_map_2d, GDTestTeardownStack.ServerType.NAVIGATION_2D, "free_nav_map_2d")
	
	# 5. NavigationServer3D RID
	var nav_map_3d: RID = NavigationServer3D.map_create()
	assert_true(nav_map_3d.is_valid(), "NavigationServer3D map RID must be valid initially")
	stack.push_rid_free(nav_map_3d, GDTestTeardownStack.ServerType.NAVIGATION_3D, "free_nav_map_3d")
	
	assert_eq(stack.size(), 5, "Stack must hold 5 RID free registrations")
	
	# Execute teardown
	await stack.execute_all()
	assert_eq(stack.size(), 0, "All RIDs should be processed and stack cleared")

# ==============================================================================
# 6. ERROR ISOLATION & RESILIENT TEARDOWNS
# ==============================================================================

func test_teardown_error_isolation_and_helper_types() -> void:
	var stack = GDTestTeardownStack.new()
	var executed: Array[String] = []
	
	# Helper 1: Node Free
	var dummy_node = Node.new()
	dummy_node.name = "DummyToFree"
	add_child(dummy_node)
	stack.push_node_free(dummy_node, "free_dummy_node")
	
	# Helper 2: Faulty teardown callable (simulates error resilience)
	var faulty_callable = Callable(self, "_non_existent_method_for_testing")
	stack.push(faulty_callable, "faulty_callable")
	
	# Helper 3: Property Reset
	var target_obj = RefCounted.new()
	var original_val = 100
	stack.push(func(): executed.append("step_after_faulty"), "resilient_step")
	
	await stack.execute_all()
	
	assert_true(executed.has("step_after_faulty"), "Subsequent teardowns must still execute even if an invalid callable exists")
	await get_tree().process_frame
	assert_true(not is_instance_valid(dummy_node) or dummy_node.is_queued_for_deletion(), "dummy_node should be queued for deletion")
