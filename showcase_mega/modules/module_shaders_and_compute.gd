# module_shaders_and_compute.gd
# 6-Station /godot-shaders Interactive Playground & Element Anatomy Showcase
extends Node3D
class_name ModuleShadersAndCompute

const ELEMENT_CATEGORIES: Array[String] = [
	"0: Pipeline & render_mode",
	"1: Uniforms & Instance Uniforms",
	"2: vertex() Stage",
	"3: fragment() & Procedural Math",
	"4: Normals, Derivatives & Optimization",
	"5: Lighting, Fresnel, SSS & Scene Sync"
]

const SHADER_STATIONS: Array[Dictionary] = [
	{
		"index": 0,
		"id": "wave_mesh",
		"title": "Station 0: WaveMesh — vertex() Displacement & Analytic Normals",
		"pipeline": "spatial",
		"node_path": "WaveMesh",
		"primary_uniform": &"wave_frequency",
		"slider_min": 1.0,
		"slider_max": 10.0,
		"focus_pos": Vector3(-0.1, -0.45, 1.4),
		"elements": [
			{
				"category": "0: Pipeline & render_mode",
				"title": "Spatial Two-Sided Specular Surface Pipeline (GDS001)",
				"explanation": "Declares shader_type spatial; with cull_disabled and specular_schlick_ggx so both the top and underside of the displaced wave plane render with physically based GGX specular highlights.",
				"code": "shader_type spatial;\nrender_mode cull_disabled, specular_schlick_ggx;"
			},
			{
				"category": "1: Uniforms & Instance Uniforms",
				"title": "Range-Hinted Wave Uniforms & : source_color Tints (GDS003)",
				"explanation": "Exposes wave_frequency (4.0), wave_amplitude (0.25), and wave_speed (3.0) with Inspector range hints alongside Godot 4 : source_color sRGB-to-linear deep/crest colors.",
				"code": "uniform float wave_frequency : hint_range(1.0, 10.0) = 4.0;\nuniform float wave_amplitude : hint_range(0.05, 1.0) = 0.25;\nuniform vec4 crest_color : source_color = vec4(0.24, 0.82, 0.98, 1.0);"
			},
			{
				"category": "2: vertex() Stage",
				"title": "Dual-Axis Harmonic Vertex Displacement (GDS008)",
				"explanation": "Offsets VERTEX.y using orthogonal sine and cosine wave phases driven by TIME. Paired with extra_cull_margin = 1.5 on WaveMesh so frustum culling never clips displaced wave crests.",
				"code": "float phase_x = VERTEX.x * wave_frequency + TIME * wave_speed;\nfloat h = sin(phase_x) * wave_amplitude + cos(phase_z) * (wave_amplitude * 0.45);\nVERTEX.y += h;"
			},
			{
				"category": "3: fragment() & Procedural Math",
				"title": "Crest Height Interpolation & UV Ripple Banding",
				"explanation": "Blends deep ocean and cyan crest colors using the normalized vertex wave height varying v_wave_h and high-frequency UV sine interference.",
				"code": "float ripple_band = 0.5 + 0.5 * sin(UV.x * 12.0 + UV.y * 8.0);\nvec3 base_col = mix(deep_color.rgb, crest_color.rgb, clamp(v_wave_h * 0.8 + ripple_band * 0.2, 0.0, 1.0));"
			},
			{
				"category": "4: Normals, Derivatives & Optimization",
				"title": "Exact Analytic Partial Derivative Normal Reconstruction (GDS011)",
				"explanation": "Computes exact partial derivatives dh/dx and dh/dz in vertex() to reconstruct NORMAL = normalize(vec3(-dh_dx, 1.0, -dh_dz)) in 1 pass without 4-tap finite difference overhead.",
				"code": "float dh_dx = cos(phase_x) * wave_frequency * wave_amplitude;\nfloat dh_dz = -sin(phase_z) * (wave_frequency * 0.75) * (wave_amplitude * 0.45);\nNORMAL = normalize(vec3(-dh_dx, 1.0, -dh_dz));"
			},
			{
				"category": "5: Lighting, Fresnel, SSS & Scene Sync",
				"title": "Clamped Schlick Fresnel Rim & Crest Emission (GDS012)",
				"explanation": "Evaluates a domain-clamped Fresnel term pow(clamp(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 0.0, 1.0), 3.0) to prevent negative-base NaN pixels in HDR glow.",
				"code": "float fresnel = pow(clamp(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 0.0, 1.0), 3.0);\nEMISSION = crest_color.rgb * (v_wave_h * v_wave_h * 0.18 + fresnel * 0.12);"
			}
		]
	},
	{
		"index": 1,
		"id": "terrain_sphere",
		"title": "Station 1: TerrainSphereMesh — Decorrelated NOISE_ROT 3D Ridge & 4-Tier Strata",
		"pipeline": "spatial",
		"node_path": "TerrainSphereMesh",
		"primary_uniform": &"ridge_scale",
		"slider_min": 1.0,
		"slider_max": 8.0,
		"focus_pos": Vector3(-0.2, 1.0, -0.4),
		"elements": [
			{
				"category": "0: Pipeline & render_mode",
				"title": "Closed Planetary Terrain Spatial Pipeline (GDS001)",
				"explanation": "Uses shader_type spatial; render_mode cull_back, specular_schlick_ggx; on a 48x24 SphereMesh with extra_cull_margin = 1.5 to bound radial mountain displacement.",
				"code": "shader_type spatial;\nrender_mode cull_back, specular_schlick_ggx;"
			},
			{
				"category": "1: Uniforms & Instance Uniforms",
				"title": "Ridge Octave & Altimetric Snow-Line Uniforms",
				"explanation": "Controls mountain frequency (ridge_scale), crest sharpness feedback (ridge_gain), radial height (displacement_amp), sedimentary frequency (strata_freq), and snow_line.",
				"code": "uniform float ridge_scale : hint_range(1.0, 8.0) = 2.6;\nuniform float ridge_gain : hint_range(0.5, 2.5) = 1.65;\nuniform float snow_line : hint_range(0.2, 0.95) = 0.58;"
			},
			{
				"category": "2: vertex() Stage",
				"title": "Radial Ridge Displacement & Gradient Normal Update (GDS008, GDS011)",
				"explanation": "Displaces sphere vertices outward along NORMAL by fbm_ridge3d() and perturbs NORMAL using the spherical ridge gradient so mountain slopes catch directional sunlight.",
				"code": "float h = fbm_ridge3d(base_dir * ridge_scale, ridge_gain);\nVERTEX += NORMAL * (h * displacement_amp);\nNORMAL = normalize(NORMAL - grad);"
			},
			{
				"category": "3: fragment() & Procedural Math",
				"title": "NOISE_ROT Inter-Octave 3x3 Orthogonal Rotation & Sharp Ridge Folding",
				"explanation": "Folds 3D value noise into sharp tectonic crests (1.0 - abs(n * 2.0 - 1.0))^2 and rotates coordinates by determinant-1 NOISE_ROT between octaves to eliminate axial grid artifacts.",
				"code": "float r = 1.0 - abs(noise3d(wp) * 2.0 - 1.0);\nr = r * r * prev_w;\nwp = NOISE_ROT * wp * 2.03;"
			},
			{
				"category": "4: Normals, Derivatives & Optimization",
				"title": "Trigonometric-Free Polynomial Hash & 3-Octave Loop Cap (GDS007)",
				"explanation": "Uses polynomial fract bit-mixing (hash31) instead of sin() to avoid mobile half-float precision banding and caps the FBM loop at a fixed 3 octaves for SPIR-V unrolling.",
				"code": "float hash31(vec3 p3) {\n\tp3 = fract(p3 * 0.1031);\n\tp3 += dot(p3, p3.zyx + 31.32);\n\treturn fract((p3.x + p3.y) * p3.z);\n}"
			},
			{
				"category": "5: Lighting, Fresnel, SSS & Scene Sync",
				"title": "4-Tier Altimetric Ramp & Sedimentary Strata Blending",
				"explanation": "Blends 4 biome tiers (valley slate -> stratified granite -> alpine moss -> snow peaks) by combining elevation v_ridge_h with world-up slope dot(v_local_norm, UP).",
				"code": "float strata = 0.5 + 0.5 * sin(v_local_pos.y * strata_freq + v_ridge_h * 4.5);\nfloat snow_mask = smoothstep(snow_line, snow_line + 0.18, elev + up_slope * 0.15);\nALBEDO = mix(col, tier3_snow, snow_mask);"
			}
		]
	},
	{
		"index": 2,
		"id": "voronoi_masonry",
		"title": "Station 2: VoronoiMasonryMesh — 2-Pass 5x5 Bisector & Cotangent Frame",
		"pipeline": "spatial",
		"node_path": "VoronoiMasonryMesh",
		"primary_uniform": &"cell_scale",
		"slider_min": 2.0,
		"slider_max": 16.0,
		"focus_pos": Vector3(1.85, 1.0, -0.4),
		"elements": [
			{
				"category": "0: Pipeline & render_mode",
				"title": "Tangent-Free Procedural Masonry Spatial Pipeline (GDS001)",
				"explanation": "Renders architectural stone masonry on a CylinderMesh without relying on precomputed mesh tangents by constructing a screen-space cotangent frame in fragment().",
				"code": "shader_type spatial;\nrender_mode cull_back, specular_schlick_ggx;"
			},
			{
				"category": "1: Uniforms & Instance Uniforms",
				"title": "Cellular Scale, Mortar Width & 3x3 vs 5x5 Mode Mix",
				"explanation": "Exposes cell_scale, mortar_width, cotangent_bump_scale, and masonry_mode_mix (blending 1-pass 3x3 cobblestone domes with 2-pass 5x5 constant-width mortar masonry).",
				"code": "uniform float cell_scale : hint_range(2.0, 16.0) = 6.0;\nuniform float mortar_width : hint_range(0.02, 0.25) = 0.08;\nuniform float masonry_mode_mix : hint_range(0.0, 1.0) = 1.0;"
			},
			{
				"category": "2: vertex() Stage",
				"title": "View-Space Position & UV Passing for Screen-Space Derivatives",
				"explanation": "Preserves un-displaced cylindrical geometry in vertex() so dFdx(VERTEX) and dFdy(VERTEX) in fragment() measure exact view-space surface tangents across 2x2 pixel quads.",
				"code": "// Built-in VERTEX (view space) and UV feed the fragment cotangent frame\nvec3 dp1 = dFdx(view_pos);\nvec3 dp2 = dFdy(view_pos);"
			},
			{
				"category": "3: fragment() & Procedural Math",
				"title": "1-Pass 3x3 Cobblestone Domes vs 2-Pass 5x5 Perpendicular Bisector",
				"explanation": "Pass 1 locates nearest cell seed mr; Pass 2 projects neighbor offsets onto normalize(r - mr) via inversesqrt(diff_len_sq) to guarantee uniform mortar joint width without pinching.",
				"code": "if (diff_len_sq > 0.0001) {\n\tvec2 bisector_dir = diff * inversesqrt(diff_len_sq);\n\tedge_d = min(edge_d, dot(0.5 * (mr + r), bisector_dir));\n}"
			},
			{
				"category": "4: Normals, Derivatives & Optimization",
				"title": "Uniform Control Flow Cotangent Frame & UV Footprint Mip-Fading (GDS002)",
				"explanation": "Evaluates fwidth(scaled_uv), dFdx, and dFdy in uniform control flow at the top of fragment() to prevent quad divergence and attenuate Moire aliasing at distance.",
				"code": "float fw = length(fwidth(scaled_uv));\nfloat mip_fade = 1.0 - smoothstep(0.25, 0.75, fw);\nNORMAL = perturb_normal_cotangent(NORMAL, VERTEX, scaled_uv, dh_duv, cotangent_bump_scale);"
			},
			{
				"category": "5: Lighting, Fresnel, SSS & Scene Sync",
				"title": "Per-Cell Hash Albedo Variation & Mortar Roughness Contrast",
				"explanation": "Modulates stone albedo by per-cell hash12(n + mg) and contrasts smooth dressed stone (roughness 0.52) against recessed matte mortar joints (roughness 0.92).",
				"code": "vec3 varied_stone = stone_color.rgb * (0.82 + 0.34 * cell_id);\nALBEDO = mix(mortar_color.rgb, varied_stone, h_profile);\nROUGHNESS = mix(0.92, 0.52, h_profile);"
			}
		]
	},
	{
		"index": 3,
		"id": "tactile_wool",
		"title": "Station 3: TactileWoolMesh — Needle-Felted PBR, Clamped Fresnel & BACKLIGHT SSS",
		"pipeline": "spatial",
		"node_path": "TactileWoolMesh",
		"primary_uniform": &"rim_power",
		"slider_min": 1.0,
		"slider_max": 8.0,
		"focus_pos": Vector3(3.9, 1.0, -0.4),
		"elements": [
			{
				"category": "0: Pipeline & render_mode",
				"title": "Burley Diffuse & GGX Tactile Craft Pipeline (GDS001)",
				"explanation": "Combines diffuse_burley and specular_schlick_ggx on a TorusMesh to capture soft retro-reflective cloth scattering across needle-felted wool fibers.",
				"code": "shader_type spatial;\nrender_mode cull_back, diffuse_burley, specular_schlick_ggx;"
			},
			{
				"category": "1: Uniforms & Instance Uniforms",
				"title": "sRGB : source_color Wool/Stitch Tints & Subsurface Controls (GDS003)",
				"explanation": "Declares wool_tint and stitch_tint with : source_color alongside rim_power (3.0), subsurf_scatter (0.48), fiber_freq (140.0), and stitch_freq (18.0).",
				"code": "uniform vec4 wool_tint : source_color = vec4(0.86, 0.34, 0.24, 1.0);\nuniform float rim_power : hint_range(1.0, 8.0) = 3.0;\nuniform float subsurf_scatter : hint_range(0.0, 1.0) = 0.48;"
			},
			{
				"category": "2: vertex() Stage",
				"title": "Curved Torus Surface Frame for Grazing-Angle Rim Inspection",
				"explanation": "Tilts the torus by 30 degrees so every viewing angle simultaneously presents front-facing stitches and grazing-angle silhouettes for Fresnel and BACKLIGHT evaluation.",
				"code": "// Torus normals sweep continuously from dot(NORMAL, VIEW) = 1.0 to 0.0"
			},
			{
				"category": "3: fragment() & Procedural Math",
				"title": "Running-Stitch Capsule SDF & High-Frequency Felt Micro-Fiber Hash",
				"explanation": "Evaluates a repeating 2D capsule Signed Distance Field (stitch_p.x -= clamp(stitch_p.x, -0.22, 0.22)) for embroidered thread bands over 140x UV felt fiber noise.",
				"code": "vec2 stitch_p = vec2(fract(UV.x * stitch_freq) - 0.5, (fract(UV.y * 3.0) - 0.5) * 4.5);\nstitch_p.x -= clamp(stitch_p.x, -0.22, 0.22);\nfloat stitch_mask = (1.0 - smoothstep(-0.04, 0.04, length(stitch_p) - 0.11)) * stitch_fade;"
			},
			{
				"category": "4: Normals, Derivatives & Optimization",
				"title": "fwidth() Stitch Mip-Fading & Domain-Guarded pow() (GDS002, GDS012)",
				"explanation": "Computes length(fwidth(UV * stitch_freq)) in uniform control flow to fade sub-pixel stitches smoothly and double-clamps 1.0 - dot(NORMAL, VIEW) before pow().",
				"code": "float stitch_fade = 1.0 - smoothstep(0.25, 0.70, length(fwidth(UV * stitch_freq)));\nfloat fresnel_rim = pow(clamp(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 0.0, 1.0), rim_power);"
			},
			{
				"category": "5: Lighting, Fresnel, SSS & Scene Sync",
				"title": "Fuzzy Rim Velvet Lift & BACKLIGHT Subsurface Scattering",
				"explanation": "Assigns high roughness (0.92) to felt wool, lower roughness (0.48) to mercerized cotton stitches, and drives BACKLIGHT = wool_tint.rgb * subsurf_scatter for warm rim translucency.",
				"code": "ROUGHNESS = mix(0.92, 0.48, stitch_mask);\nBACKLIGHT = wool_tint.rgb * subsurf_scatter;"
			}
		]
	},
	{
		"index": 4,
		"id": "foliage_multimesh",
		"title": "Station 4: FoliageMultiMesh — Cantilever UV.y^2, Height Conservation & 20-Float Buffer",
		"pipeline": "spatial",
		"node_path": "FoliageMultiMesh",
		"primary_uniform": &"wind_strength",
		"slider_min": 0.05,
		"slider_max": 1.2,
		"focus_pos": Vector3(1.85, -0.45, 1.4),
		"elements": [
			{
				"category": "0: Pipeline & render_mode",
				"title": "Two-Sided Instanced Foliage Spatial Pipeline (GDS001)",
				"explanation": "Uses shader_type spatial; render_mode cull_disabled, specular_schlick_ggx; on a 36-blade MultiMeshInstance3D populated via a single 20-float interleaved buffer.",
				"code": "shader_type spatial;\nrender_mode cull_disabled, specular_schlick_ggx;"
			},
			{
				"category": "1: Uniforms & Instance Uniforms",
				"title": "Wind Deflection, Blade Length & Bayer LOD Distance Uniforms",
				"explanation": "Exposes wind_strength (0.38), wind_speed (2.4), blade_length (0.95), and lod_max_distance (32.0) while reading per-blade phase/stiffness from INSTANCE_CUSTOM.",
				"code": "uniform float wind_strength : hint_range(0.0, 1.2) = 0.38;\nuniform float blade_length : hint_range(0.3, 2.0) = 0.95;\nuniform float lod_max_distance : hint_range(5.0, 80.0) = 32.0;"
			},
			{
				"category": "2: vertex() Stage",
				"title": "Euler-Bernoulli Cantilever Bending & Pythagorean Arc Conservation (GDS008)",
				"explanation": "Pins roots at h_t = 0.0, bends tips quadratically (bend = h_t * h_t), and pulls VERTEX.y down by sqrt(max(0.0001, L*L - disp_sq)) so blades never stretch under strong wind.",
				"code": "float h_t = clamp(1.0 - UV.y, 0.0, 1.0);\nfloat bend = h_t * h_t;\nfloat conserved_y = sqrt(max(0.0001, L * L - disp_sq));\nVERTEX.y = (VERTEX.y * L) - (L - conserved_y) * h_t;"
			},
			{
				"category": "3: fragment() & Procedural Math",
				"title": "4x4 Ordered Bayer Matrix Dithered Distance LOD",
				"explanation": "Replaces alpha-blended sorting artifacts with an ordered 4x4 Bayer threshold discard at camera distances approaching lod_max_distance.",
				"code": "float lod_vis = 1.0 - smoothstep(lod_max_distance * 0.70, lod_max_distance, v_cam_dist);\nif (lod_vis < bayer4x4(FRAGCOORD.xy)) {\n\tdiscard;\n}"
			},
			{
				"category": "4: Normals, Derivatives & Optimization",
				"title": "Bent Blade Normal Reconstruction & Zero-Derivative Discard Safety (GDS002, GDS011)",
				"explanation": "Tilts NORMAL opposite the horizontal wind displacement in vertex() and avoids any implicit-MIP texture() or dFdx/dFdy calls after the Bayer discard in fragment().",
				"code": "NORMAL = normalize(vec3(-disp_xz.x * 0.65, 1.0, -disp_xz.y * 0.65));"
			},
			{
				"category": "5: Lighting, Fresnel, SSS & Scene Sync",
				"title": "20-Float Interleaved MultiMesh Buffer & Tip BACKLIGHT Translucency",
				"explanation": "Uploads 12 Transform3D floats + 4 COLOR floats + 4 INSTANCE_CUSTOM floats per blade in one C++ multimesh.buffer assignment and shades blade tips with BACKLIGHT SSS.",
				"code": "// GDScript: 20 floats/instance (12 transform + 4 color + 4 custom)\nmultimesh.buffer = packed_20float_buffer"
			}
		]
	},
	{
		"index": 5,
		"id": "instance_batch_and_sdf",
		"title": "Station 5: InstanceBatchGroup & 2DShaderRect — instance uniform & 2D Hex SDF",
		"pipeline": "spatial + canvas_item",
		"node_path": "InstanceBatchGroup",
		"primary_uniform": &"ring_frequency",
		"slider_min": 2.0,
		"slider_max": 16.0,
		"focus_pos": Vector3(3.8, -0.45, 1.4),
		"elements": [
			{
				"category": "0: Pipeline & render_mode",
				"title": "Dual Pipeline: Forward+ Instanced Spatial + 2D canvas_item SDF (GDS001)",
				"explanation": "Pairs 3 3D orbs sharing a single ShaderMaterial RID (shader_type spatial;) with a 2D HUD swatch running shader_type canvas_item; for 6-fold hex SDF glow rings.",
				"code": "shader_type spatial; // Shared by BatchOrb0..2\nshader_type canvas_item; // Runs on 2DShaderRect"
			},
			{
				"category": "1: Uniforms & Instance Uniforms",
				"title": "16-Slot Per-Instance Uniform Batching & Safe Default Fallback (GDS004)",
				"explanation": "Declares 2 non-sampler instance uniforms (instance_tint, pulse_speed) well within the 16-slot limit so all 3 orbs batch in 1 draw call without material duplication.",
				"code": "instance uniform vec4 instance_tint : source_color = vec4(0.95, 0.55, 0.15, 1.0);\ninstance uniform float pulse_speed : hint_range(0.5, 8.0) = 2.0;"
			},
			{
				"category": "2: vertex() Stage",
				"title": "Azimuthal Equidistant Sphere-to-Disc Morphing with Clamped acos() (GDS012)",
				"explanation": "Unrolls sphere vertices toward a polar azimuthal disc via phi = acos(clamp(dir.y, -1.0, 1.0)), preventing NaN pole singularities while interpolating NORMAL toward UP.",
				"code": "float theta = atan(dir.x, dir.z);\nfloat phi = acos(clamp(dir.y, -1.0, 1.0));\nVERTEX = mix(p, flat_disc, morph_amount);\nNORMAL = normalize(mix(NORMAL, vec3(0.0, 1.0, 0.0), morph_amount * 0.75));"
			},
			{
				"category": "3: fragment() & Procedural Math",
				"title": "Exact 6-Fold Symmetry Flat-Top Hex SDF (sd_hex_flat) on 2DShaderRect",
				"explanation": "Folds 2D UV coordinates across 60-degree symmetry planes in 2DShaderRect to compute exact Euclidean signed distance to a flat-top hexagon with concentric wave rings.",
				"code": "const vec3 k = vec3(-0.866025404, 0.5, 0.577350269);\np = abs(p);\np -= 2.0 * min(dot(k.xy, p), 0.0) * k.xy;\np -= vec2(clamp(p.x, -k.z * r, k.z * r), r);"
			},
			{
				"category": "4: Normals, Derivatives & Optimization",
				"title": "RenderingServer.shader_get_parameter_default() Null-Safe Lookup",
				"explanation": "Because ShaderMaterial.get_shader_parameter() returns null when a uniform is at its default value, get_shader_param_safe() queries RenderingServer for the shader default.",
				"code": "var val: Variant = mat.get_shader_parameter(param)\nif val != null or mat.shader == null:\n\treturn val\nreturn RenderingServer.shader_get_parameter_default(mat.shader.get_rid(), param)"
			},
			{
				"category": "5: Lighting, Fresnel, SSS & Scene Sync",
				"title": "Per-Node set_instance_shader_parameter() & Exponential SDF Rim Glow",
				"explanation": "Each orb overrides instance_tint (Amber, Cyan, Emerald) and pulse_speed on its GeometryInstance3D while 2DShaderRect renders exp(-abs(d_hex) * 14.0) neon rim glow.",
				"code": "orb.set_instance_shader_parameter(&\"instance_tint\", tint_col)\norb.set_instance_shader_parameter(&\"pulse_speed\", speed_val)"
			}
		]
	}
]

