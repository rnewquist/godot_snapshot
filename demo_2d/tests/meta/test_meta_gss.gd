# test_meta_gss.gd
# Unit & Integration Test Suite for GSS (Godot Scene Snapshot).
# Validates standalone SceneTree inspection, script variable extraction, 2D/3D/UI transforms,
# physics state capture, 2D & 3D screen-space bounding box unprojection, and PNG + .gss.json + .gss.html generation.
extends "res://addons/gdtest/core/test_suite.gd"

const GSSClass = preload("res://addons/gdtest/core/gss.gd")

class MockHeroActor extends CharacterBody2D:
	var hero_name: String = "Paladin"
	var health: int = 85
	var max_health: int = 100
	var mana_regen: float = 2.5
	var inventory: Array = ["excalibur", "aegis_shield"]
	var stats: Dictionary = {"str": 18, "dex": 12}
	var _private_cache: int = 999

	signal health_changed(new_hp: int)

	func _on_dummy_health(new_hp: int) -> void:
		health = new_hp

class MockBouncingBall extends RigidBody2D:
	var bounce_count: int = 0
	var ball_state: String = "falling"

class MockBouncingSphere3D extends RigidBody3D:
	var bounce_count: int = 0
	var ball_state: String = "falling"
	var energy_pct: float = 100.0

func _init() -> void:
	suite_name = "Meta_GSS_Suite"
	test_type = "unit"

# ==============================================================================
# 1. STANDALONE NODE INSPECTION: SCRIPT VARIABLES, SIGNALS, TRANSFORMS & VISIBILITY
# ==============================================================================

func test_gss_standalone_node_script_vars_and_signals() -> void:
	var hero := MockHeroActor.new()
	hero.name = "HeroPaladin"
	hero.position = Vector2(320.5, 240.25)
	hero.rotation_degrees = 15.0
	hero.scale = Vector2(1.5, 1.5)
	hero.velocity = Vector2(120.0, -45.0)
	hero.modulate = Color(1.0, 0.8, 0.6, 0.9)
	hero.add_to_group("players")
	hero.add_to_group("party_leaders")
	hero.health_changed.connect(hero._on_dummy_health)
	autofree(hero)
	
	var info: Dictionary = GSSClass.inspect_node(hero, false)
	
	assert_eq(info["name"], "HeroPaladin")
	assert_eq(info["class"], "CharacterBody2D")
	assert_eq(info["category"], "physics")
	assert_true(info["visible"], "Hero node should be visible")
	assert_array_contains(info["groups"], "players")
	assert_array_contains(info["groups"], "party_leaders")
	
	# Script variables
	var svars: Dictionary = info["script_variables"]
	assert_eq(svars["hero_name"], "Paladin")
	assert_eq(svars["health"], 85)
	assert_eq(svars["max_health"], 100)
	assert_approx(svars["mana_regen"], 2.5, 0.0001)
	assert_eq(svars["inventory"], ["excalibur", "aegis_shield"])
	assert_eq(svars["stats"]["str"], 18)
	
	# Transforms
	var tr: Dictionary = info["transforms"]
	assert_approx(tr["position"]["x"], 320.5, 0.001)
	assert_approx(tr["position"]["y"], 240.25, 0.001)
	assert_approx(tr["rotation_deg"], 15.0, 0.01)
	assert_approx(tr["scale"]["x"], 1.5, 0.001)
	
	# Visibility & Modulate
	var vis: Dictionary = info["visibility"]
	assert_true(vis["visible"])
	assert_approx(vis["modulate"]["r"], 1.0, 0.001)
	assert_approx(vis["modulate"]["g"], 0.8, 0.001)
	assert_string_begins_with(vis["modulate"]["hex"], "#")
	
	# Physics
	var phys: Dictionary = info["physics"]
	assert_eq(phys["body_type"], "CharacterBody2D")
	assert_approx(phys["velocity"]["x"], 120.0, 0.001)
	assert_approx(phys["velocity"]["y"], -45.0, 0.001)
	assert_gt(phys["speed"], 125.0)
	
	# Connected Signals
	var sigs: Array = info["signals"]
	assert_not_empty(sigs, "Connected signal must be captured")
	var found_sig: bool = false
	for s in sigs:
		if s.get("signal") == "health_changed" and s.get("method") == "_on_dummy_health":
			found_sig = true
	assert_true(found_sig, "health_changed -> _on_dummy_health connection must be recorded")

