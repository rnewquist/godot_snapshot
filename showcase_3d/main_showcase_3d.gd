# main_showcase_3d.gd
extends Node3D
class_name MainShowcase3D

const GSS = preload("res://addons/gdtest/core/gss.gd")

@onready var camera: Camera3D = $Camera3D
@onready var modules_container: Node3D = $Modules
@onready var tab_bar: TabBar = $CanvasLayer/HUD/TabBar
@onready var module_title: Label = $CanvasLayer/HUD/Header/ModuleTitle

var module_names = [
	"1. PBR Materials & Shaders",
	"2. 3D Lighting & Shadows",
	"3. Physics & Elevators",
	"4. Joints & Constraints",
	"5. Particles & Decals"
]

func _ready() -> void:
	print("--- Godot 3D Mega Showcase Initialized ---")
	GSS.install_hotkey_listener(self)
	tab_bar.tab_changed.connect(_on_tab_changed)
	switch_to_module(0)

func _on_tab_changed(tab_idx: int) -> void:
	switch_to_module(tab_idx)

func switch_to_module(index: int) -> void:
	if index >= 0 and index < modules_container.get_child_count():
		for i in range(modules_container.get_child_count()):
			var child = modules_container.get_child(i)
			child.visible = (i == index)
		if tab_bar.current_tab != index:
			tab_bar.current_tab = index
		module_title.text = module_names[index]