@onready var wave_mesh: MeshInstance3D = $WaveMesh
@onready var terrain_sphere_mesh: MeshInstance3D = $TerrainSphereMesh
@onready var voronoi_masonry_mesh: MeshInstance3D = $VoronoiMasonryMesh
@onready var tactile_wool_mesh: MeshInstance3D = $TactileWoolMesh
@onready var foliage_multimesh: MultiMeshInstance3D = $FoliageMultiMesh
@onready var instance_batch_group: Node3D = $InstanceBatchGroup
@onready var batch_orb_0: MeshInstance3D = $InstanceBatchGroup/BatchOrb0
@onready var batch_orb_1: MeshInstance3D = $InstanceBatchGroup/BatchOrb1
@onready var batch_orb_2: MeshInstance3D = $InstanceBatchGroup/BatchOrb2
@onready var station_focus_ring: MeshInstance3D = $StationFocusRing

@onready var shader_hud: CanvasLayer = $ShaderPlaygroundHUD
@onready var shader_rect_2d: ColorRect = $"ShaderPlaygroundHUD/MainPanel/2DShaderRect"
@onready var station_title_label: Label = $ShaderPlaygroundHUD/MainPanel/StationTitleLabel
@onready var element_title_label: Label = $ShaderPlaygroundHUD/MainPanel/ElementTitleLabel
@onready var explanation_label: Label = $ShaderPlaygroundHUD/MainPanel/ExplanationLabel
@onready var code_snippet_label: Label = $ShaderPlaygroundHUD/MainPanel/CodeSnippetLabel
@onready var prev_station_btn: Button = $ShaderPlaygroundHUD/MainPanel/PrevStationBtn
@onready var next_station_btn: Button = $ShaderPlaygroundHUD/MainPanel/NextStationBtn
@onready var next_element_btn: Button = $ShaderPlaygroundHUD/MainPanel/NextElementBtn
@onready var cycle_preset_btn: Button = $ShaderPlaygroundHUD/MainPanel/CyclePresetBtn
@onready var slider_caption_label: Label = $ShaderPlaygroundHUD/MainPanel/SliderCaptionLabel
@onready var frequency_slider: HSlider = $ShaderPlaygroundHUD/MainPanel/FrequencySlider

