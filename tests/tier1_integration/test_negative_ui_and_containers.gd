# test_negative_ui_and_containers.gd
# Tier 1 Negative Boundary Suite: UI Dimensions, Deep Container Hierarchies, Overflow, SpinBox Step 0 & Empty Trees.
extends "res://addons/gdtest/core/test_suite.gd"

func _init() -> void:
	suite_name = "Tier1_Negative_UI_And_Containers"
	test_type = "integration"

# ==============================================================================
# 1. ZERO AND NEGATIVE CONTROL MINIMUM SIZES
# ==============================================================================

func test_zero_and_negative_control_minimum_sizes() -> void:
	var ctrl: Control = autofree(Control.new()) as Control
	ctrl.custom_minimum_size = Vector2.ZERO
	assert_vector2_approx(ctrl.custom_minimum_size, Vector2.ZERO, 0.001, "Control zero custom_minimum_size")
	
	var min_size: Vector2 = ctrl.get_combined_minimum_size()
	assert_gte(min_size.x, 0.0, "Combined min width must be non-negative")
	assert_gte(min_size.y, 0.0, "Combined min height must be non-negative")
	
	ctrl.custom_minimum_size = Vector2(-150.0, -80.0)
	assert_vector2_approx(ctrl.custom_minimum_size, Vector2(-150.0, -80.0), 0.001, "Negative minimum size assigned")

func test_container_zero_minimum_size_layout() -> void:
	var vbox: VBoxContainer = autofree(VBoxContainer.new()) as VBoxContainer
	vbox.custom_minimum_size = Vector2.ZERO
	var btn: Button = Button.new()
	btn.custom_minimum_size = Vector2.ZERO
	vbox.add_child(btn)
	
	var vbox_min: Vector2 = vbox.get_combined_minimum_size()
	assert_gte(vbox_min.x, 0.0, "VBox min width >= 0")
	assert_gte(vbox_min.y, 0.0, "VBox min height >= 0")

# ==============================================================================
# 2. DEEP 10-LEVEL NESTED CONTAINER HIERARCHIES
# ==============================================================================

func test_deep_10_level_nested_container_hierarchy() -> void:
	var root_container: PanelContainer = autofree(PanelContainer.new()) as PanelContainer
	add_child(root_container)
	
	var current: Control = root_container
	var container_types: Array[String] = [
		"MarginContainer", "VBoxContainer", "HBoxContainer", "ScrollContainer",
		"CenterContainer", "GridContainer", "AspectRatioContainer", "BoxContainer",
		"PanelContainer"
	]
	
	for c_type: String in container_types:
		var next_child: Control = ClassDB.instantiate(c_type) as Control
		if next_child:
			current.add_child(next_child)
			current = next_child
	
	var leaf_label: Label = Label.new()
	leaf_label.text = "Deep Leaf Label"
	current.add_child(leaf_label)
	
	# Verify depth by walking from leaf to root
	var depth: int = 0
	var iter: Node = leaf_label
	while iter != null and iter != self:
		depth += 1
		iter = iter.get_parent()
	
	assert_gte(depth, 10, "Container hierarchy depth must be at least 10 levels")
	
	# Trigger layout sort on root
	root_container.queue_sort()
	var comb_size: Vector2 = root_container.get_combined_minimum_size()
	assert_gte(comb_size.x, 0.0, "Deep container root min size calculated without crashing")

# ==============================================================================
# 3. LINEEDIT MAX_LENGTH OVERFLOWS
# ==============================================================================

func test_line_edit_max_length_overflow_and_negative() -> void:
	var line_edit: LineEdit = autofree(LineEdit.new()) as LineEdit
	line_edit.max_length = 5
	assert_eq(line_edit.max_length, 5, "LineEdit max_length set to 5")
	
	# Programmatic text assignment respects max_length constraint
	line_edit.text = "GodotEngine12345"
	assert_true(line_edit.text.length() <= 5, "LineEdit text respects max_length constraint")
	
	# Unlimited length boundary
	line_edit.max_length = 0
	assert_eq(line_edit.max_length, 0, "max_length 0 means unlimited")
	
	# Negative length boundary
	line_edit.max_length = -1
	assert_gte(line_edit.max_length, 0, "max_length negative value clamped or converted to 0")

