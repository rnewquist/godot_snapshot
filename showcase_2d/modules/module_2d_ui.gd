# module_2d_ui.gd
extends Control
class_name Module2DUI

@onready var test_button: Button = %TestButton
@onready var check_box: CheckBox = %CheckBox
@onready var check_button: CheckButton = %CheckButton
@onready var slider: HSlider = %HSlider
@onready var v_slider: VSlider = %VSlider
@onready var h_scroll_bar: HScrollBar = %HScrollBar
@onready var v_scroll_bar: VScrollBar = %VScrollBar
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var spin_box: SpinBox = %SpinBox
@onready var line_edit: LineEdit = %LineEdit
@onready var text_edit: TextEdit = %TextEdit
@onready var code_edit: CodeEdit = %CodeEdit
@onready var option_button: OptionButton = %OptionButton
@onready var menu_button: MenuButton = %MenuButton
@onready var color_picker_btn: ColorPickerButton = %ColorPickerButton
@onready var link_button: LinkButton = %LinkButton
@onready var texture_button: TextureButton = %TextureButton
@onready var rich_text_label: RichTextLabel = %RichTextLabel
@onready var output_label: Label = %OutputLabel
@onready var texture_rect: TextureRect = %TextureRect
@onready var color_rect: ColorRect = %ColorRect
@onready var tree: Tree = %Tree
@onready var item_list: ItemList = %ItemList
@onready var tab_bar: TabBar = %TabBar

var click_count: int = 0

func _ready() -> void:
	if test_button:
		test_button.pressed.connect(_on_button_pressed)
	if check_box:
		check_box.toggled.connect(_on_checkbox_toggled)
	if check_button:
		check_button.toggled.connect(_on_checkbutton_toggled)
	if slider:
		slider.value_changed.connect(_on_slider_changed)
	if v_slider:
		v_slider.value_changed.connect(_on_v_slider_changed)
	if line_edit:
		line_edit.text_changed.connect(_on_text_changed)
	if option_button:
		option_button.item_selected.connect(_on_option_selected)
		option_button.add_item("Option 1: Balanced", 0)
		option_button.add_item("Option 2: Performance", 1)
		option_button.add_item("Option 3: High Fidelity", 2)
	
	if menu_button:
		var popup = menu_button.get_popup()
		popup.clear()
		popup.add_item("File > New")
		popup.add_item("File > Save")
		popup.add_item("File > Exit")
		popup.id_pressed.connect(_on_menu_item_selected)

	if color_picker_btn:
		color_picker_btn.color_changed.connect(_on_color_changed)

	if spin_box:
		spin_box.value_changed.connect(_on_spinbox_changed)

	if tab_bar:
		tab_bar.tab_changed.connect(_on_tab_bar_changed)

	if progress_bar and slider:
		progress_bar.value = slider.value

	if tree:
		_populate_tree()

	if item_list:
		_populate_item_list()

func _populate_tree() -> void:
	tree.clear()
	var root = tree.create_item()
	root.set_text(0, "Root Node")
	var child1 = tree.create_item(root)
	child1.set_text(0, "Sub-item A")
	var child2 = tree.create_item(root)
	child2.set_text(0, "Sub-item B")
	var subchild = tree.create_item(child2)
	subchild.set_text(0, "Leaf 1")

func _populate_item_list() -> void:
	item_list.clear()
	item_list.add_item("Physics Engine 2D")
	item_list.add_item("Rendering Server")
	item_list.add_item("Audio Stream Player")
	item_list.add_item("Input Dispatcher")

func _on_button_pressed() -> void:
	click_count += 1
	if test_button:
		test_button.text = "Clicks: %d" % click_count
	if output_label:
		output_label.text = "Button clicked! Total: %d" % click_count

func _on_checkbox_toggled(pressed: bool) -> void:
	if output_label:
		output_label.text = "Feature Toggle: %s" % ("ENABLED" if pressed else "DISABLED")

func _on_checkbutton_toggled(pressed: bool) -> void:
	if output_label:
		output_label.text = "Power Grid: %s" % ("ONLINE" if pressed else "OFFLINE")

func _on_slider_changed(val: float) -> void:
	if progress_bar:
		progress_bar.value = val
	if output_label:
		output_label.text = "Slider Value: %.1f %%" % val

func _on_v_slider_changed(val: float) -> void:
	if output_label:
		output_label.text = "VSlider Value: %.1f" % val

func _on_text_changed(new_text: String) -> void:
	if output_label:
		output_label.text = "Input Text: %s" % new_text

func _on_option_selected(idx: int) -> void:
	if output_label and option_button:
		output_label.text = "Selected Profile: %s" % option_button.get_item_text(idx)

func _on_menu_item_selected(id: int) -> void:
	if output_label:
		output_label.text = "Menu Selected Item: ID %d" % id

func _on_color_changed(col: Color) -> void:
	if color_rect:
		color_rect.color = col
	if output_label:
		output_label.text = "Color Changed: %s" % col.to_html()

func _on_spinbox_changed(val: float) -> void:
	if output_label:
		output_label.text = "SpinBox Value: %.0f" % val

func _on_tab_bar_changed(tab: int) -> void:
	if output_label:
		output_label.text = "Footer Tab: %d" % tab
