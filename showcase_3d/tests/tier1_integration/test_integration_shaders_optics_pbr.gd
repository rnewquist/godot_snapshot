# test_integration_shaders_optics_pbr.gd
# Tier 1 Integration Suite 11: Custom Shaders, Surface Optics & PBR Pipeline (16 tests)
# Tests CanvasItem, Spatial, Particle shaders, and complete PBR material properties.
extends "res://addons/gdtest/core/test_suite.gd"

func _init() -> void:
	suite_name = "Tier1_Shaders_Optics_PBR_Integration_Suite"
	test_type = "integration"

## 1. CanvasItem Shader Compilation and Material Code Assignment
func test_canvas_item_shader_compilation_and_code() -> void:
	var shader: Shader = Shader.new()
	shader.code = """
shader_type canvas_item;
uniform vec4 tint_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
void fragment() {
	COLOR = tint_color;
}
"""
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("tint_color", Color(0.0, 1.0, 0.0, 1.0))
	
	var sprite: Sprite2D = autofree(Sprite2D.new()) as Sprite2D
	sprite.material = mat
	add_child(sprite)
	
	assert_eq(shader.get_mode(), Shader.MODE_CANVAS_ITEM, "Shader mode must be MODE_CANVAS_ITEM")
	assert_color_approx(mat.get_shader_parameter("tint_color"), Color(0.0, 1.0, 0.0, 1.0), 0.001, "Material uniform must be Green")

## 2. Spatial Shader Compilation & Render Modes
func test_spatial_shader_compilation_and_render_modes() -> void:
	var shader: Shader = Shader.new()
	shader.code = """
shader_type spatial;
render_mode cull_back, unshaded;
uniform float wave_freq = 2.5;
void vertex() {
	VERTEX.y += sin(VERTEX.x * wave_freq) * 0.1;
}
void fragment() {
	ALBEDO = vec3(0.1, 0.5, 0.9);
}
"""
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("wave_freq", 5.0)
	
	var mesh_inst: MeshInstance3D = autofree(MeshInstance3D.new()) as MeshInstance3D
	mesh_inst.mesh = BoxMesh.new()
	mesh_inst.material_override = mat
	add_child(mesh_inst)
	
	assert_eq(shader.get_mode(), Shader.MODE_SPATIAL, "Shader mode must be MODE_SPATIAL")
	assert_approx(mat.get_shader_parameter("wave_freq"), 5.0, 0.001, "Wave frequency uniform must equal 5.0")

## 3. Particle Process Shader Architecture
func test_particle_process_shader() -> void:
	var shader: Shader = Shader.new()
	shader.code = """
shader_type particles;
void start() {
	VELOCITY = vec3(0.0, 1.0, 0.0);
}
void process() {
	VELOCITY.y += 0.5 * DELTA;
}
"""
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = shader
	
	var particles: GPUParticles3D = autofree(GPUParticles3D.new()) as GPUParticles3D
	particles.process_material = mat
	add_child(particles)
	
	assert_eq(shader.get_mode(), Shader.MODE_PARTICLES, "Shader mode must be MODE_PARTICLES")
	assert_not_null(particles.process_material, "Particles must have process_material assigned")

