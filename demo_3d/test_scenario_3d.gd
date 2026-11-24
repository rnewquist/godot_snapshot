# test_scenario_3d.gd
extends Node3D

const TestRig = preload("res://test_rig.gd")

@onready var main_scene: Main3D = $Main3D

var rig: TestRig

func _ready() -> void:
	rig = TestRig.new()
	rig.test_name = "3D_Interactive_Raycast_And_Drag_Audit"
	add_child(rig)
	
	run_test_flow()

func run_test_flow() -> void:
	rig.log_step("Step 1: Validating initial 3D world state")
	await rig.wait_frames(5)
	await rig.wait_physics_frames(3)
	
	var initial_expected_pos = Vector3(-2.5, 0.5, 0.0)
	rig.assert_equal(main_scene.score, 0, "Initial 3D score must be 0")
	rig.assert_vector3_approx(main_scene.target_sphere.global_position, initial_expected_pos, 0.1, "3D Sphere must start at (-2.5, 0.5, 0.0)")
	rig.assert_true(not main_scene.goal_pedestal.is_active, "Goal pedestal must be inactive initially")
	
	var artifact_dir = ProjectSettings.globalize_path("res://artifacts/")
	await rig.take_screenshot(artifact_dir + "3d_01_initial_state.png")
	
	rig.log_step("Step 2: Unprojecting 3D world positions to 2D screen coordinates")
	var cam = main_scene.camera
	var sphere_screen_pos = cam.unproject_position(main_scene.target_sphere.global_position)
	var pedestal_screen_pos = cam.unproject_position(main_scene.goal_pedestal.global_position)
	
	rig.log_step("  3D Sphere Screen Pos: %s | Pedestal Screen Pos: %s" % [str(sphere_screen_pos), str(pedestal_screen_pos)])
	rig.assert_true(sphere_screen_pos.x > 0 and sphere_screen_pos.y > 0, "Sphere screen pos must be within valid viewport")
	rig.assert_true(pedestal_screen_pos.x > sphere_screen_pos.x, "Pedestal screen pos must be to the right of the sphere")
	
	rig.log_step("Step 3: Simulating 3D Raycast Mouse Pick & Drag with Live GSS recording")
	var live_rec = rig.start_live_gss("3d_raycast_drag_live", main_scene)
	InputSimulator.mouse_down(sphere_screen_pos)
	await rig.wait_physics_frames(2)
	await rig.wait_frames(2)
	rig.assert_true(main_scene.target_sphere.is_dragging, "TargetSphere3D is_dragging must be true on raycast pick")
	
	# Intermediate dragging
	for i in range(1, 6):
		var t = float(i) / 10.0
		var current = sphere_screen_pos.lerp(pedestal_screen_pos, t)
		InputSimulator.mouse_move(current, current - sphere_screen_pos)
		await rig.wait_frames(2)
		await rig.wait_physics_frames(1)
		
	# Screenshot 2: In-flight
	await rig.take_screenshot(artifact_dir + "3d_02_dragging_state.png")
	
	# Complete dragging to pedestal
	for i in range(6, 11):
		var t = float(i) / 10.0
		var current = sphere_screen_pos.lerp(pedestal_screen_pos, t)
		InputSimulator.mouse_move(current, current - sphere_screen_pos)
		await rig.wait_frames(2)
		await rig.wait_physics_frames(1)
		
	InputSimulator.mouse_up(pedestal_screen_pos)
	
	rig.log_step("Step 4: Validating 3D Goal & Collision Invariants")
	await rig.wait_physics_frames(5)
	await rig.wait_frames(5)
	rig.stop_live_gss(live_rec)
	
	rig.assert_true(not main_scene.target_sphere.is_dragging, "TargetSphere3D is_dragging must be false after drop")
	rig.assert_vector3_approx(main_scene.target_sphere.global_position, Vector3(2.5, 0.5, 0.0), 0.5, "Sphere must be placed on pedestal platform")
	rig.assert_true(main_scene.goal_pedestal.is_active, "Pedestal Area3D must detect TargetSphere3D")
	rig.assert_equal(main_scene.score, 100, "3D Score must increment to 100")
	
	# Screenshot 3: Final
	await rig.take_screenshot(artifact_dir + "3d_03_goal_reached.png")
	
	rig.log_step("Step 5: Emitting 3D Audit JSON Report")
	await rig.finish(artifact_dir + "test_report_3d.json")
