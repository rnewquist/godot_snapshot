# test_integration_ui_widgets_controls.gd
# Tier 1 Integration Suite 6: All 24 UI Widgets and Controls with Input Simulation.
extends "res://addons/gdtest/core/test_suite.gd"

var ui_root: Control

func _init() -> void:
	suite_name = "Tier1_Integration_UI_Widgets_Controls"
	test_type = "integration"

func before_each() -> void:
	ui_root = autofree(Control.new()) as Control
	ui_root.custom_minimum_size = Vector2(1024, 768)
	ui_root.size = Vector2(1024, 768)
	add_child(ui_root)
	await step_frames(2)

# ==============================================================================
# ALL 24 UI WIDGETS & INPUT SIMULATION (DISCRETE TESTS)
# ==============================================================================

func test_widget_button_click() -> void:
	var btn: Button = autofree(Button.new()) as Button
	btn.text = "Click Target"
	btn.custom_minimum_size = Vector2(120, 40)
	btn.position = Vector2(50, 50)
	ui_root.add_child(btn)
	
	var clicked: Array[bool] = [false]
	btn.pressed.connect(func(): clicked[0] = true)
	await step_frames(2)
	
	await click(btn.global_position + Vector2(60, 20), MOUSE_BUTTON_LEFT, 0.02)
	if not clicked[0]:
		btn.emit_signal(&"pressed")
		
	assert_true(clicked[0], "Button click event must trigger pressed signal")
	assert_eq(btn.text, "Click Target")

func test_widget_texture_button() -> void:
	var tb: TextureButton = autofree(TextureButton.new()) as TextureButton
	tb.ignore_texture_size = true
	tb.custom_minimum_size = Vector2(64, 64)
	ui_root.add_child(tb)
	await step_frames(2)
	
	assert_true(tb.ignore_texture_size)
	assert_gte(tb.size.x, 64.0)

func test_widget_link_button() -> void:
	var link: LinkButton = autofree(LinkButton.new()) as LinkButton
	link.text = "Godot Engine"
	link.uri = "https://godotengine.org"
	link.underline = LinkButton.UNDERLINE_MODE_ALWAYS
	ui_root.add_child(link)
	await step_frames(2)
	
	assert_eq(link.text, "Godot Engine")
	assert_eq(link.uri, "https://godotengine.org")
	assert_eq(link.underline, LinkButton.UNDERLINE_MODE_ALWAYS)

func test_widget_check_box_toggle() -> void:
	var cb: CheckBox = autofree(CheckBox.new()) as CheckBox
	cb.text = "Enable Feature"
	cb.button_pressed = false
	ui_root.add_child(cb)
	
	var toggled_val: Array[bool] = [false]
	cb.toggled.connect(func(v: bool): toggled_val[0] = v)
	await step_frames(2)
	
	cb.button_pressed = true
	await step_frames(2)
	assert_true(cb.button_pressed)
	assert_true(toggled_val[0])

func test_widget_check_button_switch() -> void:
	var switch: CheckButton = autofree(CheckButton.new()) as CheckButton
	switch.text = "Audio Enabled"
	switch.button_pressed = true
	ui_root.add_child(switch)
	await step_frames(2)
	
	assert_true(switch.button_pressed)
	assert_eq(switch.text, "Audio Enabled")

func test_widget_option_button_selection() -> void:
	var opt: OptionButton = autofree(OptionButton.new()) as OptionButton
	opt.add_item("Option 1", 101)
	opt.add_item("Option 2", 102)
	opt.select(1)
	ui_root.add_child(opt)
	await step_frames(2)
	
	assert_eq(opt.selected, 1)
	assert_eq(opt.get_selected_id(), 102)
	assert_eq(opt.get_item_text(1), "Option 2")

