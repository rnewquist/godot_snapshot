# test_meta_suite_lifecycle_and_preconditions.gd
# Meta Test Suite: GDTestSuite Lifecycle Hooks, Dual-Contract Preconditions, and Diagnostics.
# Validates require_* dual contract (_test_aborted = true & bool return), standard assert non-aborting contract,
# signal spy argument capture, autofree/auto_free_rid memory lifecycles, DiagnosticTracer failure bundles,
# and JUnit XML escaping.
extends "res://addons/gdtest/core/test_suite.gd"

const DiagnosticTracerClass = preload("res://addons/gdtest/core/diagnostic_tracer.gd")

class IsolatedMockSuite extends GDTestSuite:
	func _init() -> void:
		suite_name = "IsolatedMockSuite"
		test_type = "unit"

# Helper Node for Signal Spying Tests
class SignalEmitterNode extends Node:
	signal event_triggered(id: int, message: String, multiplier: float)
	signal no_arg_signal
	signal uninvoked_signal

func _init() -> void:
	suite_name = "Meta_Suite_Lifecycle_And_Preconditions_Suite"
	test_type = "unit"

# ==============================================================================
# 1. REQUIRE_* DUAL CONTRACT (Early Abort & Boolean Return)
# ==============================================================================

func test_require_dual_contract_passing() -> void:
	var mock_suite = IsolatedMockSuite.new()
	autofree(mock_suite)
	
	# Passing require_* calls must return true and leave _test_aborted = false
	assert_true(mock_suite.require_true(true), "require_true(true) must return true")
	assert_true(mock_suite.require_false(false), "require_false(false) must return true")
	assert_true(mock_suite.require_eq(10, 10), "require_eq(10, 10) must return true")
	assert_true(mock_suite.require_ne(10, 20), "require_ne(10, 20) must return true")
	assert_true(mock_suite.require_null(null), "require_null(null) must return true")
	assert_true(mock_suite.require_not_null("valid"), "require_not_null('valid') must return true")
	assert_true(mock_suite.require_approx(1.0001, 1.0, 0.001), "require_approx must return true")
	assert_true(mock_suite.require_in_range(5.0, 0.0, 10.0), "require_in_range must return true")
	assert_true(mock_suite.require_empty([]), "require_empty([]) must return true")
	assert_true(mock_suite.require_not_empty([1]), "require_not_empty([1]) must return true")
	assert_true(mock_suite.require_size([1, 2, 3], 3), "require_size must return true")
	
	assert_false(mock_suite.is_test_aborted(), "Passing requirements must not set _test_aborted")
	assert_eq(mock_suite.fail_count, 0, "Passing requirements must not record failures")
	assert_true(mock_suite.pass_count >= 11, "Pass count should be incremented")

func test_require_dual_contract_failing_aborts_in_isolated_mock_suite() -> void:
	var mock_suite = IsolatedMockSuite.new()
	autofree(mock_suite)
	
	assert_false(mock_suite.is_test_aborted(), "Initial mock suite must not be aborted")
	
	# Deliberately fail a requirement inside mock suite
	var result = mock_suite.require_eq("expected_val", "actual_mismatch", "Precondition mismatch")
	
	assert_false(result, "Failing require_* must return false")
	assert_true(mock_suite.is_test_aborted(), "Failing require_* must set _test_aborted = true")
	assert_eq(mock_suite.fail_count, 1, "Failing require_* must record 1 failure in mock suite")
	assert_string_contains(mock_suite.failures[0]["message"], "Precondition mismatch", "Failure message preserved")

# ==============================================================================
# 2. STANDARD ASSERT NON-ABORTING CONTRACT
# ==============================================================================