# ==============================================================================
# 2. 2D, UI CONTROLS, AND PHYSICS HIERARCHY & SCREEN-SPACE RECTANGLES
# ==============================================================================

func test_gss_tree_2d_ui_and_physics_hierarchy() -> void:
	var root := Node2D.new()
	root.name = "BattleScene2D"
	autofree(root)
	
	var hud := Control.new()
	hud.name = "HUDRoot"
	hud.position = Vector2(20, 16)
	hud.size = Vector2(400, 80)
	root.add_child(hud)
	
	var hp_bar := ProgressBar.new()
	hp_bar.name = "HealthBar"
	hp_bar.position = Vector2(10, 12)
	hp_bar.size = Vector2(200, 32)
	hp_bar.min_value = 0.0
	hp_bar.max_value = 100.0
	hp_bar.value = 75.0
	hud.add_child(hp_bar)
	
	var btn := Button.new()
	btn.name = "AttackButton"
	btn.text = "Strike"
	btn.position = Vector2(230, 10)
	btn.size = Vector2(120, 32)
	hud.add_child(btn)
	
	var crate := RigidBody2D.new()
	crate.name = "PhysicsCrate"
	crate.position = Vector2(500, 360)
	crate.mass = 12.5
	crate.linear_velocity = Vector2(30.0, 40.0)
	crate.collision_layer = 2
	crate.collision_mask = 5
	root.add_child(crate)
	
	var col_shape := CollisionShape2D.new()
	col_shape.name = "CrateCollider"
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = Vector2(64, 64)
	col_shape.shape = rect_shape
	crate.add_child(col_shape)
	
	var tree_snap: Dictionary = GSSClass.inspect_tree(root)
	var meta: Dictionary = tree_snap["metadata"]
	var flat: Array = tree_snap["flat_nodes"]
	
	assert_eq(meta["format"], "godot_scene_snapshot")
	assert_eq(meta["short_name"], "GSS")
	assert_eq(meta["total_nodes"], 6, "All 6 nodes in hierarchy must be indexed")
	assert_eq(flat.size(), 6)
	
	# Locate ProgressBar & verify UI content + screen_rect
	var found_bar: Dictionary = {}
	var found_crate: Dictionary = {}
	var found_collider: Dictionary = {}
	for n in flat:
		match n["name"]:
			"HealthBar": found_bar = n
			"PhysicsCrate": found_crate = n
			"CrateCollider": found_collider = n
			
	require_not_empty(found_bar, "HealthBar must be in flat_nodes")
	assert_eq(found_bar["category"], "control")
	assert_approx(found_bar["ui_and_content"]["value"], 75.0, 0.01)
	assert_approx(found_bar["ui_and_content"]["ratio"], 0.75, 0.01)
	assert_approx(found_bar["screen_rect"]["x"], 30.0, 0.1, "Cumulative Control X = 20 + 10")
	assert_approx(found_bar["screen_rect"]["y"], 28.0, 0.1, "Cumulative Control Y = 16 + 12")
	assert_approx(found_bar["screen_rect"]["width"], 200.0, 0.1)
	assert_approx(found_bar["screen_rect"]["height"], 32.0, 0.1)
	
	# Verify RigidBody2D physics state
	require_not_empty(found_crate, "PhysicsCrate must be in flat_nodes")
	assert_eq(found_crate["category"], "physics")
	assert_approx(found_crate["physics"]["mass"], 12.5, 0.01)
	assert_approx(found_crate["physics"]["linear_speed"], 50.0, 0.01, "Speed of (30, 40) is 50")
	assert_eq(found_crate["physics"]["collision_layer"], 2)
	assert_eq(found_crate["physics"]["collision_mask"], 5)
	
	# Verify CollisionShape2D shape bounds
	require_not_empty(found_collider, "CrateCollider must be in flat_nodes")
	assert_eq(found_collider["physics"]["shape_class"], "RectangleShape2D")
	assert_approx(found_collider["screen_rect"]["width"], 64.0, 0.1)
	assert_approx(found_collider["screen_rect"]["height"], 64.0, 0.1)

