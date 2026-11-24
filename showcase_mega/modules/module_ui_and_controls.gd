# module_ui_and_controls.gd
class_name ModuleUIAndControls
extends Control

var predictions: Dictionary = {
	"button_click_registered": true,
	"checkbox_toggle_state": true,
	"option_selected_index": 2,
	"slider_final_value": 75.0,
	"text_input_value": "Godot UI",
	"tree_root_child_count": 2,
	"item_list_count": 3
}

var actuals: Dictionary = {
	"button_click_registered": false,
	"checkbox_toggle_state": false,
	"option_selected_index": -1,
	"slider_final_value": 0.0,
	"text_input_value": "",
	"tree_root_child_count": 0,
	"item_list_count": 0
}

@onready var action_button: Button = $VBoxContainer/HBoxContainer/ActionButton
@onready var state_checkbox: CheckBox = $VBoxContainer/HBoxContainer/StateCheckBox
@onready var dropdown_options: OptionButton = $VBoxContainer/HBoxContainer/DropdownOptions
@onready var value_slider: HSlider = $VBoxContainer/SliderContainer/ValueSlider
@onready var text_input: LineEdit = $VBoxContainer/InputContainer/TextInput
@onready var tree_view: Tree = $VBoxContainer/SplitView/TreeView
@onready var item_list: ItemList = $VBoxContainer/SplitView/ItemList
@onready var rich_label: RichTextLabel = $VBoxContainer/RichLabel

func _ready() -> void:
	# Connect UI signals
	action_button.pressed.connect(_on_button_pressed)
	state_checkbox.toggled.connect(_on_checkbox_toggled)
	dropdown_options.item_selected.connect(_on_option_selected)
	value_slider.value_changed.connect(_on_slider_changed)
	text_input.text_changed.connect(_on_text_changed)
	
	# Populate Dropdown
	dropdown_options.clear()
	dropdown_options.add_item("Option Alpha", 0)
	dropdown_options.add_item("Option Beta", 1)
	dropdown_options.add_item("Option Gamma", 2)
	
	# Populate ItemList
	item_list.clear()
	item_list.add_item("Inventory Item A")
	item_list.add_item("Inventory Item B")
	item_list.add_item("Inventory Item C")
	actuals["item_list_count"] = item_list.item_count
	
	# Populate Tree
	tree_view.clear()
	var root: TreeItem = tree_view.create_item()
	root.set_text(0, "Root Node")
	var child1: TreeItem = tree_view.create_item(root)
	child1.set_text(0, "SubNode Alpha")
	var child2: TreeItem = tree_view.create_item(root)
	child2.set_text(0, "SubNode Beta")
	actuals["tree_root_child_count"] = root.get_children().size()
	
	# Rich Text Formatting
	rich_label.bbcode_enabled = true
	rich_label.text = "[b]UI Engine[/b] :: [color=cyan]Container Hierarchy Active[/color]"

func _on_button_pressed() -> void:
	actuals["button_click_registered"] = true

func _on_checkbox_toggled(toggled_on: bool) -> void:
	actuals["checkbox_toggle_state"] = toggled_on

func _on_option_selected(index: int) -> void:
	actuals["option_selected_index"] = index

func _on_slider_changed(new_val: float) -> void:
	actuals["slider_final_value"] = new_val

func _on_text_changed(new_text: String) -> void:
	actuals["text_input_value"] = new_text

func execute_programmatic_ui_interaction() -> void:
	# Programmatic invocation for validation
	action_button.emit_signal("pressed")
	state_checkbox.button_pressed = true
	dropdown_options.select(2)
	_on_option_selected(2)
	value_slider.value = 75.0
	text_input.text = "Godot UI"
	_on_text_changed("Godot UI")
