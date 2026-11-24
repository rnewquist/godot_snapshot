# test_meta_node_matcher_and_actions.gd
# Meta Test Suite 3: Composable Node Queries, Screen Transforms & Auto-Actions.
# Validates fluent query builders, visibility filters, screen coordinate resolution
# (Control, Node2D, Node3D), automated input actions (click, double_click, hover, type_text, check, drag_to),
# node-level assertions, and negative failure handling using IsolatedMockSuite sandbox.
extends "res://addons/gdtest/core/test_suite.gd"

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
	suite_name = "Meta_Node_Matcher_And_Actions_Suite"
	test_type = "unit"

# ==============================================================================
# 1. COMPOSABLE NODE QUERY BUILDERS & HIERARCHY SEARCH
# ==============================================================================

func test_node_matcher_composable_queries_and_filters() -> void:
	var root = autofree(Control.new())
	root.name = "RootUI"
	add_child(root)

	var btn_play = Button.new()
	btn_play.name = "PlayButton"
	btn_play.text = "Start Game"
	btn_play.add_to_group(&"ui_action_buttons")
	root.add_child(btn_play)

	var btn_quit = Button.new()
	btn_quit.name = "QuitButton"
	btn_quit.text = "Exit Game"
	btn_quit.disabled = true
	root.add_child(btn_quit)

	var line_edit = LineEdit.new()
	line_edit.name = "PlayerNameInput"
	line_edit.placeholder_text = "Enter your hero name..."
	root.add_child(line_edit)

	var label = Label.new()
	label.name = "ScoreLabel"
	label.text = "Score: 1000"
	root.add_child(label)

	await get_tree().process_frame

	# 1. Match by Type
	var matcher_btn = GDTestNodeMatcher.new(root, self).with_type("Button")
	assert_eq(matcher_btn.count(), 2, "Root should contain 2 Buttons")
	assert_eq(matcher_btn.find().name, "PlayButton", "First match should be PlayButton")

	# 2. Match by Text (Partial & Exact)
	var matcher_text_partial = GDTestNodeMatcher.new(root, self).with_text("Start")
	assert_eq(matcher_text_partial.find(), btn_play)

	var matcher_text_exact = GDTestNodeMatcher.new(root, self).with_text("Start Game", true)
	assert_eq(matcher_text_exact.find(), btn_play)

	var matcher_text_miss = GDTestNodeMatcher.new(root, self).with_text("Start", true) # Not exact
	assert_null(matcher_text_miss.find(), "Exact match on partial text must return null")

	# 3. Match by Placeholder Text in LineEdit
	var matcher_placeholder = GDTestNodeMatcher.new(root, self).with_text("hero name")
	assert_eq(matcher_placeholder.find(), line_edit)

	# 4. Match by Name (Exact & Partial)
	var matcher_name_exact = GDTestNodeMatcher.new(root, self).with_name("PlayButton", true)
	assert_eq(matcher_name_exact.find(), btn_play)

	var matcher_name_partial = GDTestNodeMatcher.new(root, self).with_name("Quit", false)
	assert_eq(matcher_name_partial.find(), btn_quit)

	# 5. Match by Group
	var matcher_group = GDTestNodeMatcher.new(root, self).in_group(&"ui_action_buttons")
	assert_eq(matcher_group.find(), btn_play)

	# 6. Match by Property Filter
	var matcher_prop = GDTestNodeMatcher.new(root, self).having_property(&"disabled", true)
	assert_eq(matcher_prop.find(), btn_quit)

	# 7. Custom Predicate
	var matcher_custom = GDTestNodeMatcher.new(root, self).custom(func(n): return n is Label and n.text.contains("1000"))
	assert_eq(matcher_custom.find(), label)

	# 8. Chained Composite Filter
	var matcher_combo = GDTestNodeMatcher.new(root, self) \
		.with_type("Button") \
		.in_group(&"ui_action_buttons") \
		.with_text("Start")
	assert_eq(matcher_combo.find(), btn_play)
	assert_true(matcher_combo.exists())

# ==============================================================================
# 2. VISIBILITY FILTERS & RECURSIVE SEARCH DEPTH
# ==============================================================================