var predictions: Dictionary = {}
var actuals: Dictionary = {}

var active_station_index: int = 0
var active_element_index: int = 0
var active_preset_index: int = 0
var _updating_ui: bool = false

func _ready() -> void:
	_setup_foliage_multimesh(36)
	_setup_instance_batch_group()
	_wire_hud_controls()
	shader_hud.visible = visible
	visibility_changed.connect(_on_visibility_changed)
	select_station(0)
	audit_shader_pipeline()

func _on_visibility_changed() -> void:
	if shader_hud != null:
		shader_hud.visible = visible

func audit_shader_pipeline() -> void:
	# Backward-compatible predictions & actuals required by test_master_audit.gd
	predictions["is_shader_material"] = true
	predictions["wave_frequency"] = 4.0
	predictions["wave_amplitude"] = 0.25
	predictions["station_count"] = 6
	predictions["foliage_instance_count"] = 36

	var mat: Material = wave_mesh.get_surface_override_material(0)
	actuals["is_shader_material"] = (mat is ShaderMaterial)
	if mat is ShaderMaterial:
		var smat: ShaderMaterial = mat as ShaderMaterial
		actuals["wave_frequency"] = get_shader_param_safe(smat, &"wave_frequency")
		actuals["wave_amplitude"] = get_shader_param_safe(smat, &"wave_amplitude")
	actuals["station_count"] = SHADER_STATIONS.size()
	actuals["foliage_instance_count"] = foliage_multimesh.multimesh.instance_count if foliage_multimesh.multimesh != null else 0