# ==============================================================================
# 3. 3D SCENE & CAMERA3D SCREEN-SPACE BOUNDING BOX UNPROJECTION
# ==============================================================================

func test_gss_3d_scene_camera_unprojection_and_physics3d() -> void:
	var root3d := Node3D.new()
	root3d.name = "Arena3D"
	autofree(root3d)
	
	var cam := Camera3D.new()
	cam.name = "MainCamera3D"
	cam.position = Vector3(0.0, 0.0, 10.0)
	cam.fov = 60.0
	root3d.add_child(cam)
	
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "CenterPillar"
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(2.0, 4.0, 2.0)
	mesh_inst.mesh = box_mesh
	mesh_inst.position = Vector3(0.0, 0.0, 0.0)
	root3d.add_child(mesh_inst)
	
	var body3d := RigidBody3D.new()
	body3d.name = "Boulder3D"
	body3d.position = Vector3(2.0, 1.0, 0.0)
	body3d.mass = 50.0
	body3d.linear_velocity = Vector3(0.0, -9.8, 0.0)
	root3d.add_child(body3d)
	
	var snap3d: Dictionary = GSSClass.inspect_tree(root3d)
	assert_eq(snap3d["metadata"]["camera_3d"]["name"], "MainCamera3D")
	
	var pillar_node: Dictionary = {}
	var boulder_node: Dictionary = {}
	for n in snap3d["flat_nodes"]:
		if n["name"] == "CenterPillar":
			pillar_node = n
		elif n["name"] == "Boulder3D":
			boulder_node = n
			
	require_not_empty(pillar_node)
	assert_eq(pillar_node["ui_and_content"]["mesh_class"], "BoxMesh")
	assert_true(pillar_node["screen_rect"]["has_bounds"], "3D MeshInstance must project to 2D screen_rect")
	assert_true(pillar_node["screen_rect"]["on_screen"], "Centered 3D pillar in front of camera must be on screen")
	assert_gt(pillar_node["screen_rect"]["width"], 50.0, "Projected 3D box width must be > 50px")
	assert_gt(pillar_node["screen_rect"]["height"], 100.0, "Projected 3D box height must be > 100px")
	
	require_not_empty(boulder_node)
	assert_eq(boulder_node["physics"]["body_type"], "RigidBody3D")
	assert_approx(boulder_node["physics"]["mass"], 50.0, 0.01)
	assert_approx(boulder_node["physics"]["linear_velocity"]["y"], -9.8, 0.01)

# ==============================================================================
# 4. END-TO-END DISK BUNDLE GENERATION (.PNG + .GSS.JSON + .GSS.HTML)
# ==============================================================================

