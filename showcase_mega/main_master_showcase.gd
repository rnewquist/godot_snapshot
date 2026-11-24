# main_master_showcase.gd
# Universal Master Showcase wiring 10 modules across 10 main HUD tabs.
extends Node3D
class_name MainMasterShowcase

const GSS = preload("res://addons/gdtest/core/gss.gd")

@onready var modules_container: Node = $Modules
@onready var tab_bar: TabBar = $CanvasLayer/HUD/TabBar
@onready var module_title: Label = $CanvasLayer/HUD/Header/ModuleTitle

var module_names: Array[String] = [
	"1. 2D Extended (AStarGrid, TileMapLayer & Parallax)",
	"2. 3D Procedural Meshes, CSG & Global Illumination",
	"3. 3D Rigid Body Physics & 5 Mechanical Joints",
	"4. Animation Player, Libraries & Tween Sequences",
	"5. Audio Engine, Real-Time FFT & 28 DSP Buses",
	"6. 3D Navigation Server & AI Pathfinding Agents",
	"7. Custom Spatial & Canvas Shaders and Optics",
	"8. High-Level Multiplayer, RPC & Network Sync",
	"9. Multithreading, File I/O & Low-Level Servers",
	"10. Comprehensive UI Container & 24-Widget Matrix"
]

func _ready() -> void:
	print("=== Godot Comprehensive Engine Master Showcase Initialized (10 Modules Active) ===")
	GSS.install_hotkey_listener(self)
	tab_bar.tab_changed.connect(_on_tab_changed)
	switch_to_module(0)

func _on_tab_changed(tab_idx: int) -> void:
	switch_to_module(tab_idx)

func switch_to_module(index: int) -> void:
	if index >= 0 and index < modules_container.get_child_count():
		for i in range(modules_container.get_child_count()):
			var child = modules_container.get_child(i)
			var is_active = (i == index)
			if child is Node2D or child is Node3D or child is CanvasItem:
				child.visible = is_active
			# Handle any CanvasLayer children in modules
			for subchild in child.get_children():
				if subchild is CanvasLayer:
					subchild.visible = is_active
					
		if tab_bar.current_tab != index:
			tab_bar.current_tab = index
		if index < module_names.size():
			module_title.text = module_names[index]
