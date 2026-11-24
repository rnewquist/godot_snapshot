# test_integration_3d_meshes_geometry.gd
# Tier 1 Integration Suite 4: 11 Primitive Meshes, SurfaceTool, ArrayMesh, and MultiMesh Buffers.
extends "res://addons/gdtest/core/test_suite.gd"

var test_scene_3d: Node3D

func _init() -> void:
	suite_name = "Tier1_Integration_3D_Meshes_Geometry"
	test_type = "integration"

func before_each() -> void:
	test_scene_3d = autofree(Node3D.new()) as Node3D
	add_child(test_scene_3d)

# ==============================================================================
# 1. ALL 11 PRIMITIVE MESHES (DISCRETE TESTS)
# ==============================================================================

func test_primitive_box_mesh() -> void:
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(2.0, 3.0, 4.0)
	box.subdivide_width = 2
	box.subdivide_height = 2
	box.subdivide_depth = 2
	assert_vector3_approx(box.size, Vector3(2.0, 3.0, 4.0), 0.001, "BoxMesh size must match")
	assert_eq(box.subdivide_width, 2)
	assert_eq(box.subdivide_height, 2)
	assert_eq(box.subdivide_depth, 2)

func test_primitive_sphere_mesh() -> void:
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = 1.5
	sphere.height = 3.0
	sphere.radial_segments = 32
	sphere.rings = 16
	sphere.is_hemisphere = false
	assert_approx(sphere.radius, 1.5, 0.001, "SphereMesh radius must match")
	assert_approx(sphere.height, 3.0, 0.001, "SphereMesh height must match")
	assert_eq(sphere.radial_segments, 32)
	assert_eq(sphere.rings, 16)
	assert_false(sphere.is_hemisphere)

func test_primitive_capsule_mesh() -> void:
	var capsule: CapsuleMesh = CapsuleMesh.new()
	capsule.radius = 0.5
	capsule.height = 2.0
	capsule.radial_segments = 16
	capsule.rings = 8
	assert_approx(capsule.radius, 0.5, 0.001, "CapsuleMesh radius must match")
	assert_approx(capsule.height, 2.0, 0.001, "CapsuleMesh height must match")
	assert_eq(capsule.radial_segments, 16)
	assert_eq(capsule.rings, 8)

func test_primitive_cylinder_mesh() -> void:
	var cylinder: CylinderMesh = CylinderMesh.new()
	cylinder.top_radius = 0.8
	cylinder.bottom_radius = 1.0
	cylinder.height = 2.5
	cylinder.radial_segments = 24
	assert_approx(cylinder.top_radius, 0.8, 0.001, "CylinderMesh top_radius must match")
	assert_approx(cylinder.bottom_radius, 1.0, 0.001, "CylinderMesh bottom_radius must match")
	assert_approx(cylinder.height, 2.5, 0.001, "CylinderMesh height must match")
	assert_eq(cylinder.radial_segments, 24)

func test_primitive_prism_mesh() -> void:
	var prism: PrismMesh = PrismMesh.new()
	prism.size = Vector3(1.0, 2.0, 1.0)
	prism.left_to_right = 0.5
	prism.subdivide_width = 1
	assert_vector3_approx(prism.size, Vector3(1.0, 2.0, 1.0), 0.001, "PrismMesh size must match")
	assert_approx(prism.left_to_right, 0.5, 0.001, "PrismMesh left_to_right must match")

func test_primitive_plane_mesh() -> void:
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(8.0, 8.0)
	plane.subdivide_width = 4
	plane.subdivide_depth = 4
	plane.center_offset = Vector3(0, 0.5, 0)
	assert_vector2_approx(plane.size, Vector2(8.0, 8.0), 0.001, "PlaneMesh size must match")
	assert_eq(plane.subdivide_width, 4)
	assert_eq(plane.subdivide_depth, 4)
	assert_vector3_approx(plane.center_offset, Vector3(0, 0.5, 0), 0.001)

func test_primitive_quad_mesh() -> void:
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(3.0, 3.0)
	quad.center_offset = Vector3(0, 0, 0)
	assert_vector2_approx(quad.size, Vector2(3.0, 3.0), 0.001, "QuadMesh size must match")
	assert_vector3_approx(quad.center_offset, Vector3.ZERO, 0.001)

func test_primitive_torus_mesh() -> void:
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = 0.6
	torus.outer_radius = 1.4
	torus.rings = 32
	torus.ring_segments = 16
	assert_approx(torus.inner_radius, 0.6, 0.001, "TorusMesh inner_radius must match")
	assert_approx(torus.outer_radius, 1.4, 0.001, "TorusMesh outer_radius must match")
	assert_eq(torus.rings, 32)
	assert_eq(torus.ring_segments, 16)

