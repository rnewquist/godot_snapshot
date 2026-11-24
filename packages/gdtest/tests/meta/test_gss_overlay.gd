# test_gss_overlay.gd
# Verifies GSSOverlay standalone Static GSS & Live GSS capture APIs inside Godot.
extends "res://addons/gdtest/core/test_suite.gd"

const GSSOverlayScript = preload("res://addons/gdtest/core/gss_overlay.gd")

func _init() -> void:
	suite_name = "Meta_GSS_Overlay_Suite"
	test_type = "integration"


func test_overlay_static_snapshot_and_live_recording() -> void:
	var overlay := GSSOverlayScript.new()
	overlay.show_hud = false
	overlay.output_dir = "user://gss_overlay_unit_test"
	add_child(overlay)
	autofree(overlay)

	var dummy := Node2D.new()
	dummy.name = "OverlayTestNode"
	dummy.position = Vector2(42, 84)
	add_child(dummy)
	autofree(dummy)

	# 1. Static GSS capture via GSSOverlay
	var snap_res: Dictionary = overlay.capture_snapshot("overlay_snap_test")
	assert_true(bool(snap_res.get("success", false)), "GSSOverlay.capture_snapshot() must succeed")
	assert_true(overlay.last_html_path.ends_with(".gss.html"), "last_html_path must point to .gss.html")
	assert_true(FileAccess.file_exists(overlay.last_html_path), "Static GSS HTML must exist on disk")

	# 2. Live GSS start/stop via GSSOverlay
	var started: bool = overlay.start_live_recording("overlay_live_test")
	assert_true(started, "GSSOverlay.start_live_recording() must start recording")
	assert_true(overlay.is_recording_live, "is_recording_live must be true while recording")

	dummy.position = Vector2(120, 160)
	await get_tree().physics_frame
	dummy.position = Vector2(200, 240)
	await get_tree().physics_frame

	var live_res: Dictionary = overlay.stop_live_recording()
	assert_false(overlay.is_recording_live, "is_recording_live must reset to false after stop")
	assert_true(bool(live_res.get("success", false)), "GSSOverlay.stop_live_recording() must succeed")
	assert_true(overlay.last_html_path.ends_with(".gss.live.html"), "last_html_path must point to .gss.live.html")
	assert_true(FileAccess.file_exists(overlay.last_html_path), "Live GSS HTML must exist on disk")
