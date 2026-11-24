# test_rig.gd
# Universal Godot 4 Test Harness & GSS Capture Rig
class_name TestRig
extends Node

const InputSimulator = preload("res://addons/gdtest/core/input_simulator.gd")
const GSS = preload("res://addons/gdtest/core/gss.gd")

signal scenario_completed(success: bool, report: Dictionary)

var test_name: String = "GodotAutomationTest"
var assertions_passed: int = 0
var assertions_failed: int = 0
var failure_messages: Array[String] = []
var step_logs: Array[String] = []
var screenshot_paths: Array[String] = []
var gss_snapshots: Array[Dictionary] = []
var live_gss_recordings: Array[Dictionary] = []
var telemetry_data: Dictionary = {}
var is_running: bool = false
var auto_quit_on_finish: bool = true
var start_time_msec: int = 0

func _ready() -> void:
	start_time_msec = Time.get_ticks_msec()
	if get_tree() and get_tree().root:
		var win: Window = get_tree().root
		var cfg_w: int = int(ProjectSettings.get_setting("display/window/size/viewport_width", 1152))
		var cfg_h: int = int(ProjectSettings.get_setting("display/window/size/viewport_height", 648))
		if cfg_w > 0 and cfg_h > 0:
			win.size = Vector2i(cfg_w, cfg_h)
			win.content_scale_size = Vector2i(cfg_w, cfg_h)
			win.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var scene_name = get_tree().current_scene.name if get_tree() and get_tree().current_scene else "Unknown"
	print("--- [TEST_RIG] Initialized for Scene: ", scene_name, " ---")

# ==============================================================================
# 📝 LOGGING & TELEMETRY
# ==============================================================================

## Logs a step in the test execution
func log_step(message: String) -> void:
	var msg = "[STEP] " + message
	step_logs.append(msg)
	print(msg)

## Records empirical telemetry key/value
func record_telemetry(key: String, value: Variant) -> void:
	telemetry_data[key] = value

# ==============================================================================
# 🧪 ASSERTIONS
# ==============================================================================

## Asserts a boolean condition is true
func assert_true(condition: bool, message: String) -> bool:
	if condition:
		assertions_passed += 1
		print("  [PASS] ", message)
		return true
	else:
		assertions_failed += 1
		var fail_msg = "[FAIL] " + message
		failure_messages.append(fail_msg)
		printerr("  " + fail_msg)
		return false

## Asserts a boolean condition is false
func assert_false(condition: bool, message: String) -> bool:
	return assert_true(not condition, message)

## Asserts equality between two variants
func assert_equal(actual: Variant, expected: Variant, message: String) -> bool:
	var passes = (actual == expected)
	if passes:
		assertions_passed += 1
		print("  [PASS] %s (Value: %s)" % [message, str(actual)])
		return true
	else:
		assertions_failed += 1
		var fail_msg = "[FAIL] %s - Expected: %s, Got: %s" % [message, str(expected), str(actual)]
		failure_messages.append(fail_msg)
		printerr("  " + fail_msg)
		return false

## Asserts inequality
func assert_not_equal(actual: Variant, unexpected: Variant, message: String) -> bool:
	var passes = (actual != unexpected)
	if passes:
		assertions_passed += 1
		print("  [PASS] %s (Value: %s != %s)" % [message, str(actual), str(unexpected)])
		return true
	else:
		assertions_failed += 1
		var fail_msg = "[FAIL] %s - Value %s was unexpectedly equal" % [message, str(actual)]
		failure_messages.append(fail_msg)
		printerr("  " + fail_msg)
		return false

## Asserts null
func assert_null(actual: Variant, message: String) -> bool:
	return assert_true(actual == null, message)

## Asserts not null
func assert_not_null(actual: Variant, message: String) -> bool:
	return assert_true(actual != null, message)

## Asserts a float falls within a [min_val, max_val] range
func assert_range(actual: float, min_val: float, max_val: float, message: String) -> bool:
	var passes = (actual >= min_val and actual <= max_val)
	if passes:
		assertions_passed += 1
		print("  [PASS] %s (Value: %f in [%f, %f])" % [message, actual, min_val, max_val])
		return true
	else:
		assertions_failed += 1
		var fail_msg = "[FAIL] %s - Value %f not in range [%f, %f]" % [message, actual, min_val, max_val]
		failure_messages.append(fail_msg)
		printerr("  " + fail_msg)
		return false