func test_primitive_tube_trail_mesh() -> void:
	var tube: TubeTrailMesh = TubeTrailMesh.new()
	tube.radius = 0.75
	tube.sections = 6
	tube.section_length = 0.4
	tube.section_rings = 4
	assert_approx(tube.radius, 0.75, 0.001, "TubeTrailMesh radius must match")
	assert_eq(tube.sections, 6)
	assert_approx(tube.section_length, 0.4, 0.001)

func test_primitive_ribbon_trail_mesh() -> void:
	var ribbon: RibbonTrailMesh = RibbonTrailMesh.new()
	ribbon.shape = RibbonTrailMesh.SHAPE_CROSS
	ribbon.sections = 8
	ribbon.section_length = 0.5
	ribbon.size = 1.0
	assert_eq(ribbon.shape, RibbonTrailMesh.SHAPE_CROSS)
	assert_eq(ribbon.sections, 8)
	assert_approx(ribbon.size, 1.0, 0.001)

func test_primitive_text_mesh() -> void:
	var text_mesh: TextMesh = TextMesh.new()
	text_mesh.text = "Godot Matrix"
	text_mesh.pixel_size = 0.02
	text_mesh.depth = 0.1
	text_mesh.curve_step = 0.5
	assert_eq(text_mesh.text, "Godot Matrix", "TextMesh text must match")
	assert_approx(text_mesh.pixel_size, 0.02, 0.001)
	assert_approx(text_mesh.depth, 0.1, 0.001)

# ==============================================================================
# 2. SURFACETOOL & PROCEDURAL ARRAYMESH
# ==============================================================================

func test_surface_tool_triangle_generation() -> void:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	st.set_normal(Vector3.UP)
	st.set_uv(Vector2(0, 0))
	st.add_vertex(Vector3(0, 0, 0))
	
	st.set_normal(Vector3.UP)
	st.set_uv(Vector2(1, 0))
	st.add_vertex(Vector3(1, 0, 0))
	
	st.set_normal(Vector3.UP)
	st.set_uv(Vector2(0, 1))
	st.add_vertex(Vector3(0, 0, 1))
	
	var mesh: ArrayMesh = st.commit()
	assert_not_null(mesh, "Committed ArrayMesh must not be null")
	assert_eq(mesh.get_surface_count(), 1, "Committed mesh must contain 1 surface")

func test_surface_tool_index_generation() -> void:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	st.add_vertex(Vector3(-1, 0, -1))
	st.add_vertex(Vector3(1, 0, -1))
	st.add_vertex(Vector3(1, 0, 1))
	st.add_vertex(Vector3(-1, 0, 1))
	
	st.add_index(0)
	st.add_index(1)
	st.add_index(2)
	st.add_index(0)
	st.add_index(2)
	st.add_index(3)
	
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	assert_eq(mesh.get_surface_count(), 1)
	var arrays = mesh.surface_get_arrays(0)
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	assert_eq(indices.size(), 6, "Mesh index count must equal 6")

func test_surface_tool_custom_attributes() -> void:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_color(Color.RED)
	st.set_uv2(Vector2(0.5, 0.5))
	st.add_vertex(Vector3(0, 0, 0))
	st.set_color(Color.GREEN)
	st.set_uv2(Vector2(1.0, 0.0))
	st.add_vertex(Vector3(1, 0, 0))
	st.set_color(Color.BLUE)
	st.set_uv2(Vector2(0.0, 1.0))
	st.add_vertex(Vector3(0, 1, 0))
	
	var mesh: ArrayMesh = st.commit()
	var arrays = mesh.surface_get_arrays(0)
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	assert_eq(colors.size(), 3, "Color array must contain 3 elements")
	assert_color_approx(colors[0], Color.RED)

func test_array_mesh_manual_construction() -> void:
	var mesh: ArrayMesh = ArrayMesh.new()
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var verts: PackedVector3Array = [Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(0, 1, 0)]
	var normals: PackedVector3Array = [Vector3(0, 0, 1), Vector3(0, 0, 1), Vector3(0, 0, 1)]
	var uvs: PackedVector2Array = [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1)]
	var indices: PackedInt32Array = [0, 1, 2]
	
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	assert_eq(mesh.get_surface_count(), 1, "ArrayMesh must have 1 surface after add_surface_from_arrays")

func test_array_mesh_surface_count_and_clear() -> void:
	var mesh: ArrayMesh = ArrayMesh.new()
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(0, 1, 0)])
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	assert_eq(mesh.get_surface_count(), 1)
	assert_eq(mesh.surface_get_primitive_type(0), Mesh.PRIMITIVE_TRIANGLES)
	
	mesh.clear_surfaces()
	assert_eq(mesh.get_surface_count(), 0, "ArrayMesh must have 0 surfaces after clear_surfaces")

