# test_integration_navigation_astar_agents.gd
# Tier 1 Integration Suite 12: Navigation, AStar Pathfinding & Agent AI (16 tests)
# Tests AStarGrid2D, AStar2D/3D, NavigationServer2D/3D with physics frame settling, NavAgents, Obstacles, and Links.
extends "res://addons/gdtest/core/test_suite.gd"

func _init() -> void:
	suite_name = "Tier1_Navigation_AStar_Agents_Integration_Suite"
	test_type = "integration"

## 1. AStarGrid2D Grid Initialization & Region Bounds
func test_astar_grid_2d_initialization_and_region() -> void:
	var astar: AStarGrid2D = AStarGrid2D.new()
	astar.region = Rect2i(0, 0, 10, 10)
	astar.cell_size = Vector2(16, 16)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	
	assert_eq(astar.region.size, Vector2i(10, 10), "AStarGrid2D region size must be 10x10")
	assert_vector2_approx(astar.cell_size, Vector2(16, 16), 0.001, "Cell size must be 16x16")
	assert_true(astar.is_in_bounds(5, 5), "Point (5, 5) must be in bounds")
	assert_false(astar.is_in_bounds(12, 12), "Point (12, 12) must be out of bounds")

## 2. AStarGrid2D Solid Cells & Obstacle Routing
func test_astar_grid_2d_solid_cells_and_pathfinding() -> void:
	var astar: AStarGrid2D = AStarGrid2D.new()
	astar.region = Rect2i(0, 0, 5, 5)
	astar.cell_size = Vector2(32, 32)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	
	# Block middle column except top and bottom
	astar.set_point_solid(Vector2i(2, 1), true)
	astar.set_point_solid(Vector2i(2, 2), true)
	astar.set_point_solid(Vector2i(2, 3), true)
	
	assert_true(astar.is_point_solid(Vector2i(2, 2)), "Cell (2, 2) must be solid")
	assert_false(astar.is_point_solid(Vector2i(0, 0)), "Cell (0, 0) must be walkable")
	
	var path = astar.get_id_path(Vector2i(0, 2), Vector2i(4, 2))
	assert_not_empty(path, "Path must exist around obstacle")
	assert_array_not_contains(path, Vector2i(2, 2), "Path must not traverse solid obstacle cell")

## 3. AStarGrid2D Diagonal Movement Modes
func test_astar_grid_2d_diagonal_modes() -> void:
	var astar_no_diag: AStarGrid2D = AStarGrid2D.new()
	astar_no_diag.region = Rect2i(0, 0, 5, 5)
	astar_no_diag.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_no_diag.update()
	
	var path_manhattan = astar_no_diag.get_id_path(Vector2i(0, 0), Vector2i(2, 2))
	# Manhattan path length from (0,0) to (2,2) with never diagonal is 5 points (0,0)->(1,0)->(2,0)->(2,1)->(2,2)
	assert_eq(path_manhattan.size(), 5, "Manhattan path from (0,0) to (2,2) without diagonals must have 5 steps")
	
	var astar_diag: AStarGrid2D = AStarGrid2D.new()
	astar_diag.region = Rect2i(0, 0, 5, 5)
	astar_diag.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ALWAYS
	astar_diag.update()
	
	var path_diag = astar_diag.get_id_path(Vector2i(0, 0), Vector2i(2, 2))
	# Diagonal path from (0,0) to (2,2) is 3 points: (0,0)->(1,1)->(2,2)
	assert_eq(path_diag.size(), 3, "Diagonal path from (0,0) to (2,2) must take direct 3 steps")

## 4. AStar2D Arbitrary Point Graph and Weighted Routing
func test_astar_2d_arbitrary_graph_points_and_segments() -> void:
	var astar: AStar2D = AStar2D.new()
	astar.add_point(1, Vector2(0, 0), 1.0)
	astar.add_point(2, Vector2(50, 0), 1.0)
	astar.add_point(3, Vector2(100, 0), 1.0)
	astar.connect_points(1, 2)
	astar.connect_points(2, 3)
	
	assert_true(astar.are_points_connected(1, 2), "Points 1 and 2 must be connected")
	var path = astar.get_point_path(1, 3)
	assert_eq(path.size(), 3, "Point path 1 -> 3 must traverse 3 nodes")
	
	astar.disconnect_points(1, 2)
	assert_false(astar.are_points_connected(1, 2), "Points 1 and 2 must be disconnected")
	var broken_path = astar.get_point_path(1, 3)
	assert_empty(broken_path, "Disconnected graph must return empty path")