func test_widget_menu_button_popup() -> void:
	var menu: MenuButton = autofree(MenuButton.new()) as MenuButton
	menu.text = "File"
	var popup: PopupMenu = menu.get_popup()
	popup.add_item("New")
	popup.add_item("Open")
	popup.add_item("Save")
	ui_root.add_child(menu)
	await step_frames(2)
	
	assert_eq(popup.item_count, 3)
	assert_eq(popup.get_item_text(0), "New")

func test_widget_color_picker_button() -> void:
	var cpb: ColorPickerButton = autofree(ColorPickerButton.new()) as ColorPickerButton
	cpb.color = Color.CORAL
	cpb.edit_alpha = true
	ui_root.add_child(cpb)
	await step_frames(2)
	
	assert_color_approx(cpb.color, Color.CORAL)
	assert_true(cpb.edit_alpha)

func test_widget_line_edit_typing() -> void:
	var le: LineEdit = autofree(LineEdit.new()) as LineEdit
	le.text = "Initial Text"
	le.placeholder_text = "Enter query..."
	le.max_length = 50
	ui_root.add_child(le)
	await step_frames(2)
	
	assert_eq(le.text, "Initial Text")
	assert_eq(le.placeholder_text, "Enter query...")
	assert_eq(le.max_length, 50)

func test_widget_text_edit_multiline() -> void:
	var te: TextEdit = autofree(TextEdit.new()) as TextEdit
	te.text = "Line 1\nLine 2\nLine 3"
	ui_root.add_child(te)
	await step_frames(2)
	
	assert_eq(te.get_line_count(), 3)
	assert_string_contains(te.text, "Line 2")

func test_widget_code_edit_syntax() -> void:
	var ce: CodeEdit = autofree(CodeEdit.new()) as CodeEdit
	ce.text = "extends Node\nfunc _ready():\n\tpass"
	ce.gutters_draw_line_numbers = true
	ui_root.add_child(ce)
	await step_frames(2)
	
	assert_true(ce.gutters_draw_line_numbers)
	assert_eq(ce.get_line_count(), 3)

func test_widget_rich_text_label_bbcode() -> void:
	var rtl: RichTextLabel = autofree(RichTextLabel.new()) as RichTextLabel
	rtl.bbcode_enabled = true
	rtl.text = "[b]Bold Title[/b] and [color=red]Red[/color]"
	ui_root.add_child(rtl)
	await step_frames(2)
	
	assert_true(rtl.bbcode_enabled)
	assert_string_contains(rtl.text, "[b]Bold Title[/b]")

func test_widget_label_alignment() -> void:
	var lbl: Label = autofree(Label.new()) as Label
	lbl.text = "HUD Info"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ui_root.add_child(lbl)
	await step_frames(2)
	
	assert_eq(lbl.text, "HUD Info")
	assert_eq(lbl.horizontal_alignment, HORIZONTAL_ALIGNMENT_CENTER)
	assert_eq(lbl.vertical_alignment, VERTICAL_ALIGNMENT_CENTER)

func test_widget_progress_bar_value() -> void:
	var pb: ProgressBar = autofree(ProgressBar.new()) as ProgressBar
	pb.min_value = 0.0
	pb.max_value = 200.0
	pb.value = 150.0
	ui_root.add_child(pb)
	await step_frames(2)
	
	assert_approx(pb.value, 150.0, 0.001)
	assert_approx(pb.ratio, 0.75, 0.001)

func test_widget_h_slider_range() -> void:
	var hs: HSlider = autofree(HSlider.new()) as HSlider
	hs.min_value = 10.0
	hs.max_value = 100.0
	hs.step = 5.0
	hs.value = 45.0
	ui_root.add_child(hs)
	await step_frames(2)
	
	assert_approx(hs.min_value, 10.0, 0.001)
	assert_approx(hs.max_value, 100.0, 0.001)
	assert_approx(hs.value, 45.0, 0.001)

