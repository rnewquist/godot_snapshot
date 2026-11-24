# test_showcase_2d.gd
extends Node2D

const TestRig = preload("res://test_rig.gd")

@onready var main_showcase: MainShowcase2D = $MainShowcase2D
var rig: TestRig

func _ready() -> void:
	rig = TestRig.new()
	rig.test_name = "2D_Mega_Showcase_Comprehensive_Audit"
	add_child(rig)
	
	run_comprehensive_audit()

func run_comprehensive_audit() -> void:
	var artifact_dir = ProjectSettings.globalize_path("res://artifacts/")
	
	# === MODULE 1: Materials & Lights ===
	rig.log_step("Testing Module 1: 2D Materials, Blend Modes & Real-Time Shadows")
	main_showcase.switch_to_module(0)
	await rig.wait_frames(10)
	var mat_module: Module2DMaterials = main_showcase.get_node("CanvasLayer/TabContainer/1. Materials & Lights")
	rig.assert_true(mat_module != null, "Module 1 instance must exist")
	rig.assert_true(mat_module.light.shadow_enabled, "PointLight2D real-time shadows must be enabled")
	await rig.take_screenshot(artifact_dir + "2d_showcase_01_materials_lights.png")
	
	# === MODULE 2: Physics & Restitution ===
	rig.log_step("Testing Module 2: 2D Physics Restitution, Friction & Kinematics (with Live GSS)")
	main_showcase.switch_to_module(1)
	await rig.wait_frames(5)
	var phy_module: Module2DPhysics = main_showcase.get_node("CanvasLayer/TabContainer/2. Physics & Restitution")
	rig.assert_true(phy_module != null, "Module 2 instance must exist")
	var live_phy = rig.start_live_gss("2d_showcase_physics_live", phy_module)
	await rig.wait_physics_frames(30)
	rig.stop_live_gss(live_phy)
	rig.assert_true(phy_module.ice_box.global_position.x > 380.0, "IceBox (friction 0.0) must be positioned along the ramp")
	rig.assert_true(phy_module.bouncy_ball.global_position.y > 170.0, "BouncyBall must drop under gravity")
	await rig.take_screenshot(artifact_dir + "2d_showcase_02_physics_restitution.png")
	
	# === MODULE 3: Joints & Raycasts ===
	rig.log_step("Testing Module 3: 2D Physics Joints, Constraints & Raycasting (with Live GSS)")
	main_showcase.switch_to_module(2)
	await rig.wait_frames(5)
	var jnt_module: Module2DJoints = main_showcase.get_node("CanvasLayer/TabContainer/3. Joints & Raycasts")
	rig.assert_true(jnt_module != null, "Module 3 instance must exist")
	var live_jnt = rig.start_live_gss("2d_showcase_joints_live", jnt_module)
	await rig.wait_physics_frames(20)
	rig.stop_live_gss(live_jnt)
	var pin_dist = jnt_module.pin_bob.position.distance_to(jnt_module.get_node("PinSection/PinAnchor").position)
	rig.assert_approx(pin_dist, 100.0, 30.0, "PinJoint pendulum must maintain radial constraint")
	rig.assert_true(jnt_module.has_detected_obstacle, "RayCast2D scanner must detect obstacle during sweep")
	await rig.take_screenshot(artifact_dir + "2d_showcase_03_joints_raycasts.png")
	
	# === MODULE 4: Particles & FX ===
	rig.log_step("Testing Module 4: 2D Particles, Line2D, Polygons & Path2D")
	main_showcase.switch_to_module(3)
	await rig.wait_frames(10)
	var ptc_module: Module2DParticles = main_showcase.get_node("CanvasLayer/TabContainer/4. Particles & FX")
	rig.assert_true(ptc_module != null, "Module 4 instance must exist")
	rig.assert_true(ptc_module.path_follow.progress > 0.0, "PathFollow2D drone must advance along curve")
	await rig.take_screenshot(artifact_dir + "2d_showcase_04_particles_fx.png")
	
	# === MODULE 5: UI Architecture ===
	rig.log_step("Testing Module 5: UI Controls, Layouts & Theming")
	main_showcase.switch_to_module(4)
	await rig.wait_frames(5)
	var ui_module: Module2DUI = main_showcase.get_node("CanvasLayer/TabContainer/5. UI Architecture")
	rig.assert_true(ui_module != null, "Module 5 instance must exist")
	
	# Trigger button click
	ui_module.test_button.pressed.emit()
	await rig.wait_frames(3)
	rig.assert_equal(ui_module.click_count, 1, "Button click counter must increment to 1")
	
	# Simulate slider change
	ui_module.slider.value = 85.0
	ui_module._on_slider_changed(85.0)
	await rig.wait_frames(3)
	rig.assert_equal(ui_module.progress_bar.value, 85.0, "ProgressBar must reflect slider value")
	await rig.take_screenshot(artifact_dir + "2d_showcase_05_ui_architecture.png")
	
	rig.log_step("Completing 2D Mega Showcase Audit")
	await rig.finish(artifact_dir + "test_report_showcase_2d.json")
