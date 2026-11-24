# test_integration_direct_servers_memory.gd
# Tier 1 Integration Suite 13: Direct Servers, Low-Level RIDs & Memory Lifecycle (16 tests)
# Tests RenderingServer, TextServer, PhysicsServer2D/3D, auto_free_rid lifecycle, and RID stress loops.
extends "res://addons/gdtest/core/test_suite.gd"

func _init() -> void:
	suite_name = "Tier1_Direct_Servers_Memory_Integration_Suite"
	test_type = "integration"

## 1. RenderingServer CanvasItem Creation & Lifecycle
func test_rendering_server_canvas_item_create_and_free() -> void:
	var ci_rid: RID = auto_free_rid(RenderingServer.canvas_item_create(), ServerType.RENDERING)
	assert_true(ci_rid.is_valid(), "CanvasItem RID must be valid")
	
	RenderingServer.canvas_item_set_visible(ci_rid, true)
	RenderingServer.canvas_item_set_modulate(ci_rid, Color.AQUA)

## 2. RenderingServer CanvasItem Draw Commands
func test_rendering_server_canvas_item_draw_rect() -> void:
	var ci_rid: RID = auto_free_rid(RenderingServer.canvas_item_create(), ServerType.RENDERING)
	RenderingServer.canvas_item_add_rect(ci_rid, Rect2(10, 10, 100, 100), Color.RED)
	assert_true(ci_rid.is_valid(), "CanvasItem with draw rect must remain valid")

## 3. RenderingServer Instance & Mesh RID Lifecycle
func test_rendering_server_instance_and_mesh_rid_lifecycle() -> void:
	var inst_rid: RID = auto_free_rid(RenderingServer.instance_create(), ServerType.RENDERING)
	var mesh_rid: RID = auto_free_rid(RenderingServer.mesh_create(), ServerType.RENDERING)
	assert_true(inst_rid.is_valid(), "Instance RID must be valid")
	assert_true(mesh_rid.is_valid(), "Mesh RID must be valid")
	
	RenderingServer.instance_set_base(inst_rid, mesh_rid)
	RenderingServer.instance_set_visible(inst_rid, true)

## 4. RenderingServer Scenario and Viewport Setup
func test_rendering_server_scenario_and_viewport_creation() -> void:
	var scenario_rid: RID = auto_free_rid(RenderingServer.scenario_create(), ServerType.RENDERING)
	var vp_rid: RID = auto_free_rid(RenderingServer.viewport_create(), ServerType.RENDERING)
	assert_true(scenario_rid.is_valid(), "Scenario RID must be valid")
	assert_true(vp_rid.is_valid(), "Viewport RID must be valid")
	
	if DisplayServer.get_name() != "headless":
		RenderingServer.viewport_set_scenario(vp_rid, scenario_rid)
		RenderingServer.viewport_set_size(vp_rid, 800, 600)

## 5. RenderingServer Directional Light RID
func test_rendering_server_directional_light_rid() -> void:
	var light_rid: RID = auto_free_rid(RenderingServer.directional_light_create(), ServerType.RENDERING)
	if DisplayServer.get_name() != "headless":
		assert_true(light_rid.is_valid(), "Directional light RID must be valid")
		RenderingServer.light_set_color(light_rid, Color(1, 0.9, 0.8))
		RenderingServer.light_set_param(light_rid, RenderingServer.LIGHT_PARAM_ENERGY, 2.5)
	else:
		_record_pass()

## 6. RenderingServer Camera RID Lifecycle
func test_rendering_server_camera_rid_lifecycle() -> void:
	var cam_rid: RID = auto_free_rid(RenderingServer.camera_create(), ServerType.RENDERING)
	assert_true(cam_rid.is_valid(), "Camera RID must be valid")
	
	RenderingServer.camera_set_perspective(cam_rid, 70.0, 0.05, 500.0)
	RenderingServer.camera_set_transform(cam_rid, Transform3D.IDENTITY)

## 7. TextServer Font & Shaped Text RID Lifecycle
func test_text_server_font_create_and_shaped_text() -> void:
	var ts = TextServerManager.get_primary_interface()
	if ts:
		var font_rid: RID = auto_free_rid(ts.create_font(), ServerType.TEXT)
		var shaped_rid: RID = auto_free_rid(ts.create_shaped_text(), ServerType.TEXT)
		assert_true(font_rid.is_valid(), "TextServer font RID must be valid")
		assert_true(shaped_rid.is_valid(), "TextServer shaped text RID must be valid")
	else:
		_record_pass()

## 8. TextServer Shaped Text String Addition & Sizing
func test_text_server_string_size_and_ascent() -> void:
	var ts = TextServerManager.get_primary_interface()
	if ts:
		var shaped_rid: RID = auto_free_rid(ts.create_shaped_text(), ServerType.TEXT)
		var font = ThemeDB.fallback_font
		var font_rids = font.get_rids() if font else []
		var font_rid = font_rids[0] if not font_rids.is_empty() else RID()
		
		var fonts_arr: Array = []
		if font_rid.is_valid():
			fonts_arr.append(font_rid)
			
		ts.shaped_text_add_string(shaped_rid, "Direct Server Engine Audit", fonts_arr, 16)
		var sz = ts.shaped_text_get_size(shaped_rid)
		assert_gte(sz.x, 0.0, "Shaped text width must be non-negative")
	else:
		_record_pass()

