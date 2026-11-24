# gss_overlay.gd
# Standalone in-game GSS & Live GSS Capture Overlay for Godot 4.x.
# Add as an Autoload (Project -> Project Settings -> Globals -> Autoload) or drop into any scene:
#   - Press F9  (default) -> Capture Static GSS Screenshot (.png + .gss.json + .gss.html)
#   - Press F10 (default) -> Start / Stop Live GSS Delta Recording (.gss.live.json + .gss.live.html)
#   - Press F11 (default) -> Open the most recent GSS HTML Inspector in your web browser
class_name GSSOverlay
extends CanvasLayer

const GSSLib = preload("res://addons/gdtest/core/gss.gd")

signal snapshot_captured(result: Dictionary)
signal live_recording_started(recording_name: String)
signal live_recording_stopped(result: Dictionary)

@export var output_dir: String = GSSLib.DEFAULT_OUTPUT_DIR
@export var snapshot_key: Key = KEY_F9
@export var live_toggle_key: Key = KEY_F10
@export var open_last_key: Key = KEY_F11
@export var live_step_mode: String = "physics" # "physics" or "process"
@export var show_hud: bool = true
@export var auto_open_on_capture: bool = false

var last_html_path: String = ""
var last_json_path: String = ""
var is_recording_live: bool = false

var _recorder: GSSLib.Recorder = null
var _hud_root: Control = null
var _status_label: Label = null
var _live_btn: Button = null
var _open_btn: Button = null
var _toast_label: Label = null
var _toast_timer: Timer = null


func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	if show_hud and DisplayServer.get_name() != "headless":
		_build_hud()


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	if key_event.keycode == snapshot_key:
		get_viewport().set_input_as_handled()
		capture_snapshot()
	elif key_event.keycode == live_toggle_key:
		get_viewport().set_input_as_handled()
		toggle_live_recording()
	elif key_event.keycode == open_last_key:
		get_viewport().set_input_as_handled()
		open_last_capture()


func _process(_delta: float) -> void:
	if is_recording_live and _recorder and _status_label:
		var count: int = _recorder.frames.size()
		_status_label.text = "REC LIVE GSS (%df)" % count


## Resolves the active gameplay scene to inspect (excluding this overlay itself).
func _resolve_capture_target() -> Node:
	var tree := get_tree()
	if not tree:
		return null
	if tree.current_scene and is_instance_valid(tree.current_scene):
		return tree.current_scene
	return tree.root


## Generates a readable timestamped name such as "main_2d_20261123_114500".
func _make_capture_name(prefix: String) -> String:
	var target := _resolve_capture_target()
	var scene_part: String = target.name.to_snake_case() if target else "scene"
	var dt := Time.get_datetime_dict_from_system()
	var stamp := "%04d%02d%02d_%02d%02d%02d" % [
		int(dt.get("year", 2026)),
		int(dt.get("month", 1)),
		int(dt.get("day", 1)),
		int(dt.get("hour", 0)),
		int(dt.get("minute", 0)),
		int(dt.get("second", 0))
	]
	return "%s_%s_%s" % [prefix, scene_part, stamp]


## Captures a point-in-time Static GSS Screenshot (.png + .gss.json + .gss.html).
func capture_snapshot(custom_name: String = "") -> Dictionary:
	var target := _resolve_capture_target()
	if not target:
		return {"success": false, "error": "No active scene available for GSS snapshot"}

	var snap_name := custom_name if custom_name != "" else _make_capture_name("snap")
	var prev_hud_vis := _hud_root.visible if _hud_root else false
	if _hud_root:
		_hud_root.visible = false

	var result: Dictionary = GSSLib.capture(target, snap_name, {
		"output_dir": output_dir,
		"write_html": true,
		"write_json": true,
		"write_png": true
	})

	if _hud_root:
		_hud_root.visible = prev_hud_vis

	if bool(result.get("success", false)):
		last_html_path = str(result.get("global_html_path", ""))
		last_json_path = str(result.get("global_json_path", ""))
		_update_open_button()
		var fname := last_html_path.get_file()
		print("[GSSOverlay] Static GSS captured: ", last_html_path)
		_show_toast("Saved GSS: %s (Press F11 to open)" % fname)
		snapshot_captured.emit(result)
		if auto_open_on_capture:
			open_last_capture()
	else:
		_show_toast("GSS Capture failed: " + str(result.get("error", "unknown")))

	return result