func get_shader_param_safe(mat: ShaderMaterial, param: StringName) -> Variant:
	if mat == null:
		return null
	var val: Variant = mat.get_shader_parameter(param)
	if val != null or mat.shader == null:
		return val
	var rs_default: Variant = RenderingServer.shader_get_parameter_default(mat.shader.get_rid(), param)
	if rs_default != null:
		return rs_default
	var code: String = mat.shader.code
	var needle: String = String(param)
	for line in code.split("\n"):
		var stripped: String = line.strip_edges()
		if stripped.begins_with("uniform ") and stripped.contains(needle) and stripped.contains("="):
			var rhs: String = stripped.get_slice("=", 1).trim_suffix(";").strip_edges()
			if rhs.is_valid_float():
				return rhs.to_float()
			elif rhs.is_valid_int():
				return rhs.to_int()
	return null

func _setup_foliage_multimesh(instance_count: int) -> void:
	if foliage_multimesh == null or foliage_multimesh.multimesh == null:
		return
	var mm: MultiMesh = foliage_multimesh.multimesh
	mm.instance_count = 0
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.instance_count = instance_count

	# 20 floats per instance: 12 Transform3D (3x4 row-major) + 4 RGBA color + 4 INSTANCE_CUSTOM
	var buf := PackedFloat32Array()
	buf.resize(instance_count * 20)
	var grid_cols: int = 6
	var spacing: float = 0.22
	var half_span: float = float(grid_cols - 1) * spacing * 0.5
	for i in range(instance_count):
		var base: int = i * 20
		var col_idx: int = i % grid_cols
		var row_idx: int = i / grid_cols
		var jx: float = sin(float(i) * 1.73) * 0.04
		var jz: float = cos(float(i) * 2.31) * 0.04
		var gx: float = float(col_idx) * spacing - half_span + jx
		var gz: float = float(row_idx) * spacing - half_span + jz
		var yaw: float = float(i) * 0.58
		var c: float = cos(yaw)
		var s: float = sin(yaw)

		# Row 0 (x_axis.x, y_axis.x, z_axis.x, origin.x)
		buf[base + 0] = c
		buf[base + 1] = 0.0
		buf[base + 2] = s
		buf[base + 3] = gx
		# Row 1 (x_axis.y, y_axis.y, z_axis.y, origin.y)
		buf[base + 4] = 0.0
		buf[base + 5] = 1.0
		buf[base + 6] = 0.0
		buf[base + 7] = 0.0
		# Row 2 (x_axis.z, y_axis.z, z_axis.z, origin.z)
		buf[base + 8] = -s
		buf[base + 9] = 0.0
		buf[base + 10] = c
		buf[base + 11] = gz

		# Instance COLOR (RGBA)
		buf[base + 12] = 0.35 + 0.15 * float(col_idx) / float(grid_cols)
		buf[base + 13] = 0.72 + 0.20 * float(row_idx) / float(grid_cols)
		buf[base + 14] = 0.24
		buf[base + 15] = 1.0

		# INSTANCE_CUSTOM (phase, stiffness, height_scale, wind_weight)
		buf[base + 16] = float(i) * 0.47
		buf[base + 17] = 0.75 + 0.35 * float(i % 3)
		buf[base + 18] = 0.85 + 0.25 * float((i + 1) % 3)
		buf[base + 19] = 1.0

	mm.buffer = buf