## Asserts floating-point approximation
func assert_approx(actual: float, expected: float, tolerance: float, message: String) -> bool:
	var diff = abs(actual - expected)
	if diff <= tolerance:
		assertions_passed += 1
		print("  [PASS] %s (Actual: %f, Expected: %f, Diff: %f)" % [message, actual, expected, diff])
		return true
	else:
		assertions_failed += 1
		var fail_msg = "[FAIL] %s - Value %f not within tolerance %f of %f (Diff: %f)" % [message, actual, tolerance, expected, diff]
		failure_messages.append(fail_msg)
		printerr("  " + fail_msg)
		return false

## Asserts Vector2 approximation
func assert_vector2_approx(actual: Vector2, expected: Vector2, tolerance: float, message: String) -> bool:
	var dist = actual.distance_to(expected)
	if dist <= tolerance:
		assertions_passed += 1
		print("  [PASS] %s (Actual: %s, Expected: %s, Dist: %f)" % [message, str(actual), str(expected), dist])
		return true
	else:
		assertions_failed += 1
		var fail_msg = "[FAIL] %s - Actual %s is %f away from expected %s (tolerance: %f)" % [message, str(actual), dist, str(expected), tolerance]
		failure_messages.append(fail_msg)
		printerr("  " + fail_msg)
		return false

## Asserts Vector3 approximation
func assert_vector3_approx(actual: Vector3, expected: Vector3, tolerance: float, message: String) -> bool:
	var dist = actual.distance_to(expected)
	if dist <= tolerance:
		assertions_passed += 1
		print("  [PASS] %s (Actual: %s, Expected: %s, Dist: %f)" % [message, str(actual), str(expected), dist])
		return true
	else:
		assertions_failed += 1
		var fail_msg = "[FAIL] %s - Actual %s is %f away from expected %s (tolerance: %f)" % [message, str(actual), dist, str(expected), tolerance]
		failure_messages.append(fail_msg)
		printerr("  " + fail_msg)
		return false

# ==============================================================================
# ⏱️ SYNCHRONIZATION
# ==============================================================================

## Waits for a number of process frames
func wait_frames(count: int = 1) -> void:
	for i in range(count):
		await get_tree().process_frame

## Waits for a number of physics frames
func wait_physics_frames(count: int = 1) -> void:
	for i in range(count):
		await get_tree().physics_frame

## Waits for a specified duration in seconds
func wait_seconds(duration: float) -> void:
	if duration > 0:
		await get_tree().create_timer(duration).timeout

# ==============================================================================
# 📸 VISUAL & GSS (GODOT SCENE SNAPSHOT) CAPTURE
# ==============================================================================

## Captures a screenshot to target_path AND generates a full GSS snapshot (.gss.html, .gss.json, .png)
func take_screenshot(target_path: String) -> bool:
	await wait_frames(2)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
	var snap_name = target_path.get_file().get_basename()
	if snap_name == "":
		snap_name = "snapshot_%d" % gss_snapshots.size()
	var target_node: Node = get_tree().current_scene if get_tree() and get_tree().current_scene else self
	var gss_data = GSS.capture(target_node, snap_name, {"output_dir": "res://artifacts/gss"})
	var gss_png_global: String = str(gss_data.get("global_png_path", ""))
	var gss_html_global: String = str(gss_data.get("global_html_path", ""))
	var gss_json_global: String = str(gss_data.get("global_json_path", ""))
	var global_path = ProjectSettings.globalize_path(target_path) if target_path.begins_with("res://") else target_path
	var dir = global_path.get_base_dir()
	if dir != "" and not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	if gss_png_global != "" and gss_png_global != global_path and FileAccess.file_exists(gss_png_global):
		var img = Image.load_from_file(gss_png_global)
		if img:
			img.save_png(global_path)
	screenshot_paths.append(global_path)
	gss_snapshots.append({
		"name": snap_name,
		"html_path": gss_html_global,
		"json_path": gss_json_global,
		"png_path": gss_png_global,
		"total_nodes": int(gss_data.get("total_nodes", 0))
	})
	print("  [GSS SNAPSHOT] Saved GSS HTML/JSON/PNG: ", gss_html_global)
	return true