func test_gss_capture_writes_png_json_and_interactive_html() -> void:
	var scene_root := Control.new()
	scene_root.name = "InspectorDemoScene"
	scene_root.size = Vector2(1280, 720)
	autofree(scene_root)
	
	var panel := Panel.new()
	panel.name = "MainPanel"
	panel.position = Vector2(100, 80)
	panel.size = Vector2(600, 400)
	scene_root.add_child(panel)
	
	var title_lbl := Label.new()
	title_lbl.name = "TitleLabel"
	title_lbl.text = "Inventory Status"
	title_lbl.position = Vector2(24, 20)
	title_lbl.size = Vector2(240, 32)
	panel.add_child(title_lbl)
	
	var out_dir := "res://artifacts/gss_test_output"
	var result: Dictionary = GSSClass.capture(scene_root, "inventory_snapshot", {
		"output_dir": out_dir
	})
	
	require_true(result.get("success", false), "GSS.capture must succeed")
	assert_eq(result["total_nodes"], 3)
	assert_string_ends_with(result["json_path"], ".gss.json")
	assert_string_ends_with(result["html_path"], ".gss.html")
	
	var png_global: String = result["global_png_path"]
	var json_global: String = result["global_json_path"]
	var html_global: String = result["global_html_path"]
	
	assert_true(FileAccess.file_exists(png_global), "PNG screenshot file must be created")
	assert_true(FileAccess.file_exists(json_global), "AI JSON file (.gss.json) must be created")
	assert_true(FileAccess.file_exists(html_global), "Human HTML file (.gss.html) must be created")
	
	# 1. Verify PNG image dimensions
	var loaded_img := Image.load_from_file(png_global)
	require_not_null(loaded_img, "Saved PNG must load as a valid Image")
	assert_gt(loaded_img.get_width(), 0)
	assert_gt(loaded_img.get_height(), 0)
	
	# 2. Verify JSON schema & AI data completeness
	var json_str: String = FileAccess.get_file_as_string(json_global)
	var parsed_json: Variant = JSON.parse_string(json_str)
	require_true(parsed_json is Dictionary, "Saved .gss.json must parse into a Dictionary")
	assert_eq(parsed_json["metadata"]["snapshot_name"], "inventory_snapshot")
	assert_eq(parsed_json["metadata"]["short_name"], "GSS")
	assert_eq(parsed_json["flat_nodes"].size(), 3)
	assert_eq(parsed_json["hierarchy"]["name"], "InspectorDemoScene")
	assert_eq(parsed_json["hierarchy"]["children"][0]["name"], "MainPanel")
	
	# 3. Verify Self-Contained Interactive HTML Inspector content
	var html_str: String = FileAccess.get_file_as_string(html_global)
	assert_string_contains(html_str, "<!DOCTYPE html>")
	assert_string_contains(html_str, "GSS — Godot Scene Snapshot")
	assert_string_contains(html_str, "data:image/png;base64,", "HTML must embed Base64 screenshot")
	assert_string_contains(html_str, "id=\"gss-data-payload\"", "HTML must embed JSON snapshot payload")
	assert_string_contains(html_str, "class=\"gss-prop-table\"", "HTML must include semantic properties table")
	assert_string_contains(html_str, "content-visibility: auto;", "HTML must include CSS layout containment")
	
	# Clean up test artifacts
	DirAccess.remove_absolute(png_global)
	DirAccess.remove_absolute(json_global)
	DirAccess.remove_absolute(html_global)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(out_dir))

# ==============================================================================
# 5. HOTKEY ATTACHMENT TRIGGER
# ==============================================================================

func test_gss_hotkey_listener() -> void:
	var host := Node2D.new()
	host.name = "HotkeyHostScene"
	autofree(host)
	
	var out_dir := "res://artifacts/gss_hotkey_test"
	var listener: Node = GSSClass.attach_hotkey(host, KEY_F12, out_dir)
	require_not_null(listener, "attach_hotkey must return a valid listener node")
	assert_eq(listener.name, "GSSHotkeyListener")
	
	var cap_res: Dictionary = listener.trigger_capture("manual_f12_trigger")
	assert_true(cap_res.get("success", false), "Hotkey listener trigger_capture must succeed")
	assert_true(FileAccess.file_exists(cap_res["global_json_path"]))
	
	# Clean up
	DirAccess.remove_absolute(cap_res["global_png_path"])
	DirAccess.remove_absolute(cap_res["global_json_path"])
	DirAccess.remove_absolute(cap_res["global_html_path"])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(out_dir))

# ==============================================================================
# 6. LIVE GSS: BOUNCING BALL DELTA RECORDING, TRAJECTORY & BOUNCE ANALYSIS
# ==============================================================================

