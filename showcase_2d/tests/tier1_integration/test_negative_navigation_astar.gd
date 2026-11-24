# test_negative_navigation_astar.gd
# Tier 1 Negative Boundary Suite: Unreachable A* Targets, Disconnected Graphs, Extreme Coords & Navmesh Queries.
extends "res://addons/gdtest/core/test_suite.gd"

func _init() -> void:
	suite_name = "Tier1_Negative_Navigation_AStar"
	test_type = "integration"

# ==============================================================================
# 1. ENCLOSED AND UNREACHABLE A* TARGETS
# ==============================================================================

func test_astar_2d_enclosed_unreachable_target() -> void:
	var astar: AStar2D = AStar2D.new()
	astar.add_point(1, Vector2(0, 0))
	astar.add_point(2, Vector2(100, 0))
	astar.add_point(3, Vector2(200, 0))
	astar.connect_points(1, 2)
	astar.connect_points(2, 3)
	
	# Point 4 is isolated with zero connections
	astar.add_point(4, Vector2(500, 500))
	
	var path_pts: PackedVector2Array = astar.get_point_path(1, 4)
	assert_eq(path_pts.size(), 0, "Path to unreachable isolated point must be empty")
	
	var path_ids: PackedInt64Array = astar.get_id_path(1, 4)
	assert_eq(path_ids.size(), 0, "ID path to unreachable isolated point must be empty")

func test_astar_grid_2d_enclosed_box_target() -> void:
	var grid: AStarGrid2D = AStarGrid2D.new()
	grid.region = Rect2i(0, 0, 7, 7)
	grid.cell_size = Vector2(32, 32)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	
	# Completely encircle cell (3, 3) with solid walls
	for x in range(2, 5):
		for y in range(2, 5):
			if x != 3 or y != 3:
				grid.set_point_solid(Vector2i(x, y), true)
	
	var path: Array[Vector2i] = grid.get_id_path(Vector2i(0, 0), Vector2i(3, 3))
	assert_eq(path.size(), 0, "Path into fully enclosed solid box must return empty array")

# ==============================================================================
# 2. DISCONNECTED GRAPH PARTITIONS AND BRIDGE TOGGLE
# ==============================================================================

func test_astar_3d_disconnected_graph_partitions_and_bridges() -> void:
	var astar: AStar3D = AStar3D.new()
	
	# Partition A (Points 10, 11)
	astar.add_point(10, Vector3(0, 0, 0))
	astar.add_point(11, Vector3(10, 0, 0))
	astar.connect_points(10, 11)
	
	# Partition B (Points 20, 21)
	astar.add_point(20, Vector3(100, 0, 0))
	astar.add_point(21, Vector3(110, 0, 0))
	astar.connect_points(20, 21)
	
	# Attempt pathfinding across disconnected partitions
	var disconnected_path: PackedVector3Array = astar.get_point_path(10, 21)
	assert_eq(disconnected_path.size(), 0, "Path across disconnected partitions must be empty")
	
	# Connect bridge between 11 and 20
	astar.connect_points(11, 20)
	var connected_path: PackedVector3Array = astar.get_point_path(10, 21)
	assert_eq(connected_path.size(), 4, "Connected path must traverse all 4 points")
	
	# Disable bridge point 11
	astar.set_point_disabled(11, true)
	var disabled_path: PackedVector3Array = astar.get_point_path(10, 21)
	assert_eq(disabled_path.size(), 0, "Path with disabled bridge point must be empty")

# ==============================================================================
# 3. EXTREME COORDINATES AND BOUNDS OVERFLOW
# ==============================================================================

func test_astar_extreme_coordinates_and_distance() -> void:
	var astar: AStar2D = AStar2D.new()
	astar.add_point(1, Vector2(-1e7, -1e7))
	astar.add_point(2, Vector2(1e7, 1e7))
	astar.connect_points(1, 2)
	
	var closest_1: int = astar.get_closest_point(Vector2(-1e7, -1e7))
	assert_eq(closest_1, 1, "Closest point for extreme negative coordinate")
	
	var closest_2: int = astar.get_closest_point(Vector2(1e7, 1e7))
	assert_eq(closest_2, 2, "Closest point for extreme positive coordinate")
	
	var path: PackedVector2Array = astar.get_point_path(1, 2)
	assert_eq(path.size(), 2, "Path across extreme coordinates contains 2 endpoints")

func test_astar_grid_2d_out_of_bounds_queries() -> void:
	var grid: AStarGrid2D = AStarGrid2D.new()
	grid.region = Rect2i(0, 0, 10, 10)
	grid.update()
	
	assert_false(grid.is_in_bounds(-1000, -1000), "Negative coordinate is out of bounds")
	assert_false(grid.is_in_bounds(1000, 1000), "Positive coordinate is out of bounds")
	assert_false(grid.is_point_solid(Vector2i(-50, -50)), "Out of bounds cell is not solid")

# ==============================================================================
# 4. NAVMESH EXTERIOR QUERIES & SERVER RESILIENCE
# ==============================================================================

func test_navigation_server_2d_map_exterior_query() -> void:
	var map_rid: RID = auto_free_rid(NavigationServer2D.map_create(), ServerType.NAVIGATION_2D)
	NavigationServer2D.map_set_active(map_rid, true)
	
	var closest: Vector2 = NavigationServer2D.map_get_closest_point(map_rid, Vector2(1e6, 1e6))
	assert_false(is_nan(closest.x) or is_nan(closest.y), "Closest point on empty 2D map must not be NaN")
	
	var path: PackedVector2Array = NavigationServer2D.map_get_path(map_rid, Vector2(100, 100), Vector2(500, 500), true)
	assert_eq(path.size(), 0, "Path on empty 2D map must be empty")

func test_navigation_server_3d_map_exterior_query() -> void:
	var map_rid: RID = auto_free_rid(NavigationServer3D.map_create(), ServerType.NAVIGATION_3D)
	NavigationServer3D.map_set_active(map_rid, true)
	
	var closest: Vector3 = NavigationServer3D.map_get_closest_point(map_rid, Vector3(1e6, 1e6, 1e6))
	assert_false(is_nan(closest.x) or is_nan(closest.y) or is_nan(closest.z), "Closest point on empty 3D map must not be NaN")
	
	var path: PackedVector3Array = NavigationServer3D.map_get_path(map_rid, Vector3(0, 0, 0), Vector3(100, 0, 100), true)
	assert_eq(path.size(), 0, "Path on empty 3D map must be empty")

func test_navigation_server_invalid_rid_tolerance() -> void:
	var empty_rid: RID = RID()
	assert_false(empty_rid.is_valid(), "Default RID must be invalid")
	
	var pt_2d: Vector2 = NavigationServer2D.map_get_closest_point(empty_rid, Vector2(50, 50))
	assert_vector2_approx(pt_2d, Vector2.ZERO, 0.001, "Invalid RID 2D query returns Vector2.ZERO")
	
	var pt_3d: Vector3 = NavigationServer3D.map_get_closest_point(empty_rid, Vector3(50, 50, 50))
	assert_vector3_approx(pt_3d, Vector3.ZERO, 0.001, "Invalid RID 3D query returns Vector3.ZERO")
