# test_meta_framework_and_registry.gd
# Meta Test Suite: Validates GDTest Framework, Discovery, Assertion Accounting & Teardown Stack.
extends "res://addons/gdtest/core/test_suite.gd"

func _init() -> void:
	suite_name = "Meta_Framework_And_Registry_Suite"
	test_type = "unit"

# ==============================================================================
# 1. ASSERTION ACCOUNTING & RESULT TRACKING
# ==============================================================================

func test_assertion_counter_and_pass_tracking() -> void:
	var initial_assertions: int = assertion_count
	assert_true(true, "True condition must increment assertion count")
	assert_false(false, "False condition must increment assertion count")
	assert_eq(1 + 1, 2, "Equality must increment assertion count")
	assert_gte(assertion_count, initial_assertions + 3, "Assertion count must have increased by at least 3")

func test_type_and_class_assertions() -> void:
	var node: Node = autofree(Node.new()) as Node
	assert_not_null(node, "Created node must not be null")
	assert_is(node, Node, "Node instance must match Node class")
	assert_type(100, TYPE_INT, "Integer value must match TYPE_INT")
	assert_type("Godot", TYPE_STRING, "String value must match TYPE_STRING")
	assert_type(Vector2(1, 2), TYPE_VECTOR2, "Vector2 must match TYPE_VECTOR2")

# ==============================================================================
# 2. TEARDOWN STACK (LIFO ORDER) VALIDATION
# ==============================================================================

func test_teardown_stack_lifo_execution() -> void:
	var execution_log: Array[int] = []
	
	add_teardown(func(): execution_log.append(1))
	add_teardown(func(): execution_log.append(2))
	add_teardown(func(): execution_log.append(3))
	
	_execute_teardown_callbacks()
	
	# Teardown callbacks must execute in LIFO order: [3, 2, 1]
	assert_eq(execution_log.size(), 3, "All 3 teardown callbacks executed")
	assert_eq(execution_log[0], 3, "First executed must be last registered (3)")
	assert_eq(execution_log[1], 2, "Second executed must be middle (2)")
	assert_eq(execution_log[2], 1, "Third executed must be first registered (1)")

# ==============================================================================
# 3. AUTOFREE NODE & RID LIFECYCLE MANAGEMENT
# ==============================================================================

func test_autofree_node_tracking() -> void:
	var dummy_node: Node = Node.new()
	var registered_node: Node = autofree(dummy_node) as Node
	assert_eq(registered_node, dummy_node, "autofree returns the passed node reference")
	assert_true(_auto_free_nodes.has(dummy_node), "Dummy node must be tracked in _auto_free_nodes list")

func test_autofree_rid_tracking_and_free() -> void:
	var ci_rid: RID = RenderingServer.canvas_item_create()
	assert_true(ci_rid.is_valid(), "Created CanvasItem RID is valid")
	
	var tracked_rid: RID = auto_free_rid(ci_rid, ServerType.RENDERING)
	assert_eq(tracked_rid, ci_rid, "auto_free_rid returns passed RID")
	assert_true(_auto_free_rids.any(func(item): return item["rid"] == ci_rid), "RID is tracked in auto-free list")
	
	free_rid(ci_rid, ServerType.RENDERING)
	assert_false(_auto_free_rids.any(func(item): return item["rid"] == ci_rid), "RID is removed after free_rid")

# ==============================================================================
# 4. SIGNAL SPYING AND WATCHING
# ==============================================================================

func test_signal_spy_recording() -> void:
	var emitter: Node = autofree(Node.new()) as Node
	watch_signals(emitter)
	
	emitter.tree_entered.emit()
	assert_signal_emitted(emitter, "tree_entered", "tree_entered signal must be captured")
	assert_signal_not_emitted(emitter, "tree_exited", "tree_exited signal was not emitted")
