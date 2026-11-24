# module_3d_modeling_and_gi.gd
extends Node3D
class_name Module3DModelingAndGI

@onready var csg_combiner: CSGCombiner3D = $CSGCombiner3D
@onready var procedural_mesh_instance: MeshInstance3D = $ProceduralMeshInstance
@onready var multimesh_instance: MultiMeshInstance3D = $MultiMeshInstance3D

var predictions: Dictionary = {}
var actuals: Dictionary = {}

func _ready() -> void:
	generate_procedural_array_mesh()
	populate_gpu_multimesh()

func generate_procedural_array_mesh() -> void:
	# PREDICTION:
	# A 4-faced 3D pyramid (base at y=0, apex at y=1.5) constructed with flat shaded separate vertices.
	# 4 triangles * 3 vertices = 12 total vertices, 12 normals, 12 colors.
	predictions["array_mesh_vertex_count"] = 12
	
	var surface_array: Array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	
	var verts: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var colors: PackedColorArray = PackedColorArray()
	
	var apex: Vector3 = Vector3(0, 1.5, 0)
	var p1: Vector3 = Vector3(-1, 0, -1)
	var p2: Vector3 = Vector3(1, 0, -1)
	var p3: Vector3 = Vector3(1, 0, 1)
	var p4: Vector3 = Vector3(-1, 0, 1)
	
	# 4 triangular faces
	var faces: Array = [
		[p1, p2, apex, Color(0.9, 0.2, 0.2)],
		[p2, p3, apex, Color(0.2, 0.9, 0.3)],
		[p3, p4, apex, Color(0.2, 0.4, 0.9)],
		[p4, p1, apex, Color(0.9, 0.8, 0.2)]
	]
	
	for face: Array in faces:
		var v0: Vector3 = face[0]
		var v1: Vector3 = face[1]
		var v2: Vector3 = face[2]
		var col: Color = face[3]
		var normal: Vector3 = (v1 - v0).cross(v2 - v0).normalized()
		
		verts.append(v0)
		verts.append(v1)
		verts.append(v2)
		normals.append(normal)
		normals.append(normal)
		normals.append(normal)
		colors.append(col)
		colors.append(col)
		colors.append(col)
	
	surface_array[Mesh.ARRAY_VERTEX] = verts
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_COLOR] = colors
	
	var arr_mesh: ArrayMesh = ArrayMesh.new()
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	procedural_mesh_instance.mesh = arr_mesh
	
	actuals["array_mesh_vertex_count"] = verts.size()

func populate_gpu_multimesh() -> void:
	# PREDICTION:
	# 1,000 instances rendered via GPU MultiMesh in single draw call.
	var instance_count: int = 1000
	predictions["multimesh_count"] = instance_count
	
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.instance_count = instance_count
	
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(0.08, 0.08, 0.08)
	mm.mesh = box
	
	for i in range(instance_count):
		var t: float = float(i) / float(instance_count)
		var angle: float = t * TAU * 10.0
		var radius: float = 1.0 + t * 3.0
		var pos: Vector3 = Vector3(cos(angle) * radius, t * 2.5, sin(angle) * radius)
		var tr: Transform3D = Transform3D(Basis(), pos)
		var col: Color = Color.from_hsv(t, 0.9, 1.0)
		mm.set_instance_transform(i, tr)
		mm.set_instance_color(i, col)
	
	multimesh_instance.multimesh = mm
	actuals["multimesh_count"] = mm.instance_count