## 5. AStar3D 3D Coordinate Point Routing
func test_astar_3d_points_and_pathfinding() -> void:
	var astar: AStar3D = AStar3D.new()
	astar.add_point(1, Vector3(0, 0, 0))
	astar.add_point(2, Vector3(0, 10, 0))
	astar.add_point(3, Vector3(0, 20, 0))
	astar.connect_points(1, 2)
	astar.connect_points(2, 3)
	
	var path_3d = astar.get_point_path(1, 3)
	assert_eq(path_3d.size(), 3, "3D Path must contain 3 points")
	assert_vector3_approx(path_3d[1], Vector3(0, 10, 0), 0.001, "Intermediate node must be at y=10")

## 6. NavigationServer3D Map Creation & Sync Settling
func test_navigation_server_3d_map_creation_and_synchronization() -> void:
	var map_rid: RID = auto_free_rid(NavigationServer3D.map_create(), ServerType.NAVIGATION_3D)
	assert_true(map_rid.is_valid(), "Map RID must be valid")
	
	NavigationServer3D.map_set_active(map_rid, true)
	NavigationServer3D.map_set_cell_size(map_rid, 0.4)
	await step_physics_frames(2)
	
	assert_true(NavigationServer3D.map_is_active(map_rid), "Navigation map must be active after sync")
	assert_approx(NavigationServer3D.map_get_cell_size(map_rid), 0.4, 0.001, "Cell size must equal 0.4")

## 7. NavigationServer3D Region & NavigationMesh Assignment
func test_navigation_server_3d_region_and_navigation_mesh() -> void:
	var map_rid: RID = auto_free_rid(NavigationServer3D.map_create(), ServerType.NAVIGATION_3D)
	var region_rid: RID = auto_free_rid(NavigationServer3D.region_create(), ServerType.NAVIGATION_3D)
	NavigationServer3D.map_set_active(map_rid, true)
	NavigationServer3D.region_set_map(region_rid, map_rid)
	
	var nav_mesh: NavigationMesh = NavigationMesh.new()
	nav_mesh.vertices = PackedVector3Array([
		Vector3(0, 0, 0),
		Vector3(10, 0, 0),
		Vector3(10, 0, 10),
		Vector3(0, 0, 10)
	])
	nav_mesh.add_polygon(PackedInt32Array([0, 1, 2, 3]))
	NavigationServer3D.region_set_navigation_mesh(region_rid, nav_mesh)
	await step_physics_frames(2)
	
	assert_eq(NavigationServer3D.region_get_map(region_rid), map_rid, "Region must be bound to target map")

## 8. NavigationServer3D Closest Point Query
func test_navigation_server_3d_map_closest_point_query() -> void:
	var map_rid: RID = auto_free_rid(NavigationServer3D.map_create(), ServerType.NAVIGATION_3D)
	NavigationServer3D.map_set_active(map_rid, true)
	await step_physics_frames(2)
	
	var iter_id = NavigationServer3D.map_get_iteration_id(map_rid)
	assert_gte(iter_id, 0, "Map iteration ID must be non-negative")

## 9. NavigationAgent3D Setup and Desired Distances
func test_navigation_agent_3d_setup_and_target_desired_distance() -> void:
	var agent: NavigationAgent3D = autofree(NavigationAgent3D.new()) as NavigationAgent3D
	add_child(agent)
	agent.target_position = Vector3(15, 0, 25)
	agent.target_desired_distance = 1.25
	agent.path_desired_distance = 0.5
	
	assert_vector3_approx(agent.target_position, Vector3(15, 0, 25), 0.001, "Target position must match")
	assert_approx(agent.target_desired_distance, 1.25, 0.001, "Target desired distance must be 1.25")
	assert_approx(agent.path_desired_distance, 0.5, 0.001, "Path desired distance must be 0.5")

## 10. NavigationAgent3D RVO Avoidance Configuration
func test_navigation_agent_3d_avoidance_configuration() -> void:
	var agent: NavigationAgent3D = autofree(NavigationAgent3D.new()) as NavigationAgent3D
	add_child(agent)
	agent.avoidance_enabled = true
	agent.radius = 0.75
	agent.max_speed = 8.5
	agent.neighbor_distance = 15.0
	
	assert_true(agent.avoidance_enabled, "Avoidance must be enabled")
	assert_approx(agent.radius, 0.75, 0.001, "Radius must be 0.75")
	assert_approx(agent.max_speed, 8.5, 0.001, "Max speed must be 8.5")
	assert_approx(agent.neighbor_distance, 15.0, 0.001, "Neighbor distance must be 15.0")

## 11. NavigationAgent3D Navigation Layers Mask
func test_navigation_agent_3d_navigation_layers() -> void:
	var agent: NavigationAgent3D = autofree(NavigationAgent3D.new()) as NavigationAgent3D
	add_child(agent)
	agent.navigation_layers = 5 # Binary 0101 -> Layers 1 and 3
	
	assert_eq(agent.navigation_layers, 5, "Navigation layers bitmask must equal 5")