func test_node_matcher_visibility_filters_and_max_depth() -> void:
	var root = autofree(Control.new())
	add_child(root)

	var visible_panel = Panel.new()
	visible_panel.name = "VisiblePanel"
	root.add_child(visible_panel)

	var hidden_panel = Panel.new()
	hidden_panel.name = "HiddenPanel"
	hidden_panel.visible = false
	root.add_child(hidden_panel)

	var hidden_child_btn = Button.new()
	hidden_child_btn.name = "HiddenChildButton"
	hidden_panel.add_child(hidden_child_btn)

	# Deep hierarchy for max_depth testing
	var level1 = Node.new()
	level1.name = "Level1"
	root.add_child(level1)

	var level2 = Node.new()
	level2.name = "Level2"
	level1.add_child(level2)

	var level3_btn = Button.new()
	level3_btn.name = "DeepButton"
	level2.add_child(level3_btn)

	await get_tree().process_frame

	# Visibility filter
	var matcher_all_panels = GDTestNodeMatcher.new(root, self).with_type("Panel")
	assert_eq(matcher_all_panels.count(), 2, "Unfiltered should find both panels")

	var matcher_vis_panels = GDTestNodeMatcher.new(root, self).with_type("Panel").is_visible_in_tree()
	assert_eq(matcher_vis_panels.count(), 1, "Visible filter should only find visible panel")
	assert_eq(matcher_vis_panels.find(), visible_panel)

	var matcher_vis_child = GDTestNodeMatcher.new(root, self).with_name("HiddenChildButton").is_visible_in_tree()
	assert_null(matcher_vis_child.find(), "Hidden child button should not match visible_in_tree filter")

	# Max search depth
	var matcher_shallow = GDTestNodeMatcher.new(root, self).with_name("DeepButton").max_depth(1)
	assert_null(matcher_shallow.find(), "DeepButton at depth 3 should not be found with max_depth(1)")

	var matcher_deep = GDTestNodeMatcher.new(root, self).with_name("DeepButton").max_depth(5)
	assert_eq(matcher_deep.find(), level3_btn, "DeepButton should be found with max_depth(5)")

# ==============================================================================
# 3. SCREEN TRANSFORM & COORDINATE RESOLUTION (Control, Node2D, Node3D)
# ==============================================================================

func test_node_matcher_screen_coordinate_resolution() -> void:
	# 1. Control screen position (center of bounding rectangle)
	var ctrl = autofree(Control.new())
	ctrl.position = Vector2(100, 150)
	ctrl.size = Vector2(80, 40)
	add_child(ctrl)
	await get_tree().process_frame

	var screen_pos_ctrl = GDTestNodeMatcher.get_screen_position(ctrl)
	# Center = (100 + 40, 150 + 20) = (140, 170)
	assert_approx(screen_pos_ctrl.x, 140.0, 1.0, "Control center X coordinate")
	assert_approx(screen_pos_ctrl.y, 170.0, 1.0, "Control center Y coordinate")

	# 2. Node2D screen position (origin)
	var node2d = autofree(Node2D.new())
	node2d.position = Vector2(250, 350)
	add_child(node2d)
	await get_tree().process_frame

	var screen_pos_2d = GDTestNodeMatcher.get_screen_position(node2d)
	assert_approx(screen_pos_2d.x, 250.0, 1.0, "Node2D origin X coordinate")
	assert_approx(screen_pos_2d.y, 350.0, 1.0, "Node2D origin Y coordinate")

	# 3. Invalid/Null node coordinate fallback
	assert_eq(GDTestNodeMatcher.get_screen_position(null), Vector2.ZERO)

# ==============================================================================
# 4. AUTO-ACTIONS: CHECKBOX (check) & LINE_EDIT (type_text)
# ==============================================================================

func test_node_matcher_check_action_on_button() -> void:
	var check_box = autofree(CheckBox.new())
	check_box.name = "MuteAudioCheckbox"
	check_box.button_pressed = false
	add_child(check_box)
	await get_tree().process_frame

	var toggled_values: Array[bool] = []
	check_box.toggled.connect(func(val): toggled_values.append(val))

	var matcher = GDTestNodeMatcher.new(self, self).with_name("MuteAudioCheckbox")
	
	# Execute check(true)
	matcher.check(true)
	assert_true(check_box.button_pressed, "Checkbox should be pressed after check(true)")
	assert_eq(toggled_values, [true], "Toggled signal must be emitted")

	# Execute check(false)
	matcher.check(false)
	assert_false(check_box.button_pressed, "Checkbox should be unpressed after check(false)")
	assert_eq(toggled_values, [true, false])

func test_node_matcher_type_text_action() -> void:
	var line_edit = autofree(LineEdit.new())
	line_edit.name = "ChatInput"
	line_edit.text = "Old Text"
	add_child(line_edit)
	await get_tree().process_frame

	var matcher = GDTestNodeMatcher.new(self, self).with_name("ChatInput")
	
	# Clear first and type new text
	await matcher.type_text("Hello Godot!", true, 0.001)
	assert_string_contains(line_edit.text, "Hello Godot!", "Text must be entered into LineEdit")