## Explicitly captures a GSS snapshot with custom name and options
func capture_gss(snapshot_name: String, target_node: Node = null, options: Dictionary = {}) -> Dictionary:
	var root_node: Node = target_node if target_node != null else (get_tree().current_scene if get_tree() and get_tree().current_scene else self)
	var opts = options.duplicate()
	if not opts.has("output_dir"):
		opts["output_dir"] = "res://artifacts/gss"
	var snap = GSS.capture(root_node, snapshot_name, opts)
	var html_global: String = str(snap.get("global_html_path", ""))
	gss_snapshots.append({
		"name": snapshot_name,
		"html_path": html_global,
		"json_path": str(snap.get("global_json_path", "")),
		"png_path": str(snap.get("global_png_path", "")),
		"total_nodes": int(snap.get("total_nodes", 0))
	})
	print("  [GSS SNAPSHOT] Captured: ", html_global)
	return snap

## Starts a Live GSS delta recorder on the scene (or target_node)
func start_live_gss(recording_name: String, target_node: Node = null, options: Dictionary = {}) -> GSS.Recorder:
	var root_node: Node = target_node if target_node != null else (get_tree().current_scene if get_tree() and get_tree().current_scene else self)
	var opts = options.duplicate()
	if not opts.has("output_dir"):
		opts["output_dir"] = "res://artifacts/gss"
	if not opts.has("auto_step"):
		opts["auto_step"] = true
	var recorder = GSS.start_recording(root_node, recording_name, opts)
	print("  [LIVE GSS] Started recording: ", recording_name)
	return recorder

## Stops a Live GSS recorder and registers the generated interactive HTML/JSON artifacts
func stop_live_gss(recorder: GSS.Recorder) -> Dictionary:
	if recorder == null:
		return {}
	var rec = recorder.stop()
	var analysis: Dictionary = rec.get("analysis", {})
	var summary: Dictionary = analysis.get("summary", {})
	var entry = {
		"name": str(rec.get("recording_name", "live_gss")),
		"frame_count": int(rec.get("total_frames", 0)),
		"duration_ms": int(summary.get("duration_ms", 0)),
		"active_nodes": int(summary.get("active_node_count", 0)),
		"bounce_count": int(summary.get("bounces_detected", 0)),
		"html_path": str(rec.get("global_html_path", "")),
		"json_path": str(rec.get("global_json_path", "")),
		"png_path": str(rec.get("global_png_path", ""))
	}
	live_gss_recordings.append(entry)
	print("  [LIVE GSS] Saved interactive timeline (%d frames, %d active nodes, %d bounces): %s" % [
		entry["frame_count"], entry["active_nodes"], entry["bounce_count"], entry["html_path"]
	])
	return rec

# ==============================================================================
# 📐 COORDINATE & VIEWPORT HELPERS
# ==============================================================================

## Unprojects a 3D point in world space to screen coordinates (Vector2)
func unproject_3d(camera: Camera3D, world_position: Vector3) -> Vector2:
	if not camera:
		printerr("[TEST_RIG] Camera3D reference is null!")
		return Vector2.ZERO
	return camera.unproject_position(world_position)

## Returns the screen rect of a CanvasItem or Control
func get_canvas_rect(item: CanvasItem) -> Rect2:
	if item is Control:
		return (item as Control).get_global_rect()
	elif item is Node2D:
		var n2d = item as Node2D
		return Rect2(n2d.global_position, Vector2(32, 32))
	return Rect2()

# ==============================================================================
# 🎮 INPUT ACTIONS
# ==============================================================================

## Simulates a click at screen_pos
func click_at(screen_pos: Vector2, button: MouseButton = MOUSE_BUTTON_LEFT, delay: float = 0.05) -> void:
	await InputSimulator.click(get_tree(), screen_pos, button, delay)

