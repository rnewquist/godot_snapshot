# test_meta_retry_assertions.gd
# Meta Test Suite 4: Auto-Retrying Async Polling Assertion Engine.
# Validates async condition resolution (to_exist, to_be_freed, to_be_visible, to_have_property,
# to_emit_signal), custom frame intervals (poll_every), target providers (Callable, NodePath, Matcher),
# is_instance_valid mid-polling lifecycle safety, timeout diagnostics with with_message(),
# and sandbox isolation via IsolatedMockSuite / HarnessObserver.
extends "res://addons/gdtest/core/test_suite.gd"

const GDTestRetryAssertion = preload("res://addons/gdtest/core/matchers/retry_assertion.gd")
const GDTestNodeMatcher = preload("res://addons/gdtest/core/matchers/node_matcher.gd")

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
	suite_name = "Meta_Retry_Assertions_Suite"
	test_type = "unit"

# ==============================================================================
# 1. ASYNC POLLING: TO_EXIST & TO_BE_FREED / TO_NOT_EXIST
# ==============================================================================

func test_retry_to_exist_delayed_tree_mount() -> void:
	var root = autofree(Node.new())
	add_child(root)

	var spawn_box: Array[Node] = [null]

	# Schedule node instantiation & tree mount after 3 process frames
	(func():
		for i in range(3):
			await get_tree().process_frame
		var n = Node.new()
		n.name = "SpawnedHero"
		root.add_child(n)
		spawn_box[0] = n
	).call()

	# Poll existence using Callable provider
	var retry = GDTestRetryAssertion.new(func(): return spawn_box[0], self, get_tree(), 1.0)
	var passed = await retry.within(1.0).poll_every(1).to_exist()
	assert_true(passed, "to_exist must resolve once node is mounted to tree")

	if spawn_box[0] and is_instance_valid(spawn_box[0]):
		spawn_box[0].queue_free()

func test_retry_to_be_freed_delayed_queue_free() -> void:
	var node = autofree(Node.new())
	node.name = "ExpiringNode"
	add_child(node)
	await get_tree().process_frame

	# Schedule queue_free after 3 process frames
	(func():
		for i in range(3):
			await get_tree().process_frame
		if is_instance_valid(node):
			node.queue_free()
	).call()

	var retry = GDTestRetryAssertion.new(node, self, get_tree(), 1.0)
	var passed = await retry.within(1.0).to_be_freed()
	assert_true(passed, "to_be_freed must resolve when node is freed")

# ==============================================================================
# 2. ASYNC POLLING: VISIBILITY (to_be_visible / to_be_hidden)
# ==============================================================================

func test_retry_visibility_transitions() -> void:
	var panel = autofree(Panel.new())
	panel.name = "TransitionPanel"
	panel.visible = false
	add_child(panel)
	await get_tree().process_frame

	# Schedule show after 20ms
	get_tree().create_timer(0.02).timeout.connect(func():
		if is_instance_valid(panel):
			panel.visible = true
	)

	var retry_vis = GDTestRetryAssertion.new(panel, self, get_tree(), 1.0)
	var passed_vis = await retry_vis.within(1.0).to_be_visible()
	assert_true(passed_vis, "to_be_visible must resolve when visible is set to true")

	# Schedule hide after 20ms
	get_tree().create_timer(0.02).timeout.connect(func():
		if is_instance_valid(panel):
			panel.visible = false
	)

	var retry_hide = GDTestRetryAssertion.new(panel, self, get_tree(), 1.0)
	var passed_hide = await retry_hide.within(1.0).to_be_hidden()
	assert_true(passed_hide, "to_be_hidden must resolve when visible is set to false")

# ==============================================================================
# 3. ASYNC POLLING: PROPERTIES, TEXT & CUSTOM CONDITIONS
# ==============================================================================

func test_retry_property_and_text_mutations() -> void:
	var label = autofree(Label.new())
	label.name = "StatusLabel"
	label.text = "Loading 0%"
	label.set_meta("custom_progress", 0.0)
	add_child(label)
	await get_tree().process_frame

	# Schedule property change after 20ms
	get_tree().create_timer(0.02).timeout.connect(func():
		if is_instance_valid(label):
			label.text = "Loading 100%"
			label.set_meta("custom_progress", 100.0)
	)

	var retry_text = GDTestRetryAssertion.new(label, self, get_tree(), 1.0)
	var passed_text = await retry_text.within(1.0).to_have_text("Loading 100%")
	assert_true(passed_text, "to_have_text must resolve once text updates")

	var retry_contain = GDTestRetryAssertion.new(label, self, get_tree(), 1.0)
	var passed_contain = await retry_contain.to_contain_text("100%")
	assert_true(passed_contain, "to_contain_text must resolve substring match")

	# Custom condition predicate
	var retry_pred = GDTestRetryAssertion.new(label, self, get_tree(), 1.0)
	var passed_pred = await retry_pred.to_satisfy(func(lbl):
		return lbl.has_meta("custom_progress") and lbl.get_meta("custom_progress") >= 100.0
	, "progress reaching 100")
	assert_true(passed_pred, "to_satisfy must resolve custom predicate")