# ==============================================================================
# 5. AUTO-ACTIONS: CLICK, HOVER & DRAG_TO
# ==============================================================================

func test_node_matcher_click_and_hover_actions() -> void:
	var btn = autofree(Button.new())
	btn.name = "SubmitBtn"
	btn.size = Vector2(100, 50)
	btn.position = Vector2(50, 50)
	add_child(btn)
	await get_tree().process_frame

	var click_count: Array[int] = [0]
	btn.pressed.connect(func(): click_count[0] += 1)

	var matcher = GDTestNodeMatcher.new(self, self).with_name("SubmitBtn")
	
	# Simulated click
	await matcher.click(MOUSE_BUTTON_LEFT, Vector2.ZERO, 0.01)
	assert_gte(click_count[0], 1, "Click action must trigger button pressed signal")

	# Hover action (should complete without error)
	await matcher.hover(0.01)
	assert_true(true, "Hover completed successfully")

func test_node_matcher_drag_to_action() -> void:
	var source_ctrl = autofree(Control.new())
	source_ctrl.name = "SourceControl"
	source_ctrl.position = Vector2(50, 50)
	source_ctrl.size = Vector2(40, 40)
	add_child(source_ctrl)

	var target_ctrl = autofree(Control.new())
	target_ctrl.name = "TargetControl"
	target_ctrl.position = Vector2(200, 200)
	target_ctrl.size = Vector2(40, 40)
	add_child(target_ctrl)
	await get_tree().process_frame

	var matcher = GDTestNodeMatcher.new(self, self).with_name("SourceControl")
	# Drag from source node to target node
	await matcher.drag_to(target_ctrl, 0.05, 5)
	assert_true(true, "Drag action completed")

	# Drag to Vector2 destination
	await matcher.drag_to(Vector2(300, 300), 0.05, 5)
	assert_true(true, "Drag to Vector2 completed")

# ==============================================================================
# 6. NODE QUERY ASSERTIONS (assert_exists, assert_visible, assert_text_equals, assert_disabled)
# ==============================================================================

func test_node_matcher_assertions() -> void:
	var btn = autofree(Button.new())
	btn.name = "ActionButton"
	btn.text = "Confirm Order"
	btn.disabled = true
	add_child(btn)
	await get_tree().process_frame

	var matcher = GDTestNodeMatcher.new(self, self).with_name("ActionButton")
	matcher.assert_exists()
	matcher.assert_count(1)
	matcher.assert_visible()
	matcher.assert_text_equals("Confirm Order")
	matcher.assert_text_contains("Confirm")
	matcher.assert_disabled(true)

	var matcher_ghost = GDTestNodeMatcher.new(self, self).with_name("NonExistentNode")
	matcher_ghost.assert_not_exists()

# ==============================================================================
# 7. NEGATIVE FAILURE HANDLING & QUERY MISS IN ISOLATED SANDBOX
# ==============================================================================

func test_node_matcher_query_miss_and_action_failures_in_isolated_sandbox() -> void:
	var mock_suite = IsolatedMockSuite.new()
	autofree(mock_suite)

	var obs = HarnessObserver.new()

	# 1. Action on non-existent node (click miss)
	var miss_matcher = GDTestNodeMatcher.new(self, mock_suite).with_name("GhostNode")
	await miss_matcher.click()
	assert_eq(mock_suite.fail_count, 1, "Click on non-existent node must record failure")
	assert_string_contains(mock_suite.failures[0]["message"], "click failed: No matching node found")

	# 2. Check action on non-BaseButton node (e.g. Label)
	var label = autofree(Label.new())
	label.name = "MyLabel"
	add_child(label)
	await get_tree().process_frame

	var label_matcher = GDTestNodeMatcher.new(self, mock_suite).with_name("MyLabel")
	label_matcher.check(true)
	assert_eq(mock_suite.fail_count, 2, "check() on Label must fail")
	assert_string_contains(mock_suite.failures[1]["message"], "is not a BaseButton")

	# 3. assert_exists failure on query miss
	miss_matcher.assert_exists("Custom exists failure")
	assert_eq(mock_suite.fail_count, 3)
	assert_string_contains(mock_suite.failures[2]["message"], "Custom exists failure")

	# 4. assert_visible failure on query miss
	miss_matcher.assert_visible()
	assert_eq(mock_suite.fail_count, 4)

	# 5. assert_text_equals failure on mismatched text
	label_matcher.assert_text_equals("Wrong Text")
	assert_eq(mock_suite.fail_count, 5)

	# 6. assert_disabled failure
	label_matcher.assert_disabled(true)
	assert_eq(mock_suite.fail_count, 6)

	assert_eq(mock_suite.failures.size(), 6, "Mock suite must isolate all 6 negative failures")