## Simulates a double click at screen_pos
func double_click_at(screen_pos: Vector2, button: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	await InputSimulator.double_click(get_tree(), screen_pos, button)

## Simulates a drag from start_pos to end_pos
func drag(start_pos: Vector2, end_pos: Vector2, duration: float = 0.5, steps: int = 15, _button: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	await InputSimulator.drag(get_tree(), start_pos, end_pos, duration, steps)

## Simulates a key press
func press_key(key: Key, hold_duration: float = 0.05, shift: bool = false, ctrl: bool = false, alt: bool = false) -> void:
	await InputSimulator.tap_key(get_tree(), key, hold_duration, shift, ctrl, alt)

## Simulates a joypad button press
func press_joypad_button(device: int = 0, button: JoyButton = JOY_BUTTON_A, hold_duration: float = 0.05) -> void:
	await InputSimulator.tap_joy_button(get_tree(), device, button, hold_duration)

## Simulates moving a joypad analog stick
func move_joypad_stick(device: int = 0, target_vector: Vector2 = Vector2.ZERO, duration: float = 0.3, _steps: int = 10, is_right_stick: bool = false) -> void:
	await InputSimulator.simulate_analog_stick(get_tree(), device, target_vector, duration, is_right_stick)

## Simulates pressing an analog trigger (L2 / R2)
func press_joypad_trigger(device: int = 0, trigger: JoyAxis = JOY_AXIS_TRIGGER_RIGHT, target_val: float = 1.0, duration: float = 0.2) -> void:
	await InputSimulator.simulate_trigger(get_tree(), device, trigger, target_val, duration)

## Simulates triggering an action
func trigger_action(action_name: String, pressed: bool = true, strength: float = 1.0) -> void:
	var ev = InputEventAction.new()
	ev.action = action_name
	ev.pressed = pressed
	ev.strength = strength if pressed else 0.0
	Input.parse_input_event(ev)

# ==============================================================================
# 🏁 FINISH & REPORT GENERATION
# ==============================================================================

## Completes the test run, dumps JSON report, and optionally quits Godot
func finish(report_path: String = "") -> Dictionary:
	var success = (assertions_failed == 0)
	var elapsed_sec = float(Time.get_ticks_msec() - start_time_msec) / 1000.0
	var report = {
		"test_name": test_name,
		"success": success,
		"elapsed_seconds": elapsed_sec,
		"assertions_passed": assertions_passed,
		"assertions_failed": assertions_failed,
		"failures": failure_messages,
		"step_logs": step_logs,
		"telemetry": telemetry_data,
		"screenshots": screenshot_paths,
		"gss_snapshots": gss_snapshots,
		"live_gss_recordings": live_gss_recordings,
		"timestamp": Time.get_datetime_string_from_system()
	}
	
	print("\n==================================================")
	print("--- [TEST_RIG TEST SUMMARY: %s] ---" % test_name)
	print("Status: ", "✅ PASSED" if success else "❌ FAILED")
	print("Elapsed Time: %.2f seconds" % elapsed_sec)
	print("Passed Assertions: ", assertions_passed)
	print("Failed Assertions: ", assertions_failed)
	print("GSS Snapshots: ", gss_snapshots.size())
	print("Live GSS Recordings: ", live_gss_recordings.size())
	if not success:
		print("Failures:")
		for f in failure_messages:
			print("  - ", f)
	print("==================================================\n")
	
	if report_path != "":
		var global_path = ProjectSettings.globalize_path(report_path) if report_path.begins_with("res://") else report_path
		var dir = global_path.get_base_dir()
		if dir != "" and not DirAccess.dir_exists_absolute(dir):
			DirAccess.make_dir_recursive_absolute(dir)
		var file = FileAccess.open(global_path, FileAccess.WRITE)
		if file:
			file.store_string(JSON.stringify(report, "\t"))
			file.close()
			print("[TEST_RIG] Report written to: ", global_path)
			
	scenario_completed.emit(success, report)
	
	if auto_quit_on_finish:
		await wait_frames(2)
		get_tree().quit(0 if success else 1)
		
	return report