func test_live_gss_ball_bounce_delta_recording_and_analysis() -> void:
	var scene := Node2D.new()
	scene.name = "BounceArena"
	autofree(scene)
	
	# Static ground that never changes after frame 0
	var ground := StaticBody2D.new()
	ground.name = "GroundFloor"
	ground.position = Vector2(640.0, 500.0)
	scene.add_child(ground)
	
	# HUD label that updates when the ball bounces
	var status_label := Label.new()
	status_label.name = "BounceCounterLabel"
	status_label.text = "Bounces: 0"
	status_label.position = Vector2(24.0, 20.0)
	status_label.size = Vector2(180.0, 28.0)
	scene.add_child(status_label)
	
	# Bouncing ball starting at y=100, falling toward GroundFloor at y=500
	var ball := MockBouncingBall.new()
	ball.name = "BouncingBall"
	ball.position = Vector2(640.0, 100.0)
	ball.linear_velocity = Vector2(20.0, 120.0)
	scene.add_child(ball)
	
	var out_dir := "res://artifacts/gss_live_bounce_test"
	var rec = GSSClass.start_recording(scene, "ball_bounce_session", {
		"output_dir": out_dir,
		"auto_step": false
	})
	
	# Simulate 8 frames of the ball falling, bouncing off the ground at Frame 4, and rising
	# Frame 1..3: falling (+Y velocity)
	var sim_steps: Array[Dictionary] = [
		{"pos": Vector2(645.0, 220.0), "vel": Vector2(20.0, 150.0), "bounces": 0, "state": "falling"},
		{"pos": Vector2(650.0, 360.0), "vel": Vector2(20.0, 180.0), "bounces": 0, "state": "falling"},
		{"pos": Vector2(655.0, 500.0), "vel": Vector2(20.0, 210.0), "bounces": 0, "state": "impact"},
		# Frame 4: Rebound upward (-Y velocity -> bounce!)
		{"pos": Vector2(660.0, 410.0), "vel": Vector2(20.0, -160.0), "bounces": 1, "state": "rebounding"},
		{"pos": Vector2(665.0, 310.0), "vel": Vector2(20.0, -90.0), "bounces": 1, "state": "rising"},
		# Frame 6: Apex and falling again (+Y velocity)
		{"pos": Vector2(670.0, 380.0), "vel": Vector2(20.0, 110.0), "bounces": 1, "state": "falling"},
		{"pos": Vector2(675.0, 500.0), "vel": Vector2(20.0, 190.0), "bounces": 1, "state": "impact"},
		# Frame 8: Second rebound upward (-Y velocity -> 2nd bounce!)
		{"pos": Vector2(680.0, 420.0), "vel": Vector2(20.0, -140.0), "bounces": 2, "state": "rebounding"}
	]
	
	for step in sim_steps:
		ball.position = step["pos"]
		ball.linear_velocity = step["vel"]
		ball.bounce_count = int(step["bounces"])
		ball.ball_state = str(step["state"])
		status_label.text = "Bounces: %d" % ball.bounce_count
		rec.record_step(0.05)
		
	var res: Dictionary = rec.stop()
	require_true(res.get("success", false), "Live GSS recording must finalize successfully")
	assert_eq(res["total_frames"], 9, "1 initial keyframe + 8 delta frames = 9 total frames")
	assert_eq(res["delta_frames"], 8)
	
	var rec_data: Dictionary = res["data"]
	var delta_frames: Array = rec_data["frames"]
	assert_eq(delta_frames.size(), 8)
	
	# Verify delta compression: GroundFloor never moved or mutated, so it must NOT appear in any frame's changed_nodes
	for df in delta_frames:
		var ch_nodes: Dictionary = df["changed_nodes"]
		assert_false(ch_nodes.has("/BounceArena/GroundFloor"), "Static GroundFloor must be omitted from per-frame deltas")
		assert_true(ch_nodes.has("/BounceArena/BouncingBall"), "Moving BouncingBall must be present in per-frame deltas")
		# On Frame 1, BouncingBall's mass and collision_layer didn't change, so they shouldn't be in the physics delta
		var ball_phys_delta: Dictionary = ch_nodes["/BounceArena/BouncingBall"].get("physics", {})
		assert_false(ball_phys_delta.has("mass"), "Unchanged physics property 'mass' must not be duplicated in delta")
		assert_true(ball_phys_delta.has("linear_velocity"), "Changed physics property 'linear_velocity' must be in delta")
		
	# Verify Automated Interaction Analysis (Trajectories, Bounces, Events)
	var analysis: Dictionary = res["analysis"]
	var summary: Dictionary = analysis["summary"]
	assert_eq(summary["total_frames"], 9)
	assert_eq(summary["bounces_detected"], 2, "Analysis must detect both ball bounces (Frame 4 and Frame 8)")
	assert_gte(summary["static_node_count"], 2, "BounceArena and GroundFloor remained static")
	assert_eq(summary["active_node_count"], 2, "BouncingBall and BounceCounterLabel were active")
	
	var ball_traj: Dictionary = analysis["node_trajectories"].get("/BounceArena/BouncingBall", {})
	require_not_empty(ball_traj, "Trajectory for BouncingBall must be computed")
	assert_eq(ball_traj["frames_changed"], 8)
	assert_eq(ball_traj["bounce_frames"], [4, 8], "Exact bounce frames [4, 8] must be identified")
	assert_gt(ball_traj["total_distance"], 800.0, "Cumulative travel distance across two bounces must exceed 800px")
	assert_approx(ball_traj["max_position"]["y"], 500.0, 0.1, "Lowest Y point (ground impact) must be 500.0")
	assert_eq(ball_traj["mutated_properties"]["script_variables.bounce_count"]["initial"], 0)
	assert_eq(ball_traj["mutated_properties"]["script_variables.bounce_count"]["final"], 2)
	
	# Verify live files (.png, .gss.live.json, .gss.live.html)
	assert_true(FileAccess.file_exists(res["global_png_path"]))
	assert_true(FileAccess.file_exists(res["global_json_path"]))
	assert_true(FileAccess.file_exists(res["global_html_path"]))
	
	var live_html: String = FileAccess.get_file_as_string(res["global_html_path"])
	assert_string_contains(live_html, "id=\"frame-scrubber\"", "Live HTML must include interactive timeline scrubber")
	assert_string_contains(live_html, "id=\"trail-svg\"", "Live HTML must include SVG motion trail overlay")
	assert_string_contains(live_html, "nodes: clone(Array.from(curMap.values()))", "Frame 0 nodes must be deep-cloned so delta reconstruction never mutates Frame 0")
	assert_string_contains(live_html, "const trajList = Object.values(trajectories);", "Live HTML must default selection to active trajectory node")
	assert_string_contains(live_html, "function startPlayTimer()", "Live HTML must include interactive playback timer controls")
	
	# Clean up
	DirAccess.remove_absolute(res["global_png_path"])
	DirAccess.remove_absolute(res["global_json_path"])
	DirAccess.remove_absolute(res["global_html_path"])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(out_dir))