## 4. Shader Material Uniform Types (Float, Vector2, Vector3, Vector4, Color, Bool)
func test_shader_material_uniform_set_and_get() -> void:
	var shader: Shader = Shader.new()
	shader.code = """
shader_type canvas_item;
uniform float u_float = 1.0;
uniform vec2 u_vec2 = vec2(0.0);
uniform vec3 u_vec3 = vec3(0.0);
uniform vec4 u_vec4 = vec4(0.0);
uniform vec4 u_color : source_color = vec4(1.0);
uniform bool u_bool = true;
void fragment() {
	COLOR = u_color;
}
"""
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = shader
	
	mat.set_shader_parameter("u_float", 4.2)
	mat.set_shader_parameter("u_vec2", Vector2(12, 34))
	mat.set_shader_parameter("u_vec3", Vector3(1, 2, 3))
	mat.set_shader_parameter("u_vec4", Vector4(4, 5, 6, 7))
	mat.set_shader_parameter("u_color", Color(0.2, 0.4, 0.6, 0.8))
	mat.set_shader_parameter("u_bool", false)
	
	assert_approx(mat.get_shader_parameter("u_float"), 4.2, 0.001, "Float uniform must match")
	assert_vector2_approx(mat.get_shader_parameter("u_vec2"), Vector2(12, 34), 0.001, "Vec2 uniform must match")
	assert_vector3_approx(mat.get_shader_parameter("u_vec3"), Vector3(1, 2, 3), 0.001, "Vec3 uniform must match")
	assert_vector4_approx(mat.get_shader_parameter("u_vec4"), Vector4(4, 5, 6, 7), 0.001, "Vec4 uniform must match")
	assert_color_approx(mat.get_shader_parameter("u_color"), Color(0.2, 0.4, 0.6, 0.8), 0.001, "Color uniform must match")
	assert_false(mat.get_shader_parameter("u_bool"), "Bool uniform must be false")

## 5. StandardMaterial3D PBR Albedo and Roughness
func test_standard_material_3d_pbr_albedo_and_roughness() -> void:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.2, 0.4, 1.0)
	mat.roughness = 0.35
	
	assert_color_approx(mat.albedo_color, Color(0.8, 0.2, 0.4, 1.0), 0.001, "Albedo color must match")
	assert_approx(mat.roughness, 0.35, 0.001, "Roughness must match 0.35")

## 6. StandardMaterial3D Specular and Metallic
func test_standard_material_3d_specular_and_metallic() -> void:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.metallic = 0.95
	mat.metallic_specular = 0.65
	
	assert_approx(mat.metallic, 0.95, 0.001, "Metallic must equal 0.95")
	assert_approx(mat.metallic_specular, 0.65, 0.001, "Metallic specular must equal 0.65")

## 7. StandardMaterial3D Emission and Energy
func test_standard_material_3d_emission_and_energy() -> void:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.emission_enabled = true
	mat.emission = Color(0.1, 0.9, 0.3)
	mat.emission_energy_multiplier = 3.5
	
	assert_true(mat.emission_enabled, "Emission must be enabled")
	assert_color_approx(mat.emission, Color(0.1, 0.9, 0.3), 0.001, "Emission color must match")
	assert_approx(mat.emission_energy_multiplier, 3.5, 0.001, "Emission energy must equal 3.5")

## 8. StandardMaterial3D Normal Mapping
func test_standard_material_3d_normal_mapping() -> void:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.normal_enabled = true
	mat.normal_scale = 1.75
	
	assert_true(mat.normal_enabled, "Normal mapping must be enabled")
	assert_approx(mat.normal_scale, 1.75, 0.001, "Normal scale must equal 1.75")

## 9. StandardMaterial3D Rim and Clearcoat
func test_standard_material_3d_rim_and_clearcoat() -> void:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.rim_enabled = true
	mat.rim = 0.85
	mat.rim_tint = 0.4
	mat.clearcoat_enabled = true
	mat.clearcoat = 1.0
	mat.clearcoat_roughness = 0.15
	
	assert_true(mat.rim_enabled, "Rim lighting must be enabled")
	assert_approx(mat.rim, 0.85, 0.001, "Rim strength must equal 0.85")
	assert_approx(mat.rim_tint, 0.4, 0.001, "Rim tint must equal 0.4")
	assert_true(mat.clearcoat_enabled, "Clearcoat must be enabled")
	assert_approx(mat.clearcoat, 1.0, 0.001, "Clearcoat strength must equal 1.0")
	assert_approx(mat.clearcoat_roughness, 0.15, 0.001, "Clearcoat roughness must equal 0.15")