func _setup_instance_batch_group() -> void:
	if batch_orb_0 != null:
		batch_orb_0.set_instance_shader_parameter(&"instance_tint", Color(0.96, 0.52, 0.16, 1.0))
		batch_orb_0.set_instance_shader_parameter(&"pulse_speed", 2.0)
	if batch_orb_1 != null:
		batch_orb_1.set_instance_shader_parameter(&"instance_tint", Color(0.18, 0.84, 0.98, 1.0))
		batch_orb_1.set_instance_shader_parameter(&"pulse_speed", 3.4)
	if batch_orb_2 != null:
		batch_orb_2.set_instance_shader_parameter(&"instance_tint", Color(0.32, 0.92, 0.46, 1.0))
		batch_orb_2.set_instance_shader_parameter(&"pulse_speed", 4.8)

func _wire_hud_controls() -> void:
	if prev_station_btn != null:
		prev_station_btn.pressed.connect(func() -> void:
			select_station(posmod(active_station_index - 1, SHADER_STATIONS.size()))
		)
	if next_station_btn != null:
		next_station_btn.pressed.connect(func() -> void:
			select_station(posmod(active_station_index + 1, SHADER_STATIONS.size()))
		)
	if next_element_btn != null:
		next_element_btn.pressed.connect(func() -> void:
			next_shader_element()
		)
	if cycle_preset_btn != null:
		cycle_preset_btn.pressed.connect(func() -> void:
			apply_live_parameter_preset((active_preset_index + 1) % 3)
		)
	if frequency_slider != null:
		frequency_slider.value_changed.connect(_on_frequency_slider_changed)