# ==============================================================================
# 7. LIVE GSS: FRAME RECONSTRUCTION, TIMELINE QUERY & SCENE STATE RECREATION
# ==============================================================================

func test_live_gss_reconstruct_and_apply_frame_to_scene() -> void:
	var scene := Node2D.new()
	scene.name = "ReplayStage"
	autofree(scene)
	
	var ball := MockBouncingBall.new()
	ball.name = "Ball"
	ball.position = Vector2(100.0, 100.0)
	ball.linear_velocity = Vector2(10.0, 80.0)
	ball.bounce_count = 0
	scene.add_child(ball)
	
	var label := Label.new()
	label.name = "InfoLabel"
	label.text = "Start"
	scene.add_child(label)
	
	var rec = GSSClass.start_recording(scene, "replay_verification", {
		"write_png": false,
		"write_json": false,
		"write_html": false,
		"auto_step": false
	})
	
	# Frame 1: Move ball & spawn a dynamic spark node
	ball.position = Vector2(150.0, 300.0)
	ball.linear_velocity = Vector2(10.0, 160.0)
	label.text = "Falling"
	var spark := Node2D.new()
	spark.name = "ImpactSpark"
	spark.position = Vector2(150.0, 300.0)
	scene.add_child(spark)
	rec.record_step(0.05)
	
	# Frame 2: Bounce upward & remove the spark node
	ball.position = Vector2(200.0, 180.0)
	ball.linear_velocity = Vector2(10.0, -140.0)
	ball.bounce_count = 1
	ball.ball_state = "bounced"
	label.text = "Bounced!"
	scene.remove_child(spark)
	spark.free()
	rec.record_step(0.05)
	
	var res: Dictionary = rec.stop()
	
	# 1. Reconstruct Frame 0, Frame 1 (with ImpactSpark), and Frame 2 (after spark removed)
	var snap0: Dictionary = GSSClass.reconstruct_frame(res, 0)
	var snap1: Dictionary = GSSClass.reconstruct_frame(res, 1)
	var snap2: Dictionary = GSSClass.reconstruct_frame(res, 2)
	
	assert_eq(snap0["metadata"]["total_nodes"], 3, "Frame 0 has ReplayStage, Ball, InfoLabel")
	assert_eq(snap1["metadata"]["total_nodes"], 4, "Frame 1 has dynamically added ImpactSpark")
	assert_eq(snap2["metadata"]["total_nodes"], 3, "Frame 2 has ImpactSpark removed")
	
	# 2. Query node timeline across frames
	var pos_timeline: Array = GSSClass.get_node_timeline(res, "Ball", "transforms.position")
	assert_eq(pos_timeline.size(), 3)
	assert_approx(pos_timeline[0]["value"]["y"], 100.0, 0.01)
	assert_approx(pos_timeline[1]["value"]["y"], 300.0, 0.01)
	assert_approx(pos_timeline[2]["value"]["y"], 180.0, 0.01)
	
	# 3. Corrupt live scene values, then recreate Frame 1 and Frame 0 directly onto the live scene!
	ball.position = Vector2(9999.0, 9999.0)
	ball.linear_velocity = Vector2.ZERO
	ball.bounce_count = 42
	label.text = "Corrupted"
	
	var apply1: Dictionary = GSSClass.apply_frame_to_scene(scene, res, 1)
	assert_true(apply1["success"])
	assert_approx(ball.position.x, 150.0, 0.01, "Ball X restored to Frame 1")
	assert_approx(ball.position.y, 300.0, 0.01, "Ball Y restored to Frame 1")
	assert_approx(ball.linear_velocity.y, 160.0, 0.01, "Ball velocity restored to Frame 1")
	assert_eq(ball.bounce_count, 0, "Ball script variable bounce_count restored to Frame 1")
	assert_eq(label.text, "Falling", "Label text restored to Frame 1")
	
	var apply2: Dictionary = GSSClass.apply_frame_to_scene(scene, res, 2)
	assert_true(apply2["success"])
	assert_approx(ball.position.x, 200.0, 0.01, "Ball X restored to Frame 2")
	assert_approx(ball.position.y, 180.0, 0.01, "Ball Y restored to Frame 2")
	assert_approx(ball.linear_velocity.y, -140.0, 0.01, "Ball velocity restored to Frame 2")
	assert_eq(ball.bounce_count, 1, "Ball bounce_count restored to Frame 2")
	assert_eq(ball.ball_state, "bounced", "Ball ball_state restored to Frame 2")
	assert_eq(label.text, "Bounced!", "Label text restored to Frame 2")