func test_standard_assert_non_aborting_contract() -> void:
	var mock_suite = IsolatedMockSuite.new()
	autofree(mock_suite)
	
	# Standard assert failure records failure but DOES NOT abort execution
	var res1 = mock_suite.assert_true(false, "First non-aborting failure")
	var res2 = mock_suite.assert_eq(1, 2, "Second non-aborting failure")
	
	assert_false(res1, "assert_true(false) returns false")
	assert_false(res2, "assert_eq(1, 2) returns false")
	assert_eq(mock_suite.fail_count, 2, "Mock suite records 2 failures")
	assert_false(mock_suite.is_test_aborted(), "Standard assertions must NOT set _test_aborted to true")

# ==============================================================================
# 3. SIGNAL SPY & ARGUMENT CAPTURE
# ==============================================================================

func test_signal_spy_argument_capture_and_assertions() -> void:
	var emitter = SignalEmitterNode.new()
	autofree(emitter)
	add_child(emitter)
	
	watch_signal(emitter, &"event_triggered")
	watch_signal(emitter, &"no_arg_signal")
	watch_signal(emitter, &"uninvoked_signal")
	
	# Emit signals
	emitter.event_triggered.emit(101, "First Event", 1.5)
	emitter.event_triggered.emit(102, "Second Event", 3.0)
	emitter.no_arg_signal.emit()
	
	# Assertions
	assert_signal_emitted(emitter, &"event_triggered", "event_triggered must be emitted")
	assert_signal_count(emitter, &"event_triggered", 2, "event_triggered emitted exactly 2 times")
	assert_signal_emitted(emitter, &"no_arg_signal", "no_arg_signal must be emitted")
	assert_signal_count(emitter, &"no_arg_signal", 1, "no_arg_signal emitted exactly 1 time")
	assert_signal_not_emitted(emitter, &"uninvoked_signal", "uninvoked_signal must not be emitted")
	
	# Argument payload capture verification
	var emissions = get_signal_emissions(emitter, &"event_triggered")
	assert_eq(emissions.size(), 2, "Emissions list size must be 2")
	assert_eq(emissions[0], [101, "First Event", 1.5], "First emission arguments must match exactly")
	assert_eq(emissions[1], [102, "Second Event", 3.0], "Second emission arguments must match exactly")
	
	var last_emission = get_last_signal_emission(emitter, &"event_triggered")
	assert_eq(last_emission, [102, "Second Event", 3.0], "get_last_signal_emission must return final payload")
	
	# Cleanup spies
	_cleanup_signal_spies()
	assert_eq(get_signal_emissions(emitter, &"event_triggered").size(), 0, "Spy cleanup must clear collections")

# ==============================================================================
# 4. AUTOFREE / AUTO_FREE_RID MEMORY LIFECYCLES
# ==============================================================================

func test_suite_autofree_nodes_lifecycle() -> void:
	var mock_suite = IsolatedMockSuite.new()
	autofree(mock_suite)
	
	var test_node = Node2D.new()
	test_node.name = "AutoFreeTestNode"
	mock_suite.add_child(test_node)
	mock_suite.autofree(test_node)
	
	assert_eq(mock_suite._auto_free_nodes.size(), 1, "Node should be registered in _auto_free_nodes")
	
	# Trigger suite cleanup
	mock_suite._cleanup_auto_free_nodes()
	
	assert_eq(mock_suite._auto_free_nodes.size(), 0, "_auto_free_nodes must be cleared after cleanup")
	await get_tree().process_frame
	assert_true(not is_instance_valid(test_node) or test_node.is_queued_for_deletion(), "test_node must be queued for deletion")

func test_suite_auto_free_rid_lifecycle() -> void:
	var mock_suite = IsolatedMockSuite.new()
	autofree(mock_suite)
	
	var shape_2d: RID = PhysicsServer2D.circle_shape_create()
	mock_suite.auto_free_rid(shape_2d, GDTestSuite.ServerType.PHYSICS_2D)
	
	var canvas_item: RID = RenderingServer.canvas_item_create()
	mock_suite.auto_free_rid(canvas_item, GDTestSuite.ServerType.RENDERING)
	
	assert_eq(mock_suite._auto_free_rids.size(), 2, "Two RIDs registered for auto cleanup")
	
	mock_suite._cleanup_auto_free_nodes()
	assert_eq(mock_suite._auto_free_rids.size(), 0, "Auto-free RIDs list cleared after cleanup")

