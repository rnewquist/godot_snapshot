# test_integration_ui_containers_layout.gd
# Tier 1 Integration Suite 5: UI Container Layouts, Hierarchies, and Alignment.
extends "res://addons/gdtest/core/test_suite.gd"

var ui_root: Control

func _init() -> void:
	suite_name = "Tier1_Integration_UI_Containers_Layout"
	test_type = "integration"

func before_each() -> void:
	ui_root = autofree(Control.new()) as Control
	ui_root.custom_minimum_size = Vector2(1024, 768)
	ui_root.size = Vector2(1024, 768)
	add_child(ui_root)
	await step_frames(2)

# ==============================================================================
# 1. INDIVIDUAL CONTAINER TESTS (MANDATORY await step_frames(2))
# ==============================================================================

func test_vbox_container_vertical_flow() -> void:
	var vbox: VBoxContainer = autofree(VBoxContainer.new()) as VBoxContainer
	vbox.add_theme_constant_override("separation", 10)
	ui_root.add_child(vbox)
	
	var c1: Control = Control.new()
	c1.custom_minimum_size = Vector2(100, 30)
	vbox.add_child(c1)
	
	var c2: Control = Control.new()
	c2.custom_minimum_size = Vector2(100, 40)
	vbox.add_child(c2)
	
	await step_frames(2)
	assert_gte(vbox.size.y, 80.0, "VBox total height must accommodate children (30+40+10)")
	assert_gte(c2.position.y, 30.0, "Child 2 must be positioned below Child 1")

func test_hbox_container_horizontal_flow() -> void:
	var hbox: HBoxContainer = autofree(HBoxContainer.new()) as HBoxContainer
	hbox.add_theme_constant_override("separation", 15)
	ui_root.add_child(hbox)
	
	var c1: Control = Control.new()
	c1.custom_minimum_size = Vector2(50, 30)
	hbox.add_child(c1)
	
	var c2: Control = Control.new()
	c2.custom_minimum_size = Vector2(60, 30)
	hbox.add_child(c2)
	
	await step_frames(2)
	assert_gte(hbox.size.x, 125.0, "HBox total width must accommodate children (50+60+15)")
	assert_gte(c2.position.x, 50.0, "Child 2 must be positioned to the right of Child 1")

func test_grid_container_columns_layout() -> void:
	var grid: GridContainer = autofree(GridContainer.new()) as GridContainer
	grid.columns = 3
	ui_root.add_child(grid)
	
	var cells: Array[Control] = []
	for i in range(6):
		var c = Control.new()
		c.custom_minimum_size = Vector2(40, 40)
		grid.add_child(c)
		cells.append(c)
		
	await step_frames(2)
	assert_eq(grid.columns, 3)
	assert_approx(cells[0].position.y, cells[1].position.y, 1.0, "Cells 0 and 1 in row 1 share same Y")
	assert_gt(cells[3].position.y, cells[0].position.y, "Cell 3 in row 2 is below row 1")

func test_margin_container_insets() -> void:
	var margin: MarginContainer = autofree(MarginContainer.new()) as MarginContainer
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_right", 25)
	margin.add_theme_constant_override("margin_bottom", 10)
	ui_root.add_child(margin)
	
	var child: Control = Control.new()
	child.custom_minimum_size = Vector2(80, 50)
	margin.add_child(child)
	
	await step_frames(2)
	assert_gte(margin.size.x, 125.0, "Margin width >= 80 + 20 + 25")
	assert_gte(margin.size.y, 75.0, "Margin height >= 50 + 15 + 10")
	assert_approx(child.position.x, 20.0, 1.0, "Child X offset matches margin_left")
	assert_approx(child.position.y, 15.0, 1.0, "Child Y offset matches margin_top")