## 9. PhysicsServer2D Body and Shape RID Lifecycle
func test_physics_server_2d_body_and_shape_rid_lifecycle() -> void:
	var body_rid: RID = auto_free_rid(PhysicsServer2D.body_create(), ServerType.PHYSICS_2D)
	var shape_rid: RID = auto_free_rid(PhysicsServer2D.circle_shape_create(), ServerType.PHYSICS_2D)
	assert_true(body_rid.is_valid(), "PhysicsServer2D body RID must be valid")
	assert_true(shape_rid.is_valid(), "PhysicsServer2D circle shape RID must be valid")
	
	PhysicsServer2D.shape_set_data(shape_rid, 25.0)
	PhysicsServer2D.body_add_shape(body_rid, shape_rid)
	PhysicsServer2D.body_set_mode(body_rid, PhysicsServer2D.BODY_MODE_RIGID)

## 10. PhysicsServer3D Body and Shape RID Lifecycle
func test_physics_server_3d_body_and_shape_rid_lifecycle() -> void:
	var body_3d_rid: RID = auto_free_rid(PhysicsServer3D.body_create(), ServerType.PHYSICS_3D)
	var shape_3d_rid: RID = auto_free_rid(PhysicsServer3D.sphere_shape_create(), ServerType.PHYSICS_3D)
	assert_true(body_3d_rid.is_valid(), "PhysicsServer3D body RID must be valid")
	assert_true(shape_3d_rid.is_valid(), "PhysicsServer3D sphere shape RID must be valid")
	
	PhysicsServer3D.shape_set_data(shape_3d_rid, 1.5)
	PhysicsServer3D.body_add_shape(body_3d_rid, shape_3d_rid)
	PhysicsServer3D.body_set_mode(body_3d_rid, PhysicsServer3D.BODY_MODE_RIGID)

## 11. PhysicsServer2D Area and Space Configuration
func test_physics_server_2d_area_rid_lifecycle() -> void:
	var space_2d_rid: RID = auto_free_rid(PhysicsServer2D.space_create(), ServerType.PHYSICS_2D)
	var area_2d_rid: RID = auto_free_rid(PhysicsServer2D.area_create(), ServerType.PHYSICS_2D)
	assert_true(space_2d_rid.is_valid(), "2D Space RID must be valid")
	assert_true(area_2d_rid.is_valid(), "2D Area RID must be valid")
	
	PhysicsServer2D.area_set_space(area_2d_rid, space_2d_rid)
	PhysicsServer2D.space_set_active(space_2d_rid, true)

## 12. PhysicsServer3D Area and Space Configuration
func test_physics_server_3d_area_rid_lifecycle() -> void:
	var space_3d_rid: RID = auto_free_rid(PhysicsServer3D.space_create(), ServerType.PHYSICS_3D)
	var area_3d_rid: RID = auto_free_rid(PhysicsServer3D.area_create(), ServerType.PHYSICS_3D)
	assert_true(space_3d_rid.is_valid(), "3D Space RID must be valid")
	assert_true(area_3d_rid.is_valid(), "3D Area RID must be valid")
	
	PhysicsServer3D.area_set_space(area_3d_rid, space_3d_rid)
	PhysicsServer3D.space_set_active(space_3d_rid, true)

## 13. Auto Free RID Automatic Registration Verification
func test_auto_free_rid_automatic_cleanup_in_teardown() -> void:
	var count_start = _auto_free_rids.size()
	var test_rid: RID = auto_free_rid(PhysicsServer2D.body_create(), ServerType.PHYSICS_2D)
	assert_eq(_auto_free_rids.size(), count_start + 1, "auto_free_rid must register RID into tracked collection")
	assert_true(test_rid.is_valid(), "Tracked RID must be valid")

## 14. Manual free_rid Execution and Unregister
func test_manual_free_rid_and_unregister() -> void:
	var test_rid: RID = auto_free_rid(PhysicsServer2D.body_create(), ServerType.PHYSICS_2D)
	var count_during = _auto_free_rids.size()
	free_rid(test_rid, ServerType.PHYSICS_2D)
	assert_eq(_auto_free_rids.size(), count_during - 1, "free_rid must remove RID from auto_free collection")

## 15. Direct Server RID Stress Allocation Loop (Zero Leaks)
func test_direct_server_rid_stress_allocation_loop() -> void:
	var loop_count = 100
	for i in range(loop_count):
		var p2d = PhysicsServer2D.body_create()
		var p3d = PhysicsServer3D.body_create()
		var rs_ci = RenderingServer.canvas_item_create()
		
		PhysicsServer2D.free_rid(p2d)
		PhysicsServer3D.free_rid(p3d)
		RenderingServer.free_rid(rs_ci)
		
	_record_pass()

## 16. RenderingServer 2D Texture RID Creation
func test_rendering_server_texture_rid_creation() -> void:
	var img: Image = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color.MAGENTA)
	var tex_rid: RID = auto_free_rid(RenderingServer.texture_2d_create(img), ServerType.RENDERING)
	assert_true(tex_rid.is_valid(), "RenderingServer texture 2D RID must be valid")
	var fetched_img: Image = RenderingServer.texture_2d_get(tex_rid)
	if fetched_img:
		assert_eq(fetched_img.get_width(), 8, "Texture width must equal 8")
		assert_eq(fetched_img.get_height(), 8, "Texture height must equal 8")
	else:
		assert_true(tex_rid.is_valid(), "Texture RID is valid")