func get_station_material(station_index: int) -> ShaderMaterial:
	var idx: int = posmod(station_index, SHADER_STATIONS.size())
	match idx:
		0:
			return wave_mesh.get_surface_override_material(0) as ShaderMaterial
		1:
			return terrain_sphere_mesh.get_surface_override_material(0) as ShaderMaterial
		2:
			return voronoi_masonry_mesh.get_surface_override_material(0) as ShaderMaterial
		3:
			return tactile_wool_mesh.get_surface_override_material(0) as ShaderMaterial
		4:
			return foliage_multimesh.material_override as ShaderMaterial
		5:
			return shader_rect_2d.material as ShaderMaterial
	return null

func select_station(index: int) -> Dictionary:
	active_station_index = posmod(index, SHADER_STATIONS.size())
	var station: Dictionary = SHADER_STATIONS[active_station_index]
	if station_focus_ring != null:
		station_focus_ring.position = station["focus_pos"]

	var mat: ShaderMaterial = get_station_material(active_station_index)
	var param_name: StringName = station["primary_uniform"]
	var cur_val: float = float(get_shader_param_safe(mat, param_name)) if mat != null else 4.0

	_updating_ui = true
	if frequency_slider != null:
		frequency_slider.min_value = float(station["slider_min"])
		frequency_slider.max_value = float(station["slider_max"])
		frequency_slider.value = cur_val
	if slider_caption_label != null:
		slider_caption_label.text = "%s: %.2f" % [String(param_name), cur_val]
	_updating_ui = false

	select_shader_element(active_element_index)
	return station