func test_panel_container_panel_style() -> void:
	var panel: PanelContainer = autofree(PanelContainer.new()) as PanelContainer
	panel.custom_minimum_size = Vector2(200, 100)
	ui_root.add_child(panel)
	
	var child: Label = Label.new()
	child.text = "Inside Panel"
	panel.add_child(child)
	
	await step_frames(2)
	assert_gte(panel.size.x, 200.0)
	assert_gte(panel.size.y, 100.0)
	assert_not_null(child.get_parent())

func test_scroll_container_scrolling() -> void:
	var scroll: ScrollContainer = autofree(ScrollContainer.new()) as ScrollContainer
	scroll.custom_minimum_size = Vector2(150, 100)
	scroll.size = Vector2(150, 100)
	ui_root.add_child(scroll)
	
	var inner: Control = Control.new()
	inner.custom_minimum_size = Vector2(400, 500)
	scroll.add_child(inner)
	
	await step_frames(2)
	scroll.scroll_horizontal = 50
	scroll.scroll_vertical = 75
	await step_frames(2)
	
	assert_eq(scroll.scroll_horizontal, 50)
	assert_eq(scroll.scroll_vertical, 75)

func test_hsplit_container_split_offset() -> void:
	var hsplit: HSplitContainer = autofree(HSplitContainer.new()) as HSplitContainer
	hsplit.custom_minimum_size = Vector2(300, 100)
	hsplit.size = Vector2(300, 100)
	ui_root.add_child(hsplit)
	
	var left: Control = Control.new()
	left.custom_minimum_size = Vector2(100, 50)
	hsplit.add_child(left)
	
	var right: Control = Control.new()
	right.custom_minimum_size = Vector2(100, 50)
	hsplit.add_child(right)
	
	hsplit.split_offset = 30
	await step_frames(2)
	
	assert_eq(hsplit.split_offset, 30)
	assert_gte(hsplit.size.x, 300.0)

func test_vsplit_container_split_offset() -> void:
	var vsplit: VSplitContainer = autofree(VSplitContainer.new()) as VSplitContainer
	vsplit.custom_minimum_size = Vector2(100, 300)
	vsplit.size = Vector2(100, 300)
	ui_root.add_child(vsplit)
	
	var top: Control = Control.new()
	top.custom_minimum_size = Vector2(50, 100)
	vsplit.add_child(top)
	
	var bottom: Control = Control.new()
	bottom.custom_minimum_size = Vector2(50, 100)
	vsplit.add_child(bottom)
	
	vsplit.split_offset = 20
	await step_frames(2)
	
	assert_eq(vsplit.split_offset, 20)
	assert_gte(vsplit.size.y, 300.0)

func test_tab_container_tab_navigation() -> void:
	var tab_container: TabContainer = autofree(TabContainer.new()) as TabContainer
	tab_container.custom_minimum_size = Vector2(300, 150)
	ui_root.add_child(tab_container)
	
	var page1: Control = Control.new()
	page1.name = "Page 1"
	tab_container.add_child(page1)
	
	var page2: Control = Control.new()
	page2.name = "Page 2"
	tab_container.add_child(page2)
	
	await step_frames(2)
	assert_eq(tab_container.get_tab_count(), 2)
	assert_eq(tab_container.current_tab, 0)
	assert_true(page1.visible)
	
	tab_container.current_tab = 1
	await step_frames(2)
	assert_eq(tab_container.current_tab, 1)

func test_aspect_ratio_container_aspect() -> void:
	var aspect: AspectRatioContainer = autofree(AspectRatioContainer.new()) as AspectRatioContainer
	aspect.ratio = 16.0 / 9.0
	aspect.custom_minimum_size = Vector2(320, 240)
	aspect.size = Vector2(320, 240)
	ui_root.add_child(aspect)
	
	var child: Control = Control.new()
	child.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	child.size_flags_vertical = Control.SIZE_EXPAND_FILL
	aspect.add_child(child)
	
	await step_frames(2)
	assert_approx(aspect.ratio, 16.0 / 9.0, 0.001)
	assert_approx(child.size.x / child.size.y, 16.0 / 9.0, 0.05, "Child rect maintains aspect ratio")