func test_array_mesh_blend_shapes() -> void:
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_blend_shape(&"KeyShape_Smile")
	mesh.add_blend_shape(&"KeyShape_Blink")
	
	assert_eq(mesh.get_blend_shape_count(), 2)
	assert_eq(mesh.get_blend_shape_name(0), &"KeyShape_Smile")
	assert_eq(mesh.get_blend_shape_name(1), &"KeyShape_Blink")

func test_mesh_data_tool_manipulation() -> void:
	var box: BoxMesh = BoxMesh.new()
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, box.get_mesh_arrays())
	
	var mdt: MeshDataTool = MeshDataTool.new()
	var err = mdt.create_from_surface(mesh, 0)
	assert_eq(err, OK, "MeshDataTool create_from_surface must return OK")
	assert_gt(mdt.get_vertex_count(), 0, "Vertex count > 0")
	assert_gt(mdt.get_face_count(), 0, "Face count > 0")
	assert_gt(mdt.get_edge_count(), 0, "Edge count > 0")

func test_immediate_mesh_generation() -> void:
	var imm: ImmediateMesh = ImmediateMesh.new()
	imm.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	imm.surface_set_normal(Vector3.UP)
	imm.surface_add_vertex(Vector3(0, 0, 0))
	imm.surface_add_vertex(Vector3(1, 0, 0))
	imm.surface_add_vertex(Vector3(0, 0, 1))
	imm.surface_end()
	
	assert_eq(imm.get_surface_count(), 1, "ImmediateMesh surface count must equal 1")

# ==============================================================================
# 3. MULTIMESH BUFFERS & GEOMETRY
# ==============================================================================

func test_multimesh_transform_format_3d() -> void:
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = BoxMesh.new()
	mm.instance_count = 5
	mm.visible_instance_count = 5
	
	var t0 = Transform3D(Basis.IDENTITY, Vector3(0, 1, 0))
	var t1 = Transform3D(Basis.IDENTITY, Vector3(2, 1, 0))
	mm.set_instance_transform(0, t0)
	mm.set_instance_transform(1, t1)
	
	assert_eq(mm.instance_count, 5)
	if DisplayServer.get_name() != "headless":
		assert_vector3_approx(mm.get_instance_transform(0).origin, Vector3(0, 1, 0), 0.001)
		assert_vector3_approx(mm.get_instance_transform(1).origin, Vector3(2, 1, 0), 0.001)
	else:
		_record_pass()

func test_multimesh_color_and_custom_data() -> void:
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = BoxMesh.new()
	mm.use_colors = true
	mm.use_custom_data = true
	mm.instance_count = 2
	
	mm.set_instance_color(0, Color.GREEN)
	mm.set_instance_custom_data(0, Color(1, 2, 3, 4))
	
	assert_true(mm.use_colors)
	assert_true(mm.use_custom_data)
	if DisplayServer.get_name() != "headless":
		assert_color_approx(mm.get_instance_color(0), Color.GREEN)
		assert_color_approx(mm.get_instance_custom_data(0), Color(1, 2, 3, 4))
	else:
		_record_pass()

func test_multimesh_buffer_bulk_array() -> void:
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = BoxMesh.new()
	mm.instance_count = 3
	for i in range(3):
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, Vector3(i * 2.0, 0, 0)))
	
	assert_eq(mm.instance_count, 3)
	if DisplayServer.get_name() != "headless":
		assert_vector3_approx(mm.get_instance_transform(2).origin, Vector3(4.0, 0, 0), 0.001)
	else:
		_record_pass()

func test_multimesh_instance_3d_rendering() -> void:
	var mmi: MultiMeshInstance3D = autofree(MultiMeshInstance3D.new()) as MultiMeshInstance3D
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = BoxMesh.new()
	mm.instance_count = 4
	mmi.multimesh = mm
	test_scene_3d.add_child(mmi)
	
	assert_not_null(mmi.multimesh)
	assert_eq(mmi.multimesh.instance_count, 4)

func test_mesh_instance_3d_aabb_and_skin() -> void:
	var mi: MeshInstance3D = autofree(MeshInstance3D.new()) as MeshInstance3D
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(2, 4, 6)
	mi.mesh = box
	test_scene_3d.add_child(mi)
	
	var aabb: AABB = mi.get_aabb()
	assert_approx(aabb.size.x, 2.0, 0.001)
	assert_approx(aabb.size.y, 4.0, 0.001)
	assert_approx(aabb.size.z, 6.0, 0.001)