# ==============================================================================
# 8. LIVE GSS: AUTOMATIC SCENETREE FRAME HOOK RECORDING (record_interaction)
# ==============================================================================

func test_live_gss_auto_step_in_scene_tree() -> void:
	var live_arena := Node2D.new()
	live_arena.name = "LivePhysicsArena"
	add_child(autofree(live_arena))
	
	var mover := Node2D.new()
	mover.name = "AnimatedOrb"
	mover.position = Vector2(50.0, 50.0)
	live_arena.add_child(mover)
	
	var rec_res: Dictionary = await GSSClass.record_interaction(
		live_arena,
		func():
			for i in range(4):
				mover.position += Vector2(25.0, 15.0)
				await step_physics_frames(1),
		2,
		"orb_interaction",
		{
			"write_png": false,
			"write_json": false,
			"write_html": false
		}
	)
	
	require_true(rec_res.get("success", false), "record_interaction must complete successfully")
	assert_gte(rec_res["delta_frames"], 4, "At least 4 physics frames must be auto-recorded")
	var final_snap: Dictionary = GSSClass.reconstruct_frame(rec_res, rec_res["delta_frames"])
	var orb_rec: Dictionary = {}
	for n in final_snap["flat_nodes"]:
		if n["name"] == "AnimatedOrb":
			orb_rec = n
	require_not_empty(orb_rec, "AnimatedOrb must be present in reconstructed final frame")
	assert_approx(orb_rec["transforms"]["position"]["x"], 150.0, 0.01)
	assert_approx(orb_rec["transforms"]["position"]["y"], 110.0, 0.01)

# ==============================================================================
# 9. LIVE GSS 3D: 3D RIGIDBODY SPHERE BOUNCE RECORDING, UNPROJECTION & REPLAY
# ==============================================================================