# ==============================================================================
# 4. SPINBOX STEP 0 AND CONTINUOUS PRECISION
# ==============================================================================

func test_spin_box_step_zero_and_continuous_precision() -> void:
	var spin: SpinBox = autofree(SpinBox.new()) as SpinBox
	spin.min_value = 0.0
	spin.max_value = 100.0
	spin.step = 0.0 # Continuous mode in Godot Range
	assert_approx(spin.step, 0.0, 0.0001, "SpinBox step can be 0.0")
	
	spin.value = 73.14159265
	assert_approx(spin.value, 73.14159265, 0.0001, "SpinBox retains fractional value with step 0")
	
	# Extreme step value
	spin.step = 1000.0
	assert_approx(spin.step, 1000.0, 0.001, "Extreme step 1000.0 accepted")

# ==============================================================================
# 5. PROGRESSBAR MIN == MAX AND INVERTED BOUNDS
# ==============================================================================

func test_progress_bar_min_equals_max_and_inverted() -> void:
	var pbar: ProgressBar = autofree(ProgressBar.new()) as ProgressBar
	pbar.min_value = 50.0
	pbar.max_value = 50.0
	pbar.value = 50.0
	
	assert_approx(pbar.min_value, 50.0, 0.001, "ProgressBar min_value 50.0")
	assert_approx(pbar.max_value, 50.0, 0.001, "ProgressBar max_value 50.0")
	assert_approx(pbar.value, 50.0, 0.001, "ProgressBar value 50.0")
	assert_false(is_nan(pbar.ratio), "ProgressBar ratio must not be NaN when min == max")
	
	# Inverted bounds
	pbar.min_value = 100.0
	pbar.max_value = 0.0
	assert_false(is_nan(pbar.value), "ProgressBar value remains valid with inverted bounds")

# ==============================================================================
# 6. SCROLLCONTAINER OUT-OF-BOUNDS OFFSETS
# ==============================================================================

func test_scroll_container_out_of_bounds_offsets() -> void:
	var scroll: ScrollContainer = autofree(ScrollContainer.new()) as ScrollContainer
	scroll.custom_minimum_size = Vector2(200, 200)
	var content: Control = Control.new()
	content.custom_minimum_size = Vector2(50, 50)
	scroll.add_child(content)
	
	# Extreme scroll offsets
	scroll.scroll_horizontal = 999999
	scroll.scroll_vertical = -999999
	
	assert_gte(scroll.scroll_horizontal, 0, "Horizontal scroll non-negative")
	assert_gte(scroll.scroll_vertical, 0, "Vertical scroll non-negative")

# ==============================================================================
# 7. EMPTY ITEMLIST AND TREE OPERATIONS
# ==============================================================================

func test_empty_item_list_boundary_operations() -> void:
	var list: ItemList = autofree(ItemList.new()) as ItemList
	list.clear()
	
	assert_eq(list.item_count, 0, "ItemList must have 0 items")
	assert_eq(list.get_selected_items().size(), 0, "Selected items array must be empty")
	
	# Defensive boundary calls
	list.deselect_all()
	list.ensure_current_is_visible()
	assert_eq(list.item_count, 0, "ItemList remains empty after boundary calls")

func test_empty_tree_boundary_operations() -> void:
	var tree: Tree = autofree(Tree.new()) as Tree
	
	assert_null(tree.get_root(), "Empty Tree root must be null")
	assert_null(tree.get_selected(), "Empty Tree selected item must be null")
	assert_null(tree.get_next_selected(null), "Empty Tree next selected must be null")
	
	# Create single root and test invalid column index queries
	var root: TreeItem = tree.create_item()
	root.set_text(0, "Root Item")
	assert_eq(root.get_text(0), "Root Item", "Root item text column 0")
	assert_eq(root.get_text(50), "", "Out-of-bounds column returns empty string")
	
	tree.clear()
	assert_null(tree.get_root(), "Tree root null after clear()")