func test_suite_manual_free_rid_unregisters() -> void:
	var mock_suite = IsolatedMockSuite.new()
	autofree(mock_suite)
	
	var nav_map: RID = NavigationServer2D.map_create()
	mock_suite.auto_free_rid(nav_map, GDTestSuite.ServerType.NAVIGATION_2D)
	assert_eq(mock_suite._auto_free_rids.size(), 1)
	
	# Manually free RID
	mock_suite.free_rid(nav_map, GDTestSuite.ServerType.NAVIGATION_2D)
	assert_eq(mock_suite._auto_free_rids.size(), 0, "free_rid must unregister RID from pending cleanup list")

# ==============================================================================
# 5. DIAGNOSTIC TRACER ZERO-COST FAILURE BUNDLES
# ==============================================================================

func test_diagnostic_tracer_failure_bundle_generation() -> void:
	var mock_suite = IsolatedMockSuite.new()
	autofree(mock_suite)
	mock_suite.suite_name = "DiagnosticMockSuite"
	
	var test_name = "test_sample_failure"
	var failure_reasons = ["Expected 42, got 0", "Null pointer encountered"]
	
	var bundle = DiagnosticTracerClass.capture_failure(mock_suite, test_name, failure_reasons, null)
	
	assert_true(bundle.has("directory"), "Bundle must return target directory")
	assert_true(bundle.has("files"), "Bundle must return generated files dictionary")
	assert_true(bundle.has("metadata"), "Bundle must return metadata payload")
	
	var files = bundle["files"]
	assert_true(files.has("scene_tree_dump"), "Bundle must include scene_tree_dump")
	assert_true(files.has("engine_log"), "Bundle must include engine_log")
	assert_true(files.has("test_metadata"), "Bundle must include test_metadata")
	
	var metadata = bundle["metadata"]
	assert_eq(metadata["suite"], "DiagnosticMockSuite")
	assert_eq(metadata["test"], test_name)
	assert_eq(metadata["failure_count"], 2)

func test_diagnostic_tracer_dump_scene_tree() -> void:
	var root_node = Node2D.new()
	root_node.name = "DiagnosticRoot"
	root_node.position = Vector2(10.0, 20.0)
	autofree(root_node)
	
	var body = RigidBody2D.new()
	body.name = "PhysicalBox"
	body.mass = 5.0
	body.sleeping = false
	root_node.add_child(body)
	
	var dump = DiagnosticTracerClass.dump_scene_tree(root_node)
	
	assert_eq(dump["name"], "DiagnosticRoot")
	assert_eq(dump["type"], "Node2D")
	assert_eq(dump["children_count"], 1)
	assert_eq(dump["children"][0]["name"], "PhysicalBox")
	assert_eq(dump["children"][0]["type"], "RigidBody2D")
	assert_true(dump["children"][0].has("physics_state"), "RigidBody dump must include physics_state")

# ==============================================================================
# 6. JUNIT XML ESCAPING
# ==============================================================================

func test_junit_xml_escaping_security() -> void:
	var raw_str = 'Special <chars> & "quotes" \'apostrophe\''
	var escaped_str = raw_str.xml_escape(true)
	
	assert_false(escaped_str.contains("<chars>"), "Raw '<' must be escaped")
	assert_false(escaped_str.contains('"quotes"'), "Raw '\"' must be escaped")
	assert_true(escaped_str.contains("&lt;chars&gt;"), "'<chars>' should become '&lt;chars&gt;'")
	assert_true(escaped_str.contains("&amp;"), "'&' should become '&amp;'")
	assert_true(escaped_str.contains("&quot;quotes&quot;"), "'\"quotes\"' should become '&quot;quotes&quot;'")
	assert_true(escaped_str.contains("&apos;apostrophe&apos;"), "Apostrophes should become '&apos;'")