## Starts recording a Live GSS delta session.
func start_live_recording(custom_name: String = "") -> bool:
	if is_recording_live:
		return false
	var target := _resolve_capture_target()
	if not target:
		return false

	var rec_name := custom_name if custom_name != "" else _make_capture_name("live")
	var prev_hud_vis := _hud_root.visible if _hud_root else false
	if _hud_root:
		_hud_root.visible = false

	_recorder = GSSLib.start_recording(target, rec_name, {
		"output_dir": output_dir,
		"step_mode": live_step_mode,
		"auto_step": true,
		"write_html": true,
		"write_json": true,
		"write_png": true
	})

	if _hud_root:
		_hud_root.visible = prev_hud_vis

	is_recording_live = true
	_update_live_hud_state()
	print("[GSSOverlay] Live GSS recording started: ", rec_name)
	_show_toast("Live GSS recording started (Press F10 to stop)")
	live_recording_started.emit(rec_name)
	return true


## Stops the active Live GSS recording and saves .gss.live.json + .gss.live.html.
func stop_live_recording() -> Dictionary:
	if not is_recording_live or not _recorder:
		return {"success": false, "error": "No active Live GSS recording"}

	var result: Dictionary = _recorder.stop()
	_recorder = null
	is_recording_live = false
	_update_live_hud_state()

	if bool(result.get("success", false)):
		last_html_path = str(result.get("global_html_path", ""))
		last_json_path = str(result.get("global_json_path", ""))
		_update_open_button()
		var summary: Dictionary = result.get("analysis", {}).get("summary", {})
		var frames_count: int = int(summary.get("total_frames", 0))
		var bounces: int = int(summary.get("bounces_detected", 0))
		print("[GSSOverlay] Live GSS saved (%df, %d bounces): %s" % [frames_count, bounces, last_html_path])
		_show_toast("Live GSS saved: %s (%df, %d bounces)" % [last_html_path.get_file(), frames_count, bounces])
		live_recording_stopped.emit(result)
		if auto_open_on_capture:
			open_last_capture()
	else:
		_show_toast("Live GSS save failed")

	return result


## Toggles Live GSS recording on/off.
func toggle_live_recording() -> void:
	if is_recording_live:
		stop_live_recording()
	else:
		start_live_recording()


## Opens the most recently captured .gss.html or .gss.live.html in the system browser.
func open_last_capture() -> bool:
	if last_html_path == "" or not FileAccess.file_exists(last_html_path):
		_show_toast("No GSS report captured yet (Press F9 or F10)")
		return false
	var url := "file://" + last_html_path
	var err := OS.shell_open(url)
	if err == OK:
		_show_toast("Opened in browser: " + last_html_path.get_file())
		return true
	_show_toast("Could not open browser for: " + last_html_path.get_file())
	return false


# --- Compact On-Screen HUD ---

func _build_hud() -> void:
	_hud_root = Control.new()
	_hud_root.name = "GSSHUDRoot"
	_hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hud_root)

	var bar_panel := PanelContainer.new()
	bar_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	bar_panel.offset_left = -335
	bar_panel.offset_top = 10
	bar_panel.offset_right = -10
	bar_panel.offset_bottom = 44
	_hud_root.add_child(bar_panel)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	bar_panel.add_child(hbox)

	var snap_btn := Button.new()
	snap_btn.text = "Snap (F9)"
	snap_btn.pressed.connect(func(): capture_snapshot())
	hbox.add_child(snap_btn)

	_live_btn = Button.new()
	_live_btn.text = "Live (F10)"
	_live_btn.pressed.connect(func(): toggle_live_recording())
	hbox.add_child(_live_btn)

	_open_btn = Button.new()
	_open_btn.text = "Open (F11)"
	_open_btn.disabled = true
	_open_btn.pressed.connect(func(): open_last_capture())
	hbox.add_child(_open_btn)

	_status_label = Label.new()
	_status_label.text = ""
	_status_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_status_label.offset_left = -335
	_status_label.offset_top = 48
	_status_label.offset_right = -10
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_status_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35, 1.0))
	_hud_root.add_child(_status_label)

	_toast_label = Label.new()
	_toast_label.visible = false
	_toast_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_toast_label.offset_left = -520
	_toast_label.offset_top = -36
	_toast_label.offset_right = -12
	_toast_label.offset_bottom = -10
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hud_root.add_child(_toast_label)

	_toast_timer = Timer.new()
	_toast_timer.one_shot = true
	_toast_timer.wait_time = 4.0
	_toast_timer.timeout.connect(func():
		if _toast_label:
			_toast_label.visible = false
	)
	add_child(_toast_timer)


func _update_live_hud_state() -> void:
	if _live_btn:
		_live_btn.text = "Stop (F10)" if is_recording_live else "Live (F10)"
	if _status_label and not is_recording_live:
		_status_label.text = ""


func _update_open_button() -> void:
	if _open_btn:
		_open_btn.disabled = (last_html_path == "")


func _show_toast(msg: String) -> void:
	if _toast_label:
		_toast_label.text = msg
		_toast_label.visible = true
		if _toast_timer:
			_toast_timer.start()