func test_live_gss_3d_object_bounce_and_trajectory() -> void:
	var arena3d := Node3D.new()
	arena3d.name = "BounceArena3D"
	autofree(arena3d)
	
	var cam3d := Camera3D.new()
	cam3d.name = "MainCamera3D"
	cam3d.position = Vector3(0.0, 3.8, 9.5)
	cam3d.rotation_degrees = Vector3(-14.0, 0.0, 0.0)
	cam3d.fov = 60.0
	cam3d.current = true
	arena3d.add_child(cam3d)
	
	var floor3d := StaticBody3D.new()
	floor3d.name = "ArenaFloor3D"
	floor3d.position = Vector3(0.0, 0.0, 0.0)
	arena3d.add_child(floor3d)
	
	var sphere3d := MockBouncingSphere3D.new()
	sphere3d.name = "PhysicsSphere3D"
	sphere3d.position = Vector3(-3.2, 4.2, 0.0)
	sphere3d.linear_velocity = Vector3(1.2, -3.5, -0.3)
	arena3d.add_child(sphere3d)
	
	var col3d := CollisionShape3D.new()
	col3d.name = "SphereCollider3D"
	var sph_shape := SphereShape3D.new()
	sph_shape.radius = 0.5
	col3d.shape = sph_shape
	sphere3d.add_child(col3d)
	
	var rec = GSSClass.start_recording(arena3d, "sphere_bounce_3d_test", {
		"write_png": false,
		"write_json": false,
		"write_html": false,
		"auto_step": false
	})
	
	var trajectory_3d: Array = [
		{"pos": Vector3(-2.4, 2.1, -0.2), "vel": Vector3(1.2, -6.4, -0.3), "b": 0, "st": "falling", "e": 100.0},
		{"pos": Vector3(-1.6, 0.5, -0.4), "vel": Vector3(1.2, -8.8, -0.3), "b": 0, "st": "impact_1", "e": 94.0},
		{"pos": Vector3(-0.8, 2.3, -0.6), "vel": Vector3(1.2, 6.8, -0.3), "b": 1, "st": "rebound_1", "e": 82.0},
		{"pos": Vector3(0.0, 3.2, -0.8), "vel": Vector3(1.2, 0.4, -0.3), "b": 1, "st": "apex_1", "e": 82.0},
		{"pos": Vector3(0.8, 0.5, -1.0), "vel": Vector3(1.2, -7.2, -0.3), "b": 1, "st": "impact_2", "e": 76.0},
		{"pos": Vector3(1.6, 1.9, -1.2), "vel": Vector3(1.2, 5.1, -0.3), "b": 2, "st": "rebound_2", "e": 64.0}
	]
	for step in trajectory_3d:
		sphere3d.position = step["pos"]
		sphere3d.linear_velocity = step["vel"]
		sphere3d.bounce_count = step["b"]
		sphere3d.ball_state = step["st"]
		sphere3d.energy_pct = step["e"]
		rec.record_step(0.05)
		
	var res: Dictionary = rec.stop()
	require_true(res.get("success", false), "3D Live GSS recording must succeed")
	assert_eq(res["total_frames"], 7, "1 initial 3D keyframe + 6 delta frames")
	
	var analysis: Dictionary = res["analysis"]
	assert_eq(analysis["summary"]["bounces_detected"], 2, "Must detect both 3D bounces (-Y falling to +Y rebound)")
	
	var sph_traj: Dictionary = analysis["node_trajectories"].get("/BounceArena3D/PhysicsSphere3D", {})
	require_not_empty(sph_traj, "PhysicsSphere3D 3D trajectory must be analyzed")
	assert_true(sph_traj["is_3d"], "Trajectory must be marked is_3d = true")
	assert_eq(sph_traj["bounce_frames"], [3, 6], "3D bounces occur at Frame 3 and Frame 6")
	assert_approx(sph_traj["min_position"]["y"], 0.5, 0.01, "Lowest 3D Y height at floor impact is 0.5m")
	
	# Reconstruct & apply Frame 3 back onto the live 3D scene
	sphere3d.position = Vector3(99.0, 99.0, 99.0)
	sphere3d.linear_velocity = Vector3.ZERO
	sphere3d.bounce_count = 0
	var apply3d: Dictionary = GSSClass.apply_frame_to_scene(arena3d, res, 3)
	assert_true(apply3d["success"], "apply_frame_to_scene must restore 3D RigidBody3D state")
	assert_approx(sphere3d.position.x, -0.8, 0.01)
	assert_approx(sphere3d.position.y, 2.3, 0.01)
	assert_approx(sphere3d.position.z, -0.6, 0.01)
	assert_approx(sphere3d.linear_velocity.y, 6.8, 0.01)
	assert_eq(sphere3d.bounce_count, 1)
	assert_eq(sphere3d.ball_state, "rebound_1")