func select_shader_element(element_index: int) -> Dictionary:
	var station: Dictionary = SHADER_STATIONS[active_station_index]
	var elements: Array = station["elements"]
	active_element_index = posmod(element_index, elements.size())
	var elem: Dictionary = elements[active_element_index]

	if station_title_label != null:
		station_title_label.text = "%s [%s]" % [station["title"], station["pipeline"]]
	if element_title_label != null:
		element_title_label.text = "Element [%d/%d] — %s: %s" % [
			active_element_index + 1,
			elements.size(),
			elem["category"],
			elem["title"]
		]
	if explanation_label != null:
		explanation_label.text = String(elem["explanation"])
	if code_snippet_label != null:
		code_snippet_label.text = String(elem["code"])

	return elem

func next_shader_element() -> Dictionary:
	return select_shader_element(active_element_index + 1)

func _on_frequency_slider_changed(value: float) -> void:
	if _updating_ui:
		return
	var station: Dictionary = SHADER_STATIONS[active_station_index]
	var param_name: StringName = station["primary_uniform"]
	var mat: ShaderMaterial = get_station_material(active_station_index)
	if mat != null:
		mat.set_shader_parameter(param_name, value)
	if slider_caption_label != null:
		slider_caption_label.text = "%s: %.2f" % [String(param_name), value]

