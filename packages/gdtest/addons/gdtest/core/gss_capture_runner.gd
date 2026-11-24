# gss_capture_runner.gd
# Zero-code Godot scene runner invoked by tools/gss_cli.py to capture a Static GSS
# Screenshot or a Live GSS Delta Recording of any scene without writing a test suite.
extends Node

const GSSLib = preload("res://addons/gdtest/core/gss.gd")

func _ready() -> void:
	call_deferred("_run_capture")


func _parse_user_args() -> Dictionary:
	var cfg := {
		"mode": "snap",
		"scene": "",
		"name": "",
		"out": GSSLib.DEFAULT_OUTPUT_DIR,
		"wait": 5,
		"frames": 60,
		"step_mode": "physics"
	}
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--gss-mode="):
			cfg["mode"] = arg.substr("--gss-mode=".length()).strip_edges().to_lower()
		elif arg.begins_with("--gss-scene="):
			cfg["scene"] = arg.substr("--gss-scene=".length()).strip_edges()
		elif arg.begins_with("--gss-name="):
			cfg["name"] = arg.substr("--gss-name=".length()).strip_edges()
		elif arg.begins_with("--gss-out="):
			cfg["out"] = arg.substr("--gss-out=".length()).strip_edges()
		elif arg.begins_with("--gss-wait="):
			cfg["wait"] = maxi(1, int(arg.substr("--gss-wait=".length())))
		elif arg.begins_with("--gss-frames="):
			cfg["frames"] = maxi(1, int(arg.substr("--gss-frames=".length())))
		elif arg.begins_with("--gss-step-mode="):
			cfg["step_mode"] = arg.substr("--gss-step-mode=".length()).strip_edges().to_lower()
	return cfg


func _emit_and_quit(payload: Dictionary, exit_code: int) -> void:
	print("[GSS_CLI_RESULT] " + JSON.stringify(payload))
	get_tree().quit(exit_code)


func _run_capture() -> void:
	var cfg := _parse_user_args()
	var scene_path: String = str(cfg["scene"])
	if scene_path == "":
		scene_path = str(ProjectSettings.get_setting("application/run/main_scene", ""))

	if scene_path == "" or not ResourceLoader.exists(scene_path):
		_emit_and_quit({
			"success": false,
			"error": "Target scene not found: " + scene_path
		}, 1)
		return

	var packed: Resource = load(scene_path)
	if not (packed is PackedScene):
		_emit_and_quit({
			"success": false,
			"error": "Resource is not a PackedScene: " + scene_path
		}, 1)
		return

	var scene_inst: Node = (packed as PackedScene).instantiate()
	add_child(scene_inst)

	# Wait settle frames so lighting, shaders, camera, and initial physics initialize
	var wait_frames: int = int(cfg["wait"])
	for _i in range(wait_frames):
		await get_tree().process_frame

	var cap_name: String = str(cfg["name"])
	if cap_name == "":
		cap_name = scene_path.get_file().get_basename() + ("_live" if cfg["mode"] == "live" else "_snap")

	var out_dir: String = str(cfg["out"])
	var mode: String = str(cfg["mode"])

	if mode == "live":
		var res: Dictionary = await GSSLib.record_frames(
			scene_inst,
			int(cfg["frames"]),
			cap_name,
			{
				"output_dir": out_dir,
				"step_mode": str(cfg["step_mode"]),
				"write_html": true,
				"write_json": true,
				"write_png": true
			}
		)
		var ok: bool = bool(res.get("success", false))
		var summary: Dictionary = res.get("analysis", {}).get("summary", {})
		_emit_and_quit({
			"success": ok,
			"mode": "live",
			"scene": scene_path,
			"name": cap_name,
			"html": str(res.get("global_html_path", "")),
			"json": str(res.get("global_json_path", "")),
			"total_frames": int(summary.get("total_frames", res.get("total_frames", 0))),
			"active_nodes": int(summary.get("active_node_count", 0)),
			"bounces_detected": int(summary.get("bounces_detected", 0)),
			"shaded_nodes": int(summary.get("shaded_node_count", 0))
		}, 0 if ok else 1)
	else:
		var res: Dictionary = GSSLib.capture(scene_inst, cap_name, {
			"output_dir": out_dir,
			"write_html": true,
			"write_json": true,
			"write_png": true
		})
		var ok: bool = bool(res.get("success", false))
		var snap: Dictionary = res.get("data", {})
		var meta: Dictionary = snap.get("metadata", {})
		var sh_sum: Dictionary = meta.get("shaders_summary", {})
		_emit_and_quit({
			"success": ok,
			"mode": "snap",
			"scene": scene_path,
			"name": cap_name,
			"html": str(res.get("global_html_path", "")),
			"json": str(res.get("global_json_path", "")),
			"png": str(res.get("global_png_path", "")),
			"total_nodes": int(meta.get("total_nodes", 0)),
			"visible_nodes": int(meta.get("visible_nodes", 0)),
			"shaded_nodes": int(sh_sum.get("shaded_nodes", 0)),
			"unique_shaders": int(sh_sum.get("unique_shader_count", 0)),
			"is_synthetic_preview": bool(meta.get("is_synthetic_preview", false))
		}, 0 if ok else 1)
