# test_negative_shaders_and_rids.gd
# Tier 1 Negative Boundary Suite: Invalid Shader Syntax, Missing Uniforms, Double-Free RID & Invalid RIDs.
extends "res://addons/gdtest/core/test_suite.gd"

func _init() -> void:
	suite_name = "Tier1_Negative_Shaders_And_RIDs"
	test_type = "integration"

# ==============================================================================
# 1. INVALID SHADER SYNTAX COMPILATION SAFETY
# ==============================================================================

func test_invalid_shader_syntax_compilation_safety() -> void:
	var shader: Shader = Shader.new()
	var broken_code: String = "shader_type spatial;\nvoid fragment() { broken_syntax_invalid_token %%% $$$; }"
	shader.code = broken_code
	
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = shader
	
	assert_eq(shader.code, broken_code, "Shader retains raw assigned code string")
	assert_not_null(mat.shader, "ShaderMaterial holds shader reference despite syntax error")

# ==============================================================================
# 2. NON-EXISTENT UNIFORMS AND PARAMETER TYPE MISMATCHES
# ==============================================================================

func test_shader_material_non_existent_uniform_handling() -> void:
	var shader: Shader = Shader.new()
	shader.code = "shader_type canvas_item;\nuniform vec4 custom_tint : source_color = vec4(1.0, 0.0, 0.0, 1.0);\nvoid fragment() { COLOR = custom_tint; }"
	
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = shader
	
	# Set non-existent uniform parameter
	mat.set_shader_parameter("unknown_uniform_property_xyz", Vector3(1.0, 2.0, 3.0))
	var retrieved: Variant = mat.get_shader_parameter("unknown_uniform_property_xyz")
	# In Godot ShaderMaterial, non-existent parameter set/get does not crash
	assert_true(retrieved == null or retrieved is Vector3, "Non-existent uniform parameter query is safe")
	
	# Setting wrong type for existing uniform
	mat.set_shader_parameter("custom_tint", "invalid_string_type_for_vec4")
	assert_not_null(mat.shader, "Material remains valid after setting mismatched parameter type")

# ==============================================================================
# 3. DOUBLE-FREE RID PROTECTION
# ==============================================================================

func test_double_free_rid_protection_in_test_suite() -> void:
	var ci_rid: RID = RenderingServer.canvas_item_create()
	assert_true(ci_rid.is_valid(), "Created CanvasItem RID must be valid")
	
	# Register with auto-free
	auto_free_rid(ci_rid, ServerType.RENDERING)
	
	# First manual free
	free_rid(ci_rid, ServerType.RENDERING)
	
	# Second manual free attempt (must be guarded and not double-free crash)
	free_rid(ci_rid, ServerType.RENDERING)
	_record_pass()

func test_physics_server_rid_manual_free_and_invalid_state() -> void:
	var body_rid: RID = PhysicsServer2D.body_create()
	assert_true(body_rid.is_valid(), "PhysicsServer2D body RID must be valid")
	
	# Free directly
	PhysicsServer2D.free_rid(body_rid)
	
	# Pass empty RID into PhysicsServer2D
	PhysicsServer2D.free_rid(RID())
	_record_pass()

# ==============================================================================
# 4. EMPTY AND INVALID RIDS ACROSS ALL SERVERS
# ==============================================================================

func test_empty_and_invalid_rid_server_calls() -> void:
	var empty_rid: RID = RID()
	assert_false(empty_rid.is_valid(), "Default constructed RID must not be valid")
	
	# RenderingServer resilience with empty RID
	RenderingServer.canvas_item_set_visible(empty_rid, true)
	RenderingServer.free_rid(empty_rid)
	
	# PhysicsServer2D/3D resilience with empty RID
	PhysicsServer2D.body_set_space(empty_rid, empty_rid)
	PhysicsServer2D.free_rid(empty_rid)
	PhysicsServer3D.body_set_space(empty_rid, empty_rid)
	PhysicsServer3D.free_rid(empty_rid)
	
	# NavigationServer2D/3D resilience with empty RID
	NavigationServer2D.region_set_map(empty_rid, empty_rid)
	NavigationServer2D.free_rid(empty_rid)
	NavigationServer3D.region_set_map(empty_rid, empty_rid)
	NavigationServer3D.free_rid(empty_rid)
	
	_record_pass()