# ==============================================================================
# 4. ASYNC POLLING: SIGNAL EMISSION (to_emit_signal)
# ==============================================================================

func test_retry_to_emit_signal_resolution() -> void:
	var btn = autofree(Button.new())
	add_child(btn)
	await get_tree().process_frame

	# Emit pressed signal after 25ms
	get_tree().create_timer(0.025).timeout.connect(func():
		if is_instance_valid(btn):
			btn.pressed.emit()
	)

	var retry_sig = GDTestRetryAssertion.new(btn, self, get_tree(), 1.0)
	var passed = await retry_sig.within(1.0).to_emit_signal(&"pressed")
	assert_true(passed, "to_emit_signal must resolve when signal is emitted")

# ==============================================================================
# 5. ASYNC POLLING: GROUPS (to_be_in_group)
# ==============================================================================

func test_retry_to_be_in_group_resolution() -> void:
	var hero = autofree(Node2D.new())
	add_child(hero)
	await get_tree().process_frame

	# Add to group after 20ms
	get_tree().create_timer(0.02).timeout.connect(func():
		if is_instance_valid(hero):
			hero.add_to_group(&"active_allies")
	)

	var retry_grp = GDTestRetryAssertion.new(hero, self, get_tree(), 1.0)
	var passed = await retry_grp.within(1.0).to_be_in_group(&"active_allies")
	assert_true(passed, "to_be_in_group must resolve once node enters group")

# ==============================================================================
# 6. TARGET PROVIDERS (Callable, NodePath, Matcher) & FRAME INTERVALS
# ==============================================================================

func test_retry_target_providers_and_frame_intervals() -> void:
	var container = autofree(Control.new())
	container.name = "MyContainer"
	add_child(container)

	var inner_btn = Button.new()
	inner_btn.name = "InnerButton"
	container.add_child(inner_btn)
	await get_tree().process_frame

	# 1. GDTestNodeMatcher target provider
	var matcher = GDTestNodeMatcher.new(container, self).with_name("InnerButton")
	var retry_matcher = GDTestRetryAssertion.new(matcher, self, get_tree(), 0.5)
	var passed_m = await retry_matcher.poll_every(2).to_exist()
	assert_true(passed_m, "Matcher target provider must resolve node")

	# 2. NodePath target provider
	var path_str = container.get_path_to(inner_btn)
	var retry_path = GDTestRetryAssertion.new(path_str, container, get_tree(), 0.5)
	var passed_p = await retry_path.to_exist()
	assert_true(passed_p, "NodePath target provider must resolve node")

# ==============================================================================
# 7. IS_INSTANCE_VALID MID-POLLING LIFECYCLE SAFETY
# ==============================================================================

func test_retry_polling_safety_with_freed_object() -> void:
	var temp_node = Node.new()
	add_child(temp_node)
	await get_tree().process_frame

	# Free immediately
	temp_node.free()

	# Polling on a freed object must not crash the engine
	var retry = GDTestRetryAssertion.new(temp_node, self, get_tree(), 0.1)
	var freed_res = await retry.within(0.1).to_be_freed()
	assert_true(freed_res, "to_be_freed must return true safely for already freed object")

# ==============================================================================
# 8. TIMEOUT EXPIRATION DIAGNOSTICS IN ISOLATED SANDBOX
# ==============================================================================

func test_retry_timeout_diagnostics_and_custom_message_in_isolated_sandbox() -> void:
	var mock_suite = IsolatedMockSuite.new()
	autofree(mock_suite)

	var static_node = autofree(Node.new())
	static_node.name = "StaticNode"
	add_child(static_node)
	await get_tree().process_frame

	# 1. Deliberately timeout waiting for non-existent signal
	var retry_sig = GDTestRetryAssertion.new(static_node, mock_suite, get_tree(), 0.05)
	var passed_sig = await retry_sig.within(0.05) \
		.with_message("Mission Countdown Signal") \
		.to_have_property(&"non_existent_prop", 999)

	assert_false(passed_sig, "Timeout must return false")
	assert_eq(mock_suite.fail_count, 1, "Mock suite must capture 1 timeout failure")
	assert_eq(mock_suite.failures.size(), 1)
	var err_msg = mock_suite.failures[0]["message"]
	assert_string_contains(err_msg, "[Mission Countdown Signal]", "Custom message prefix must be included")
	assert_string_contains(err_msg, "Timed out after 0.05s waiting for StaticNode", "Diagnostic timeout text must be formatted")

	# 2. Timeout waiting for visibility on hidden node with short timeout
	var hidden_node = autofree(Panel.new())
	hidden_node.name = "PermanentHiddenPanel"
	hidden_node.visible = false
	add_child(hidden_node)
	await get_tree().process_frame

	var retry_vis = GDTestRetryAssertion.new(hidden_node, mock_suite, get_tree(), 0.04)
	var passed_vis = await retry_vis.within(0.04).to_be_visible()
	assert_false(passed_vis)
	assert_eq(mock_suite.fail_count, 2, "Mock suite must record 2nd timeout failure")
	assert_string_contains(mock_suite.failures[1]["message"], "Timed out after 0.04s waiting for PermanentHiddenPanel")
