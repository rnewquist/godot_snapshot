# test_scenario_2d.gd
extends Node2D

const TestRig = preload("res://test_rig.gd")

@onready var main_scene: Main2D = $Main2D

var rig: TestRig

func _ready() -> void:
	rig = TestRig.new()
	rig.test_name = "2D_Interactive_Drag_And_Drop_Audit"
	add_child(rig)
	
	run_test_flow()

func run_test_flow() -> void:
	rig.log_step("Step 1: Validating initial state")
	await rig.wait_frames(5)
	await rig.wait_physics_frames(2)
	
	rig.assert_equal(main_scene.score, 0, "Initial score must be 0")
	rig.assert_vector2_approx(main_scene.ball.position, Vector2(250, 324), 1.0, "Ball must start at (250, 324)")
	rig.assert_true(not main_scene.target_zone.is_active, "Target zone must be inactive initially")
	
	# Screenshot 1: Initial
	var artifact_dir = ProjectSettings.globalize_path("res://artifacts/")
	await rig.take_screenshot(artifact_dir + "2d_01_initial_state.png")
	
	rig.log_step("Step 2: Testing Reset Button interaction")
	var btn_center = main_scene.reset_button.get_global_rect().get_center()
	await rig.click_at(btn_center)
	await rig.wait_frames(3)
	rig.assert_equal(main_scene.score, 0, "Score remains 0 after reset")
	
	rig.log_step("Step 3: Executing drag from Ball (250, 324) to Target Zone (850, 324) with Live GSS recording")
	var start_pos = Vector2(250, 324)
	var end_pos = Vector2(850, 324)
	var live_rec = rig.start_live_gss("2d_drag_interaction_live", main_scene)
	
	# Mouse down at start
	InputSimulator.mouse_down(start_pos)
	await rig.wait_physics_frames(2)
	await rig.wait_frames(2)
	rig.assert_true(main_scene.ball.is_dragging, "Ball is_dragging must be true on mouse down")
	
	# Intermediate dragging
	for i in range(1, 6):
		var t = float(i) / 10.0
		var current = start_pos.lerp(end_pos, t)
		InputSimulator.mouse_move(current, current - start_pos)
		await rig.wait_frames(2)
		await rig.wait_physics_frames(1)
	
	# Screenshot 2: Mid-drag
	await rig.take_screenshot(artifact_dir + "2d_02_dragging_state.png")
	
	# Complete drag to end
	for i in range(6, 11):
		var t = float(i) / 10.0
		var current = start_pos.lerp(end_pos, t)
		InputSimulator.mouse_move(current, current - start_pos)
		await rig.wait_frames(2)
		await rig.wait_physics_frames(1)
		
	InputSimulator.mouse_up(end_pos)
	
	rig.log_step("Step 4: Validating final gameplay & scoring invariants")
	await rig.wait_physics_frames(5)
	await rig.wait_frames(5)
	rig.stop_live_gss(live_rec)
	
	rig.assert_true(not main_scene.ball.is_dragging, "Ball is_dragging must be false after drop")
	rig.assert_vector2_approx(main_scene.ball.position, end_pos, 5.0, "Ball must be dropped at target coordinates")
	rig.assert_true(main_scene.target_zone.is_active, "Target zone must detect Ball2D entry")
	rig.assert_equal(main_scene.score, 100, "Score must increment by 100 points")
	
	# Screenshot 3: Final
	await rig.take_screenshot(artifact_dir + "2d_03_target_reached.png")
	
	rig.log_step("Step 5: Completing audit and emitting JSON report")
	await rig.finish(artifact_dir + "test_report_2d.json")