## 10. StandardMaterial3D Anisotropy
func test_standard_material_3d_anisotropy() -> void:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.anisotropy_enabled = true
	mat.anisotropy = 0.7
	
	assert_true(mat.anisotropy_enabled, "Anisotropy must be enabled")
	assert_approx(mat.anisotropy, 0.7, 0.001, "Anisotropy must equal 0.7")

## 11. StandardMaterial3D Subsurface Scattering
func test_standard_material_3d_subsurface_scattering() -> void:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.subsurf_scatter_enabled = true
	mat.subsurf_scatter_strength = 0.55
	mat.subsurf_scatter_skin_mode = true
	
	assert_true(mat.subsurf_scatter_enabled, "SSS must be enabled")
	assert_approx(mat.subsurf_scatter_strength, 0.55, 0.001, "SSS strength must equal 0.55")
	assert_true(mat.subsurf_scatter_skin_mode, "SSS skin mode must be true")

## 12. StandardMaterial3D Transparency and Blend Modes
func test_standard_material_3d_transparency_and_blend_modes() -> void:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	
	assert_eq(mat.transparency, BaseMaterial3D.TRANSPARENCY_ALPHA, "Transparency mode must be ALPHA")
	assert_eq(mat.blend_mode, BaseMaterial3D.BLEND_MODE_ADD, "Blend mode must be ADD")

## 13. StandardMaterial3D Cull Mode and Shading Mode
func test_standard_material_3d_cull_mode_and_shading_mode() -> void:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	assert_eq(mat.cull_mode, BaseMaterial3D.CULL_DISABLED, "Cull mode must be DISABLED (two-sided)")
	assert_eq(mat.shading_mode, BaseMaterial3D.SHADING_MODE_UNSHADED, "Shading mode must be UNSHADED")

## 14. ORMMaterial3D Channel Packing Properties
func test_orm_material_3d_properties() -> void:
	var mat: ORMMaterial3D = ORMMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.7, 0.5)
	mat.metallic = 0.8
	mat.roughness = 0.2
	mat.ao_light_affect = 0.6
	
	assert_color_approx(mat.albedo_color, Color(0.9, 0.7, 0.5), 0.001, "ORMMaterial3D albedo must match")
	assert_approx(mat.metallic, 0.8, 0.001, "Metallic must equal 0.8")
	assert_approx(mat.roughness, 0.2, 0.001, "Roughness must equal 0.2")
	assert_approx(mat.ao_light_affect, 0.6, 0.001, "AO light affect must equal 0.6")

## 15. CanvasItemMaterial Blend Modes and Light Modes
func test_canvas_item_material_blend_modes_and_light_modes() -> void:
	var mat: CanvasItemMaterial = CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	
	assert_eq(mat.blend_mode, CanvasItemMaterial.BLEND_MODE_ADD, "CanvasItemMaterial blend mode must be ADD")
	assert_eq(mat.light_mode, CanvasItemMaterial.LIGHT_MODE_UNSHADED, "CanvasItemMaterial light mode must be UNSHADED")

## 16. Sky Material and World Environment Optics
func test_sky_material_and_environment_optics() -> void:
	var sky_mat: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.15, 0.35, 0.75)
	sky_mat.sky_horizon_color = Color(0.65, 0.75, 0.85)
	sky_mat.ground_bottom_color = Color(0.1, 0.1, 0.1)
	
	var sky: Sky = Sky.new()
	sky.sky_material = sky_mat
	
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.glow_enabled = true
	env.glow_intensity = 1.2
	
	assert_eq(env.background_mode, Environment.BG_SKY, "Background mode must be BG_SKY")
	assert_true(env.glow_enabled, "Environment glow must be enabled")
	assert_approx(env.glow_intensity, 1.2, 0.001, "Glow intensity must equal 1.2")
	assert_color_approx(sky_mat.sky_top_color, Color(0.15, 0.35, 0.75), 0.001, "Sky top color must match")