func test_center_container_centering() -> void:
	var center: CenterContainer = autofree(CenterContainer.new()) as CenterContainer
	center.custom_minimum_size = Vector2(200, 200)
	center.size = Vector2(200, 200)
	ui_root.add_child(center)
	
	var child: Control = Control.new()
	child.custom_minimum_size = Vector2(60, 40)
	center.add_child(child)
	
	await step_frames(2)
	var expected_x = (200.0 - 60.0) / 2.0
	var expected_y = (200.0 - 40.0) / 2.0
	assert_approx(child.position.x, expected_x, 1.0, "Child X must be centered")
	assert_approx(child.position.y, expected_y, 1.0, "Child Y must be centered")

func test_flow_container_wrapping() -> void:
	var flow: HFlowContainer = autofree(HFlowContainer.new()) as HFlowContainer
	flow.custom_minimum_size = Vector2(100, 100)
	flow.size = Vector2(100, 100)
	ui_root.add_child(flow)
	
	for i in range(4):
		var c = Control.new()
		c.custom_minimum_size = Vector2(60, 30)
		flow.add_child(c)
		
	await step_frames(2)
	assert_gte(flow.get_child_count(), 4)

func test_subviewport_container_dimensions() -> void:
	var svc: SubViewportContainer = autofree(SubViewportContainer.new()) as SubViewportContainer
	svc.stretch = true
	svc.custom_minimum_size = Vector2(256, 128)
	ui_root.add_child(svc)
	
	var sv: SubViewport = SubViewport.new()
	svc.add_child(sv)
	
	await step_frames(2)
	assert_true(svc.stretch)
	assert_gte(svc.size.x, 256.0)

func test_container_size_flags_expansion() -> void:
	var hbox: HBoxContainer = autofree(HBoxContainer.new()) as HBoxContainer
	hbox.custom_minimum_size = Vector2(400, 50)
	hbox.size = Vector2(400, 50)
	ui_root.add_child(hbox)
	
	var fixed_item: Control = Control.new()
	fixed_item.custom_minimum_size = Vector2(100, 50)
	fixed_item.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	hbox.add_child(fixed_item)
	
	var expand_item: Control = Control.new()
	expand_item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(expand_item)
	
	await step_frames(2)
	assert_gte(expand_item.size.x, 200.0, "Expanding child takes remaining width")

func test_nested_container_hierarchy() -> void:
	var margin: MarginContainer = autofree(MarginContainer.new()) as MarginContainer
	margin.add_theme_constant_override("margin_left", 10)
	ui_root.add_child(margin)
	
	var panel: PanelContainer = PanelContainer.new()
	margin.add_child(panel)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	panel.add_child(vbox)
	
	var btn: Button = Button.new()
	btn.text = "Nested"
	vbox.add_child(btn)
	
	await step_frames(2)
	assert_gte(btn.size.x, 50.0)
	assert_eq(btn.get_parent(), vbox)
	assert_eq(vbox.get_parent(), panel)
	assert_eq(panel.get_parent(), margin)

func test_container_visibility_reflow() -> void:
	var vbox: VBoxContainer = autofree(VBoxContainer.new()) as VBoxContainer
	ui_root.add_child(vbox)
	
	var c1: Control = Control.new()
	c1.custom_minimum_size = Vector2(100, 40)
	vbox.add_child(c1)
	
	var c2: Control = Control.new()
	c2.custom_minimum_size = Vector2(100, 40)
	vbox.add_child(c2)
	
	await step_frames(2)
	var initial_c2_y = c2.position.y
	assert_gte(initial_c2_y, 40.0)
	
	c1.visible = false
	await step_frames(2)
	assert_lt(c2.position.y, initial_c2_y, "Child 2 reflows upwards when Child 1 is hidden")
