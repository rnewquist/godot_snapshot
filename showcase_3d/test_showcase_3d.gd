# test_showcase_3d.gd
extends Node3D

const TestRig = preload("res://test_rig.gd")

@onready var main_showcase: MainShowcase3D = $MainShowcase3D
var rig: TestRig

func _ready() -> void:
	rig = TestRig.new()
	rig.test_name = "3D_Mega_Showcase_Comprehensive_Audit"
	add_child(rig)
	
	run_comprehensive_3d_audit()

func run_comprehensive_3d_audit() -> void:
	var artifact_dir = ProjectSettings.globalize_path("res://artifacts/")
	
	# === MODULE 1: PBR Materials & Shaders ===
	rig.log_step("Testing Module 1: 3D PBR StandardMaterial3D (Metallic, Roughness, Emission, Glass)")
	main_showcase.switch_to_module(0)
	await rig.wait_frames(10)
	var mat_module: Module3DMaterials = main_showcase.modules_container.get_child(0)
	rig.assert_true(mat_module != null, "Module 1 instance must exist")
	var gold_mesh: MeshInstance3D = mat_module.get_node("SpheresContainer/GoldSphere")
	var gold_mat: StandardMaterial3D = gold_mesh.get_surface_override_material(0)
	rig.assert_approx(gold_mat.metallic, 1.0, 0.01, "Gold material metallic must be 1.0")
	rig.assert_approx(gold_mat.roughness, 0.1, 0.01, "Gold material roughness must be 0.1")
	var glow_mesh: MeshInstance3D = mat_module.get_node("SpheresContainer/GlowSphere")
	var glow_mat: StandardMaterial3D = glow_mesh.get_surface_override_material(0)
	rig.assert_true(glow_mat.emission_enabled, "Glow sphere emission must be enabled")
	await rig.take_screenshot(artifact_dir + "3d_showcase_01_materials.png")
	
	# === MODULE 2: 3D Lighting & WorldEnvironment ===
	rig.log_step("Testing Module 2: 3D Lighting (Directional, Omni, Spot), Shadows & WorldEnvironment")
	main_showcase.switch_to_module(1)
	await rig.wait_frames(10)
	var lit_module: Module3DLighting = main_showcase.modules_container.get_child(1)
	rig.assert_true(lit_module != null, "Module 2 instance must exist")
	rig.assert_true(lit_module.omni_light.shadow_enabled, "OmniLight3D shadows must be enabled")
	rig.assert_true(lit_module.spot_light.shadow_enabled, "SpotLight3D shadows must be enabled")
	await rig.take_screenshot(artifact_dir + "3d_showcase_02_lighting.png")
	
	# === MODULE 3: Physics & Elevators ===
	rig.log_step("Testing Module 3: 3D Physics RigidBodies, Restitution & Kinematic Elevator (with Live GSS)")
	main_showcase.switch_to_module(2)
	await rig.wait_frames(5)
	var phy_module: Module3DPhysics = main_showcase.modules_container.get_child(2)
	rig.assert_true(phy_module != null, "Module 3 instance must exist")
	phy_module.reset_physics()
	var live_phy = rig.start_live_gss("3d_showcase_physics_live", phy_module)
	await rig.wait_physics_frames(30)
	rig.stop_live_gss(live_phy)
	rig.assert_true(phy_module.bouncy_sphere.global_position.y < 3.0, "Bouncy sphere must descend under gravity")
	rig.assert_range(phy_module.elevator.position.y, 0.1, 2.0, "Elevator position must remain within stroke bounds")
	await rig.take_screenshot(artifact_dir + "3d_showcase_03_physics.png")
	
	# === MODULE 4: Joints & Constraints ===
	rig.log_step("Testing Module 4: 3D Mechanical Joints (Hinge, Slider, Pin) & RayCast3D (with Live GSS)")
	main_showcase.switch_to_module(3)
	await rig.wait_frames(5)
	var jnt_module: Module3DJoints = main_showcase.modules_container.get_child(3)
	rig.assert_true(jnt_module != null, "Module 4 instance must exist")
	var live_jnt = rig.start_live_gss("3d_showcase_joints_live", jnt_module)
	await rig.wait_physics_frames(20)
	rig.stop_live_gss(live_jnt)
	rig.assert_true(jnt_module.slider_piston.position.x != 0.0, "Slider piston must displace along linear axis")
	jnt_module.raycast.force_raycast_update()
	rig.assert_true(jnt_module.raycast.is_colliding(), "RayCast3D must detect ground surface")
	await rig.take_screenshot(artifact_dir + "3d_showcase_04_joints.png")
	
	# === MODULE 5: Particles & Decals ===
	rig.log_step("Testing Module 5: 3D Particles, Decals & Path3D Orbit")
	main_showcase.switch_to_module(4)
	await rig.wait_frames(10)
	var ptc_module: Module3DParticles = main_showcase.modules_container.get_child(4)
	rig.assert_true(ptc_module != null, "Module 5 instance must exist")
	rig.assert_true(ptc_module.path_follow.progress > 0.0, "PathFollow3D drone must advance along 3D path")
	await rig.take_screenshot(artifact_dir + "3d_showcase_05_particles.png")
	
	rig.log_step("Completing 3D Mega Showcase Audit")
	await rig.finish(artifact_dir + "test_report_showcase_3d.json")
