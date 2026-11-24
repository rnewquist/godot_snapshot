# test_master_audit.gd
extends Node3D

const TestRig = preload("res://test_rig.gd")

@onready var master_showcase: MainMasterShowcase = $MainMasterShowcase
var rig: TestRig

func _ready() -> void:
	rig = TestRig.new()
	rig.test_name = "Master_Comprehensive_Engine_Audit"
	add_child(rig)
	
	run_master_audit()

func run_master_audit() -> void:
	var artifact_dir = ProjectSettings.globalize_path("res://artifacts/")
	var audit_results = {}
	
	# === MODULE 1: 2D Grid & AStar Pathfinding ===
	rig.log_step("Audit Module 1: 2D AStarGrid2D Obstacle Routing & Parallax")
	master_showcase.switch_to_module(0)
	await rig.wait_frames(10)
	var mod1: Module2DExtended = master_showcase.modules_container.get_child(0)
	rig.assert_true(mod1 != null, "Module 1 instance must exist")
	rig.assert_equal(mod1.actuals["astar_path_length"], mod1.predictions["astar_path_length"], "AStar2D path length must match detour prediction")
	rig.assert_equal(mod1.actuals["astar_routes_around_wall"], mod1.predictions["astar_routes_around_wall"], "AStar2D must route around wall")
	audit_results["module_1_2d_extended"] = {"predictions": mod1.predictions, "actuals": mod1.actuals}
	await rig.take_screenshot(artifact_dir + "mega_showcase_01_2d_grid.png")
	
	# === MODULE 2: 3D CSG Modeling, Procedural Mesh & MultiMesh ===
	rig.log_step("Audit Module 2: 3D CSG Boolean, ArrayMesh & GPU MultiMesh")
	master_showcase.switch_to_module(1)
	await rig.wait_frames(10)
	var mod2: Module3DModelingAndGI = master_showcase.modules_container.get_child(1)
	rig.assert_true(mod2 != null, "Module 2 instance must exist")
	rig.assert_equal(mod2.actuals["array_mesh_vertex_count"], mod2.predictions["array_mesh_vertex_count"], "ArrayMesh vertex count must match prediction")
	rig.assert_equal(mod2.actuals["multimesh_count"], mod2.predictions["multimesh_count"], "MultiMesh instance count must match prediction")
	audit_results["module_2_3d_modeling"] = {"predictions": mod2.predictions, "actuals": mod2.actuals}
	await rig.take_screenshot(artifact_dir + "mega_showcase_02_3d_modeling.png")
	
	# === MODULE 3: Audio DSP Architecture ===
	rig.log_step("Audit Module 3: AudioServer Bus Routing & DSP Filter Effects")
	master_showcase.switch_to_module(4)
	await rig.wait_frames(5)
	var mod3: ModuleAudioDSP = master_showcase.modules_container.get_node("ModuleAudioDSP")
	rig.assert_true(mod3 != null, "Module 3 instance must exist")
	rig.assert_true(mod3.actuals["sfx_bus_exists"], "SFX audio bus must exist")
	rig.assert_approx(mod3.actuals["reverb_room_size"], mod3.predictions["reverb_room_size"], 0.01, "Reverb room size must match prediction")
	rig.assert_approx(mod3.actuals["lowpass_cutoff"], mod3.predictions["lowpass_cutoff"], 1.0, "LowPass cutoff must match prediction")
	audit_results["module_3_audio_dsp"] = {"predictions": mod3.predictions, "actuals": mod3.actuals}
	await rig.take_screenshot(artifact_dir + "mega_showcase_03_audio_dsp.png")
	
	# === MODULE 4: 3D Navigation & AI Pathfinding ===
	rig.log_step("Audit Module 4: 3D NavigationMesh & NavigationAgent3D (with Live GSS)")
	master_showcase.switch_to_module(5)
	await rig.wait_frames(5)
	var mod4: ModuleNavigationAI = master_showcase.modules_container.get_node("ModuleNavigationAI")
	rig.assert_true(mod4 != null, "Module 4 instance must exist")
	var live_nav = rig.start_live_gss("mega_showcase_navigation_3d_live", mod4)
	await rig.wait_physics_frames(25)
	rig.stop_live_gss(live_nav)
	rig.assert_true(mod4.character.global_position.x > -3.0, "Navigation agent must navigate along target path")
	audit_results["module_4_navigation"] = {"predictions": mod4.predictions, "actuals": mod4.actuals}
	await rig.take_screenshot(artifact_dir + "mega_showcase_04_navigation.png")
	
	# === MODULE 5: Custom Shaders & Surface Optics ===
	rig.log_step("Audit Module 5: Custom Spatial Vertex & Fragment Shader Pipeline")
	master_showcase.switch_to_module(6)
	await rig.wait_frames(5)
	var mod5: ModuleShadersAndCompute = master_showcase.modules_container.get_node("ModuleShadersAndCompute")
	rig.assert_true(mod5 != null, "Module 5 instance must exist")
	rig.assert_true(mod5.actuals["is_shader_material"], "Material must be ShaderMaterial")
	rig.assert_approx(mod5.actuals["wave_frequency"], mod5.predictions["wave_frequency"], 0.01, "Wave frequency parameter must match")
	audit_results["module_5_shaders"] = {"predictions": mod5.predictions, "actuals": mod5.actuals}
	await rig.take_screenshot(artifact_dir + "mega_showcase_05_shaders.png")
	
	# === MODULE 6: High-Level Multiplayer & RPC ===
	rig.log_step("Audit Module 6: High-Level Multiplayer RPC & Property Synchronization")
	master_showcase.switch_to_module(7)
	await rig.wait_frames(5)
	var mod6: ModuleMultiplayerRPC = master_showcase.modules_container.get_node("ModuleMultiplayerRPC")
	rig.assert_true(mod6 != null, "Module 6 instance must exist")
	rig.assert_equal(mod6.actuals["rpc_count_target"], mod6.predictions["rpc_count_target"], "RPC call count must match prediction")
	rig.assert_approx(mod6.actuals["sync_value_target"], mod6.predictions["sync_value_target"], 0.01, "Synchronized value must match prediction")
	audit_results["module_6_multiplayer"] = {"predictions": mod6.predictions, "actuals": mod6.actuals}
	await rig.take_screenshot(artifact_dir + "mega_showcase_06_multiplayer.png")
	
	# === MODULE 7: Threading, File I/O & Low-Level Servers ===
	rig.log_step("Audit Module 7: WorkerThreadPool, JSON Serialization & PhysicsServer3D RID")
	master_showcase.switch_to_module(8)
	await rig.wait_frames(5)
	var mod7: ModuleSystemsIOThreads = master_showcase.modules_container.get_node("ModuleSystemsIOThreads")
	rig.assert_true(mod7 != null, "Module 7 instance must exist")
	rig.assert_equal(mod7.actuals["parallel_sum"], mod7.predictions["parallel_sum"], "Parallel thread sum must match prediction")
	rig.assert_true(mod7.actuals["json_roundtrip_match"], "JSON file save/load schema must match prediction")
	rig.assert_equal(mod7.actuals["expression_eval"], mod7.predictions["expression_eval"], "Dynamic expression evaluation must match prediction")
	rig.assert_approx(mod7.actuals["server_body_origin_x"], mod7.predictions["server_body_origin_x"], 0.01, "Low-level server body origin must match prediction")
	audit_results["module_7_systems_io"] = {"predictions": mod7.predictions, "actuals": mod7.actuals}
	await rig.take_screenshot(artifact_dir + "mega_showcase_07_systems_io.png")

	# === MODULE 8: AnimationPlayer & Tween Sequence (with Live GSS) ===
	rig.log_step("Audit Module 8: AnimationPlayer & Tween Sequence (with Live GSS)")
	master_showcase.switch_to_module(3)
	await rig.wait_frames(3)
	var mod_anim = master_showcase.modules_container.get_node("ModuleAnimationAndTweens")
	rig.assert_true(mod_anim != null, "Animation module instance must exist")
	mod_anim.animated_sprite.position.x = 120.0
	var live_tween = rig.start_live_gss("mega_showcase_tween_live", mod_anim, {"step_mode": "process"})
	await mod_anim.execute_tween_sequence()
	await rig.wait_frames(5)
	rig.stop_live_gss(live_tween)
	rig.assert_approx(mod_anim.actuals["tween_target_position_x"], mod_anim.predictions["tween_target_position_x"], 1.0, "Tween target position X must reach 300")
	await rig.take_screenshot(artifact_dir + "mega_showcase_08_animation_tweens.png")

	# === MODULE 9: UI Container & Widget Matrix ===
	rig.log_step("Audit Module 9: Comprehensive UI Container & Widget Matrix")
	master_showcase.switch_to_module(9)
	await rig.wait_frames(3)
	var mod_ui = master_showcase.modules_container.get_node("ModuleUIAndControls")
	rig.assert_true(mod_ui != null, "UI Matrix module instance must exist")
	mod_ui.execute_programmatic_ui_interaction()
	await rig.wait_frames(3)
	rig.assert_true(mod_ui.actuals["button_click_registered"], "UI Button click must register")
	rig.assert_equal(mod_ui.actuals["text_input_value"], "Godot UI", "LineEdit text value must update")
	await rig.take_screenshot(artifact_dir + "mega_showcase_09_ui_matrix.png")
	
	# Save complete empirical audit report
	var file = FileAccess.open(artifact_dir + "empirical_audit_results.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(audit_results, "\t"))
	file.close()
	
	rig.log_step("Completing Master Comprehensive Audit")
	await rig.finish(artifact_dir + "test_report_master_audit.json")