## 12. NavigationServer2D Map Creation & Synchronization
func test_navigation_server_2d_map_creation_and_synchronization() -> void:
	var map_2d_rid: RID = auto_free_rid(NavigationServer2D.map_create(), ServerType.NAVIGATION_2D)
	assert_true(map_2d_rid.is_valid(), "2D Map RID must be valid")
	
	NavigationServer2D.map_set_active(map_2d_rid, true)
	NavigationServer2D.map_set_cell_size(map_2d_rid, 1.5)
	await step_physics_frames(2)
	
	assert_true(NavigationServer2D.map_is_active(map_2d_rid), "2D map must be active after sync")
	assert_approx(NavigationServer2D.map_get_cell_size(map_2d_rid), 1.5, 0.001, "2D cell size must match 1.5")

## 13. NavigationServer2D Region & Polygon Configuration
func test_navigation_server_2d_region_and_polygon() -> void:
	var map_2d_rid: RID = auto_free_rid(NavigationServer2D.map_create(), ServerType.NAVIGATION_2D)
	var reg_2d_rid: RID = auto_free_rid(NavigationServer2D.region_create(), ServerType.NAVIGATION_2D)
	NavigationServer2D.region_set_map(reg_2d_rid, map_2d_rid)
	
	var nav_poly: NavigationPolygon = NavigationPolygon.new()
	nav_poly.vertices = PackedVector2Array([
		Vector2(0, 0),
		Vector2(100, 0),
		Vector2(100, 100),
		Vector2(0, 100)
	])
	nav_poly.add_polygon(PackedInt32Array([0, 1, 2, 3]))
	NavigationServer2D.region_set_navigation_polygon(reg_2d_rid, nav_poly)
	await step_physics_frames(2)
	
	assert_eq(NavigationServer2D.region_get_map(reg_2d_rid), map_2d_rid, "2D Region must be connected to 2D Map")

## 14. NavigationAgent2D Setup and Path Properties
func test_navigation_agent_2d_setup_and_properties() -> void:
	var agent_2d: NavigationAgent2D = autofree(NavigationAgent2D.new()) as NavigationAgent2D
	add_child(agent_2d)
	agent_2d.target_position = Vector2(250, 350)
	agent_2d.path_max_distance = 64.0
	agent_2d.target_desired_distance = 4.0
	
	assert_vector2_approx(agent_2d.target_position, Vector2(250, 350), 0.001, "Target position must match")
	assert_approx(agent_2d.path_max_distance, 64.0, 0.001, "Path max distance must match 64.0")
	assert_approx(agent_2d.target_desired_distance, 4.0, 0.001, "Target desired distance must match 4.0")

## 15. Navigation Obstacles (2D & 3D) Configuration
func test_navigation_obstacle_2d_and_3d_setup() -> void:
	var obs2d: NavigationObstacle2D = autofree(NavigationObstacle2D.new()) as NavigationObstacle2D
	obs2d.radius = 32.0
	obs2d.avoidance_enabled = true
	add_child(obs2d)
	
	var obs3d: NavigationObstacle3D = autofree(NavigationObstacle3D.new()) as NavigationObstacle3D
	obs3d.radius = 2.4
	obs3d.avoidance_enabled = true
	add_child(obs3d)
	
	assert_approx(obs2d.radius, 32.0, 0.001, "2D Obstacle radius must be 32.0")
	assert_true(obs2d.avoidance_enabled, "2D Obstacle avoidance must be true")
	assert_approx(obs3d.radius, 2.4, 0.001, "3D Obstacle radius must be 2.4")
	assert_true(obs3d.avoidance_enabled, "3D Obstacle avoidance must be true")

## 16. Navigation Links (2D & 3D) Bidirectional Connections
func test_navigation_link_2d_and_3d_bidirectional() -> void:
	var link2d: NavigationLink2D = autofree(NavigationLink2D.new()) as NavigationLink2D
	link2d.start_position = Vector2(10, 20)
	link2d.end_position = Vector2(150, 200)
	link2d.bidirectional = true
	add_child(link2d)
	
	var link3d: NavigationLink3D = autofree(NavigationLink3D.new()) as NavigationLink3D
	link3d.start_position = Vector3(0, 1, 0)
	link3d.end_position = Vector3(10, 5, 20)
	link3d.bidirectional = false
	add_child(link3d)
	
	assert_vector2_approx(link2d.start_position, Vector2(10, 20), 0.001, "2D Link start pos must match")
	assert_vector2_approx(link2d.end_position, Vector2(150, 200), 0.001, "2D Link end pos must match")
	assert_true(link2d.bidirectional, "2D Link must be bidirectional")
	
	assert_vector3_approx(link3d.start_position, Vector3(0, 1, 0), 0.001, "3D Link start pos must match")
	assert_vector3_approx(link3d.end_position, Vector3(10, 5, 20), 0.001, "3D Link end pos must match")
	assert_false(link3d.bidirectional, "3D Link must be unidirectional")