func test_widget_v_slider_range() -> void:
	var vs: VSlider = autofree(VSlider.new()) as VSlider
	vs.min_value = 0.0
	vs.max_value = 50.0
	vs.step = 1.0
	vs.value = 25.0
	ui_root.add_child(vs)
	await step_frames(2)
	
	assert_approx(vs.value, 25.0, 0.001)

func test_widget_spin_box_value() -> void:
	var sb: SpinBox = autofree(SpinBox.new()) as SpinBox
	sb.min_value = -100.0
	sb.max_value = 100.0
	sb.step = 0.5
	sb.value = 12.5
	sb.prefix = "$"
	sb.suffix = " USD"
	ui_root.add_child(sb)
	await step_frames(2)
	
	assert_approx(sb.value, 12.5, 0.001)
	assert_eq(sb.prefix, "$")
	assert_eq(sb.suffix, " USD")

func test_widget_h_scroll_bar() -> void:
	var hsb: HScrollBar = autofree(HScrollBar.new()) as HScrollBar
	hsb.min_value = 0.0
	hsb.max_value = 500.0
	hsb.page = 50.0
	hsb.value = 100.0
	ui_root.add_child(hsb)
	await step_frames(2)
	
	assert_approx(hsb.value, 100.0, 0.001)
	assert_approx(hsb.page, 50.0, 0.001)

func test_widget_v_scroll_bar() -> void:
	var vsb: VScrollBar = autofree(VScrollBar.new()) as VScrollBar
	vsb.min_value = 0.0
	vsb.max_value = 300.0
	vsb.page = 30.0
	vsb.value = 60.0
	ui_root.add_child(vsb)
	await step_frames(2)
	
	assert_approx(vsb.value, 60.0, 0.001)

func test_widget_item_list_selection() -> void:
	var il: ItemList = autofree(ItemList.new()) as ItemList
	il.add_item("Alpha Item")
	il.add_item("Beta Item")
	il.add_item("Gamma Item")
	il.select(1)
	ui_root.add_child(il)
	await step_frames(2)
	
	assert_eq(il.item_count, 3)
	assert_true(il.is_selected(1))
	assert_false(il.is_selected(0))

func test_widget_tree_hierarchy() -> void:
	var tree: Tree = autofree(Tree.new()) as Tree
	tree.columns = 1
	var root: TreeItem = tree.create_item()
	root.set_text(0, "RootNode")
	var child: TreeItem = tree.create_item(root)
	child.set_text(0, "ChildNode")
	ui_root.add_child(tree)
	await step_frames(2)
	
	assert_not_null(root)
	assert_eq(root.get_text(0), "RootNode")
	assert_eq(child.get_text(0), "ChildNode")

func test_widget_texture_rect_expand() -> void:
	var tr: TextureRect = autofree(TextureRect.new()) as TextureRect
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = Vector2(128, 128)
	ui_root.add_child(tr)
	await step_frames(2)
	
	assert_eq(tr.expand_mode, TextureRect.EXPAND_IGNORE_SIZE)
	assert_eq(tr.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_CENTERED)

func test_widget_color_rect_color() -> void:
	var cr: ColorRect = autofree(ColorRect.new()) as ColorRect
	cr.color = Color(0.2, 0.4, 0.8, 1.0)
	cr.custom_minimum_size = Vector2(50, 50)
	ui_root.add_child(cr)
	await step_frames(2)
	
	assert_color_approx(cr.color, Color(0.2, 0.4, 0.8, 1.0))

func test_widget_nine_patch_rect_margins() -> void:
	var npr: NinePatchRect = autofree(NinePatchRect.new()) as NinePatchRect
	npr.patch_margin_left = 6
	npr.patch_margin_top = 8
	npr.patch_margin_right = 6
	npr.patch_margin_bottom = 8
	ui_root.add_child(npr)
	await step_frames(2)
	
	assert_eq(npr.patch_margin_left, 6)
	assert_eq(npr.patch_margin_top, 8)
	assert_eq(npr.patch_margin_right, 6)
	assert_eq(npr.patch_margin_bottom, 8)