func apply_live_parameter_preset(preset_index: int) -> void:
	active_preset_index = posmod(preset_index, 3)
	if cycle_preset_btn != null:
		cycle_preset_btn.text = "Cycle Live Preset (%d)" % active_preset_index

	var wave_mat := wave_mesh.get_surface_override_material(0) as ShaderMaterial
	var terrain_mat := terrain_sphere_mesh.get_surface_override_material(0) as ShaderMaterial
	var voronoi_mat := voronoi_masonry_mesh.get_surface_override_material(0) as ShaderMaterial
	var wool_mat := tactile_wool_mesh.get_surface_override_material(0) as ShaderMaterial
	var foliage_mat := foliage_multimesh.material_override as ShaderMaterial
	var batch_mat := batch_orb_0.get_surface_override_material(0) as ShaderMaterial
	var sdf_mat := shader_rect_2d.material as ShaderMaterial

	match active_preset_index:
		0:
			# Preset 0: Canonical Default Baseline (restores wave_frequency = 4.0, wave_amplitude = 0.25)
			if wave_mat != null:
				wave_mat.set_shader_parameter(&"wave_frequency", 4.0)
				wave_mat.set_shader_parameter(&"wave_amplitude", 0.25)
			if terrain_mat != null:
				terrain_mat.set_shader_parameter(&"ridge_scale", 2.6)
				terrain_mat.set_shader_parameter(&"snow_line", 0.58)
			if voronoi_mat != null:
				voronoi_mat.set_shader_parameter(&"cell_scale", 6.0)
				voronoi_mat.set_shader_parameter(&"masonry_mode_mix", 1.0)
			if wool_mat != null:
				wool_mat.set_shader_parameter(&"rim_power", 3.0)
				wool_mat.set_shader_parameter(&"subsurf_scatter", 0.48)
			if foliage_mat != null:
				foliage_mat.set_shader_parameter(&"wind_strength", 0.38)
			if batch_mat != null:
				batch_mat.set_shader_parameter(&"morph_amount", 0.0)
			if sdf_mat != null:
				sdf_mat.set_shader_parameter(&"ring_frequency", 6.0)
			_setup_instance_batch_group()
		1:
			# Preset 1: High-Frequency Storm & Cobblestone Dome Mode
			if wave_mat != null:
				wave_mat.set_shader_parameter(&"wave_frequency", 6.5)
				wave_mat.set_shader_parameter(&"wave_amplitude", 0.35)
			if terrain_mat != null:
				terrain_mat.set_shader_parameter(&"ridge_scale", 4.2)
				terrain_mat.set_shader_parameter(&"snow_line", 0.42)
			if voronoi_mat != null:
				voronoi_mat.set_shader_parameter(&"cell_scale", 9.0)
				voronoi_mat.set_shader_parameter(&"masonry_mode_mix", 0.0)
			if wool_mat != null:
				wool_mat.set_shader_parameter(&"rim_power", 4.5)
				wool_mat.set_shader_parameter(&"subsurf_scatter", 0.72)
			if foliage_mat != null:
				foliage_mat.set_shader_parameter(&"wind_strength", 0.78)
			if batch_mat != null:
				batch_mat.set_shader_parameter(&"morph_amount", 0.55)
			if sdf_mat != null:
				sdf_mat.set_shader_parameter(&"ring_frequency", 10.0)
			if batch_orb_0 != null:
				batch_orb_0.set_instance_shader_parameter(&"instance_tint", Color(1.0, 0.25, 0.45, 1.0))
				batch_orb_0.set_instance_shader_parameter(&"pulse_speed", 5.0)
		2:
			# Preset 2: Calm Swell, Alpine Glacier & Unrolled Azimuthal Disc Mode
			if wave_mat != null:
				wave_mat.set_shader_parameter(&"wave_frequency", 2.5)
				wave_mat.set_shader_parameter(&"wave_amplitude", 0.18)
			if terrain_mat != null:
				terrain_mat.set_shader_parameter(&"ridge_scale", 1.8)
				terrain_mat.set_shader_parameter(&"snow_line", 0.30)
			if voronoi_mat != null:
				voronoi_mat.set_shader_parameter(&"cell_scale", 4.5)
				voronoi_mat.set_shader_parameter(&"masonry_mode_mix", 0.5)
			if wool_mat != null:
				wool_mat.set_shader_parameter(&"rim_power", 2.0)
				wool_mat.set_shader_parameter(&"subsurf_scatter", 0.85)
			if foliage_mat != null:
				foliage_mat.set_shader_parameter(&"wind_strength", 0.18)
			if batch_mat != null:
				batch_mat.set_shader_parameter(&"morph_amount", 0.92)
			if sdf_mat != null:
				sdf_mat.set_shader_parameter(&"ring_frequency", 4.0)
			if batch_orb_0 != null:
				batch_orb_0.set_instance_shader_parameter(&"instance_tint", Color(0.75, 0.42, 1.0, 1.0))
				batch_orb_0.set_instance_shader_parameter(&"pulse_speed", 1.5)

	# Refresh slider display for currently selected station
	select_station(active_station_index)
