# main_showcase_2d.gd
extends Node2D
class_name MainShowcase2D

const GSS = preload("res://addons/gdtest/core/gss.gd")

@onready var tab_container: TabContainer = $CanvasLayer/TabContainer

func _ready() -> void:
	print("--- Godot 2D Mega Showcase Initialized ---")
	GSS.install_hotkey_listener(self)
	tab_container.tab_changed.connect(_on_tab_changed)
	_on_tab_changed(tab_container.current_tab)

func _on_tab_changed(tab_idx: int) -> void:
	for i in range(tab_container.get_child_count()):
		var child = tab_container.get_child(i)
		child.visible = (i == tab_idx)

func switch_to_module(index: int) -> void:
	if tab_container and index >= 0 and index < tab_container.get_tab_count():
		tab_container.current_tab = index
		_on_tab_changed(index)
